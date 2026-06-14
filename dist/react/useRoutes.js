import e from "./usePage.js";
import { useMemo as t } from "react";
//#region priv/nb_inertia/react/useRoutes.tsx
function n(e, t) {
	let n = (...n) => e(t, ...n);
	return Object.keys(e).forEach((r) => {
		let i = e[r];
		if (typeof i == "function") n[r] = (...e) => i(t, ...e);
		else if (typeof i == "object" && i) {
			let e = {};
			Object.keys(i).forEach((n) => {
				let r = i[n];
				typeof r == "function" ? e[n] = (...e) => r(t, ...e) : e[n] = r;
			}), n[r] = e;
		} else n[r] = i;
	}), Object.defineProperty(n, "name", {
		value: e.name,
		writable: !1
	}), n;
}
function r(r, i) {
	let { props: a } = e(), { scopeParam: o, getScopeValue: s, throwOnMissing: c = !0 } = i, l = s(a);
	if (l == null) {
		if (c) throw Error(`[useRoutes] Scope parameter "${o}" is not available in page props. Make sure the value returned by getScopeValue() is defined.`);
		return r;
	}
	return t(() => {
		let e = {};
		return Object.keys(r).forEach((t) => {
			let i = r[t];
			typeof i == "function" ? e[t] = n(i, l) : e[t] = i;
		}), e;
	}, [r, l]);
}
//#endregion
export { r as default, r as useRoutes };
