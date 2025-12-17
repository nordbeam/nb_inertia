defmodule NbInertia.Plugs.PrecognitionTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias NbInertia.Plugs.Precognition

  describe "plug call/2" do
    test "detects Precognition request from header" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      assert conn.private[:precognition] == true
    end

    test "marks non-Precognition request as false" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      assert conn.private[:precognition] == false
    end

    test "extracts Precognition-Validate-Only fields" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> put_req_header("precognition-validate-only", "name,email")
        |> Precognition.call([])

      assert conn.private[:precognition_validate_only] == ["name", "email"]
    end

    test "handles whitespace in Precognition-Validate-Only" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> put_req_header("precognition-validate-only", "name , email , phone")
        |> Precognition.call([])

      assert conn.private[:precognition_validate_only] == ["name", "email", "phone"]
    end

    test "sets validate_only to nil when header not present" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      assert conn.private[:precognition_validate_only] == nil
    end

    test "sets validate_only to nil when header is empty" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> put_req_header("precognition-validate-only", "")
        |> Precognition.call([])

      assert conn.private[:precognition_validate_only] == nil
    end
  end

  describe "precognition_request?/1" do
    test "returns true for Precognition requests" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      assert Precognition.precognition_request?(conn) == true
    end

    test "returns false for non-Precognition requests" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      assert Precognition.precognition_request?(conn) == false
    end
  end

  describe "precognition_fields/1" do
    test "returns list of fields when header present" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> put_req_header("precognition-validate-only", "name,email")
        |> Precognition.call([])

      assert Precognition.precognition_fields(conn) == ["name", "email"]
    end

    test "returns nil when header not present" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      assert Precognition.precognition_fields(conn) == nil
    end
  end

  describe "validate_precognition/3 with error map" do
    test "returns {:ok, conn} for non-Precognition requests" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      errors = %{name: ["is required"]}

      assert {:ok, ^conn} = Precognition.validate_precognition(conn, errors)
    end

    test "returns {:precognition, conn} with 204 when no errors" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      {:precognition, result_conn} = Precognition.validate_precognition(conn, %{})

      assert result_conn.status == 204
      assert result_conn.halted == true
      assert get_resp_header(result_conn, "precognition") == ["true"]
      assert get_resp_header(result_conn, "precognition-success") == ["true"]
      assert get_resp_header(result_conn, "vary") == ["Precognition"]
    end

    test "returns {:precognition, conn} with 422 when errors exist" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      errors = %{name: ["is required"], email: ["is invalid"]}

      {:precognition, result_conn} = Precognition.validate_precognition(conn, errors)

      assert result_conn.status == 422
      assert result_conn.halted == true
      assert get_resp_header(result_conn, "precognition") == ["true"]
      assert get_resp_header(result_conn, "vary") == ["Precognition"]

      body = Jason.decode!(result_conn.resp_body)
      assert body["errors"]["name"] == ["is required"]
      assert body["errors"]["email"] == ["is invalid"]
    end

    test "filters errors when :only option provided" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      errors = %{name: ["is required"], email: ["is invalid"], phone: ["too short"]}

      {:precognition, result_conn} =
        Precognition.validate_precognition(conn, errors, only: ["name", "email"])

      body = Jason.decode!(result_conn.resp_body)
      assert body["errors"]["name"] == ["is required"]
      assert body["errors"]["email"] == ["is invalid"]
      refute Map.has_key?(body["errors"], "phone")
    end

    test "camelizes error keys when :camelize is true" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      errors = %{first_name: ["is required"], last_name: ["is required"]}

      {:precognition, result_conn} =
        Precognition.validate_precognition(conn, errors, camelize: true)

      body = Jason.decode!(result_conn.resp_body)
      assert Map.has_key?(body["errors"], "firstName")
      assert Map.has_key?(body["errors"], "lastName")
      refute Map.has_key?(body["errors"], "first_name")
      refute Map.has_key?(body["errors"], "last_name")
    end

    test "does not camelize error keys when :camelize is false" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      errors = %{first_name: ["is required"]}

      {:precognition, result_conn} =
        Precognition.validate_precognition(conn, errors, camelize: false)

      body = Jason.decode!(result_conn.resp_body)
      assert Map.has_key?(body["errors"], "first_name")
      refute Map.has_key?(body["errors"], "firstName")
    end
  end

  describe "validate_precognition/3 with Ecto.Changeset" do
    defmodule TestSchema do
      use Ecto.Schema
      import Ecto.Changeset

      embedded_schema do
        field(:name, :string)
        field(:email, :string)
      end

      def changeset(struct, params) do
        struct
        |> cast(params, [:name, :email])
        |> validate_required([:name, :email])
        |> validate_length(:name, min: 3)
        |> validate_format(:email, ~r/@/)
      end
    end

    test "extracts errors from invalid changeset" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      changeset = TestSchema.changeset(%TestSchema{}, %{name: "ab", email: "invalid"})

      {:precognition, result_conn} = Precognition.validate_precognition(conn, changeset)

      assert result_conn.status == 422

      body = Jason.decode!(result_conn.resp_body)
      assert body["errors"]["name"] != nil
      assert body["errors"]["email"] != nil
    end

    test "returns 204 for valid changeset" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      changeset =
        TestSchema.changeset(%TestSchema{}, %{name: "John Doe", email: "john@example.com"})

      {:precognition, result_conn} = Precognition.validate_precognition(conn, changeset)

      assert result_conn.status == 204
      assert get_resp_header(result_conn, "precognition-success") == ["true"]
    end

    test "filters changeset errors when :only option provided" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      changeset = TestSchema.changeset(%TestSchema{}, %{name: "ab", email: "invalid"})

      {:precognition, result_conn} =
        Precognition.validate_precognition(conn, changeset, only: ["name"])

      body = Jason.decode!(result_conn.resp_body)
      assert body["errors"]["name"] != nil
      refute Map.has_key?(body["errors"], "email")
    end
  end

  describe "send_precognition_response/2" do
    test "sends 204 with success headers for empty errors" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      result_conn = Precognition.send_precognition_response(conn, %{})

      assert result_conn.status == 204
      assert result_conn.halted == true
      assert get_resp_header(result_conn, "precognition") == ["true"]
      assert get_resp_header(result_conn, "precognition-success") == ["true"]
      assert get_resp_header(result_conn, "vary") == ["Precognition"]
      assert result_conn.resp_body == ""
    end

    test "sends 422 with errors JSON for non-empty errors" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      errors = %{name: "is required"}
      result_conn = Precognition.send_precognition_response(conn, errors)

      assert result_conn.status == 422
      assert result_conn.halted == true
      assert get_resp_header(result_conn, "precognition") == ["true"]
      assert get_resp_header(result_conn, "vary") == ["Precognition"]
      refute "true" in get_resp_header(result_conn, "precognition-success")

      body = Jason.decode!(result_conn.resp_body)
      assert body["errors"]["name"] == "is required"
    end
  end

  describe "precognition/3 macro" do
    defmodule TestController do
      use NbInertia.Plugs.Precognition

      def create_with_errors(conn, errors) do
        precognition conn, errors do
          # This block should not run for Precognition requests
          send_resp(conn, 200, "created")
        end
      end

      def create_with_changeset(conn, changeset) do
        precognition conn, changeset do
          send_resp(conn, 200, "created")
        end
      end

      def create_with_options(conn, errors, only) do
        precognition conn, errors, only: only do
          send_resp(conn, 200, "created")
        end
      end
    end

    test "handles Precognition request with errors" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      result_conn = TestController.create_with_errors(conn, %{name: ["is required"]})

      assert result_conn.status == 422
      assert result_conn.halted == true
    end

    test "handles Precognition request with no errors" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      result_conn = TestController.create_with_errors(conn, %{})

      assert result_conn.status == 204
      assert result_conn.halted == true
    end

    test "executes block for non-Precognition requests" do
      conn =
        conn(:post, "/users")
        |> Precognition.call([])

      result_conn = TestController.create_with_errors(conn, %{name: ["is required"]})

      assert result_conn.status == 200
      assert result_conn.resp_body == "created"
    end

    test "passes options to validate_precognition" do
      conn =
        conn(:post, "/users")
        |> put_req_header("precognition", "true")
        |> Precognition.call([])

      errors = %{name: ["is required"], email: ["is invalid"]}
      result_conn = TestController.create_with_options(conn, errors, ["name"])

      body = Jason.decode!(result_conn.resp_body)
      assert Map.has_key?(body["errors"], "name")
      refute Map.has_key?(body["errors"], "email")
    end
  end
end
