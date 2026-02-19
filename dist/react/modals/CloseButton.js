import { jsx as o } from "react/jsx-runtime";
const a = {
  "top-right": "absolute top-4 right-4",
  "top-left": "absolute top-4 left-4",
  custom: ""
}, u = {
  sm: "h-4 w-4",
  md: "h-6 w-6",
  lg: "h-8 w-8"
}, d = ({
  onClick: t,
  position: e = "top-right",
  size: r = "md",
  colorClasses: s = "text-gray-400 hover:text-gray-600",
  ariaLabel: n = "Close",
  className: i = ""
}) => {
  const l = [
    a[e],
    s,
    "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
    "rounded transition-colors",
    i
  ].filter(Boolean).join(" ");
  return /* @__PURE__ */ o("button", { type: "button", className: l, "aria-label": n, onClick: t, children: /* @__PURE__ */ o(
    "svg",
    {
      className: u[r],
      xmlns: "http://www.w3.org/2000/svg",
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor",
      "aria-hidden": "true",
      children: /* @__PURE__ */ o("path", { strokeLinecap: "round", strokeLinejoin: "round", strokeWidth: 2, d: "M6 18L18 6M6 6l12 12" })
    }
  ) });
};
export {
  d as CloseButton,
  d as default
};
