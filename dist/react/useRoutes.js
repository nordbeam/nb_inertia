import { usePage as f } from "@inertiajs/react";
import { useMemo as p } from "react";
function l(e, a) {
  const n = (...o) => e(a, ...o);
  return Object.keys(e).forEach((o) => {
    const t = e[o];
    if (typeof t == "function")
      n[o] = (...u) => t(a, ...u);
    else if (typeof t == "object" && t !== null) {
      const u = {};
      Object.keys(t).forEach((r) => {
        const s = t[r];
        typeof s == "function" ? u[r] = (...c) => s(a, ...c) : u[r] = s;
      }), n[o] = u;
    } else
      n[o] = t;
  }), Object.defineProperty(n, "name", {
    value: e.name,
    writable: !1
  }), n;
}
function b(e, a) {
  const { props: n } = f(), { scopeParam: o, getScopeValue: t, throwOnMissing: u = !0 } = a, r = t(n);
  if (r == null) {
    if (u)
      throw new Error(
        `[useRoutes] Scope parameter "${o}" is not available in page props. Make sure the value returned by getScopeValue() is defined.`
      );
    return e;
  }
  return p(() => {
    const s = {};
    return Object.keys(e).forEach((c) => {
      const i = e[c];
      typeof i == "function" ? s[c] = l(i, r) : s[c] = i;
    }), s;
  }, [e, r]);
}
export {
  b as default,
  b as useRoutes
};
