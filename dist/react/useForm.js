import { useForm as n } from "@inertiajs/react";
import { isRouteResult as s } from "../shared/types.js";
function o(e) {
  return typeof e == "function" || s(e);
}
function d(...e) {
  if (e.length === 0)
    return n();
  if (e.length === 3) {
    const [t, r, f] = e;
    return n(t, r, f);
  }
  if (e.length === 2) {
    const [t, r] = e;
    if (typeof t == "string" && !o(r))
      return n(t, r);
    if (o(t))
      return n(t, r);
    if (typeof t != "string" && o(r))
      return n(r, t);
  }
  return n(e[0]);
}
function p(e, t, r) {
  const f = n(t, e);
  return !r || r.url === t.url && r.method === t.method ? f : new Proxy(f, {
    get(u, i, m) {
      return i === "submit" ? (c) => u.submit(r.method, r.url, c) : Reflect.get(u, i, m);
    }
  });
}
export {
  d as default,
  s as isRouteResult,
  d as useForm,
  p as useFormWithPrecognition
};
