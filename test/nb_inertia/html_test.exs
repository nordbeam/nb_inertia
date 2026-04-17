defmodule NbInertia.HTMLTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "inertia_ssr renders the SSR body without wrapping it again" do
    body = ~s(<script data-page="app" type="application/json">{}</script><div id="app" data-server-rendered="true"><h1>Hello</h1></div>)

    html = render_component(&NbInertia.HTML.inertia_ssr/1, body: body)

    assert html == body
    assert html =~ ~s(data-server-rendered="true")
    assert html =~ "<h1>Hello</h1>"
  end
end
