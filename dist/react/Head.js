import { useIsInModal as e } from "./modals/modalStack.js";
import t, { Component as n, createElement as r, useMemo as i } from "react";
import { Head as a } from "@inertiajs/react";
import { createPortal as o } from "react-dom";
import { jsx as s } from "react/jsx-runtime";
//#region priv/nb_inertia/react/Head.tsx
function c(e) {
	return t.Children.toArray(e).some((e) => t.isValidElement(e) ? e.type === t.Fragment ? c(e.props.children) : e.type === "title" : !1);
}
function l(e) {
	let n = [];
	return t.Children.forEach(e, (e) => {
		if (!t.isValidElement(e)) {
			e && n.push(e);
			return;
		}
		if (e.type === t.Fragment) {
			n.push(...l(e.props.children));
			return;
		}
		let r = e.props["head-key"], i = typeof r == "string" || typeof r == "number" ? String(r) : "";
		n.push(t.cloneElement(e, { "data-nb-inertia-modal-head": i }));
	}), n;
}
function u({ title: e, children: t }) {
	let n = i(() => {
		let n = l(t);
		return e && !c(t) && n.push(r("title", { "data-nb-inertia-modal-head": "" }, e)), n;
	}, [t, e]);
	return typeof document > "u" ? null : o(n, document.head);
}
var d = class extends n {
	constructor(...e) {
		super(...e), this.state = { hasError: !1 };
	}
	static getDerivedStateFromError() {
		return { hasError: !0 };
	}
	render() {
		return this.state.hasError ? this.props.fallback : this.props.children;
	}
}, f = (t) => e() ? /* @__PURE__ */ s(d, {
	fallback: /* @__PURE__ */ s(u, { ...t }),
	children: /* @__PURE__ */ s(a, { ...t })
}) : /* @__PURE__ */ s(a, { ...t });
//#endregion
export { f as Head, f as default };
