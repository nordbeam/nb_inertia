import { jsx as w, Fragment as h } from "react/jsx-runtime";
import { useState as x, useEffect as p, useCallback as I } from "react";
import { router as H } from "../router.js";
import { useModalStack as L } from "./modalStack.js";
import { ModalStackProvider as A, useModal as B } from "./modalStack.js";
const S = ({
  id: y,
  component: a,
  componentProps: o = {},
  config: r = {},
  baseUrl: l,
  open: s = !0,
  onClose: u,
  onSuccess: n,
  children: v
}) => {
  const { pushModal: E, popModal: d, emitEvent: f } = L(), [e, M] = x(y || null), [k, c] = x(!1);
  p(() => {
    if (s && !e) {
      const t = E({
        component: a,
        props: o,
        config: r,
        baseUrl: l
      });
      M(t);
    }
  }, [s, e, E, a, o, r, l]);
  const i = I(async (t = !1) => {
    if (!e || k) return;
    if (c(!0), !await f(e, "beforeClose")) {
      c(!1);
      return;
    }
    await f(e, t ? "success" : "close"), d(e), t && n ? n() : !t && u && u(), l && H.visit(l), M(null), c(!1);
  }, [e, k, f, d, n, u, l]);
  return p(() => {
    if (!s || !e || r.closeExplicitly) return;
    const t = (m) => {
      m.key === "Escape" && (m.preventDefault(), i());
    };
    return document.addEventListener("keydown", t), () => document.removeEventListener("keydown", t);
  }, [s, e, r.closeExplicitly, i]), p(() => () => {
    e && d(e);
  }, [e, d]), !s || !e ? null : v && e ? /* @__PURE__ */ w(h, { children: v({
    id: e,
    component: a,
    props: o,
    config: r,
    baseUrl: l,
    index: 0,
    eventHandlers: /* @__PURE__ */ new Map()
  }, i) }) : /* @__PURE__ */ w(a, { ...o, close: i });
};
export {
  S as HeadlessModal,
  A as ModalStackProvider,
  S as default,
  B as useModal,
  L as useModalStack
};
