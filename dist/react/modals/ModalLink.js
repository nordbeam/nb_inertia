import { jsx as K } from "react/jsx-runtime";
import { useMemo as N, useCallback as l, useEffect as j, useRef as H } from "react";
import { router as O } from "@inertiajs/react";
import { isRouteResult as b } from "../../shared/types.js";
import { routerPrefetch as q } from "../../shared/routerCompat.js";
import { useModalStack as z } from "./modalStack.js";
const A = () => null, X = ({
  href: s,
  method: y,
  data: g,
  modalConfig: m,
  loadingComponent: h,
  onClick: p,
  prefetch: r,
  cacheFor: d,
  cacheTags: M,
  children: k,
  className: x,
  ...n
}) => {
  const { pushModal: w, modals: S, prefetchModal: v, getPrefetchedModal: L } = z(), t = b(s) ? s.url : s, f = (b(s) && !y ? s.method : y) || "get", i = N(() => r ? r === !0 ? ["hover"] : typeof r == "string" ? [r] : r : [], [r]), u = l(() => {
    if (f === "get")
      if (v)
        v(t, { cacheFor: d });
      else {
        const e = {};
        d !== void 0 && (e.cacheFor = d), M !== void 0 && (e.cacheTags = M), q(t, { preserveState: !0 }, e);
      }
  }, [t, f, d, M, v]);
  j(() => {
    if (i.includes("mount")) {
      const e = setTimeout(u, 0);
      return () => clearTimeout(e);
    }
  }, [i, u]);
  const a = H(null), D = l(
    (e) => {
      n.onMouseEnter?.(e), i.includes("hover") && (a.current = setTimeout(u, 75));
    },
    [i, u, n]
  ), E = l(
    (e) => {
      n.onMouseLeave?.(e), a.current && (clearTimeout(a.current), a.current = null);
    },
    [n]
  ), R = l(
    (e) => {
      n.onMouseDown?.(e), i.includes("click") && u();
    },
    [i, u, n]
  ), T = l(
    (e) => {
      if (e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), p && p(e), S.find((U) => U.url === t)))
        return;
      const c = typeof window < "u" ? window.location.href : "", o = L?.(t);
      if (o) {
        w({
          component: o.component,
          componentName: o.data.component,
          props: o.data.props,
          url: o.data.url,
          config: o.data.config || m || {},
          baseUrl: o.data.baseUrl,
          returnUrl: c,
          onClose: () => {
            c && typeof window < "u" && window.history.replaceState({}, "", c);
          }
        }), typeof window < "u" && window.history.pushState({}, "", o.data.url);
        return;
      }
      w({
        component: A,
        componentName: "",
        props: {},
        url: t,
        config: m || {},
        baseUrl: "",
        // Will be updated by InitialModalHandler
        returnUrl: c,
        // Capture the return URL now so it's available when modal is updated
        loading: !0,
        loadingComponent: h
      }), O.visit(t, {
        method: f,
        data: g ?? {},
        preserveState: !0,
        preserveScroll: !0
      });
    },
    [t, f, g, p, m, h, w, S, L]
  );
  return /* @__PURE__ */ K(
    "a",
    {
      href: t,
      className: x,
      onClick: T,
      onMouseEnter: D,
      onMouseLeave: E,
      onMouseDown: R,
      ...n,
      children: k
    }
  );
};
export {
  X as ModalLink,
  X as default
};
