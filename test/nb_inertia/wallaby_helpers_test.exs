defmodule NbInertia.WallabyHelpersTest do
  use ExUnit.Case, async: true

  describe "module availability" do
    test "module is defined when Wallaby is available" do
      assert Code.ensure_loaded?(NbInertia.WallabyHelpers)
    end

    test "exports page state helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_page_data, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_component, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_props, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_prop, 2)
    end

    test "exports navigation helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_visit, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :wait_for_inertia, 1)
    end

    test "exports page assertion helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :assert_inertia_component, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_inertia_prop, 3)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_path, 2)
    end

    test "exports modal helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :assert_modal_open, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :refute_modal_open, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :click_modal_link, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :close_modal, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :dismiss_modal, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_modal_text, 2)
    end

    test "exports flash helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :inertia_flash, 1)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_inertia_flash, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_inertia_flash, 3)
    end

    test "exports form helpers" do
      assert function_exported?(NbInertia.WallabyHelpers, :fill_inertia_form, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :submit_form, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :trigger_blur, 2)
      assert function_exported?(NbInertia.WallabyHelpers, :assert_form_error, 2)
    end
  end
end
