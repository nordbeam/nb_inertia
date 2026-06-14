import { ModalLink as e } from "./ModalLink.js";
import { useEffect as t, useState as n } from "react";
import { Link as r } from "@inertiajs/react";
import { jsxDEV as i } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/modals/ClientModalLink.tsx
var a = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/modals/ClientModalLink.tsx";
function o({ href: o, children: s, className: c, modalConfig: l, loadingComponent: u, prefetch: d, cacheFor: f, cacheTags: p }) {
	let [m, h] = n(!1);
	return t(() => {
		h(!0);
	}, []), m ? /* @__PURE__ */ i(e, {
		href: o,
		className: c,
		modalConfig: l,
		loadingComponent: u,
		prefetch: d,
		cacheFor: f,
		cacheTags: p,
		children: s
	}, void 0, !1, {
		fileName: a,
		lineNumber: 130,
		columnNumber: 5
	}, this) : /* @__PURE__ */ i(r, {
		href: typeof o == "string" ? o : o.url,
		className: c,
		prefetch: d,
		cacheFor: f,
		children: s
	}, void 0, !1, {
		fileName: a,
		lineNumber: 117,
		columnNumber: 7
	}, this);
}
//#endregion
export { o as ClientModalLink, o as default };
