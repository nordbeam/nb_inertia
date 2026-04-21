import { useForm as i } from "@inertiajs/react";
import { isRouteResult as g } from "../shared/types.js";
import { useModalPageContext as h } from "./modals/modalStack.js";
import { mergeModalHeaders as a } from "./modals/requestContext.js";
function d(e) {
  return typeof e == "function" || g(e);
}
function p(e) {
  return Object.prototype.toString.call(e) === "[object Object]";
}
function u(e, r) {
  return r ? new Proxy(e, {
    get(t, n, f) {
      const s = Reflect.get(t, n, f);
      return typeof s != "function" || !["submit", "get", "post", "put", "patch", "delete"].includes(String(n)) ? s : (...l) => {
        const o = [...l], c = o[o.length - 1], m = a(
          p(c) ? c : void 0,
          {
            url: r.url,
            baseUrl: r.baseUrl,
            returnUrl: r.returnUrl
          }
        );
        return p(c) ? o[o.length - 1] = m : o.push(m), s.apply(t, o);
      };
    }
  }) : e;
}
function x(...e) {
  const r = h();
  if (e.length === 0)
    return u(i(), r);
  if (e.length === 3) {
    const [t, n, f] = e;
    return u(i(t, n, f), r);
  }
  if (e.length === 2) {
    const [t, n] = e;
    if (typeof t == "string" && !d(n))
      return u(i(t, n), r);
    if (d(t))
      return u(
        i(t, n),
        r
      );
    if (typeof t != "string" && d(n))
      return u(
        i(n, t),
        r
      );
  }
  return u(
    i(e[0]),
    r
  );
}
function O(e, r, t) {
  const n = h(), f = i(r, e);
  if (!t || t.url === r.url && t.method === r.method)
    return u(f, n);
  const s = new Proxy(f, {
    get(l, o, c) {
      return o === "submit" ? (m) => l.submit(t.method, t.url, m) : Reflect.get(l, o, c);
    }
  });
  return u(
    s,
    n
  );
}
export {
  x as default,
  g as isRouteResult,
  x as useForm,
  O as useFormWithPrecognition
};
