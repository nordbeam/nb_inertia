function o(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const e = t;
  return typeof e.url == "string" && typeof e.method == "string" && ["get", "post", "put", "patch", "delete"].includes(e.method);
}
export {
  o as isRouteResult
};
