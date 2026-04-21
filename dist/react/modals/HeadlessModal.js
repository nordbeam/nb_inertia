import { jsx as p, Fragment as C } from "react/jsx-runtime";
import { createContext as b, forwardRef as E, useImperativeHandle as w, useRef as H, useCallback as a, useMemo as S, useEffect as U, useContext as I } from "react";
import { router as R } from "@inertiajs/react";
import { mergeModalConfig as h } from "./types.js";
import { mergeModalHeaders as L } from "./requestContext.js";
import { useModalStack as N } from "./modalStack.js";
const M = b(null);
M.displayName = "NbInertiaCurrentModalContext";
function O() {
  const i = I(M);
  if (!i)
    throw new Error("useCurrentModal must be used within a HeadlessModal");
  return i;
}
const V = E(function({ children: t }, s) {
  const o = O();
  return w(s, () => o, [o]), typeof t == "function" ? /* @__PURE__ */ p(C, { children: t(o) }) : /* @__PURE__ */ p(C, { children: t });
}), q = E(function({ modal: t, onClose: s, isOpen: o = !0, children: k }, y) {
  const f = H(!1), v = h(t.config), { modals: u, popModal: m } = N(), d = a(() => {
    f.current || (f.current = !0, s(), setTimeout(() => {
      f.current = !1;
    }, 0));
  }, [s]);
  a(
    (e) => {
      e || d();
    },
    [d]
  );
  const x = a((e, r) => {
    R.visit(
      e.url,
      L(
        {
          ...r ?? {},
          preserveState: r?.preserveState ?? !0,
          preserveScroll: r?.preserveScroll ?? !0
        },
        {
          url: e.url,
          baseUrl: e.returnUrl || e.baseUrl,
          returnUrl: e.returnUrl
        }
      )
    );
  }, []), c = a(
    (e) => {
      const r = u.findIndex((n) => n.id === e.id);
      return r === -1 ? null : {
        modal: e,
        id: e.id,
        index: r,
        onTopOfStack: r === u.length - 1,
        isOpen: e.id === t.id ? o : !0,
        config: h(e.config),
        close: () => m(e.id),
        setOpen: (n) => {
          n || m(e.id);
        },
        reload: (n) => x(e, n),
        getParentModal: () => {
          const n = u[r - 1];
          return n ? c(n) : null;
        },
        getChildModal: () => {
          const n = u[r + 1];
          return n ? c(n) : null;
        }
      };
    },
    [o, t.id, u, m, x]
  ), l = S(() => c(t), [c, t]);
  return w(y, () => {
    if (!l)
      throw new Error("Cannot create modal ref for a modal that is not in the stack");
    return l;
  }, [l]), U(() => {
    if (v.closeExplicitly) return;
    function e(r) {
      r.key === "Escape" && (r.preventDefault(), d());
    }
    return document.addEventListener("keydown", e), () => document.removeEventListener("keydown", e);
  }, [v.closeExplicitly, d]), l ? /* @__PURE__ */ p(M.Provider, { value: l, children: k(l) }) : null;
});
export {
  q as HeadlessModal,
  V as Modal,
  q as default,
  O as useCurrentModal
};
