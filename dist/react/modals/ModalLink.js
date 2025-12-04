import { jsx as K } from "react/jsx-runtime";
import { useMemo as N, useCallback as d, useEffect as H, useRef as O } from "react";
import { router as L } from "@inertiajs/react";
import { useModalStack as q } from "./modalStack.js";
function k(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const u = t;
  return typeof u.url == "string" && typeof u.method == "string" && ["get", "post", "put", "patch", "delete", "head"].includes(u.method);
}
const z = () => null, Q = ({
  href: t,
  method: u,
  data: g,
  modalConfig: m,
  loadingComponent: h,
  onClick: M,
  prefetch: i,
  cacheFor: f,
  cacheTags: w,
  children: x,
  className: D,
  ...r
}) => {
  const { pushModal: y, modals: b, prefetchModal: v, getPrefetchedModal: S } = q(), o = k(t) ? t.url : t, a = (k(t) && !u ? t.method : u) || "get", s = N(() => i ? i === !0 ? ["hover"] : typeof i == "string" ? [i] : i : [], [i]), l = d(() => {
    if (a === "get")
      if (v)
        v(o, { cacheFor: f });
      else {
        const e = {};
        f !== void 0 && (e.cacheFor = f), w !== void 0 && (e.cacheTags = w), L.prefetch?.(o, { preserveState: !0 }, e);
      }
  }, [o, a, f, w, v]);
  H(() => {
    if (s.includes("mount")) {
      const e = setTimeout(l, 0);
      return () => clearTimeout(e);
    }
  }, [s, l]);
  const c = O(null), E = d(
    (e) => {
      r.onMouseEnter?.(e), s.includes("hover") && (c.current = setTimeout(l, 75));
    },
    [s, l, r]
  ), R = d(
    (e) => {
      r.onMouseLeave?.(e), c.current && (clearTimeout(c.current), c.current = null);
    },
    [r]
  ), T = d(
    (e) => {
      r.onMouseDown?.(e), s.includes("click") && l();
    },
    [s, l, r]
  ), U = d(
    (e) => {
      if (e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), M && M(e), b.find((j) => j.url === o)))
        return;
      const p = typeof window < "u" ? window.location.href : "", n = S?.(o);
      if (n) {
        y({
          component: n.component,
          componentName: n.data.component,
          props: n.data.props,
          url: n.data.url,
          config: n.data.config || m || {},
          baseUrl: n.data.baseUrl,
          returnUrl: p,
          onClose: () => {
            p && typeof window < "u" && window.history.replaceState({}, "", p);
          }
        }), typeof window < "u" && window.history.pushState({}, "", n.data.url);
        return;
      }
      y({
        component: z,
        componentName: "",
        props: {},
        url: o,
        config: m || {},
        baseUrl: "",
        // Will be updated by InitialModalHandler
        returnUrl: p,
        // Capture the return URL now so it's available when modal is updated
        loading: !0,
        loadingComponent: h
      }), L.visit(o, {
        method: a,
        data: g ?? {},
        preserveState: !0,
        preserveScroll: !0
      });
    },
    [o, a, g, M, m, h, y, b, S]
  );
  return /* @__PURE__ */ K(
    "a",
    {
      href: o,
      className: D,
      onClick: U,
      onMouseEnter: E,
      onMouseLeave: R,
      onMouseDown: T,
      ...r,
      children: x
    }
  );
};
export {
  Q as ModalLink,
  Q as default
};
