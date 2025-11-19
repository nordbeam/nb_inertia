import { jsx as o } from "react/jsx-runtime";
import * as c from "@radix-ui/react-dialog";
const u = {
  "top-right": "absolute top-4 right-4",
  "top-left": "absolute top-4 left-4",
  custom: ""
}, d = {
  sm: "h-4 w-4",
  md: "h-6 w-6",
  lg: "h-8 w-8"
}, g = ({
  onClose: t,
  className: s,
  position: e = "top-right",
  size: r = "md",
  colorClasses: n = "text-gray-400 hover:text-gray-600",
  ariaLabel: i = "Close"
}) => {
  const l = u[e], a = d[r];
  return /* @__PURE__ */ o(c.Close, { asChild: !0, children: /* @__PURE__ */ o(
    "button",
    {
      type: "button",
      className: `
          ${l}
          ${n}
          focus:outline-none
          focus:ring-2
          focus:ring-offset-2
          focus:ring-indigo-500
          rounded
          transition-colors
          ${s || ""}
        `,
      onClick: t,
      "aria-label": i,
      children: /* @__PURE__ */ o(
        "svg",
        {
          className: a,
          xmlns: "http://www.w3.org/2000/svg",
          fill: "none",
          viewBox: "0 0 24 24",
          stroke: "currentColor",
          "aria-hidden": "true",
          children: /* @__PURE__ */ o(
            "path",
            {
              strokeLinecap: "round",
              strokeLinejoin: "round",
              strokeWidth: 2,
              d: "M6 18L18 6M6 6l12 12"
            }
          )
        }
      )
    }
  ) });
};
export {
  g as CloseButton,
  g as default
};
