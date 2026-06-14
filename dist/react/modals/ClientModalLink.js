import { ModalLink as e } from "./ModalLink.js";
import { useEffect as t, useState as n } from "react";
import { Link as r } from "@inertiajs/react";
import { jsx as i } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ClientModalLink.tsx
function a({ href: a, children: o, className: s, modalConfig: c, loadingComponent: l, prefetch: u, cacheFor: d, cacheTags: f }) {
	let [p, m] = n(!1);
	return t(() => {
		m(!0);
	}, []), p ? /* @__PURE__ */ i(e, {
		href: a,
		className: s,
		modalConfig: c,
		loadingComponent: l,
		prefetch: u,
		cacheFor: d,
		cacheTags: f,
		children: o
	}) : /* @__PURE__ */ i(r, {
		href: typeof a == "string" ? a : a.url,
		className: s,
		prefetch: u,
		cacheFor: d,
		children: o
	});
}
//#endregion
export { a as ClientModalLink, a as default };
