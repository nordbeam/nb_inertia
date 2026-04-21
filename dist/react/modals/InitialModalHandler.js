import { useRef as s, useCallback as N, useEffect as R } from "react";
import { usePage as _, router as d } from "@inertiajs/react";
import { useModalStack as v } from "./modalStack.js";
function y({ resolveComponent: g }) {
  const { props: S } = _(), { pushModal: b, updateModal: f, clearModals: U, modals: l } = v(), p = s(!1), M = s(!1), i = s(null), c = s(/* @__PURE__ */ new Set()), u = N((r, t) => () => {
    if (i.current = null, c.current.delete(r.url), !p.current && typeof window < "u") {
      const e = t || r.baseUrl;
      e && window.location.href !== e && window.history.replaceState({}, "", e);
    }
  }, []), a = N((r) => {
    const t = r.url, e = l.find((n) => n.loading && n.url === t), o = l.find((n) => !n.loading && n.url === t);
    c.current.has(t) && !e && !o || (c.current.add(t), g(r.component).then((n) => {
      if (e) {
        if (!l.find(
          (w) => w.id === e.id && w.loading
        )) {
          c.current.delete(t);
          return;
        }
        const h = e.returnUrl;
        f(e.id, {
          component: n,
          componentName: r.component,
          props: r.props,
          config: r.config || {},
          baseUrl: r.baseUrl,
          returnUrl: h,
          // Preserve the return URL
          onClose: u(r, h),
          loading: !1
        }), i.current = r;
      } else o ? (f(o.id, {
        component: n,
        componentName: r.component,
        props: r.props,
        config: r.config || {},
        baseUrl: r.baseUrl,
        onClose: o.onClose || u(r, o.returnUrl)
      }), i.current = r) : (i.current = r, b({
        component: n,
        componentName: r.component,
        props: r.props,
        url: r.url,
        config: r.config || {},
        baseUrl: r.baseUrl,
        onClose: u(r)
      }));
    }).catch((n) => {
      c.current.delete(t), console.error("[InitialModalHandler] Failed to resolve modal component:", r.component, n);
    }));
  }, [g, b, f, l, u]);
  return R(() => {
    const r = S._nb_modal;
    r && !M.current && (M.current = !0, a(r));
  }, []), R(() => {
    const r = d.on("start", () => {
      p.current = !0;
    }), t = d.on("finish", () => {
      p.current = !1;
    }), e = d.on("navigate", (o) => {
      const n = o.detail.page.props?._nb_modal;
      if (!n) {
        U(), i.current = null, c.current.clear();
        return;
      }
      a(n);
    });
    return () => {
      r(), t(), e();
    };
  }, [a, U]), null;
}
export {
  y as InitialModalHandler,
  y as default
};
