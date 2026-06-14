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
function o(e, n) {
	return n ? new Proxy(e, { get(e, r, i) {
		let o = Reflect.get(e, r, i);
		return typeof o != "function" || ![
			"submit",
			"get",
			"post",
			"put",
			"patch",
			"delete"
		].includes(String(r)) ? o : (...r) => {
			let i = [...r], s = i[i.length - 1], c = t(a(s) ? s : void 0, {
				url: n.url,
				baseUrl: n.baseUrl,
				returnUrl: n.returnUrl
			});
			return a(s) ? i[i.length - 1] = c : i.push(c), o.apply(e, i);
		};
	} }) : e;
}
function s(...e) {
	let t = n();
	if (e.length === 0) return o(r(), t);
	if (e.length === 3) {
		let [n, i, a] = e;
		return o(r(n, i, a), t);
	}
	if (e.length === 2) {
		let [n, a] = e;
		if (typeof n == "string" && !i(a) || i(n)) return o(r(n, a), t);
		if (typeof n != "string" && i(a)) return o(r(a, n), t);
	}
	return o(r(e[0]), t);
}
function c(e, t, i) {
	let a = n(), s = r(t, e);
	return !i || i.url === t.url && i.method === t.method ? o(s, a) : o(new Proxy(s, { get(e, t, n) {
		return t === "submit" ? (t) => e.submit(i.method, i.url, t) : Reflect.get(e, t, n);
	} }), a);
}
//#endregion
export { s as default, s as useForm, e as isRouteResult, c as useFormWithPrecognition };
