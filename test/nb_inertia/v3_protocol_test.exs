defmodule NbInertia.V3ProtocolTest do
  use ExUnit.Case, async: true

  import NbInertia.CoreController
  import ExUnit.CaptureLog
  import Plug.Conn
  import Plug.Test

  alias NbInertia.Flash

  defp inertia_conn(extra_headers \\ []) do
    version =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])
      |> then(& &1.private[:inertia_version])

    base_headers = [
      {"x-inertia", "true"},
      {"x-inertia-version", version}
    ]

    conn =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})

    Enum.reduce(base_headers ++ extra_headers, conn, fn {key, value}, acc ->
      put_req_header(acc, key, value)
    end)
    |> NbInertia.Plug.call([])
  end

  test "skips once props already cached by the client" do
    conn =
      inertia_conn([{"x-inertia-except-once-props", "plans"}])
      |> render_inertia("Billing/Plans", %{
        plans: inertia_once(fn -> [%{id: 1, name: "Basic"}] end),
        current_plan: %{id: 1, name: "Basic"}
      })

    page = Jason.decode!(conn.resp_body)

    assert page["onceProps"] == %{"plans" => %{"prop" => "plans"}}
    refute Map.has_key?(page["props"], "plans")
    assert page["props"]["currentPlan"] == %{"id" => 1, "name" => "Basic"}
  end

  test "keeps fresh once props even when the client sends the exclusion header" do
    conn =
      inertia_conn([{"x-inertia-except-once-props", "plans"}])
      |> render_inertia("Billing/Plans", %{
        plans: inertia_once(fn -> [%{id: 1, name: "Basic"}] end, fresh: true)
      })

    page = Jason.decode!(conn.resp_body)

    assert page["onceProps"] == %{"plans" => %{"prop" => "plans"}}
    assert page["props"]["plans"] == [%{"id" => 1, "name" => "Basic"}]
  end

  test "rescues deferred prop failures and exposes rescuedProps metadata" do
    log =
      capture_log(fn ->
        conn =
          inertia_conn([
            {"x-inertia-partial-component", "Analytics/Show"},
            {"x-inertia-partial-data", "riskScore"}
          ])
          |> render_inertia("Analytics/Show", %{
            risk_score: inertia_defer(fn -> raise "analytics unavailable" end, on_error: :ignore),
            stable: true
          })

        page = Jason.decode!(conn.resp_body)

        assert conn.status == 200
        assert page["rescuedProps"] == ["riskScore"]
        refute Map.has_key?(page["props"], "riskScore")
        refute Map.has_key?(page["props"], "stable")
      end)

    assert log =~ "Rescued deferred Inertia prop \"riskScore\""
    assert log =~ "analytics unavailable"
  end

  test "does not rescue deferred failures unless explicitly requested" do
    assert_raise RuntimeError, "analytics unavailable", fn ->
      inertia_conn([
        {"x-inertia-partial-component", "Analytics/Show"},
        {"x-inertia-partial-data", "riskScore"}
      ])
      |> render_inertia("Analytics/Show", %{
        risk_score: inertia_defer(fn -> raise "analytics unavailable" end)
      })
    end
  end

  test "supports a named rescue-enabled deferred group" do
    prop = inertia_defer(fn -> :ok end, "analytics", on_error: :ignore)

    assert {:defer, {fun, "analytics", :ignore}} = prop
    assert fun.() == :ok
  end

  test "supports nested deferred paths and nested rescue metadata" do
    initial =
      inertia_conn()
      |> render_inertia("Analytics/Show", %{
        analytics: %{
          risk_score:
            inertia_defer(fn -> raise "analytics unavailable" end, "analytics", on_error: :ignore)
        }
      })
      |> then(&Jason.decode!(&1.resp_body))

    assert initial["deferredProps"] == %{"analytics" => ["analytics.riskScore"]}
    assert initial["props"]["analytics"] == %{}

    log =
      capture_log(fn ->
        page =
          inertia_conn([
            {"x-inertia-partial-component", "Analytics/Show"},
            {"x-inertia-partial-data", "analytics.riskScore"}
          ])
          |> render_inertia("Analytics/Show", %{
            analytics: %{
              risk_score:
                inertia_defer(fn -> raise "analytics unavailable" end, "analytics",
                  on_error: :ignore
                )
            }
          })
          |> then(&Jason.decode!(&1.resp_body))

        assert page["props"]["analytics"] == %{}
        assert page["rescuedProps"] == ["analytics.riskScore"]
      end)

    assert log =~ "analytics.riskScore"
  end

  test "supports nested once props and client exclusions" do
    initial =
      inertia_conn()
      |> render_inertia("Billing/Plans", %{
        billing: %{plans: inertia_once(fn -> [%{id: 1}] end)}
      })
      |> then(&Jason.decode!(&1.resp_body))

    assert initial["onceProps"] == %{"billing.plans" => %{"prop" => "billing.plans"}}
    assert initial["props"]["billing"]["plans"] == [%{"id" => 1}]

    cached =
      inertia_conn([{"x-inertia-except-once-props", "billing.plans"}])
      |> render_inertia("Billing/Plans", %{
        billing: %{plans: inertia_once(fn -> raise "must not run" end)}
      })
      |> then(&Jason.decode!(&1.resp_body))

    assert cached["onceProps"] == %{"billing.plans" => %{"prop" => "billing.plans"}}
    assert cached["props"]["billing"] == %{}
  end

  test "serializes matchPropsOn using dot-notation paths" do
    conn =
      inertia_conn()
      |> render_inertia("Feed/Index", %{
        items: inertia_match_merge([%{id: 1, name: "Updated"}], :id)
      })

    page = Jason.decode!(conn.resp_body)

    assert page["mergeProps"] == ["items"]
    assert page["matchPropsOn"] == ["items.id"]
    assert page["props"]["items"] == [%{"id" => 1, "name" => "Updated"}]
  end

  test "camelizes nested prop keys while honoring preserved keys" do
    conn =
      inertia_conn()
      |> render_inertia("Users/Index", %{
        user_profile: %{
          :first_name => "Ada",
          "alreadyCamel" => true,
          preserve_case(:api_token) => "secret",
          :organizations => [
            %{display_name: "Acme", billing_plan: "team"},
            %{display_name: "Globex", billing_plan: "enterprise"}
          ]
        }
      })

    page = Jason.decode!(conn.resp_body)
    profile = page["props"]["userProfile"]

    assert profile["firstName"] == "Ada"
    assert profile["alreadyCamel"] == true
    assert profile["api_token"] == "secret"

    assert profile["organizations"] == [
             %{"displayName" => "Acme", "billingPlan" => "team"},
             %{"displayName" => "Globex", "billingPlan" => "enterprise"}
           ]
  end

  test "camelizes slash-delimited string and atom keys with Phoenix.Naming semantics" do
    conn =
      inertia_conn()
      |> render_inertia("Api/Show", %{
        "api/token" => 1,
        :"user/profile" => %{
          "api/token" => 2,
          :"account/id" => 3
        },
        records: [
          %{"api/token" => "first"},
          %{"api/token" => "second"}
        ]
      })

    page = Jason.decode!(conn.resp_body)
    props = page["props"]

    assert props["api.Token"] == 1
    refute Map.has_key?(props, "api/token")

    assert props["user.Profile"]["api.Token"] == 2
    assert props["user.Profile"]["account.Id"] == 3

    assert props["records"] == [
             %{"api.Token" => "first"},
             %{"api.Token" => "second"}
           ]
  end

  test "unwraps preserved prop keys when camelization is disabled" do
    conn =
      inertia_conn()
      |> camelize_props(false)
      |> render_inertia("Users/Index", %{
        preserve_case(:api_token) => "secret",
        user_profile: %{
          preserve_case(:account_id) => 42,
          :first_name => "Ada",
          :organizations => [
            %{preserve_case(:billing_plan) => "team", display_name: "Acme"}
          ]
        }
      })

    page = Jason.decode!(conn.resp_body)
    props = page["props"]
    profile = props["user_profile"]

    assert props["api_token"] == "secret"
    refute Map.has_key?(props, "apiToken")

    assert profile["first_name"] == "Ada"
    assert profile["account_id"] == 42
    refute Map.has_key?(profile, "accountId")

    assert profile["organizations"] == [
             %{"display_name" => "Acme", "billing_plan" => "team"}
           ]
  end

  test "serializes scroll props with append merge behavior by default" do
    conn =
      inertia_conn()
      |> render_inertia("Feed/Index", %{
        posts:
          inertia_scroll(%{
            entries: [%{id: 1, name: "First"}],
            page_name: "users",
            page_number: 2,
            total_pages: 4
          })
      })

    page = Jason.decode!(conn.resp_body)

    assert page["mergeProps"] == ["posts.entries"]
    refute Map.has_key?(page, "prependProps")
    assert page["props"]["posts"]["entries"] == [%{"id" => 1, "name" => "First"}]
    assert page["scrollProps"]["posts"]["pageName"] == "users"
    assert page["scrollProps"]["posts"]["currentPage"] == 2
    assert page["scrollProps"]["posts"]["previousPage"] == 1
    assert page["scrollProps"]["posts"]["nextPage"] == 3
  end

  test "uses prepend merge behavior when requested by infinite scroll header" do
    conn =
      inertia_conn([{"x-inertia-infinite-scroll-merge-intent", "prepend"}])
      |> render_inertia("Feed/Index", %{
        posts:
          inertia_scroll(%{
            entries: [%{id: 1, name: "Older"}],
            page_name: "users",
            page_number: 3,
            total_pages: 4
          })
      })

    page = Jason.decode!(conn.resp_body)

    assert page["prependProps"] == ["posts.entries"]
    refute Map.has_key?(page, "mergeProps")
  end

  test "suppresses flash data for prefetch requests" do
    conn =
      inertia_conn([{"purpose", "prefetch"}])
      |> Flash.inertia_flash(:message, "prefetched")
      |> render_inertia("Dashboard", %{})

    page = Jason.decode!(conn.resp_body)

    assert page["flash"] == %{}
  end
end
