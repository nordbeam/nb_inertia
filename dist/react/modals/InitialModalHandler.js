import { useRef as u, useCallback as H, useEffect as m } from "react";
import { usePage as I, router as p } from "@inertiajs/react";
import { useModalStack as y } from "./modalStack.js";
function k({ resolveComponent: f }) {
  const { props: R } = I(), { pushModal: g, updateModal: M, clearModals: b, modals: i } = y(), a = u(!1), h = u(!1), t = u(null), l = u(/* @__PURE__ */ new Set()), s = H((n, r) => () => {
    if (t.current = null, l.current.delete(n.url), !a.current && typeof window < "u") {
      const e = r || n.baseUrl;
      e && window.location.href !== e && window.history.replaceState({}, "", e);
    }
  }, []), d = H((n) => {
    const r = n.url;
    if (console.log("[InitialModalHandler] openModal called:", { url: r, alreadyHandled: l.current.has(r), modalsCount: i.length }), l.current.has(r)) {
      console.log("[InitialModalHandler] URL already handled, skipping");
      return;
    }
    const e = i.find(
      (o) => o.loading && o.url === r
    );
    console.log("[InitialModalHandler] loadingModal found:", !!e), l.current.add(r), f(n.component).then((o) => {
      if (e) {
        if (!i.find(
          (w) => w.id === e.id && w.loading
        )) {
          l.current.delete(r);
          return;
        }
        const U = e.returnUrl;
        M(e.id, {
          component: o,
          componentName: n.component,
          props: n.props,
          config: n.config || {},
          baseUrl: n.baseUrl,
          returnUrl: U,
          // Preserve the return URL
          onClose: s(n, U),
          loading: !1
        }), t.current = n;
      } else
        t.current = n, g({
          component: o,
          componentName: n.component,
          props: n.props,
          url: n.url,
          config: n.config || {},
          baseUrl: n.baseUrl,
          onClose: s(n)
        });
    }).catch((o) => {
      l.current.delete(r), console.error("[InitialModalHandler] Failed to resolve modal component:", n.component, o);
    });
  }, [f, g, M, i, s]);
  return m(() => {
    const n = R._nb_modal;
    n && !h.current && (h.current = !0, d(n));
  }, []), m(() => {
    const n = p.on("start", () => {
      a.current = !0;
    }), r = p.on("finish", () => {
      a.current = !1;
    }), e = p.on("navigate", (o) => {
      const c = o.detail.page.props?._nb_modal;
      if (!c) {
        b(), t.current = null, l.current.clear();
        return;
      }
      t.current && t.current.component === c.component && t.current.url === c.url || d(c);
    });
    return () => {
      n(), r(), e();
    };
  }, [d, b]), null;
}
export {
  k as InitialModalHandler,
  k as default
};
