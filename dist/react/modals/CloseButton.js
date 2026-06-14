import "react";
import { jsx as e } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/CloseButton.tsx
var t = {
	"top-right": "absolute top-4 right-4",
	"top-left": "absolute top-4 left-4",
	custom: ""
}, n = {
	sm: "h-4 w-4",
	md: "h-6 w-6",
	lg: "h-8 w-8"
}, r = ({ onClick: r, position: i = "top-right", size: a = "md", colorClasses: o = "text-gray-400 hover:text-gray-600", ariaLabel: s = "Close", className: c = "" }) => /* @__PURE__ */ e("button", {
	type: "button",
	className: [
		t[i],
		o,
		"focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
		"rounded transition-colors",
		c
	].filter(Boolean).join(" "),
	"aria-label": s,
	onClick: r,
	children: /* @__PURE__ */ e("svg", {
		className: n[a],
		xmlns: "http://www.w3.org/2000/svg",
		fill: "none",
		viewBox: "0 0 24 24",
		stroke: "currentColor",
		"aria-hidden": "true",
		children: /* @__PURE__ */ e("path", {
			strokeLinecap: "round",
			strokeLinejoin: "round",
			strokeWidth: 2,
			d: "M6 18L18 6M6 6l12 12"
		})
	})
});
//#endregion
export { r as CloseButton, r as default };
