import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { useModalStack as n } from "./modalStack.js";
import { useCallback as r, useEffect as i, useMemo as a, useRef as o } from "react";
import { jsx as s } from "react/jsx-runtime";
import { shouldIntercept as c } from "@inertiajs/core";
//#region priv/nb_inertia/react/modals/ModalLink.tsx
var l = () => null, u = ({ href: u, method: d, data: f, modalConfig: p, loadingComponent: m, onClick: h, prefetch: g, cacheFor: _, cacheTags: v, children: y, className: b, ...x }) => {
	let { modals: S, prefetchModal: C, visitModal: w } = n(), T = t(u) ? u.url : u, E = (t(u) && !d ? u.method : d) || "get", D = a(() => g ? g === !0 ? ["hover"] : typeof g == "string" ? [g] : g : [], [g]), O = r(() => {
		if (E === "get") {
			if (C) C(T, { cacheFor: _ });
			else {
				let t = {};
				_ !== void 0 && (t.cacheFor = _), v !== void 0 && (t.cacheTags = v), e(T, { preserveState: !0 }, t);
			}
		}
	}, [
		T,
		E,
		_,
		v,
		C
	]);
	i(() => {
		if (D.includes("mount")) {
			let e = setTimeout(O, 0);
			return () => clearTimeout(e);
		}
	}, [D, O]);
	let k = o(null), A = r((e) => {
		x.onMouseEnter?.(e), D.includes("hover") && (k.current = setTimeout(O, 75));
	}, [
		D,
		O,
		x
	]), j = r((e) => {
		x.onMouseLeave?.(e), k.current &&= (clearTimeout(k.current), null);
	}, [x]), M = r((e) => {
		x.onMouseDown?.(e), D.includes("click") && c(e) && O();
	}, [
		D,
		O,
		x
	]), N = r((e) => {
		if (h?.(e), !c(e) || (e.preventDefault(), S.find((e) => e.url === T))) return;
		let t = typeof window < "u" ? window.location.href : "";
		w(u, {
			method: E,
			data: f ?? {},
			modalConfig: p,
			loadingComponent: m || l,
			returnUrl: t
		});
	}, [
		f,
		E,
		u,
		m,
		p,
		S,
		h,
		w
	]);
	return /* @__PURE__ */ s("a", {
		href: T,
		className: b,
		onClick: N,
		onMouseEnter: A,
		onMouseLeave: j,
		onMouseDown: M,
		...x,
		children: y
	});
};
//#endregion
export { u as ModalLink, u as default };
