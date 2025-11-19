import { jsx as M } from "react/jsx-runtime";
import { useState as b, useCallback as w } from "react";
import { router as K } from "../router.js";
import { useModalStack as L } from "./modalStack.js";
function f(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const o = t;
  return typeof o.url == "string" && typeof o.method == "string" && ["get", "post", "put", "patch", "delete", "head"].includes(o.method);
}
const B = ({
  href: t,
  method: o,
  data: i,
  modalConfig: a = {},
  baseUrl: l,
  onClick: n,
  children: m,
  className: d,
  ...h
}) => {
  const [y, s] = b(!1), { pushModal: c } = L(), r = f(t) ? t.url : t, p = (f(t) && !o ? t.method : o) || "get", g = w((e) => {
    e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), n && n(e), s(!0), K.visit(r, {
      method: p,
      data: i,
      preserveState: !0,
      preserveScroll: !0,
      only: [],
      // Don't merge with current page props
      onSuccess: (u) => {
        const j = u.component, k = u.props;
        c({
          component: j,
          // This would need proper component resolution
          props: k,
          config: a,
          baseUrl: l || window.location.pathname
        }), s(!1);
      },
      onError: () => {
        s(!1);
      },
      onFinish: () => {
        s(!1);
      }
    }));
  }, [r, p, i, a, l, n, c]), S = [
    d,
    y ? "opacity-50 cursor-wait" : "cursor-pointer"
  ].filter(Boolean).join(" ");
  return /* @__PURE__ */ M(
    "a",
    {
      href: r,
      className: S,
      onClick: g,
      ...h,
      children: m
    }
  );
};
export {
  B as ModalLink,
  B as default
};
