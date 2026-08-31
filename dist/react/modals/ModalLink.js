import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { useModalStack as n } from "./modalStack.js";
import { shouldIntercept as r } from "../node_modules/@inertiajs/core/dist/index.js";
import { useCallback as i, useEffect as a, useMemo as o, useRef as s } from "react";
import { jsx as c } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ModalLink.tsx
var l = () => null, u = ({ href: u, method: d, data: f, modalConfig: p, loadingComponent: m, onClick: h, prefetch: g, cacheFor: _, cacheTags: v, children: y, className: b, ...x }) => {
	let { modals: S, prefetchModal: C, visitModal: w } = n(), T = t(u) ? u.url : u, E = (t(u) && !d ? u.method : d) || "get", D = o(() => g ? g === !0 ? ["hover"] : typeof g == "string" ? [g] : g : [], [g]), O = i(() => {
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
	a(() => {
		if (D.includes("mount")) {
			let e = setTimeout(O, 0);
			return () => clearTimeout(e);
		}
	}, [D, O]);
	let k = s(null), A = i((e) => {
		x.onMouseEnter?.(e), D.includes("hover") && (k.current = setTimeout(O, 75));
	}, [
		D,
		O,
		x
	]), j = i((e) => {
		x.onMouseLeave?.(e), k.current &&= (clearTimeout(k.current), null);
	}, [x]), M = i((e) => {
		x.onMouseDown?.(e), D.includes("click") && r(e) && O();
	}, [
		D,
		O,
		x
	]), N = i((e) => {
		if (h?.(e), !r(e) || (e.preventDefault(), S.find((e) => e.url === T))) return;
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
	return /* @__PURE__ */ c("a", {
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
