import { jsx as j } from "react/jsx-runtime";
import { useMemo as K, useCallback as a, useEffect as N, useRef as H } from "react";
import { router as S } from "@inertiajs/react";
import { useModalStack as O } from "./modalStack.js";
function U(o) {
  if (typeof o != "object" || o === null)
    return !1;
  const i = o;
  return typeof i.url == "string" && typeof i.method == "string" && ["get", "post", "put", "patch", "delete", "head"].includes(i.method);
}
const q = () => null, J = ({
  href: o,
  method: i,
  data: y,
  modalConfig: p,
  loadingComponent: g,
  onClick: m,
  prefetch: u,
  cacheFor: d,
  cacheTags: M,
  children: L,
  className: k,
  ...r
}) => {
  const { pushModal: w, modals: h, prefetchModal: v, getPrefetchedModal: b } = O(), n = U(o) ? o.url : o, f = (U(o) && !i ? o.method : i) || "get", s = K(() => u ? u === !0 ? ["hover"] : typeof u == "string" ? [u] : u : [], [u]), l = a(() => {
    if (f === "get")
      if (v)
        v(n, { cacheFor: d });
      else {
        const e = {};
        d !== void 0 && (e.cacheFor = d), M !== void 0 && (e.cacheTags = M), S.prefetch?.(n, { preserveState: !0 }, e);
      }
  }, [n, f, d, M, v]);
  N(() => {
    if (s.includes("mount")) {
      const e = setTimeout(l, 0);
      return () => clearTimeout(e);
    }
  }, [s, l]);
  const c = H(null), x = a(
    (e) => {
      r.onMouseEnter?.(e), s.includes("hover") && (c.current = setTimeout(l, 75));
    },
    [s, l, r]
  ), D = a(
    (e) => {
      r.onMouseLeave?.(e), c.current && (clearTimeout(c.current), c.current = null);
    },
    [r]
  ), E = a(
    (e) => {
      r.onMouseDown?.(e), s.includes("click") && l();
    },
    [s, l, r]
  ), R = a(
    (e) => {
      if (e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), m && m(e), h.find((T) => T.url === n)))
        return;
      const t = b?.(n);
      if (t) {
        w({
          component: t.component,
          componentName: t.data.component,
          props: t.data.props,
          url: t.data.url,
          config: t.data.config || p || {},
          baseUrl: t.data.baseUrl,
          onClose: () => {
            t.data.baseUrl && typeof window < "u" && window.location.pathname !== t.data.baseUrl && window.history.replaceState({}, "", t.data.baseUrl);
          }
        }), typeof window < "u" && window.history.pushState({}, "", t.data.url);
        return;
      }
      w({
        component: q,
        componentName: "",
        props: {},
        url: n,
        config: p || {},
        baseUrl: "",
        // Will be updated by InitialModalHandler
        loading: !0,
        loadingComponent: g
      }), S.visit(n, {
        method: f,
        data: y ?? {},
        preserveState: !0,
        preserveScroll: !0
      });
    },
    [n, f, y, m, p, g, w, h, b]
  );
  return /* @__PURE__ */ j(
    "a",
    {
      href: n,
      className: k,
      onClick: R,
      onMouseEnter: x,
      onMouseLeave: D,
      onMouseDown: E,
      ...r,
      children: L
    }
  );
};
export {
  J as ModalLink,
  J as default
};
