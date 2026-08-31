//#region priv/nb_inertia/react/modals/requestContext.ts
var e = "__nb_inertia_modal_request_context_stack";
function t() {
	if (typeof window > "u") return [];
	let t = window[e];
	if (t) return t;
	let n = [];
	return window[e] = n, n;
}
function n(e, n) {
	if (typeof window > "u") return;
	let r = t(), i = r.findIndex((t) => t.id === e);
	i >= 0 ? r[i] = {
		id: e,
		context: n
	} : r.push({
		id: e,
		context: n
	});
}
function r(e) {
	if (typeof window > "u") return;
	let n = t(), r = n.findIndex((t) => t.id === e);
	r >= 0 && n.splice(r, 1);
}
function i() {
	let e = t();
	return e[e.length - 1]?.context ?? null;
}
function a(e) {
	if (e) return e.returnUrl || e.baseUrl || e.url;
}
function o(e, t) {
	let n = a(t);
	return n ? {
		...e,
		headers: {
			...e?.headers,
			"x-inertia-modal": "true",
			"x-inertia-modal-base-url": n
		}
	} : e;
}
//#endregion
export { i as getCurrentModalRequestContext, o as mergeModalHeaders, n as registerModalRequestContext, a as resolveModalBaseUrl, r as unregisterModalRequestContext };
