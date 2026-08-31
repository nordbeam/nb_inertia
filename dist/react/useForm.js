import { isRouteResult as e } from "../shared/types.js";
import { mergeModalHeaders as t } from "./modals/requestContext.js";
import { useModalPageContext as n } from "./modals/modalStack.js";
import { useForm as r } from "@inertiajs/react";
//#region priv/nb_inertia/react/useForm.tsx
function i(t) {
	return typeof t == "function" || e(t);
}
function a(e) {
	return Object.prototype.toString.call(e) === "[object Object]";
}
var o = /* @__PURE__ */ new Set([
	"submit",
	"get",
	"post",
	"put",
	"patch",
	"delete"
]), s = /* @__PURE__ */ new Set([
	"dontRemember",
	"optimistic",
	"withPrecognition",
	"withAllErrors",
	"withoutFileValidation",
	"setValidationTimeout",
	"touch",
	"validate",
	"validateFiles",
	"setErrors",
	"forgetError"
]);
function c(e) {
	return (typeof e == "object" && !!e || typeof e == "function") && typeof e.submit == "function";
}
function l(e) {
	return e ? {
		url: e.url,
		baseUrl: e.baseUrl,
		returnUrl: e.returnUrl
	} : null;
}
function u(n, r) {
	let i = a(n) && !e(n) ? n : void 0;
	return t(i, l(r));
}
function d(t, n, r) {
	if (r) {
		let i;
		return t.length >= 3 ? i = t[2] : t.length === 2 && e(t[0]) ? i = t[1] : t.length === 1 && (i = t[0]), [
			r.method,
			r.url,
			u(i, n)
		];
	}
	if (t.length === 0) return [u(void 0, n)];
	let i = [...t], o = i[i.length - 1];
	return a(o) && !e(o) ? i[i.length - 1] = u(o, n) : i.push(u(void 0, n)), i;
}
function f(e, t, n) {
	return !t && !n ? e : new Proxy(e, { get(e, r, i) {
		let a = Reflect.get(e, r, i);
		if (typeof a != "function") return a;
		let l = String(r);
		return s.has(l) ? (...r) => {
			let i = a.apply(e, r);
			return c(i) ? f(i, t, n) : i;
		} : o.has(l) ? (...r) => {
			let i = l === "submit" ? d(r, t, n) : d(r, t);
			return a.apply(e, i);
		} : (...t) => a.apply(e, t);
	} });
}
function p(...e) {
	let t = n();
	if (e.length === 0) return f(r(), t);
	if (e.length === 3) {
		let [n, i, a] = e;
		return f(r(n, i, a), t);
	}
	if (e.length === 2) {
		let [n, a] = e;
		if (typeof n == "string" && !i(a) || i(n)) return f(r(n, a), t);
		if (typeof n != "string" && i(a)) return f(r(a, n), t);
	}
	return f(r(e[0]), t);
}
function m(e, t, i) {
	let a = n(), o = r(t, e);
	return !i || i.url === t.url && i.method === t.method ? f(o, a) : f(o, a, i);
}
//#endregion
export { p as default, p as useForm, e as isRouteResult, m as useFormWithPrecognition };
