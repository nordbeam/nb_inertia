//#region priv/nb_inertia/shared/pageProps.ts
var e = class extends Error {
	constructor(e, t) {
		super(`Expected Inertia page ${e}, received ${t}`), this.name = "PagePropsComponentMismatchError", this.expected = e, this.actual = t;
	}
};
function t() {
	let e = globalThis.process;
	return e?.env?.NODE_ENV ? e.env.NODE_ENV !== "production" : import.meta.env?.DEV ?? !0;
}
function n(n, r = {}) {
	return function(i) {
		let a = n(), o = String(i);
		if ((r.development ?? t()) && a.component !== o) {
			let t = {
				expected: o,
				actual: a.component
			};
			throw r.onMismatch?.(t), new e(t.expected, t.actual);
		}
		return a.props;
	};
}
function r(e, t = {}) {
	return n(e, t);
}
//#endregion
export { e as PagePropsComponentMismatchError, n as createPagePropsHook, r as createUsePageProps };
