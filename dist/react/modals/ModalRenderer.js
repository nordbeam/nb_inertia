import { jsx as e, Fragment as p, jsxs as a } from "react/jsx-runtime";
import { useModalStack as h, ModalPageProvider as g } from "./modalStack.js";
import { HeadlessModal as v } from "./HeadlessModal.js";
import { CloseButton as m } from "./CloseButton.js";
import { mergeModalConfig as C } from "./types.js";
const x = 50;
function k(t) {
  return x + t * 2;
}
function y({
  modal: t,
  close: o,
  config: s,
  zIndex: i,
  backdropClassName: l,
  wrapperClassName: n
}) {
  const c = t.component, d = s.closeButton !== !1;
  if (t.loading) {
    const r = t.loadingComponent;
    return /* @__PURE__ */ a(p, { children: [
      /* @__PURE__ */ e(
        "div",
        {
          className: l,
          style: { zIndex: i },
          onClick: s.closeExplicitly ? void 0 : o,
          "aria-hidden": "true"
        }
      ),
      /* @__PURE__ */ e("div", { className: n, style: { zIndex: i + 1 }, children: /* @__PURE__ */ a("div", { className: "relative", children: [
        d && /* @__PURE__ */ e(m, { onClick: o }),
        r ? /* @__PURE__ */ e(r, {}) : null
      ] }) })
    ] });
  }
  return /* @__PURE__ */ a(p, { children: [
    /* @__PURE__ */ e(
      "div",
      {
        className: l,
        style: { zIndex: i },
        onClick: s.closeExplicitly ? void 0 : o,
        "aria-hidden": "true"
      }
    ),
    /* @__PURE__ */ e(
      "div",
      {
        className: n,
        style: { zIndex: i + 1 },
        role: "dialog",
        "aria-modal": "true",
        children: /* @__PURE__ */ a("div", { className: "relative", children: [
          d && /* @__PURE__ */ e(m, { onClick: o }),
          /* @__PURE__ */ e(c, { ...t.props, close: o })
        ] })
      }
    )
  ] });
}
const j = ({
  renderModal: t,
  backdropClassName: o = "fixed inset-0 bg-black/50",
  wrapperClassName: s = "fixed inset-0 flex items-center justify-center"
}) => {
  const { modals: i, popModal: l } = h();
  return i.length === 0 ? null : /* @__PURE__ */ e(p, { children: i.map((n, c) => {
    const d = k(c), r = C(n.config), u = () => l(n.id), f = {
      modal: n,
      close: u,
      config: r,
      zIndex: d,
      index: c
    };
    return /* @__PURE__ */ e(
      g,
      {
        component: n.componentName,
        props: n.props,
        url: n.url,
        children: /* @__PURE__ */ e(v, { modal: n, onClose: u, children: () => t ? t(f) : /* @__PURE__ */ e(
          y,
          {
            ...f,
            backdropClassName: r.backdropClasses ? `${o} ${r.backdropClasses}` : o,
            wrapperClassName: s
          }
        ) })
      },
      n.id
    );
  }) });
};
export {
  j as ModalRenderer,
  j as default
};
