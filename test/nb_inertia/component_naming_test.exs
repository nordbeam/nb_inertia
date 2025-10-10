defmodule NbInertia.ComponentNamingTest do
  use ExUnit.Case, async: true

  alias NbInertia.ComponentNaming

  describe "infer/1" do
    test "infers component names from common CRUD action atoms" do
      assert ComponentNaming.infer(:users_index) == "Users/Index"
      assert ComponentNaming.infer(:users_show) == "Users/Show"
      assert ComponentNaming.infer(:users_new) == "Users/New"
      assert ComponentNaming.infer(:users_edit) == "Users/Edit"
      assert ComponentNaming.infer(:users_create) == "Users/Create"
    end

    test "handles single word page names" do
      assert ComponentNaming.infer(:dashboard) == "Dashboard"
      assert ComponentNaming.infer(:profile) == "Profile"
      assert ComponentNaming.infer(:settings) == "Settings"
    end

    test "handles common namespace prefixes" do
      assert ComponentNaming.infer(:admin_dashboard) == "Admin/Dashboard"
      assert ComponentNaming.infer(:admin_users_index) == "Admin/Users/Index"
      assert ComponentNaming.infer(:api_posts_show) == "Api/Posts/Show"
    end

    test "handles page names without standard action suffixes" do
      assert ComponentNaming.infer(:user_profile) == "UserProfile"
      assert ComponentNaming.infer(:edit_profile) == "EditProfile"
    end
  end
end
