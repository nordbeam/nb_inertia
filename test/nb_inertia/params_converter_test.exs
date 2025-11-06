defmodule NbInertia.ParamsConverterTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias NbInertia.ParamsConverter

  describe "ParamsConverter plug" do
    test "converts camelCase keys to snake_case" do
      conn =
        conn(:post, "/test", %{
          "firstName" => "John",
          "lastName" => "Doe",
          "emailAddress" => "john@example.com"
        })
        |> ParamsConverter.call([])

      assert conn.params["first_name"] == "John"
      assert conn.params["last_name"] == "Doe"
      assert conn.params["email_address"] == "john@example.com"
    end

    test "converts nested maps" do
      conn =
        conn(:post, "/test", %{
          "user" => %{
            "firstName" => "John",
            "profileData" => %{
              "dateOfBirth" => "1990-01-01"
            }
          }
        })
        |> ParamsConverter.call([])

      assert conn.params["user"]["first_name"] == "John"
      assert conn.params["user"]["profile_data"]["date_of_birth"] == "1990-01-01"
    end

    test "converts arrays of maps" do
      conn =
        conn(:post, "/test", %{
          "userList" => [
            %{"firstName" => "John", "lastName" => "Doe"},
            %{"firstName" => "Jane", "lastName" => "Smith"}
          ]
        })
        |> ParamsConverter.call([])

      assert conn.params["user_list"] == [
               %{"first_name" => "John", "last_name" => "Doe"},
               %{"first_name" => "Jane", "last_name" => "Smith"}
             ]
    end

    test "handles nested list fields from form_inputs" do
      conn =
        conn(:post, "/test", %{
          "space" => %{
            "name" => "My Space",
            "questions" => [
              %{
                "questionText" => "What is your name?",
                "required" => true,
                "position" => 1
              },
              %{
                "questionText" => "What is your email?",
                "required" => false,
                "position" => 2
              }
            ]
          }
        })
        |> ParamsConverter.call([])

      assert conn.params["space"]["name"] == "My Space"

      assert conn.params["space"]["questions"] == [
               %{
                 "question_text" => "What is your name?",
                 "required" => true,
                 "position" => 1
               },
               %{
                 "question_text" => "What is your email?",
                 "required" => false,
                 "position" => 2
               }
             ]
    end

    test "handles deeply nested list structures" do
      conn =
        conn(:post, "/test", %{
          "formData" => %{
            "sections" => [
              %{
                "sectionTitle" => "Personal Info",
                "fields" => [
                  %{"fieldName" => "firstName", "fieldType" => "text"},
                  %{"fieldName" => "lastName", "fieldType" => "text"}
                ]
              }
            ]
          }
        })
        |> ParamsConverter.call([])

      assert conn.params["form_data"]["sections"] == [
               %{
                 "section_title" => "Personal Info",
                 "fields" => [
                   %{"field_name" => "firstName", "field_type" => "text"},
                   %{"field_name" => "lastName", "field_type" => "text"}
                 ]
               }
             ]
    end

    test "preserves atom keys" do
      # Manually set params with atom keys since conn() converts to strings
      conn = %Plug.Conn{
        params: %{
          "camelCaseString" => "value",
          camelCaseAtom: "value2"
        },
        body_params: %{}
      }

      conn = ParamsConverter.call(conn, [])

      assert conn.params["camel_case_string"] == "value"
      assert conn.params[:camelCaseAtom] == "value2"
    end

    test "handles mixed types in arrays" do
      conn =
        conn(:post, "/test", %{
          "mixedArray" => [
            "string",
            123,
            %{"nestedKey" => "value"},
            true
          ]
        })
        |> ParamsConverter.call([])

      assert conn.params["mixed_array"] == [
               "string",
               123,
               %{"nested_key" => "value"},
               true
             ]
    end

    test "handles empty structures" do
      conn =
        conn(:post, "/test", %{
          "emptyMap" => %{},
          "emptyArray" => []
        })
        |> ParamsConverter.call([])

      assert conn.params["empty_map"] == %{}
      assert conn.params["empty_array"] == []
    end

    test "skips conversion when snake_case_params is false" do
      # Set config to false
      Application.put_env(:nb_inertia, :snake_case_params, false)

      on_exit(fn ->
        Application.delete_env(:nb_inertia, :snake_case_params)
      end)

      conn =
        conn(:post, "/test", %{
          "firstName" => "John",
          "lastName" => "Doe"
        })
        |> ParamsConverter.call([])

      # Should NOT convert
      assert conn.params["firstName"] == "John"
      assert conn.params["lastName"] == "Doe"
      refute Map.has_key?(conn.params, "first_name")
    end

    test "converts both params and body_params" do
      conn =
        conn(:post, "/test", %{"queryParam" => "query_value"})
        |> Map.put(:body_params, %{"bodyParam" => "body_value"})
        |> ParamsConverter.call([])

      assert conn.params["query_param"] == "query_value"
      assert conn.body_params["body_param"] == "body_value"
    end
  end

  describe "deep_convert_keys/1" do
    test "handles nil values" do
      result = ParamsConverter.deep_convert_keys(%{"nullValue" => nil})
      assert result["null_value"] == nil
    end

    test "handles boolean values" do
      result =
        ParamsConverter.deep_convert_keys(%{
          "isActive" => true,
          "isDeleted" => false
        })

      assert result["is_active"] == true
      assert result["is_deleted"] == false
    end

    test "handles numeric values" do
      result =
        ParamsConverter.deep_convert_keys(%{
          "itemCount" => 42,
          "priceAmount" => 99.99
        })

      assert result["item_count"] == 42
      assert result["price_amount"] == 99.99
    end

    test "preserves non-map, non-list values" do
      assert ParamsConverter.deep_convert_keys("string") == "string"
      assert ParamsConverter.deep_convert_keys(123) == 123
      assert ParamsConverter.deep_convert_keys(true) == true
      assert ParamsConverter.deep_convert_keys(nil) == nil
    end
  end

  describe "real-world form input scenarios" do
    test "handles form submission with nested questions list" do
      # Simulates data from the TypeScript form we generate
      conn =
        conn(:post, "/spaces", %{
          "space" => %{
            "name" => "Customer Feedback",
            "description" => "Collect customer feedback",
            "questions" => [
              %{
                "questionText" => "How satisfied are you?",
                "questionType" => "rating",
                "required" => true,
                "position" => 1,
                "options" => [
                  %{"optionText" => "Very Satisfied", "optionValue" => "5"},
                  %{"optionText" => "Satisfied", "optionValue" => "4"}
                ]
              },
              %{
                "questionText" => "Additional comments",
                "questionType" => "text",
                "required" => false,
                "position" => 2
              }
            ]
          }
        })
        |> ParamsConverter.call([])

      space = conn.params["space"]
      assert space["name"] == "Customer Feedback"
      assert space["description"] == "Collect customer feedback"

      [question1, question2] = space["questions"]

      assert question1["question_text"] == "How satisfied are you?"
      assert question1["question_type"] == "rating"
      assert question1["required"] == true
      assert question1["position"] == 1

      assert question1["options"] == [
               %{"option_text" => "Very Satisfied", "option_value" => "5"},
               %{"option_text" => "Satisfied", "option_value" => "4"}
             ]

      assert question2["question_text"] == "Additional comments"
      assert question2["question_type"] == "text"
      assert question2["required"] == false
      assert question2["position"] == 2
    end

    test "handles multiple forms submission" do
      conn =
        conn(:post, "/settings", %{
          "profile" => %{
            "displayName" => "John Doe",
            "emailAddress" => "john@example.com"
          },
          "password" => %{
            "currentPassword" => "old123",
            "newPassword" => "new456",
            "confirmPassword" => "new456"
          }
        })
        |> ParamsConverter.call([])

      assert conn.params["profile"]["display_name"] == "John Doe"
      assert conn.params["profile"]["email_address"] == "john@example.com"
      assert conn.params["password"]["current_password"] == "old123"
      assert conn.params["password"]["new_password"] == "new456"
      assert conn.params["password"]["confirm_password"] == "new456"
    end
  end
end
