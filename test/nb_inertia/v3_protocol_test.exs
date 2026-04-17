defmodule NbInertia.V3ProtocolTest do
  use ExUnit.Case, async: true

  import NbInertia.CoreController
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
