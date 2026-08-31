import { ModalLink as e } from "./ModalLink.js";
import { Link as t } from "@inertiajs/react";
import { useEffect as n, useState as r } from "react";
import { jsx as i } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ClientModalLink.tsx
function a({ children: a, ...o }) {
	let [s, c] = r(!1);
	if (n(() => {
		c(!0);
	}, []), !s) {
		let { modalConfig: e, loadingComponent: n, returnUrl: r, ...s } = o;
		return /* @__PURE__ */ i(t, {
			...s,
			children: a
		});
	}
	return /* @__PURE__ */ i(e, {
		...o,
		children: a
	});
}
//#endregion
export { a as ClientModalLink, a as default };
