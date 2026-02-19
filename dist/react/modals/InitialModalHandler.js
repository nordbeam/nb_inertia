import { useRef as u, useCallback as m, useEffect as R } from "react";
import { usePage as S, router as p } from "@inertiajs/react";
import { useModalStack as _ } from "./modalStack.js";
function y({ resolveComponent: d }) {
  const { props: N } = S(), { pushModal: g, updateModal: b, clearModals: M, modals: i } = _(), s = u(!1), h = u(!1), o = u(null), c = u(/* @__PURE__ */ new Set()), a = m((r, e) => () => {
    if (o.current = null, c.current.delete(r.url), !s.current && typeof window < "u") {
      const n = e || r.baseUrl;
      n && window.location.href !== n && window.history.replaceState({}, "", n);
    }
  }, []), f = m((r) => {
    const e = r.url;
    if (c.current.has(e))
      return;
    const n = i.find(
      (t) => t.loading && t.url === e
    );
    c.current.add(e), d(r.component).then((t) => {
      if (n) {
        if (!i.find(
          (w) => w.id === n.id && w.loading
        )) {
          c.current.delete(e);
          return;
        }
        const U = n.returnUrl;
        b(n.id, {
          component: t,
          componentName: r.component,
          props: r.props,
          config: r.config || {},
          baseUrl: r.baseUrl,
          returnUrl: U,
          // Preserve the return URL
          onClose: a(r, U),
          loading: !1
        }), o.current = r;
      } else
        o.current = r, g({
          component: t,
          componentName: r.component,
          props: r.props,
          url: r.url,
          config: r.config || {},
          baseUrl: r.baseUrl,
          onClose: a(r)
        });
    }).catch((t) => {
      c.current.delete(e), console.error("[InitialModalHandler] Failed to resolve modal component:", r.component, t);
    });
  }, [d, g, b, i, a]);
  return R(() => {
    const r = N._nb_modal;
    r && !h.current && (h.current = !0, f(r));
  }, []), R(() => {
    const r = p.on("start", () => {
      s.current = !0;
    }), e = p.on("finish", () => {
      s.current = !1;
    }), n = p.on("navigate", (t) => {
      const l = t.detail.page.props?._nb_modal;
      if (!l) {
        M(), o.current = null, c.current.clear();
        return;
      }
      o.current && o.current.component === l.component && o.current.url === l.url || f(l);
    });
    return () => {
      r(), e(), n();
    };
  }, [f, M]), null;
}
export {
  y as InitialModalHandler,
  y as default
};
