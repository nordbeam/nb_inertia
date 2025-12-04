import { useRef as u, useCallback as w, useEffect as H } from "react";
import { usePage as m, router as p } from "@inertiajs/react";
import { useModalStack as I } from "./modalStack.js";
function _({ resolveComponent: f }) {
  const { props: R } = m(), { pushModal: g, updateModal: b, clearModals: M, modals: i } = I(), a = u(!1), h = u(!1), o = u(null), t = u(/* @__PURE__ */ new Set()), s = w((n) => () => {
    o.current = null, t.current.delete(n.url), n.baseUrl && !a.current && typeof window < "u" && window.location.pathname !== n.baseUrl && window.history.replaceState({}, "", n.baseUrl);
  }, []), d = w((n) => {
    const e = n.url;
    if (console.log("[InitialModalHandler] openModal called:", { url: e, alreadyHandled: t.current.has(e), modalsCount: i.length }), t.current.has(e)) {
      console.log("[InitialModalHandler] URL already handled, skipping");
      return;
    }
    const l = i.find(
      (r) => r.loading && r.url === e
    );
    console.log("[InitialModalHandler] loadingModal found:", !!l), t.current.add(e), f(n.component).then((r) => {
      if (l) {
        if (!i.find(
          (U) => U.id === l.id && U.loading
        )) {
          t.current.delete(e);
          return;
        }
        b(l.id, {
          component: r,
          componentName: n.component,
          props: n.props,
          config: n.config || {},
          baseUrl: n.baseUrl,
          onClose: s(n),
          loading: !1
        }), o.current = n;
      } else
        o.current = n, g({
          component: r,
          componentName: n.component,
          props: n.props,
          url: n.url,
          config: n.config || {},
          baseUrl: n.baseUrl,
          onClose: s(n)
        });
    }).catch((r) => {
      t.current.delete(e), console.error("[InitialModalHandler] Failed to resolve modal component:", n.component, r);
    });
  }, [f, g, b, i, s]);
  return H(() => {
    const n = R._nb_modal;
    n && !h.current && (h.current = !0, d(n));
  }, []), H(() => {
    const n = p.on("start", () => {
      a.current = !0;
    }), e = p.on("finish", () => {
      a.current = !1;
    }), l = p.on("navigate", (r) => {
      const c = r.detail.page.props?._nb_modal;
      if (!c) {
        M(), o.current = null, t.current.clear();
        return;
      }
      o.current && o.current.component === c.component && o.current.url === c.url || d(c);
    });
    return () => {
      n(), e(), l();
    };
  }, [d, M]), null;
}
export {
  _ as InitialModalHandler,
  _ as default
};
