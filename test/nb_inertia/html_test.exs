defmodule NbInertia.HTMLTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component, only: [sigil_H: 2]

  defp title_fixture(assigns) do
    _ = assigns

    ~H"""
    <NbInertia.HTML.inertia_title>Dashboard</NbInertia.HTML.inertia_title>
    """
  end

  test "inertia_ssr renders the SSR body without wrapping it again" do
    body =
      ~s(<script data-page="app" type="application/json">{}</script><div id="app" data-server-rendered="true"><h1>Hello</h1></div>)

    html = render_component(&NbInertia.HTML.inertia_ssr/1, body: body)

    assert html == body
    assert html =~ ~s(data-server-rendered="true")
    assert html =~ "<h1>Hello</h1>"
  end

  test "inertia_title emits the Inertia v3 head marker" do
    html = render_component(&title_fixture/1, %{})

    assert html =~ ~s(<title data-inertia="")
    refute html =~ ~r/\sinertia(?:\s|>)/
  end

  test "extracts and unescapes titles emitted by v3 SSR adapters" do
    assert NbInertia.CoreController.extract_ssr_page_title(
             ~s(<title data-inertia="title">Tom &amp; Jerry &lt;Admin&gt; &#39;Home&#39;</title>)
           ) == "Tom & Jerry <Admin> 'Home'"

    assert NbInertia.CoreController.extract_ssr_page_title("<title inertia>Legacy</title>") ==
             "Legacy"
  end
end
