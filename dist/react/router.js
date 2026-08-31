import { getCurrentModalRequestContext as e, mergeModalHeaders as t } from "./modals/requestContext.js";
import { router as n } from "@inertiajs/react";
//#region priv/nb_inertia/react/router.ts
function r(n) {
	return t(n, e());
}
function i(e) {
	return typeof e == "function" ? () => r(e()) : r(e);
}
function a(e, t) {
	let n = [...e];
	return n[t] = r(n[t]), n;
}
var o = new Proxy(n, { get(e, t, n) {
	let r = Reflect.get(e, t, e);
	return typeof r == "function" ? (...o) => {
		let s = o;
		switch (t) {
			case "visit":
			case "reload":
				s = a(s, +(t === "visit"));
				break;
			case "get":
			case "post":
			case "put":
			case "patch":
				s = a(s, 2);
				break;
			case "delete":
				s = a(s, 1);
				break;
			case "poll":
				s = [...s], s[1] = i(s[1]);
				break;
			case "prefetch":
			case "getCached":
			case "flush":
			case "getPrefetching": s = a(s, 1);
		}
		let c = Reflect.apply(r, e, s);
		return c === e ? n : c;
	} : r;
} });
//#endregion
export { o as default, o as router };
