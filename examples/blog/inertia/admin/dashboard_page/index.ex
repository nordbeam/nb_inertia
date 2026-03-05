# Example: Admin dashboard — history controls, from: props, page-level shared
#
# Features demonstrated:
#   - use NbInertia.Page with encrypt_history: true and clear_history: true
#   - prop with from: option (auto-pull from conn.assigns)
#   - prop with defer: true (lazy-loaded after initial render)
#   - Page-level shared props (inline shared do...end block)
#   - Convention naming with nested scope: BlogWeb.Admin.DashboardPage.Index → "Admin/Dashboard/Index"
#   - ~TSX sigil
#
# Route: inertia_resource "/dashboard", Admin.DashboardPage, only: [:index]
# HTTP:  GET /admin/dashboard → mount/2

defmodule BlogWeb.Admin.DashboardPage.Index do
  use NbInertia.Page,
    # encrypt_history: true encrypts the page state stored in the browser's
    # history stack. Use for pages with sensitive data that shouldn't be
    # readable if someone inspects history entries.
    encrypt_history: true,

    # clear_history: true clears the history state when navigating away
    # from this page. Prevents the "back button" from showing stale
    # sensitive data.
    clear_history: true

  # from: :user_timezone — automatically pulls this prop's value from
  # conn.assigns[:user_timezone]. No need to return it from mount/2.
  prop :timezone, :string, from: :user_timezone

  # from: :locale — shorthand. When from: matches the prop name,
  # it pulls from conn.assigns[:locale].
  prop :locale, :string, from: :locale

  prop :recent_posts, list: Blog.PostSerializer
  prop :site_stats, :map

  # defer: true — loaded after the initial page render via a follow-up request.
  # Use for expensive queries that aren't needed for the initial paint.
  prop :activity_log, :list, defer: true

  # Page-level inline shared props. These are type declarations only —
  # the values come from the shared props modules registered in the router
  # (BlogWeb.InertiaShared.Auth and BlogWeb.InertiaShared.Admin).
  # Declaring them here ensures nb_ts generates correct TypeScript types
  # for this page's props interface (extends the shared types).
  shared do
    prop :admin_permissions, :list
  end

  def mount(_conn, _params) do
    %{
      recent_posts: Blog.Posts.recent(limit: 10),
      site_stats: %{
        total_posts: Blog.Posts.count(),
        posts_today: Blog.Posts.count_today(),
        total_comments: Blog.Comments.count(),
        active_users: Blog.Accounts.active_count()
      },
      activity_log: Blog.AuditLog.recent(limit: 50)
      # timezone and locale are NOT returned here — they come from conn.assigns
      # via the from: option automatically.
    }
  end

  def render do
    ~TSX"""
    export default function AdminDashboard({
      recent_posts, site_stats, activity_log, timezone, locale
    }: Props) {
      return (
        <div className="admin-dashboard">
          <h1>Admin Dashboard</h1>
          <p className="meta">Timezone: {timezone} | Locale: {locale}</p>

          <div className="stats-grid">
            <div className="stat-card">
              <h3>Total Posts</h3>
              <span className="stat-value">{site_stats.total_posts}</span>
            </div>
            <div className="stat-card">
              <h3>Posts Today</h3>
              <span className="stat-value">{site_stats.posts_today}</span>
            </div>
            <div className="stat-card">
              <h3>Comments</h3>
              <span className="stat-value">{site_stats.total_comments}</span>
            </div>
            <div className="stat-card">
              <h3>Active Users</h3>
              <span className="stat-value">{site_stats.active_users}</span>
            </div>
          </div>

          <section>
            <h2>Recent Posts</h2>
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Author</th>
                  <th>Status</th>
                  <th>Published</th>
                </tr>
              </thead>
              <tbody>
                {recent_posts.map(post => (
                  <tr key={post.id}>
                    <td>{post.title}</td>
                    <td>{post.author.name}</td>
                    <td>{post.status}</td>
                    <td>{post.published_at || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>

          {activity_log && (
            <section>
              <h2>Activity Log</h2>
              <ul className="activity-log">
                {activity_log.map((entry: any, i: number) => (
                  <li key={i}>
                    <strong>{entry.action}</strong> by {entry.user}
                    <time>{entry.timestamp}</time>
                  </li>
                ))}
              </ul>
            </section>
          )}
        </div>
      )
    }
    """
  end
end
