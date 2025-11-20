import { router as n } from "@inertiajs/react";
function u(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const e = t;
  return typeof e.url == "string" && typeof e.method == "string" && ["get", "post", "put", "patch", "delete", "head", "options"].includes(e.method);
}
function s(t) {
  return u(t) ? t.url : t;
}
const i = Object.assign(Object.create(n), {
  ...n,
  /**
   * Visit a URL with automatic method detection
   *
   * When given a RouteResult, automatically uses the method from the route.
   * When given a string, uses the method from options or defaults to 'get'.
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options
   *
   * @example
   * // With RouteResult (method auto-detected)
   * router.visit(post_path(1));                    // Uses GET
   * router.visit(update_post_path.patch(1));       // Uses PATCH
   *
   * // With string (backward compatible)
   * router.visit('/posts/1');
   * router.visit('/posts/1', { method: 'post' });
   */
  visit(t, e = {}) {
    const r = s(t), o = u(t) && !e.method ? { ...e, method: t.method } : e;
    return n.visit(r, o);
  },
  /**
   * Make a GET request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options (method will be overridden to 'get')
   *
   * @example
   * router.get(post_path(1));
   * router.get('/posts/1');
   */
  get(t, e = {}) {
    const r = s(t);
    return n.get(r, e);
  },
  /**
   * Make a POST request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'post')
   *
   * @example
   * router.post(posts_path(), { title: 'New Post' });
   * router.post('/posts', { title: 'New Post' });
   */
  post(t, e = {}, r = {}) {
    const o = s(t);
    return n.post(o, e, r);
  },
  /**
   * Make a PUT request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'put')
   *
   * @example
   * router.put(update_post_path.put(1), { title: 'Updated' });
   * router.put('/posts/1', { title: 'Updated' });
   */
  put(t, e = {}, r = {}) {
    const o = s(t);
    return n.put(o, e, r);
  },
  /**
   * Make a PATCH request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param data - Data to send with the request
   * @param options - Inertia visit options (method will be overridden to 'patch')
   *
   * @example
   * router.patch(update_post_path.patch(1), { title: 'Updated' });
   * router.patch('/posts/1', { title: 'Updated' });
   */
  patch(t, e = {}, r = {}) {
    const o = s(t);
    return n.patch(o, e, r);
  },
  /**
   * Make a DELETE request
   *
   * @param urlOrRoute - String URL or RouteResult object
   * @param options - Inertia visit options (method will be overridden to 'delete')
   *
   * @example
   * router.delete(delete_post_path.delete(1));
   * router.delete('/posts/1');
   */
  delete(t, e = {}) {
    const r = s(t);
    return n.delete(r, e);
  }
});
export {
  i as default,
  i as router
};
