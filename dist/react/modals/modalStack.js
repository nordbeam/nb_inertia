import { jsx as H } from "react/jsx-runtime";
import { createContext as P, useContext as b, useState as y, useRef as L, useCallback as c } from "react";
const u = P(null), R = () => {
  const l = b(u);
  if (!l)
    throw new Error("useModalStack must be used within a ModalStackProvider");
  return l;
}, z = () => {
  const { modals: l } = R();
  return l.length > 0 ? l[l.length - 1] : null;
}, I = ({
  children: l,
  onStackChange: d
}) => {
  const [a, i] = y([]), f = L(0), M = c(
    (n) => {
      const e = `modal-${f.current++}`, r = a.length, s = {
        ...n,
        id: e,
        index: r,
        eventHandlers: /* @__PURE__ */ new Map()
      };
      return i((t) => {
        const o = [...t, s];
        return d && d(o), o;
      }), e;
    },
    [a.length, d]
  ), v = c(
    (n) => {
      i((e) => {
        const r = e.filter((s) => s.id !== n);
        return d && d(r), r;
      });
    },
    [d]
  ), m = c(() => {
    i([]), d && d([]);
  }, [d]), p = c(
    (n) => a.find((e) => e.id === n),
    [a]
  ), w = c((n, e, r) => {
    i(
      (s) => s.map((t) => {
        if (t.id === n) {
          const o = t.eventHandlers.get(e) || /* @__PURE__ */ new Set();
          o.add(r), t.eventHandlers.set(e, o);
        }
        return t;
      })
    );
  }, []), x = c(
    (n, e, r) => {
      i(
        (s) => s.map((t) => {
          if (t.id === n) {
            const o = t.eventHandlers.get(e);
            o && o.delete(r);
          }
          return t;
        })
      );
    },
    []
  ), h = c(
    async (n, e) => {
      const r = a.find((t) => t.id === n);
      if (!r) return !0;
      const s = r.eventHandlers.get(e);
      if (!s || s.size === 0) return !0;
      for (const t of s)
        try {
          if (await t(r) === !1)
            return !1;
        } catch (o) {
          console.error(`Error in modal event handler (${e}):`, o);
        }
      return !0;
    },
    [a]
  ), E = {
    modals: a,
    pushModal: M,
    popModal: v,
    clearModals: m,
    getModal: p,
    addEventListener: w,
    removeEventListener: x,
    emitEvent: h
  };
  return /* @__PURE__ */ H(u.Provider, { value: E, children: l });
};
export {
  I as ModalStackProvider,
  I as default,
  z as useModal,
  R as useModalStack
};
