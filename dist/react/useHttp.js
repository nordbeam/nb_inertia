import { isRouteResult as e } from "../shared/types.js";
import { useHttp as t } from "@inertiajs/react";
//#region priv/nb_inertia/react/useHttp.tsx
function n(t) {
	return typeof t == "function" || e(t);
}
function r(...e) {
	if (e.length === 0) return t();
	if (e.length === 3) {
		let [n, r, i] = e;
		return t(n, r, i);
	}
	if (e.length === 2) {
		let [r, i] = e;
		if (typeof r == "string" && !n(i) || n(r)) return t(r, i);
		if (typeof r != "string" && n(i)) return t(i, r);
	}
	return t(e[0]);
}
function i(e, n, r) {
	let i = t(n, e);
	return !r || r.url === n.url && r.method === n.method ? i : new Proxy(i, { get(e, t, n) {
		return t === "submit" ? (t) => e.submit(r.method, r.url, t) : Reflect.get(e, t, n);
	} });
}
//#endregion
export { r as default, r as useHttp, e as isRouteResult, i as useHttpWithPrecognition };
