import { jsx as R } from "react/jsx-runtime";
import _, { createContext as v, useContext as x, useState as j, useRef as h, useCallback as d, useEffect as J } from "react";
import { router as P } from "@inertiajs/react";
const b = v(null);
b.displayName = "NbInertiaModalPageContext";
function B() {
  return x(b) !== null;
}
function G() {
  return x(b);
}
const K = ({
  component: s,
  props: n,
  url: u,
  children: p
}) => {
  const i = _.useMemo(
    () => ({
      component: s,
      props: n,
      url: u,
      version: "1.0",
      scrollRegions: [],
      rememberedState: {},
      clearHistory: !1,
      encryptHistory: !1
    }),
    [s, n, u]
  );
  return /* @__PURE__ */ R(b.Provider, { value: i, children: p });
}, y = v(null), T = () => {
  const s = x(y);
  if (!s)
    throw new Error("useModalStack must be used within a ModalStackProvider");
  return s;
}, L = () => {
  const { modals: s } = T();
  return s.length > 0 ? s[s.length - 1] : null;
}, Q = ({
  children: s,
  onStackChange: n,
  resolveComponent: u
}) => {
  const [p, i] = j([]), U = h(0), f = h(/* @__PURE__ */ new Map()), g = h(/* @__PURE__ */ new Map()), w = h(/* @__PURE__ */ new Set()), D = d(
    (t) => {
      const r = `modal-${U.current++}`, o = {
        ...t,
        id: r
      };
      let a = !1;
      return i((e) => {
        if (e.find((m) => m.url === t.url))
          return e;
        a = !0;
        const l = [...e, o];
        return n && n(l), l;
      }), a ? r : "";
    },
    [n]
  ), I = d(
    (t) => {
      const r = { current: null };
      i((o) => {
        const a = o.find((c) => c.id === t);
        r.current = a?.onClose || null;
        const e = o.filter((c) => c.id !== t);
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
  ), N = d(() => {
    i([]), n && n([]);
  }, [n]), E = d(
    (t) => p.find((r) => r.id === t),
    [p]
  ), F = d(
    (t, r) => {
      i((o) => {
        const a = o.map(
          (e) => e.id === t ? { ...e, ...r } : e
        );
        return n && n(a), a;
      });
    },
    [n]
  ), A = d((t) => {
    const r = f.current.get(t);
    if (!r) return;
    if (Date.now() - r.timestamp > 3e4) {
      f.current.delete(t);
      return;
    }
    return r;
  }, []), H = d((t, r) => {
    if (w.current.has(t) || f.current.has(t)) return;
    w.current.add(t);
    const o = {};
    r?.cacheFor !== void 0 && (o.cacheFor = r.cacheFor), P.prefetch?.(t, { preserveState: !0 }, o), w.current.delete(t);
  }, []);
  J(() => u ? P.on("prefetched", (r) => {
    const o = r.detail?.response, a = typeof o == "string" ? JSON.parse(o) : o, e = a?.props?._nb_modal;
    if (!e?.component) return;
    const c = e.component, l = e.url || a?.url;
    if (!l || f.current.has(l)) return;
    const m = g.current.get(c);
    m ? f.current.set(l, {
      data: {
        component: c,
        props: e.props || {},
        url: l,
        baseUrl: e.baseUrl || "",
        config: e.config
      },
      component: m,
      timestamp: Date.now()
    }) : u(c).then((M) => {
      g.current.set(c, M), f.current.set(l, {
        data: {
          component: c,
          props: e.props || {},
          url: l,
          baseUrl: e.baseUrl || "",
          config: e.config
        },
        component: M,
        timestamp: Date.now()
      });
    }).catch((M) => {
      console.warn("[ModalStack] Component preload failed:", c, M);
    });
  }) : void 0, [u]);
  const O = {
    modals: p,
    pushModal: D,
    popModal: I,
    clearModals: N,
    getModal: E,
    updateModal: F,
    resolveComponent: u,
    prefetchModal: u ? H : void 0,
    getPrefetchedModal: A
  };
  return /* @__PURE__ */ R(y.Provider, { value: O, children: s });
};
export {
  K as ModalPageProvider,
  Q as ModalStackProvider,
  Q as default,
  B as useIsInModal,
  L as useModal,
  G as useModalPageContext,
  T as useModalStack
};
