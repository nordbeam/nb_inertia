import { jsx as g } from "react/jsx-runtime";
import H, { createContext as R, useState as T, useRef as b, useCallback as d, useEffect as _, useContext as x } from "react";
import { router as j } from "@inertiajs/react";
import { routerPrefetch as J } from "../../shared/routerCompat.js";
const h = R(null);
h.displayName = "NbInertiaModalPageContext";
function K() {
  return x(h) !== null;
}
function L() {
  return x(h);
}
const Q = ({
  component: c,
  props: n,
  url: u,
  children: p
}) => {
  const i = H.useMemo(
    () => ({
      component: c,
      props: n,
      url: u,
      version: "1.0",
      scrollRegions: [],
      rememberedState: {},
      clearHistory: !1,
      encryptHistory: !1
    }),
    [c, n, u]
  );
  return /* @__PURE__ */ g(h.Provider, { value: i, children: p });
}, y = R(null), $ = () => {
  const c = x(y);
  if (!c)
    throw new Error("useModalStack must be used within a ModalStackProvider");
  return c;
}, V = () => {
  const { modals: c } = $();
  return c.length > 0 ? c[c.length - 1] : null;
}, W = ({
  children: c,
  onStackChange: n,
  resolveComponent: u
}) => {
  const [p, i] = T([]), v = b(0), f = b(/* @__PURE__ */ new Map()), P = b(/* @__PURE__ */ new Map()), w = b(/* @__PURE__ */ new Set()), E = d(
    (t) => {
      const r = `modal-${v.current++}`, o = {
        ...t,
        id: r
      };
      let s = !1;
      return i((e) => {
        if (e.find((m) => m.url === t.url))
          return e;
        s = !0;
        const l = [...e, o];
        return n && n(l), l;
      }), s ? r : "";
    },
    [n]
  ), U = d(
    (t) => {
      const r = { current: null };
      i((o) => {
        const s = o.find((a) => a.id === t);
        r.current = s?.onClose || null;
        const e = o.filter((a) => a.id !== t);
        return n && n(e), e;
      }), setTimeout(() => {
        if (r.current)
          try {
            r.current();
          } catch (o) {
            console.error("Error in modal onClose callback:", o);
          }
      }, 0);
    },
    [n]
  ), D = d((t) => {
    t?.fireOnClose ? i((r) => {
      const o = r.map((s) => s.onClose).filter((s) => typeof s == "function");
      return n && n([]), setTimeout(() => {
        o.forEach((s) => {
          try {
            s();
          } catch (e) {
            console.error("Error in modal onClose callback:", e);
          }
        });
      }, 0), [];
    }) : (i([]), n && n([]));
  }, [n]), I = d(
    (t) => p.find((r) => r.id === t),
    [p]
  ), N = d(
    (t, r) => {
      i((o) => {
        const s = o.map(
          (e) => e.id === t ? { ...e, ...r } : e
        );
        return n && n(s), s;
      });
    },
    [n]
  ), F = d((t) => {
    const r = f.current.get(t);
    if (!r) return;
    if (Date.now() - r.timestamp > 3e4) {
      f.current.delete(t);
      return;
    }
    return r;
  }, []), O = d((t, r) => {
    if (w.current.has(t) || f.current.has(t)) return;
    w.current.add(t);
    const o = {};
    r?.cacheFor !== void 0 && (o.cacheFor = r.cacheFor), J(t, { preserveState: !0 }, o), w.current.delete(t);
  }, []);
  _(() => u ? j.on("prefetched", (r) => {
    const o = r.detail?.response, s = typeof o == "string" ? JSON.parse(o) : o, e = s?.props?._nb_modal;
    if (!e?.component) return;
    const a = e.component, l = e.url || s?.url;
    if (!l || f.current.has(l)) return;
    const m = P.current.get(a);
    m ? f.current.set(l, {
      data: {
        component: a,
        props: e.props || {},
        url: l,
        baseUrl: e.baseUrl || "",
        config: e.config
      },
      component: m,
      timestamp: Date.now()
    }) : u(a).then((M) => {
      P.current.set(a, M), f.current.set(l, {
        data: {
          component: a,
          props: e.props || {},
          url: l,
          baseUrl: e.baseUrl || "",
          config: e.config
        },
        component: M,
        timestamp: Date.now()
      });
    }).catch((M) => {
      console.warn("[ModalStack] Component preload failed:", a, M);
    });
  }) : void 0, [u]);
  const A = {
    modals: p,
    pushModal: E,
    popModal: U,
    clearModals: D,
    getModal: I,
    updateModal: N,
    resolveComponent: u,
    prefetchModal: u ? O : void 0,
    getPrefetchedModal: F
  };
  return /* @__PURE__ */ g(y.Provider, { value: A, children: c });
};
export {
  Q as ModalPageProvider,
  W as ModalStackProvider,
  W as default,
  K as useIsInModal,
  V as useModal,
  L as useModalPageContext,
  $ as useModalStack
};
