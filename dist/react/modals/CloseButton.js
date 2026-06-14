import "react";
import { jsxDEV as e } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/modals/CloseButton.tsx
var t = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/modals/CloseButton.tsx", n = {
	"top-right": "absolute top-4 right-4",
	"top-left": "absolute top-4 left-4",
	custom: ""
}, r = {
	sm: "h-4 w-4",
	md: "h-6 w-6",
	lg: "h-8 w-8"
}, i = ({ onClick: i, position: a = "top-right", size: o = "md", colorClasses: s = "text-gray-400 hover:text-gray-600", ariaLabel: c = "Close", className: l = "" }) => /* @__PURE__ */ e("button", {
	type: "button",
	className: [
		n[a],
		s,
		"focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
		"rounded transition-colors",
		l
	].filter(Boolean).join(" "),
	"aria-label": c,
	onClick: i,
	children: /* @__PURE__ */ e("svg", {
		className: r[o],
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
		}, void 0, !1, {
			fileName: t,
			lineNumber: 70,
			columnNumber: 9
		}, void 0)
	}, void 0, !1, {
		fileName: t,
		lineNumber: 62,
		columnNumber: 7
	}, void 0)
}, void 0, !1, {
	fileName: t,
	lineNumber: 61,
	columnNumber: 5
}, void 0);
//#endregion
export { i as CloseButton, i as default };
