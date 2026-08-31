import { useIsInModal as e } from "./modals/modalStack.js";
import { Head as t } from "@inertiajs/react";
import n, { Component as r, useEffect as i } from "react";
import { jsx as a } from "react/jsx-runtime";
//#region priv/nb_inertia/react/Head.tsx
function o(e) {
	return n.Children.toArray(e).some((e) => n.isValidElement(e) ? e.type === n.Fragment ? o(e.props.children) : e.type === "title" : !1);
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
	return n.Children.toArray(e).map((e) => typeof e == "string" || typeof e == "number" ? String(e) : n.isValidElement(e) ? c(e.props.children) : "").join("");
}
function l(e, t) {
	let r = [], i, a = (e) => {
		n.Children.forEach(e, (e) => {
			if (!n.isValidElement(e)) return;
			if (e.type === n.Fragment) {
				a(e.props.children);
				return;
			}
			if (typeof e.type != "string") return;
			let t = e.props;
			if (e.type === "title") {
				i = c(t.children);
				return;
			}
			let o = document.createElement(e.type), l = t["head-key"];
			o.setAttribute("data-nb-inertia-modal-head", typeof l == "string" || typeof l == "number" ? String(l) : ""), Object.entries(t).forEach(([e, t]) => {
				[
					"children",
					"dangerouslySetInnerHTML",
					"head-key"
				].includes(e) || t === !1 || t == null || typeof t != "string" && typeof t != "number" && typeof t != "boolean" || o.setAttribute(s[e] ?? e, t === !0 ? "" : String(t));
			});
			let u = t.dangerouslySetInnerHTML;
			u?.__html === void 0 ? t.children !== void 0 && (o.textContent = c(t.children)) : o.innerHTML = u.__html, document.head.appendChild(o), r.push(o);
		});
	};
	a(e);
	let o = i || t;
	if (o) {
		let e = document.createElement("title");
		e.setAttribute("data-nb-inertia-modal-head", ""), e.textContent = o, document.head.insertBefore(e, document.head.querySelector("title")), r.push(e);
	}
	return r;
}
function u({ title: e, children: t }) {
	return i(() => {
		if (typeof document > "u") return;
		let n = l(t, o(t) ? void 0 : e);
		return () => {
			n.forEach((e) => {
				e.parentNode === document.head && document.head.removeChild(e);
			});
		};
	}, [t, e]), null;
}
var d = class extends r {
	constructor(...e) {
		super(...e), this.state = { hasError: !1 };
	}
	static getDerivedStateFromError() {
		return { hasError: !0 };
	}
	render() {
		return this.state.hasError ? this.props.fallback : this.props.children;
	}
}, f = (n) => e() ? /* @__PURE__ */ a(d, {
	fallback: /* @__PURE__ */ a(u, { ...n }),
	children: /* @__PURE__ */ a(t, { ...n })
}) : /* @__PURE__ */ a(t, { ...n });
//#endregion
export { f as Head, f as default };
