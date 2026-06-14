import { useIsInModal as e } from "./modals/modalStack.js";
import { useEffect as t, useRef as n } from "react";
import { Head as r } from "@inertiajs/react";
import { jsxDEV as i } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/Head.tsx
var a = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/Head.tsx", o = ({ title: o, children: s }) => {
	let c = e(), l = n(null);
	return t(() => {
		if (!(!c || !o)) return l.current === null && (l.current = document.title), document.title = o, () => {
			l.current !== null && (document.title = l.current);
		};
	}, [c, o]), c ? null : /* @__PURE__ */ i(r, {
		title: o,
		children: s
	}, void 0, !1, {
		fileName: a,
		lineNumber: 80,
		columnNumber: 10
	}, void 0);
};
//#endregion
export { o as Head, o as default };
