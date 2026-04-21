import { jsx as n, Fragment as p, jsxs as u } from "react/jsx-runtime";
import { useModalStack as h, ModalPageProvider as C } from "./modalStack.js";
import { HeadlessModal as v } from "./HeadlessModal.js";
import { CloseButton as m } from "./CloseButton.js";
import { mergeModalConfig as g } from "./types.js";
const k = 50;
function x(t) {
  return k + t * 2;
}
function y({
  modal: t,
  close: r,
  config: i,
  zIndex: o,
  backdropClassName: c,
  wrapperClassName: e
}) {
  const a = t.component, d = i.closeButton !== !1, s = i.closeOnClickOutside !== !1;
  if (t.loading) {
    const l = t.loadingComponent;
    return /* @__PURE__ */ u(p, { children: [
      /* @__PURE__ */ n(
        "div",
        {
          className: c,
          style: { zIndex: o },
          onClick: i.closeExplicitly || !s ? void 0 : r,
          "aria-hidden": "true"
        }
      ),
      /* @__PURE__ */ n("div", { className: e, style: { zIndex: o + 1 }, children: /* @__PURE__ */ u("div", { className: "relative", children: [
        d && /* @__PURE__ */ n(m, { onClick: r }),
        l ? /* @__PURE__ */ n(l, {}) : null
      ] }) })
    ] });
  }
  return /* @__PURE__ */ u(p, { children: [
    /* @__PURE__ */ n(
      "div",
      {
        className: c,
        style: { zIndex: o },
        onClick: i.closeExplicitly || !s ? void 0 : r,
        "aria-hidden": "true"
      }
    ),
    /* @__PURE__ */ n(
      "div",
      {
        className: e,
        style: { zIndex: o + 1 },
        role: "dialog",
        "aria-modal": "true",
        children: /* @__PURE__ */ u("div", { className: "relative", children: [
          d && /* @__PURE__ */ n(m, { onClick: r }),
          /* @__PURE__ */ n(a, { ...t.props, close: r })
        ] })
      }
    )
  ] });
}
const O = ({
  renderModal: t,
  backdropClassName: r = "fixed inset-0 bg-black/50",
  wrapperClassName: i = "fixed inset-0 flex items-center justify-center"
}) => {
  const { modals: o, popModal: c } = h();
  return o.length === 0 ? null : /* @__PURE__ */ n(p, { children: o.map((e, a) => {
    const d = x(a), s = g(e.config), l = () => c(e.id), f = {
      modal: e,
      close: l,
      config: s,
      zIndex: d,
      index: a
    };
    return /* @__PURE__ */ n(
      C,
      {
        component: e.componentName,
        props: e.props,
        url: e.url,
        baseUrl: e.baseUrl,
        returnUrl: e.returnUrl,
        children: /* @__PURE__ */ n(v, { modal: e, onClose: l, children: () => t ? t(f) : /* @__PURE__ */ n(
          y,
          {
            ...f,
            backdropClassName: s.backdropClasses ? `${r} ${s.backdropClasses}` : r,
            wrapperClassName: i
          }
        ) })
      },
      e.id
    );
  }) });
};
export {
  O as ModalRenderer,
  O as default
};
