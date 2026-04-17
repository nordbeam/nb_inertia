import { useHttp as r } from "@inertiajs/react";
import { isRouteResult as p } from "../shared/types.js";
function u(n) {
  return typeof n == "function" || p(n);
}
function m(...n) {
  if (n.length === 0)
    return r();
  if (n.length === 3) {
    const [e, t, f] = n;
    return r(e, t, f);
  }
  if (n.length === 2) {
    const [e, t] = n;
    if (typeof e == "string" && !u(t))
      return r(e, t);
    if (u(e))
      return r(e, t);
    if (typeof e != "string" && u(t))
      return r(t, e);
  }
  return r(n[0]);
}
function d(n, e, t) {
  const f = r(e, n);
  return !t || t.url === e.url && t.method === e.method ? f : new Proxy(f, {
    get(i, o, c) {
      return o === "submit" ? (h) => i.submit(t.method, t.url, h) : Reflect.get(i, o, c);
    }
  });
}
export {
  m as default,
  p as isRouteResult,
  m as useHttp,
  d as useHttpWithPrecognition
};
