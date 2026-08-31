import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { mergeModalHeaders as n, registerModalRequestContext as r, unregisterModalRequestContext as i } from "./requestContext.js";
import { router as a } from "@inertiajs/react";
import o, { createContext as s, useCallback as c, useContext as l, useEffect as u, useRef as d, useState as f } from "react";
import { jsx as p } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/modalStack.tsx
var m = s(null);
m.displayName = "NbInertiaModalPageContext";
function h() {
	return l(m) !== null;
}
function g() {
	return l(m);
}
var _ = ({ component: e, props: t, url: n, baseUrl: a, returnUrl: s, pageMetadata: c, children: l }) => {
	let d = o.useRef(Symbol("nb-inertia-modal-request-context")), f = o.useMemo(() => ({
		component: e,
		props: t,
		url: n,
		baseUrl: a,
		returnUrl: s,
		version: c?.version === void 0 ? "1.0" : c.version,
		flash: c?.flash ?? {},
		scrollRegions: c?.scrollRegions ?? [],
		rememberedState: c?.rememberedState ?? {},
		clearHistory: c?.clearHistory ?? !1,
		encryptHistory: c?.encryptHistory ?? !1,
		preserveFragment: c?.preserveFragment ?? !1,
		deferredProps: c?.deferredProps,
		initialDeferredProps: c?.initialDeferredProps,
		rescuedProps: c?.rescuedProps ?? [],
		mergeProps: c?.mergeProps,
		prependProps: c?.prependProps,
		deepMergeProps: c?.deepMergeProps,
		matchPropsOn: c?.matchPropsOn,
		sharedProps: c?.sharedProps,
		scrollProps: c?.scrollProps,
		onceProps: c?.onceProps,
		optimisticUpdatedAt: c?.optimisticUpdatedAt
	}), [
		e,
		t,
		n,
		a,
		s,
		c
	]);
	return u(() => (r(d.current, {
		url: n,
		baseUrl: a,
		returnUrl: s
	}), () => {
		i(d.current);
	}), [
		n,
		a,
		s
	]), /* @__PURE__ */ p(m.Provider, {
		value: f,
		children: l
	});
}, v = s(null), y = () => {
	let e = l(v);
	if (!e) throw Error("useModalStack must be used within a ModalStackProvider");
	return e;
}, b = () => {
	let { modals: e } = y();
	return e.length > 0 ? e[e.length - 1] : null;
};
function x(e, n) {
	return {
		url: t(e) ? e.url : e,
		method: (t(e) && !n ? e.method : n) || "get"
	};
}
var S = 3e4;
function C(e) {
	if (Array.isArray(e) && e.length === 0) return 0;
	let t = Array.isArray(e) ? e[e.length - 1] : e;
	if (t === void 0) return S;
	if (typeof t == "number") return t;
	let n = String(t).trim().match(/^(-?\d+(?:\.\d+)?)(ms|s|m|h|d)$/i);
	return n ? Number(n[1]) * ({
		ms: 1,
		s: 1e3,
		m: 6e4,
		h: 36e5,
		d: 864e5
	}[n[2].toLowerCase()] ?? 1) : Number.parseInt(String(t), 10) || S;
}
var w = ({ children: t, onStackChange: r, resolveComponent: i }) => {
	let [o, s] = f([]), l = d(0), m = d(/* @__PURE__ */ new Map()), h = d(/* @__PURE__ */ new Map()), g = d(/* @__PURE__ */ new Set()), _ = d(/* @__PURE__ */ new Map()), y = c((e) => {
		let t = `modal-${l.current++}`, n = {
			...e,
			id: t
		}, i = !1;
		return s((t) => {
			if (t.find((t) => t.url === e.url)) return t;
			i = !0;
			let a = [...t, n];
			return r && r(a), a;
		}), i ? t : "";
	}, [r]), b = c((e) => {
		let t = { current: null };
		s((n) => {
			let i = n.find((t) => t.id === e);
			t.current = i?.onClose || null;
			let a = n.filter((t) => t.id !== e);
			return r && r(a), a;
		}), setTimeout(() => {
			if (t.current) try {
				t.current();
			} catch (e) {
				console.error("Error in modal onClose callback:", e);
			}
		}, 0);
	}, [r]), w = c((e) => {
		e?.fireOnClose ? s((e) => {
			let t = e.map((e) => e.onClose).filter((e) => typeof e == "function");
			return r && r([]), setTimeout(() => {
				t.forEach((e) => {
					try {
						e();
					} catch (e) {
						console.error("Error in modal onClose callback:", e);
					}
				});
			}, 0), [];
		}) : (s([]), r && r([]));
	}, [r]), T = c((e) => o.find((t) => t.id === e), [o]), E = c((e, t) => {
		s((n) => {
			let i = n.map((n) => n.id === e ? {
				...n,
				...t
			} : n);
			return r && r(i), i;
		});
	}, [r]), D = c((e) => {
		let t = m.current.get(e);
		if (!t) return;
		let n = t.cacheFor === void 0 ? S : C(t.cacheFor);
		if (n <= 0 || Date.now() - t.timestamp > n) {
			m.current.delete(e), _.current.delete(e);
			return;
		}
		if (t.visitOptions && a.getCached(e, t.visitOptions) === null) {
			m.current.delete(e), _.current.delete(e);
			return;
		}
		return t;
	}, []), O = c((e, t = {}) => {
		let { url: r, method: i } = x(e, t.method), { modalConfig: s, loadingComponent: c, returnUrl: l, ...u } = t;
		if (o.find((e) => e.url === r)) return;
		let d = l || (typeof window < "u" ? window.location.href : ""), f = i === "get" ? D(r) : void 0;
		if (f) {
			y({
				component: f.component,
				componentName: f.data.component,
				props: f.data.props,
				url: f.data.url,
				config: f.data.config || s || {},
				baseUrl: f.data.baseUrl,
				returnUrl: d,
				pageMetadata: f.data.pageMetadata,
				onClose: () => {
					d && typeof window < "u" && window.history.replaceState({}, "", d);
				}
			}), typeof window < "u" && window.history.pushState({}, "", f.data.url);
			return;
		}
		y({
			component: () => null,
			componentName: "",
			props: {},
			url: r,
			config: s || {},
			baseUrl: "",
			returnUrl: d,
			loading: !0,
			loadingComponent: c
		});
		let p = {
			...u,
			method: i,
			data: t.data ?? {},
			preserveState: t.preserveState ?? !0,
			preserveScroll: t.preserveScroll ?? !0,
			headers: t.headers
		};
		a.visit(r, n(p, {
			url: r,
			baseUrl: d,
			returnUrl: d
		}));
	}, [
		D,
		o,
		y
	]), k = c((t, n = {}) => {
		if (g.current.has(t) || m.current.has(t)) return;
		g.current.add(t);
		let { cacheFor: r, cacheTags: i, preserveState: a, ...o } = n, s = {
			...o,
			preserveState: a ?? !0
		}, c = () => g.current.delete(t), l = () => {
			c(), _.current.delete(t);
		}, u = s.onFinish, d = s.onCancel, f = s.onError, p = s.onHttpException, h = s.onNetworkError;
		s.onFinish = (e) => {
			c(), u?.(e);
		}, s.onCancel = () => {
			l(), d?.();
		}, s.onError = (e, t) => {
			l(), f?.(e, t);
		}, s.onHttpException = (e) => (l(), p?.(e)), s.onNetworkError = (e) => (l(), h?.(e)), _.current.set(t, {
			visitOptions: s,
			cacheFor: r,
			cacheTags: i
		});
		let v = {};
		r !== void 0 && (v.cacheFor = r), i !== void 0 && (v.cacheTags = i);
		try {
			e(t, s, Object.keys(v).length > 0 ? v : void 0);
		} catch (e) {
			throw l(), e;
		}
	}, []);
	u(() => {
		if (i) return a.on("prefetched", (e) => {
			let t = e.detail?.response, n = t && typeof t == "object" && "data" in t ? t.data : t, r = typeof n == "string" ? JSON.parse(n) : n, a = e.detail?.visit?.url, o = r?.url || a, s = [...g.current].filter((e) => {
				if (!o) return !1;
				try {
					return new URL(e, window.location.href).href === new URL(o, window.location.href).href;
				} catch {
					return e === String(o);
				}
			}), c = r?.props?._nb_modal;
			if (!c?.component) {
				s.forEach((e) => {
					g.current.delete(e), _.current.delete(e);
				});
				return;
			}
			let l = c.component, u = c.url || r?.url;
			if (!u) return;
			let d = _.current.get(u) || _.current.get(r?.url);
			if (g.current.delete(u), r?.url && r.url !== u && g.current.delete(r.url), s.forEach((e) => g.current.delete(e)), m.current.has(u)) return;
			let f = h.current.get(l);
			f ? m.current.set(u, {
				data: {
					component: l,
					props: c.props || {},
					url: u,
					baseUrl: c.baseUrl || "",
					config: c.config,
					pageMetadata: c.pageMetadata || r
				},
				component: f,
				timestamp: Date.now(),
				cacheFor: d?.cacheFor,
				cacheTags: d?.cacheTags,
				visitOptions: d?.visitOptions
			}) : i(l).then((e) => {
				h.current.set(l, e), m.current.set(u, {
					data: {
						component: l,
						props: c.props || {},
						url: u,
						baseUrl: c.baseUrl || "",
						config: c.config,
						pageMetadata: c.pageMetadata || r
					},
					component: e,
					timestamp: Date.now(),
					cacheFor: d?.cacheFor,
					cacheTags: d?.cacheTags,
					visitOptions: d?.visitOptions
				});
			}).catch((e) => {
				_.current.delete(u), console.warn("[ModalStack] Component preload failed:", l, e);
			});
		});
	}, [i]);
	let A = {
		modals: o,
		pushModal: y,
		popModal: b,
		clearModals: w,
		getModal: T,
		updateModal: E,
		visitModal: O,
		resolveComponent: i,
		prefetchModal: i ? k : void 0,
		getPrefetchedModal: D
	};
	return /* @__PURE__ */ p(v.Provider, {
		value: A,
		children: t
	});
};
//#endregion
export { _ as ModalPageProvider, w as ModalStackProvider, w as default, h as useIsInModal, b as useModal, g as useModalPageContext, y as useModalStack };
