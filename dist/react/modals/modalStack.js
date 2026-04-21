import { jsx as E } from "react/jsx-runtime";
import P, { createContext as I, useContext as y, useState as _, useRef as h, useCallback as p, useEffect as S } from "react";
import { router as N } from "@inertiajs/react";
import { routerPrefetch as j } from "../../shared/routerCompat.js";
import { isRouteResult as C } from "../../shared/types.js";
import { mergeModalHeaders as J, registerModalRequestContext as V, unregisterModalRequestContext as $ } from "./requestContext.js";
const b = I(null);
b.displayName = "NbInertiaModalPageContext";
function Y() {
  return y(b) !== null;
}
function Z() {
  return y(b);
}
const k = ({
  component: l,
  props: n,
  url: d,
  baseUrl: i,
  returnUrl: u,
  children: x
}) => {
  const f = P.useRef(Symbol("nb-inertia-modal-request-context")), M = P.useMemo(
    () => ({
      component: l,
      props: n,
      url: d,
      baseUrl: i,
      returnUrl: u,
      version: "1.0",
      flash: {},
      scrollRegions: [],
      rememberedState: {},
      clearHistory: !1,
      encryptHistory: !1,
      preserveFragment: !1
    }),
    [l, n, d, i, u]
  );
  return S(() => (V(f.current, {
    url: d,
    baseUrl: i,
    returnUrl: u
  }), () => {
    $(f.current);
  }), [d, i, u]), /* @__PURE__ */ E(b.Provider, { value: M, children: x });
}, U = I(null), z = () => {
  const l = y(U);
  if (!l)
    throw new Error("useModalStack must be used within a ModalStackProvider");
  return l;
}, ee = () => {
  const { modals: l } = z();
  return l.length > 0 ? l[l.length - 1] : null;
};
function B(l, n) {
  const d = C(l) ? l.url : l, i = (C(l) && !n ? l.method : n) || "get";
  return { url: d, method: i };
}
const te = ({
  children: l,
  onStackChange: n,
  resolveComponent: d
}) => {
  const [i, u] = _([]), x = h(0), f = h(/* @__PURE__ */ new Map()), M = h(/* @__PURE__ */ new Map()), R = h(/* @__PURE__ */ new Set()), g = p(
    (r) => {
      const e = `modal-${x.current++}`, t = {
        ...r,
        id: e
      };
      let s = !1;
      return u((o) => {
        if (o.find((m) => m.url === r.url))
          return o;
        s = !0;
        const a = [...o, t];
        return n && n(a), a;
      }), s ? e : "";
    },
    [n]
  ), q = p(
    (r) => {
      const e = { current: null };
      u((t) => {
        const s = t.find((c) => c.id === r);
        e.current = s?.onClose || null;
        const o = t.filter((c) => c.id !== r);
        return n && n(o), o;
      }), setTimeout(() => {
        if (e.current)
          try {
            e.current();
          } catch (t) {
            console.error("Error in modal onClose callback:", t);
          }
      }, 0);
    },
    [n]
  ), D = p((r) => {
    r?.fireOnClose ? u((e) => {
      const t = e.map((s) => s.onClose).filter((s) => typeof s == "function");
      return n && n([]), setTimeout(() => {
        t.forEach((s) => {
          try {
            s();
          } catch (o) {
            console.error("Error in modal onClose callback:", o);
          }
        });
      }, 0), [];
    }) : (u([]), n && n([]));
  }, [n]), F = p(
    (r) => i.find((e) => e.id === r),
    [i]
  ), H = p(
    (r, e) => {
      u((t) => {
        const s = t.map(
          (o) => o.id === r ? { ...o, ...e } : o
        );
        return n && n(s), s;
      });
    },
    [n]
  ), v = p((r) => {
    const e = f.current.get(r);
    if (!e) return;
    if (Date.now() - e.timestamp > 3e4) {
      f.current.delete(r);
      return;
    }
    return e;
  }, []), O = p(
    (r, e = {}) => {
      const { url: t, method: s } = B(r, e.method);
      if (i.find((m) => m.url === t))
        return;
      const c = e.returnUrl || (typeof window < "u" ? window.location.href : ""), a = s === "get" ? v(t) : void 0;
      if (a) {
        g({
          component: a.component,
          componentName: a.data.component,
          props: a.data.props,
          url: a.data.url,
          config: a.data.config || e.modalConfig || {},
          baseUrl: a.data.baseUrl,
          returnUrl: c,
          onClose: () => {
            c && typeof window < "u" && window.history.replaceState({}, "", c);
          }
        }), typeof window < "u" && window.history.pushState({}, "", a.data.url);
        return;
      }
      g({
        component: () => null,
        componentName: "",
        props: {},
        url: t,
        config: e.modalConfig || {},
        baseUrl: "",
        returnUrl: c,
        loading: !0,
        loadingComponent: e.loadingComponent
      }), N.visit(t, {
        method: s,
        data: e.data ?? {},
        preserveState: e.preserveState ?? !0,
        preserveScroll: e.preserveScroll ?? !0,
        ...J(
          {
            headers: e.headers
          },
          { url: t, baseUrl: c, returnUrl: c }
        )
      });
    },
    [v, i, g]
  ), T = p((r, e) => {
    if (R.current.has(r) || f.current.has(r)) return;
    R.current.add(r);
    const t = {};
    e?.cacheFor !== void 0 && (t.cacheFor = e.cacheFor), j(r, { preserveState: !0 }, t), R.current.delete(r);
  }, []);
  S(() => d ? N.on("prefetched", (e) => {
    const t = e.detail?.response, s = typeof t == "string" ? JSON.parse(t) : t, o = s?.props?._nb_modal;
    if (!o?.component) return;
    const c = o.component, a = o.url || s?.url;
    if (!a || f.current.has(a)) return;
    const m = M.current.get(c);
    m ? f.current.set(a, {
      data: {
        component: c,
        props: o.props || {},
        url: a,
        baseUrl: o.baseUrl || "",
        config: o.config
      },
      component: m,
      timestamp: Date.now()
    }) : d(c).then((w) => {
      M.current.set(c, w), f.current.set(a, {
        data: {
          component: c,
          props: o.props || {},
          url: a,
          baseUrl: o.baseUrl || "",
          config: o.config
        },
        component: w,
        timestamp: Date.now()
      });
    }).catch((w) => {
      console.warn("[ModalStack] Component preload failed:", c, w);
    });
  }) : void 0, [d]);
  const A = {
    modals: i,
    pushModal: g,
    popModal: q,
    clearModals: D,
    getModal: F,
    updateModal: H,
    visitModal: O,
    resolveComponent: d,
    prefetchModal: d ? T : void 0,
    getPrefetchedModal: v
  };
  return /* @__PURE__ */ E(U.Provider, { value: A, children: l });
};
export {
  k as ModalPageProvider,
  te as ModalStackProvider,
  te as default,
  Y as useIsInModal,
  ee as useModal,
  Z as useModalPageContext,
  z as useModalStack
};
