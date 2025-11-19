import { jsx as n, jsxs as a } from "react/jsx-runtime";
import * as d from "@radix-ui/react-dialog";
import { HeadlessModal as b } from "./HeadlessModal.js";
import { ModalContent as I } from "./ModalContent.js";
import { SlideoverContent as c } from "./SlideoverContent.js";
import { CloseButton as x } from "./CloseButton.js";
function k(e) {
  const t = "fixed inset-0 bg-black/50";
  return e?.backdropClasses ? `${t} ${e.backdropClasses}` : t;
}
function l(e) {
  return 50 + e;
}
const Z = ({
  children: e,
  className: t,
  config: o = {},
  open: i = !0,
  onClose: p,
  ...f
}) => {
  const m = o.slideover || !1, u = o.closeButton !== !1;
  return /* @__PURE__ */ n(
    b,
    {
      ...f,
      config: o,
      open: i,
      onClose: p,
      children: (r, s) => /* @__PURE__ */ n(d.Root, { open: i, onOpenChange: (C) => !C && s(), children: /* @__PURE__ */ a(d.Portal, { children: [
        /* @__PURE__ */ n(
          d.Overlay,
          {
            className: k(o),
            style: { zIndex: l(r.index) }
          }
        ),
        m ? /* @__PURE__ */ a(
          c,
          {
            config: o,
            className: t,
            zIndex: l(r.index) + 1,
            children: [
              u && /* @__PURE__ */ n(x, { onClose: s }),
              typeof e == "function" ? e(s) : e
            ]
          }
        ) : /* @__PURE__ */ a(
          I,
          {
            config: o,
            className: t,
            zIndex: l(r.index) + 1,
            children: [
              u && /* @__PURE__ */ n(x, { onClose: s }),
              typeof e == "function" ? e(s) : e
            ]
          }
        )
      ] }) })
    }
  );
};
export {
  Z as Modal,
  Z as default
};
