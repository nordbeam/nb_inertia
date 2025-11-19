import { jsx as i } from "react/jsx-runtime";
import S from "react";
import * as g from "@radix-ui/react-dialog";
const l = {
  sm: "max-w-sm",
  md: "max-w-md",
  lg: "max-w-lg",
  xl: "max-w-xl",
  "2xl": "max-w-2xl",
  full: "max-w-full"
}, s = {
  left: "inset-y-0 left-0",
  right: "inset-y-0 right-0",
  top: "inset-x-0 top-0",
  bottom: "inset-x-0 bottom-0"
}, o = {
  left: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-left
    data-[state=open]:slide-in-from-left
  `,
  right: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-right
    data-[state=open]:slide-in-from-right
  `,
  top: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-top
    data-[state=open]:slide-in-from-top
  `,
  bottom: `
    data-[state=open]:animate-in
    data-[state=closed]:animate-out
    data-[state=closed]:fade-out-0
    data-[state=open]:fade-in-0
    data-[state=closed]:slide-out-to-bottom
    data-[state=open]:slide-in-from-bottom
  `
};
function h(e) {
  const t = e?.size || "md";
  return typeof t == "string" && t in l ? l[t] : t;
}
function w(e) {
  const t = e?.position || "right";
  return typeof t == "string" && t in s ? s[t] : s.right;
}
function E(e) {
  const t = e?.position || "right";
  return typeof t == "string" && t in o ? o[t] : o.right;
}
function y(e) {
  const t = "bg-white shadow-xl";
  return e?.panelClasses ? `${t} ${e.panelClasses}` : t;
}
function v(e) {
  return e?.paddingClasses || "p-6";
}
function D(e) {
  return e === "left" || e === "right" || !e;
}
const I = S.forwardRef(
  ({ children: e, config: t, className: d, zIndex: r = 50, onClose: $, ...u }, m) => {
    const p = h(t), f = w(t), c = E(t), C = y(t), x = v(t), n = D(t?.position);
    return /* @__PURE__ */ i(
      g.Content,
      {
        ref: m,
        className: `
          fixed
          ${f}
          ${n ? "h-full" : "w-full"}
          ${n ? p : ""}
          ${C}
          transform
          transition-all
          duration-300
          ease-out
          ${c}
          overflow-y-auto
          ${d || ""}
        `,
        style: { zIndex: r },
        onEscapeKeyDown: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        onPointerDownOutside: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        onInteractOutside: t?.closeExplicitly ? (a) => a.preventDefault() : void 0,
        ...u,
        children: /* @__PURE__ */ i("div", { className: `min-h-full ${x}`, children: e })
      }
    );
  }
);
I.displayName = "SlideoverContent";
export {
  I as SlideoverContent,
  I as default
};
