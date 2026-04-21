import { jsx as b } from "react/jsx-runtime";
import { useMemo as j, useCallback as s, useEffect as H, useRef as O } from "react";
import { isRouteResult as k } from "../../shared/types.js";
import { routerPrefetch as U } from "../../shared/routerCompat.js";
import { useModalStack as q } from "./modalStack.js";
const z = () => null, N = ({
  href: t,
  method: M,
  data: v,
  modalConfig: w,
  loadingComponent: y,
  onClick: c,
  prefetch: n,
  cacheFor: l,
  cacheTags: m,
  children: x,
  className: D,
  ...o
}) => {
  const { modals: L, prefetchModal: a, visitModal: g } = q(), r = k(t) ? t.url : t, f = (k(t) && !M ? t.method : M) || "get", u = j(() => n ? n === !0 ? ["hover"] : typeof n == "string" ? [n] : n : [], [n]), i = s(() => {
    if (f === "get")
      if (a)
        a(r, { cacheFor: l });
      else {
        const e = {};
        l !== void 0 && (e.cacheFor = l), m !== void 0 && (e.cacheTags = m), U(r, { preserveState: !0 }, e);
      }
  }, [r, f, l, m, a]);
  H(() => {
    if (u.includes("mount")) {
      const e = setTimeout(i, 0);
      return () => clearTimeout(e);
    }
  }, [u, i]);
  const d = O(null), E = s(
    (e) => {
      o.onMouseEnter?.(e), u.includes("hover") && (d.current = setTimeout(i, 75));
    },
    [u, i, o]
  ), R = s(
    (e) => {
      o.onMouseLeave?.(e), d.current && (clearTimeout(d.current), d.current = null);
    },
    [o]
  ), T = s(
    (e) => {
      o.onMouseDown?.(e), u.includes("click") && i();
    },
    [u, i, o]
  ), p = s(
    (e) => {
      if (e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), c && c(e), L.find((S) => S.url === r)))
        return;
      const K = typeof window < "u" ? window.location.href : "";
      g(t, {
        method: f,
        data: v ?? {},
        modalConfig: w,
        loadingComponent: y || z,
        returnUrl: K
      });
    },
    [v, f, t, y, w, L, c, g]
  );
  return /* @__PURE__ */ b(
    "a",
    {
      href: r,
      className: D,
      onClick: p,
      onMouseEnter: E,
      onMouseLeave: R,
      onMouseDown: T,
      ...o,
      children: x
    }
  );
};
export {
  N as ModalLink,
  N as default
};
