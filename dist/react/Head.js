import { useIsInModal as e } from "./modals/modalStack.js";
import { useEffect as t, useRef as n } from "react";
import { Head as r } from "@inertiajs/react";
import { jsx as i } from "react/jsx-runtime";
//#region priv/nb_inertia/react/Head.tsx
var a = ({ title: a, children: o }) => {
	let s = e(), c = n(null);
	return t(() => {
		if (!(!s || !a)) return c.current === null && (c.current = document.title), document.title = a, () => {
			c.current !== null && (document.title = c.current);
		};
	}, [s, a]), s ? null : /* @__PURE__ */ i(r, {
		title: a,
		children: o
	});
};
//#endregion
export { a as Head, a as default };
