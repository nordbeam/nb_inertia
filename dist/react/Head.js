import { useIsInModal as e } from "./modals/modalStack.js";
import t, { Component as n, useEffect as r } from "react";
import { Head as i } from "@inertiajs/react";
import { jsx as a } from "react/jsx-runtime";
//#region priv/nb_inertia/react/Head.tsx
function o(e) {
	return t.Children.toArray(e).some((e) => t.isValidElement(e) ? e.type === t.Fragment ? o(e.props.children) : e.type === "title" : !1);
}
var s = {
	charSet: "charset",
	className: "class",
	crossOrigin: "crossorigin",
	httpEquiv: "http-equiv",
	itemProp: "itemprop",
	referrerPolicy: "referrerpolicy"
};
function c(e) {
	return t.Children.toArray(e).map((e) => typeof e == "string" || typeof e == "number" ? String(e) : t.isValidElement(e) ? c(e.props.children) : "").join("");
}
function l(e, n) {
	let r = [], i, a = (e) => {
		t.Children.forEach(e, (e) => {
			if (!t.isValidElement(e)) return;
			if (e.type === t.Fragment) {
				a(e.props.children);
				return;
			}
			if (typeof e.type != "string") return;
			let n = e.props;
			if (e.type === "title") {
				i = c(n.children);
				return;
			}
			let o = document.createElement(e.type), l = n["head-key"];
			o.setAttribute("data-nb-inertia-modal-head", typeof l == "string" || typeof l == "number" ? String(l) : ""), Object.entries(n).forEach(([e, t]) => {
				[
					"children",
					"dangerouslySetInnerHTML",
					"head-key"
				].includes(e) || t !== !1 && t != null && typeof t != "function" && o.setAttribute(s[e] ?? e, t === !0 ? "" : String(t));
			});
			let u = n.dangerouslySetInnerHTML;
			u?.__html === void 0 ? n.children !== void 0 && (o.textContent = c(n.children)) : o.innerHTML = u.__html, document.head.appendChild(o), r.push(o);
		});
	};
	a(e);
	let o = i || n;
	if (o) {
		let e = document.createElement("title");
		e.setAttribute("data-nb-inertia-modal-head", ""), e.textContent = o, document.head.insertBefore(e, document.head.querySelector("title")), r.push(e);
	}
	return r;
}
function u({ title: e, children: t }) {
	return r(() => {
		if (typeof document > "u") return;
		let n = l(t, o(t) ? void 0 : e);
		return () => {
			n.forEach((e) => {
				e.parentNode === document.head && document.head.removeChild(e);
			});
		};
	}, [t, e]), null;
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
}, f = (t) => e() ? /* @__PURE__ */ a(d, {
	fallback: /* @__PURE__ */ a(u, { ...t }),
	children: /* @__PURE__ */ a(i, { ...t })
}) : /* @__PURE__ */ a(i, { ...t });
//#endregion
export { f as Head, f as default };
