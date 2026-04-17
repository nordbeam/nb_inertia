defmodule NbInertia.Modal.HttpClientTest do
  use ExUnit.Case, async: true

  alias NbInertia.Modal.HttpClient

  describe "extract_page_data_from_html/1" do
    test "extracts page data from Inertia v3 script tag" do
      html =
        ~s(<script data-page="app" type="application/json">{"component":"Users/Index","props":{"users":[]},"url":"/users","version":"1.0"}</script><div id="app"></div>)

      assert {:ok, page_data} = HttpClient.extract_page_data_from_html(html)
      assert page_data["component"] == "Users/Index"
      assert page_data["props"] == %{"users" => []}
      assert page_data["url"] == "/users"
    end

    test "extracts page data from legacy double-quoted data-page attribute" do
      html =
        ~s(<div id="app" data-page="{&quot;component&quot;:&quot;Users/Index&quot;,&quot;props&quot;:{},&quot;url&quot;:&quot;/users&quot;}"></div>)

      assert {:ok, page_data} = HttpClient.extract_page_data_from_html(html)
      assert page_data["component"] == "Users/Index"
      assert page_data["url"] == "/users"
    end

    test "returns error when no embedded page data is found" do
      html = ~s(<div id="app">Hello</div>)

      assert {:error, "No Inertia page data found in HTML"} =
               HttpClient.extract_page_data_from_html(html)
    end

    test "handles HTML entities in legacy data-page markup" do
      json = Jason.encode!(%{component: "Test", props: %{html: "<b>bold</b>"}, url: "/"})
      encoded = HttpClient.encode_html_entities(json)
      html = ~s(<div data-page='#{encoded}'></div>)

      assert {:ok, page_data} = HttpClient.extract_page_data_from_html(html)
      assert page_data["props"]["html"] == "<b>bold</b>"
    end

    test "handles multiline HTML" do
      html = """
      <!DOCTYPE html>
      <html>
      <head><title>Test</title></head>
      <body>
        <script data-page="app" type="application/json">{"component":"Dashboard","props":{"count":42},"url":"/dashboard","version":"1.0"}</script>
        <div id="app"></div>
        <script src="/app.js"></script>
      </body>
      </html>
      """

      assert {:ok, page_data} = HttpClient.extract_page_data_from_html(html)
      assert page_data["component"] == "Dashboard"
      assert page_data["props"]["count"] == 42
    end
  end

  describe "inject_page_data_into_html/2" do
    test "replaces Inertia v3 script page data" do
      original_html =
        ~s(<script data-page="app" type="application/json">{"component":"Old","props":{},"url":"/"}</script><div id="app"></div>)

      new_page_data = %{"component" => "New", "props" => %{"name" => "test"}, "url" => "/new"}

      assert {:ok, modified_html} =
               HttpClient.inject_page_data_into_html(original_html, new_page_data)

      assert modified_html =~ ~s(script data-page="app" type="application/json")
      refute modified_html =~ "Old"

      # Verify we can extract the injected data back
      assert {:ok, extracted} = HttpClient.extract_page_data_from_html(modified_html)
      assert extracted["component"] == "New"
      assert extracted["props"]["name"] == "test"
    end

    test "replaces legacy double-quoted data-page" do
      original_html =
        ~s(<div id="app" data-page="{&quot;component&quot;:&quot;Old&quot;,&quot;props&quot;:{},&quot;url&quot;:&quot;/&quot;}"></div>)

      new_page_data = %{"component" => "New", "props" => %{}, "url" => "/new"}

      assert {:ok, modified_html} =
               HttpClient.inject_page_data_into_html(original_html, new_page_data)

      assert modified_html =~ "data-page=\""
    end

    test "returns error when no embedded page data is found" do
      html = ~s(<div id="app">No page data here</div>)
      page_data = %{"component" => "Test"}

      assert {:error, "No Inertia page data found in HTML"} =
               HttpClient.inject_page_data_into_html(html, page_data)
    end

    test "preserves surrounding HTML" do
      original_html = """
      <html>
      <head><link rel="stylesheet" href="/app.css"></head>
      <body>
        <script data-page="app" type="application/json">{"component":"Old","props":{},"url":"/"}</script>
        <div id="app"></div>
        <script src="/app.js"></script>
      </body>
      </html>
      """

      new_page_data = %{"component" => "New", "props" => %{}, "url" => "/"}
      assert {:ok, modified} = HttpClient.inject_page_data_into_html(original_html, new_page_data)

      assert modified =~ ~s(<link rel="stylesheet" href="/app.css">)
      assert modified =~ ~s(<script src="/app.js">)
    end

    test "roundtrip: inject then extract" do
      html =
        ~s(<script data-page="app" type="application/json">{"component":"Start","props":{},"url":"/"}</script><div id="app"></div>)

      page_data = %{
        "component" => "Users/Index",
        "props" => %{
          "users" => [%{"id" => 1, "name" => "Alice"}],
          "_nb_modal" => %{"component" => "Users/Show"}
        },
        "url" => "/users/1"
      }

      assert {:ok, modified} = HttpClient.inject_page_data_into_html(html, page_data)
      assert {:ok, extracted} = HttpClient.extract_page_data_from_html(modified)
      assert extracted == page_data
    end
  end

  describe "decode_html_entities/1" do
    test "decodes common HTML entities" do
      assert HttpClient.decode_html_entities("&quot;hello&quot;") == "\"hello\""
      assert HttpClient.decode_html_entities("&amp;") == "&"
      assert HttpClient.decode_html_entities("&lt;div&gt;") == "<div>"
      assert HttpClient.decode_html_entities("&#39;") == "'"
      assert HttpClient.decode_html_entities("&apos;") == "'"
    end

    test "handles strings without entities" do
      assert HttpClient.decode_html_entities("hello world") == "hello world"
    end

    test "handles multiple entities in sequence" do
      assert HttpClient.decode_html_entities("&lt;&amp;&gt;") == "<&>"
    end
  end

  describe "encode_html_entities/1" do
    test "encodes special characters" do
      assert HttpClient.encode_html_entities("\"hello\"") == "&quot;hello&quot;"
      assert HttpClient.encode_html_entities("a & b") == "a &amp; b"
      assert HttpClient.encode_html_entities("<div>") == "&lt;div&gt;"
    end

    test "roundtrip: encode then decode" do
      original = ~s({"key": "value <with> special & chars"})
      encoded = HttpClient.encode_html_entities(original)
      decoded = HttpClient.decode_html_entities(encoded)
      assert decoded == original
    end
  end
end
