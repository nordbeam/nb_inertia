defmodule NbInertia.TypeNameOptionTest do
  use ExUnit.Case, async: true

  defmodule TestController do
    use NbInertia.Controller

    # Page with custom type_name
    inertia_page :preview,
      component: "Public/WidgetShow",
      type_name: "WidgetPreviewProps" do
      prop(:widget, :map)
      prop(:settings, :map)
    end

    # Regular page without custom type_name
    inertia_page :show,
      component: "Public/WidgetShow" do
      prop(:widget, :map)
    end

    # Another page with custom type_name
    inertia_page :embed,
      component: "Widgets/Embed",
      type_name: "CustomEmbedProps" do
      prop(:widget, :map)
      prop(:config, :map)
    end
  end

  describe "type_name option" do
    test "stores custom type_name in page config" do
      config = TestController.inertia_page_config(:preview)
      assert config.type_name == "WidgetPreviewProps"
    end

    test "page without type_name option has no type_name in config" do
      config = TestController.inertia_page_config(:show)
      refute Map.has_key?(config, :type_name)
    end

    test "multiple pages can have different custom type_names" do
      preview_config = TestController.inertia_page_config(:preview)
      embed_config = TestController.inertia_page_config(:embed)

      assert preview_config.type_name == "WidgetPreviewProps"
      assert embed_config.type_name == "CustomEmbedProps"
    end

    test "custom type_name is different from component path" do
      config = TestController.inertia_page_config(:preview)
      # Component is "Public/WidgetShow" which would generate "PublicWidgetShowProps"
      # But custom type_name is "WidgetPreviewProps"
      assert config.component == "Public/WidgetShow"
      assert config.type_name == "WidgetPreviewProps"
    end
  end
end
