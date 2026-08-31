import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { useModalStack as n } from "./modalStack.js";
import { useCallback as r, useEffect as ee, useMemo as i, useRef as te } from "react";
import { jsx as ne } from "react/jsx-runtime";
import { shouldIntercept as a } from "@inertiajs/core";
//#region priv/nb_inertia/react/modals/ModalLink.tsx
var re = () => null, o = ({ href: o, method: s, data: ie, modalConfig: ae, loadingComponent: oe, returnUrl: se, onClick: ce, prefetch: c, cacheFor: l, cacheTags: u, children: le, className: ue, component: d, replace: f, preserveScroll: p, preserveState: m, preserveUrl: h, only: g, except: _, headers: v, errorBag: y, forceFormData: b, queryStringArrayFormat: x, async: S, showProgress: C, fresh: w, reset: T, preserveErrors: E, invalidateCacheTags: D, viewTransition: O, optimistic: k, pageProps: A, onCancelToken: de, onBefore: j, onBeforeUpdate: M, onStart: N, onProgress: P, onFinish: F, onCancel: I, onSuccess: L, onError: R, onHttpException: z, onNetworkError: B, onFlash: V, onPrefetched: H, onPrefetching: U, ...W }) => {
	let { modals: G, prefetchModal: K, visitModal: q } = n(), J = t(o) ? o.url : o, Y = (t(o) && !s ? o.method : s) || "get", X = i(() => ({
		method: Y,
		data: ie,
		component: d,
		replace: f,
		preserveScroll: p,
		preserveState: m,
		preserveUrl: h,
		only: g,
		except: _,
		headers: v,
		errorBag: y,
		forceFormData: b,
		queryStringArrayFormat: x,
		async: S,
		showProgress: C,
		fresh: w,
		reset: T,
		preserveErrors: E,
		invalidateCacheTags: D,
		viewTransition: O,
		optimistic: k,
		pageProps: A,
		onCancelToken: de,
		onBefore: j,
		onBeforeUpdate: M,
		onStart: N,
		onProgress: P,
		onFinish: F,
		onCancel: I,
		onSuccess: L,
		onError: R,
		onHttpException: z,
		onNetworkError: B,
		onFlash: V,
		onPrefetched: H,
		onPrefetching: U
	}), [
		Y,
		ie,
		d,
		f,
		p,
		m,
		h,
		g,
		_,
		v,
		y,
		b,
		x,
		S,
		C,
		w,
		T,
		E,
		D,
		O,
		k,
		A,
		de,
		j,
		M,
		N,
		P,
		F,
		I,
		L,
		R,
		z,
		B,
		V,
		H,
		U
	]), Z = i(() => c ? c === !0 ? ["hover"] : typeof c == "string" ? [c] : c : [], [c]), Q = r(() => {
		if (Y !== "get") return;
		let t = {
			...X,
			method: "get"
		};
		if (K) K(J, {
			...t,
			cacheFor: l,
			cacheTags: u
		});
		else {
			let n = {};
			l !== void 0 && (n.cacheFor = l), u !== void 0 && (n.cacheTags = u), e(J, {
				...t,
				preserveState: m ?? !0
			}, Object.keys(n).length > 0 ? n : void 0);
		}
	}, [
		J,
		Y,
		l,
		u,
		K,
		m,
		X
	]);
	ee(() => {
		if (Z.includes("mount")) {
			let e = setTimeout(Q, 0);
			return () => clearTimeout(e);
		}
	}, [Z, Q]);
	let $ = te(null), fe = r((e) => {
		W.onMouseEnter?.(e), Z.includes("hover") && ($.current = setTimeout(Q, 75));
	}, [
		Z,
		Q,
		W
	]), pe = r((e) => {
		W.onMouseLeave?.(e), $.current &&= (clearTimeout($.current), null);
	}, [W]), me = r((e) => {
		W.onMouseDown?.(e), Z.includes("click") && a(e) && Q();
	}, [
		Z,
		Q,
		W
	]), he = r((e) => {
		if (ce?.(e), !a(e) || (e.preventDefault(), G.find((e) => e.url === J))) return;
		let t = se || (typeof window < "u" ? window.location.href : "");
		q(o, {
			...X,
			modalConfig: ae,
			loadingComponent: oe || re,
			returnUrl: t
		});
	}, [
		o,
		oe,
		ae,
		G,
		ce,
		se,
		q,
		X
	]);
	return /* @__PURE__ */ ne("a", {
		href: J,
		className: ue,
		onClick: he,
		onMouseEnter: fe,
		onMouseLeave: pe,
		onMouseDown: me,
		...W,
		children: le
	});
};
//#endregion
export { o as ModalLink, o as default };
