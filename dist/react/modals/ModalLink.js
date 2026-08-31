import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { useModalStack as n } from "./modalStack.js";
import { useCallback as r, useEffect as i, useMemo as a, useRef as o } from "react";
import { jsx as s } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ModalLink.tsx
var c = () => null, l = ({ href: l, method: u, data: d, modalConfig: f, loadingComponent: p, onClick: m, prefetch: h, cacheFor: g, cacheTags: _, children: v, className: y, ...b }) => {
	let { modals: x, prefetchModal: S, visitModal: C } = n(), w = t(l) ? l.url : l, T = (t(l) && !u ? l.method : u) || "get", E = a(() => h ? h === !0 ? ["hover"] : typeof h == "string" ? [h] : h : [], [h]), D = r(() => {
		if (T === "get") {
			if (S) S(w, { cacheFor: g });
			else {
				let t = {};
				g !== void 0 && (t.cacheFor = g), _ !== void 0 && (t.cacheTags = _), e(w, { preserveState: !0 }, t);
			}
		}
	}, [
		w,
		T,
		g,
		_,
		S
	]);
	i(() => {
		if (E.includes("mount")) {
			let e = setTimeout(D, 0);
			return () => clearTimeout(e);
		}
	}, [E, D]);
	let O = o(null), k = r((e) => {
		b.onMouseEnter?.(e), E.includes("hover") && (O.current = setTimeout(D, 75));
	}, [
		E,
		D,
		b
	]), A = r((e) => {
		b.onMouseLeave?.(e), O.current &&= (clearTimeout(O.current), null);
	}, [b]), j = r((e) => {
		b.onMouseDown?.(e), E.includes("click") && D();
	}, [
		E,
		D,
		b
	]), M = r((e) => {
		if (e.ctrlKey || e.metaKey || e.shiftKey || (e.preventDefault(), m && m(e), x.find((e) => e.url === w))) return;
		let t = typeof window < "u" ? window.location.href : "";
		C(l, {
			method: T,
			data: d ?? {},
			modalConfig: f,
			loadingComponent: p || c,
			returnUrl: t
		});
	}, [
		d,
		T,
		l,
		p,
		f,
		x,
		m,
		C
	]);
	return /* @__PURE__ */ s("a", {
		href: w,
		className: y,
		onClick: M,
		onMouseEnter: k,
		onMouseLeave: A,
		onMouseDown: j,
		...b,
		children: v
	});
};
//#endregion
export { l as ModalLink, l as default };
