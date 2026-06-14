defmodule NbInertia.Perf.Fixtures.Item do
  @moduledoc false

  defstruct [:id, :name, :metadata, :children]
end

defimpl NbInertia.PropSerializer, for: NbInertia.Perf.Fixtures.Item do
  @moduledoc false

  def serialize(%NbInertia.Perf.Fixtures.Item{} = item, opts) do
    item
    |> Map.from_struct()
    |> NbInertia.PropSerializer.serialize(opts)
  end
end

defmodule NbInertia.Perf.Fixtures.SharedProps do
  @moduledoc false

  use NbInertia.SharedProps

  inertia_shared do
    prop(:current_user, :map)
    prop(:tenant, :map)
    prop(:feature_flags, :map)
    prop(:navigation, :list)
    prop(:locale, :string)
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    count = conn.assigns[:perf_count] || 5

    %{
      current_user: %{
        id: 1,
        email: "ada@example.com",
        role: "admin",
        account_ids: Enum.to_list(1..min(count, 25))
      },
      tenant: %{
        id: "tenant-#{count}",
        plan: "pro",
        limits: %{users: count * 10, projects: count * 20}
      },
      feature_flags: feature_flags(count),
      navigation: NbInertia.Perf.Fixtures.navigation_items(min(count, 30)),
      locale: conn.assigns[:locale] || "en"
    }
  end

  defp feature_flags(count) do
    for index <- 1..min(count, 40), into: %{} do
      {"flag_#{index}", rem(index, 3) == 0}
    end
  end
end

defmodule NbInertia.Perf.Fixtures.ConditionalSharedProps do
  @moduledoc false

  use NbInertia.SharedProps

  inertia_shared do
    prop(:request_meta, :map)
    prop(:permissions, :list)
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    count = conn.assigns[:perf_count] || 5

    %{
      request_meta: %{
        request_id: "perf-#{count}",
        path: conn.request_path,
        method: conn.method
      },
      permissions: Enum.map(1..min(count, 35), &"permission:#{&1}")
    }
  end
end

defmodule NbInertia.Perf.Fixtures.Controller do
  @moduledoc false

  use NbInertia.Controller

  include_shared_props(NbInertia.Perf.Fixtures.SharedProps)

  inertia_shared do
    prop(:inline_locale, :string, from: :locale)
    prop(:inline_defaults, :map, default: %{theme: "system", density: "compact"})
  end

  inertia_page :dashboard do
    prop(:users, :list)
    prop(:stats, :map)
    prop(:settings, :map, default: %{})
    prop(:activity_feed, :map, scroll: [wrapper: "data", page_name: "feed"], match_on: :id)
    prop(:lazy_metrics, :map, lazy: true)
    prop(:deferred_metrics, :map, defer: "metrics")
    prop(:once_metrics, :map, once: [as: "perf-metrics"])
  end

  def render_dashboard(conn, props, page \\ :dashboard) do
    render_inertia_page(conn, page, props, deep_merge: true, ssr: false)
  end
end

defmodule NbInertia.Perf.Fixtures do
  @moduledoc false

  import Plug.Conn
  import Plug.Test

  alias NbInertia.CoreController
  alias NbInertia.Modal
  alias NbInertia.Perf.Fixtures.Item

  @sizes [:small, :medium, :large]
  @counts %{small: 5, medium: 50, large: 200}

  def sizes, do: @sizes

  def count_for(size), do: Map.fetch!(@counts, size)

  def inertia_conn(size, path \\ "/perf/dashboard") do
    count = count_for(size)
    version = inertia_version()

    :get
    |> conn(path)
    |> init_test_session(%{})
    |> assign(:flash, %{"info" => "Loaded"})
    |> assign(:locale, "en")
    |> assign(:perf_count, count)
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", version)
    |> NbInertia.Plug.call([])
    |> put_private(:phoenix_action, :index)
    |> put_private(:phoenix_controller, NbInertia.Perf.Fixtures.Controller)
  end

  def raw_conn(size, path \\ "/perf/dashboard") do
    count = count_for(size)

    :get
    |> conn(path)
    |> init_test_session(%{
      nb_inertia_flash: %{
        "notice" => "Saved",
        "selected_record_id" => count
      }
    })
    |> assign(:flash, %{"info" => "Loaded"})
    |> assign(:locale, "en")
    |> assign(:perf_count, count)
  end

  def controller_props(size) do
    count = count_for(size)

    %{
      users: users(count),
      stats: stats(count),
      settings: settings(count),
      activity_feed: activity_feed(count),
      lazy_metrics: metrics(count),
      once_metrics: metrics(max(div(count, 2), 1))
    }
  end

  def core_props(size) do
    count = count_for(size)

    %{
      users: users(count),
      settings: CoreController.inertia_deep_merge(settings(count)),
      activity_feed:
        CoreController.inertia_scroll(activity_feed(count), wrapper: "data", match_on: :id),
      recent_events: CoreController.inertia_prepend(events(max(div(count, 2), 1))),
      totals: CoreController.inertia_always(stats(count)),
      lazy_metrics: fn -> metrics(count) end,
      optional_metrics: CoreController.inertia_optional(fn -> metrics(count) end),
      once_metrics:
        CoreController.inertia_once(fn -> metrics(max(div(count, 2), 1)) end,
          as: "core-metrics"
        )
    }
  end

  def camelized_props(size) do
    count = count_for(size)

    %{
      current_user: %{
        first_name: "Ada",
        last_name: "Lovelace",
        account_settings: settings(count)
      },
      activity_feed: activity_feed(count),
      nested_records: for(item <- users(count), do: nested_record(item, count))
    }
  end

  def runtime_props(size) do
    count = count_for(size)

    %{
      users: users(count),
      settings: settings(count),
      activity_feed: activity_feed(count),
      lazy_metrics: metrics(count)
    }
  end

  def runtime_prop_configs(size) do
    count = count_for(size)

    base = [
      %{name: :locale, opts: [from: :locale]},
      %{name: :theme, opts: [default: "light"]},
      %{name: :users, opts: [merge: true]},
      %{name: :settings, opts: [merge: :deep]},
      %{name: :activity_feed, opts: [scroll: [wrapper: "data"], match_on: :id]},
      %{name: :lazy_metrics, opts: [lazy: true]},
      %{
        name: :deferred_metrics,
        opts: [defer: "metrics", default: metrics(max(div(count, 4), 1))]
      }
    ]

    generated =
      for index <- 1..min(count, 80) do
        %{name: String.to_atom("default_prop_#{index}"), opts: [default: index]}
      end

    base ++ generated
  end

  def shared_modules do
    [
      NbInertia.Perf.Fixtures.SharedProps,
      %{module: NbInertia.Perf.Fixtures.ConditionalSharedProps, only: [:index]}
    ]
  end

  def inline_shared_prop_configs(size) do
    count = count_for(size)

    base = [
      %{name: :inline_locale, opts: [from: :locale]},
      %{name: :inline_theme, opts: [default: "light"]}
    ]

    generated =
      for index <- 1..min(count, 60) do
        %{name: String.to_atom("inline_default_#{index}"), opts: [default: index]}
      end

    base ++ generated
  end

  def serializer_value(size) do
    count = count_for(size)

    %{
      users: Enum.map(1..count, &serializer_item(&1, max(div(count, 25), 1))),
      metadata: settings(count),
      tree: serializer_tree(3, min(count, 20))
    }
  end

  def modal_fixture(size) do
    count = count_for(size)

    props =
      [
        edited_user: List.first(users(count)),
        organizations: organizations(min(count, 75)),
        permissions: Enum.map(1..min(count, 50), &"permission:#{&1}")
      ]

    modal =
      Modal.new("Perf/Users/Edit", %{})
      |> Modal.base_url("/perf/users")
      |> Modal.size(:lg)
      |> Modal.position(:right)
      |> Modal.slideover(true)
      |> Modal.close_button(true)
      |> Modal.close_explicitly(false)
      |> Modal.close_on_click_outside(true)

    %{modal: modal, props: props}
  end

  def ssr_payload(size) do
    %{
      component: "Perf/SSR",
      props: camelized_props(size),
      url: "/perf/ssr?size=#{size}",
      version: NbInertia.Config.default_version(),
      flash: %{},
      mergeProps: ["users"],
      deferredProps: %{"metrics" => ["lazyMetrics"]},
      onceProps: %{"core-metrics" => %{prop: "onceMetrics"}}
    }
  end

  def navigation_items(count) do
    for index <- 1..count do
      %{
        id: index,
        label: "Section #{index}",
        href: "/perf/sections/#{index}",
        active: index == 1,
        children:
          for child <- 1..min(index, 5) do
            %{
              id: "#{index}-#{child}",
              label: "Child #{child}",
              href: "/perf/sections/#{index}/#{child}"
            }
          end
      }
    end
  end

  defp inertia_version do
    :get
    |> conn("/")
    |> init_test_session(%{})
    |> assign(:flash, %{})
    |> NbInertia.Plug.call([])
    |> then(& &1.private[:inertia_version])
  end

  defp users(count) do
    for index <- 1..count do
      %{
        id: index,
        first_name: "User",
        last_name: Integer.to_string(index),
        email: "user#{index}@example.com",
        role: if(rem(index, 5) == 0, do: "admin", else: "member"),
        inserted_at: "2026-06-14T12:00:00Z",
        profile: %{
          title: "Engineer #{index}",
          team_name: "Team #{rem(index, 7)}",
          notification_settings: %{
            email_digest: rem(index, 2) == 0,
            product_updates: rem(index, 3) == 0
          }
        }
      }
    end
  end

  defp organizations(count) do
    for index <- 1..count do
      %{
        id: index,
        display_name: "Organization #{index}",
        billing_plan: if(rem(index, 4) == 0, do: "enterprise", else: "team")
      }
    end
  end

  defp events(count) do
    for index <- 1..count do
      %{
        id: index,
        actor_id: rem(index, 17),
        event_name: "record.updated",
        created_at: "2026-06-14T12:00:00Z"
      }
    end
  end

  defp activity_feed(count) do
    %{
      data: events(count),
      page_name: "page",
      current_page: 1,
      previous_page: nil,
      next_page: 2,
      total_count: count * 4
    }
  end

  defp stats(count) do
    %{
      total_users: count,
      active_users: div(count * 3, 4),
      conversion_rate: 0.427,
      buckets:
        for index <- 1..min(count, 30), into: %{} do
          {"bucket_#{index}", %{count: index * 3, delta: rem(index, 5) - 2}}
        end
    }
  end

  defp settings(count) do
    %{
      theme_name: "light",
      dashboard_density: "compact",
      enabled_columns: Enum.map(1..min(count, 40), &"column_#{&1}"),
      filters: %{
        account_status: ["active", "trial"],
        owner_ids: Enum.to_list(1..min(count, 50)),
        created_after: "2026-01-01"
      }
    }
  end

  defp metrics(count) do
    %{
      samples:
        for index <- 1..min(count, 100) do
          %{time_bucket: index, p50_ms: index * 2, p95_ms: index * 5, error_count: rem(index, 3)}
        end,
      summary: %{p50_ms: count * 2, p95_ms: count * 5}
    }
  end

  defp nested_record(item, count) do
    %{
      user_record: item,
      audit_trail: events(min(count, 15)),
      permission_matrix:
        for index <- 1..min(count, 20), into: %{} do
          {"permission_#{index}", %{allowed: rem(index, 2) == 0, inherited_from_role: "member"}}
        end
    }
  end

  defp serializer_item(index, child_count) do
    %Item{
      id: index,
      name: "Item #{index}",
      metadata: %{
        snake_case_key: "value",
        counters: %{views: index * 10, clicks: index * 2},
        tags: Enum.map(1..min(index, 5), &"tag-#{&1}")
      },
      children:
        for child <- 1..child_count do
          %Item{
            id: index * 1_000 + child,
            name: "Child #{child}",
            metadata: %{depth: 1},
            children: []
          }
        end
    }
  end

  defp serializer_tree(0, index) do
    %Item{id: index, name: "Leaf #{index}", metadata: %{leaf: true}, children: []}
  end

  defp serializer_tree(depth, index) do
    %Item{
      id: index,
      name: "Node #{index}",
      metadata: %{depth: depth},
      children: Enum.map(1..3, &serializer_tree(depth - 1, index * 10 + &1))
    }
  end
end
