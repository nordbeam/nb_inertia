defmodule NbInertia.Page.NamingTest do
  use ExUnit.Case, async: true

  alias NbInertia.Page.Naming

  describe "derive_component/1" do
    test "standard page module: Web.UsersPage.Index → Users/Index" do
      assert Naming.derive_component(MyAppWeb.UsersPage.Index) == "Users/Index"
    end

    test "standard page module: Web.UsersPage.Show → Users/Show" do
      assert Naming.derive_component(MyAppWeb.UsersPage.Show) == "Users/Show"
    end

    test "standard page module: Web.UsersPage.Edit → Users/Edit" do
      assert Naming.derive_component(MyAppWeb.UsersPage.Edit) == "Users/Edit"
    end

    test "standard page module: Web.UsersPage.New → Users/New" do
      assert Naming.derive_component(MyAppWeb.UsersPage.New) == "Users/New"
    end

    test "single-segment page: Web.DashboardPage → Dashboard" do
      assert Naming.derive_component(MyAppWeb.DashboardPage) == "Dashboard"
    end

    test "nested namespace: Web.Admin.UsersPage.Index → Admin/Users/Index" do
      assert Naming.derive_component(MyAppWeb.Admin.UsersPage.Index) == "Admin/Users/Index"
    end

    test "nested namespace: Web.Admin.UsersPage.Edit → Admin/Users/Edit" do
      assert Naming.derive_component(MyAppWeb.Admin.UsersPage.Edit) == "Admin/Users/Edit"
    end

    test "deep nesting: Web.Admin.Settings.SecurityPage.Index → Admin/Settings/Security/Index" do
      assert Naming.derive_component(MyAppWeb.Admin.Settings.SecurityPage.Index) ==
               "Admin/Settings/Security/Index"
    end

    test "no Page suffix: Web.Settings → Settings" do
      assert Naming.derive_component(MyAppWeb.Settings) == "Settings"
    end

    test "no Page suffix with action: Web.Settings.Index → Settings/Index" do
      assert Naming.derive_component(MyAppWeb.Settings.Index) == "Settings/Index"
    end

    test "module without Web prefix: SomePage → Some" do
      assert Naming.derive_component(SomePage) == "Some"
    end

    test "module without Web prefix with nesting: MyApp.SomePage.Index → MyApp/Some/Index" do
      assert Naming.derive_component(MyApp.SomePage.Index) == "MyApp/Some/Index"
    end

    test "module named just Page stays as Page" do
      assert Naming.derive_component(MyAppWeb.Page) == "Page"
    end

    test "multi-word page segment: Web.UserProfilesPage.Show → UserProfiles/Show" do
      assert Naming.derive_component(MyAppWeb.UserProfilesPage.Show) == "UserProfiles/Show"
    end

    test "different Web prefix: AdminWeb.UsersPage.Index → Users/Index" do
      assert Naming.derive_component(AdminWeb.UsersPage.Index) == "Users/Index"
    end

    test "DashboardPage with Index: Web.DashboardPage.Index → Dashboard/Index" do
      assert Naming.derive_component(MyAppWeb.DashboardPage.Index) == "Dashboard/Index"
    end

    test "module without Web or Page: Dashboard → Dashboard" do
      assert Naming.derive_component(MyAppWeb.Dashboard) == "Dashboard"
    end
  end
end
