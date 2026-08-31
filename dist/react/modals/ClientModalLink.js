import { ModalLink as e } from "./ModalLink.js";
import { useEffect as t, useState as n } from "react";
import { Link as r } from "@inertiajs/react";
import { jsx as i } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ClientModalLink.tsx
function a({ href: a, children: o, className: s, target: c, modalConfig: l, loadingComponent: u, prefetch: d, cacheFor: f, cacheTags: p }) {
	let [m, h] = n(!1);
	if (t(() => {
		h(!0);
	}, []), !m) {
		let e = typeof a == "string" ? a : a.url;
		return /* @__PURE__ */ i(r, {
			href: e,
			className: s,
			target: c,
			prefetch: d,
			cacheFor: f,
			children: o
		});
	}
	return /* @__PURE__ */ i(e, {
		href: a,
		className: s,
		target: c,
		modalConfig: l,
		loadingComponent: u,
		prefetch: d,
		cacheFor: f,
		cacheTags: p,
		children: o
	});
}
//#endregion
export { a as ClientModalLink, a as default };
