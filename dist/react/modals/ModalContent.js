import { jsx as l } from "react/jsx-runtime";
import p from "react";
import * as c from "@radix-ui/react-dialog";
const o = {
  sm: "max-w-sm",
  md: "max-w-md",
  lg: "max-w-lg",
  xl: "max-w-xl",
  "2xl": "max-w-2xl",
  "3xl": "max-w-3xl",
  "4xl": "max-w-4xl",
  "5xl": "max-w-5xl",
  full: "max-w-full"
};
function f(e) {
  const t = e?.size || "md";
  return typeof t == "string" && t in o ? o[t] : t;
}
function w(e) {
  const t = "bg-white rounded-lg shadow-xl";
  return e?.panelClasses ? `${t} ${e.panelClasses}` : t;
}
function C(e) {
  return e?.paddingClasses || "p-6";
}
function y(e) {
  return e?.maxWidth;
}
const v = p.forwardRef(
  ({ children: e, config: t, className: n, zIndex: d = 50, onClose: g, ...i }, r) => {
    const m = f(t), x = w(t), u = C(t), s = y(t);
    return /* @__PURE__ */ l(
      c.Content,
      {
        ref: r,
        className: `
          fixed
          left-1/2
          top-1/2
          -translate-x-1/2
          -translate-y-1/2
          w-full
          ${m}
          ${x}
          transform
          transition-all
          duration-300
          ease-out
          data-[state=open]:animate-in
          data-[state=closed]:animate-out
          data-[state=closed]:fade-out-0
          data-[state=open]:fade-in-0
          data-[state=closed]:zoom-out-95
          data-[state=open]:zoom-in-95
          data-[state=closed]:slide-out-to-left-1/2
          data-[state=closed]:slide-out-to-top-[48%]
          data-[state=open]:slide-in-from-left-1/2
          data-[state=open]:slide-in-from-top-[48%]
          ${n || ""}
        `,
        style: { zIndex: d, ...s ? { maxWidth: s } : {} },
        onEscapeKeyDown: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        onPointerDownOutside: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        onInteractOutside: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        ...i,
        children: /* @__PURE__ */ l("div", { className: u, children: e })
      }
    );
  }
);
v.displayName = "ModalContent";
export {
  v as ModalContent,
  v as default
};
