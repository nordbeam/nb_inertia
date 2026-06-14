import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { mergeModalHeaders as n, registerModalRequestContext as r, unregisterModalRequestContext as i } from "./requestContext.js";
import a, { createContext as o, useCallback as s, useContext as c, useEffect as l, useRef as u, useState as d } from "react";
import { router as f } from "@inertiajs/react";
import { jsxDEV as p } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/modals/modalStack.tsx
var m = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/modals/modalStack.tsx", h = o(null);
h.displayName = "NbInertiaModalPageContext";
function g() {
	return c(h) !== null;
}
function _() {
	return c(h);
}
var v = ({ component: e, props: t, url: n, baseUrl: o, returnUrl: s, children: c }) => {
	let u = a.useRef(Symbol("nb-inertia-modal-request-context")), d = a.useMemo(() => ({
		component: e,
		props: t,
		url: n,
		baseUrl: o,
		returnUrl: s,
		version: "1.0",
		flash: {},
		scrollRegions: [],
		rememberedState: {},
		clearHistory: !1,
		encryptHistory: !1,
		preserveFragment: !1
	}), [
		e,
		t,
		n,
		o,
		s
	]);
	return l(() => (r(u.current, {
		url: n,
		baseUrl: o,
		returnUrl: s
	}), () => {
		i(u.current);
	}), [
		n,
		o,
		s
	]), /* @__PURE__ */ p(h.Provider, {
		value: d,
		children: c
	}, void 0, !1, {
		fileName: m,
		lineNumber: 149,
		columnNumber: 5
	}, void 0);
}, y = o(null), b = () => {
	let e = c(y);
	if (!e) throw Error("useModalStack must be used within a ModalStackProvider");
	return e;
}, x = () => {
	let { modals: e } = b();
	return e.length > 0 ? e[e.length - 1] : null;
};
function S(e, n) {
	return {
		url: t(e) ? e.url : e,
		method: (t(e) && !n ? e.method : n) || "get"
	};
}
var C = ({ children: t, onStackChange: r, resolveComponent: i }) => {
	let [a, o] = d([]), c = u(0), h = u(/* @__PURE__ */ new Map()), g = u(/* @__PURE__ */ new Map()), _ = u(/* @__PURE__ */ new Set()), v = s((e) => {
		let t = `modal-${c.current++}`, n = {
			...e,
			id: t
		}, i = !1;
		return o((t) => {
			if (t.find((t) => t.url === e.url)) return t;
			i = !0;
			let a = [...t, n];
			return r && r(a), a;
		}), i ? t : "";
	}, [r]), b = s((e) => {
		let t = { current: null };
		o((n) => {
			t.current = n.find((t) => t.id === e)?.onClose || null;
			let i = n.filter((t) => t.id !== e);
			return r && r(i), i;
		}), setTimeout(() => {
			if (t.current) try {
				t.current();
			} catch (e) {
				console.error("Error in modal onClose callback:", e);
			}
		}, 0);
	}, [r]), x = s((e) => {
		e?.fireOnClose ? o((e) => {
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
		}) : (o([]), r && r([]));
	}, [r]), C = s((e) => a.find((t) => t.id === e), [a]), w = s((e, t) => {
		o((n) => {
			let i = n.map((n) => n.id === e ? {
				...n,
				...t
			} : n);
			return r && r(i), i;
		});
	}, [r]), T = s((e) => {
		let t = h.current.get(e);
		if (t) {
			if (Date.now() - t.timestamp > 3e4) {
				h.current.delete(e);
				return;
			}
			return t;
		}
	}, []), E = s((e, t = {}) => {
		let { url: r, method: i } = S(e, t.method);
		if (a.find((e) => e.url === r)) return;
		let o = t.returnUrl || (typeof window < "u" ? window.location.href : ""), s = i === "get" ? T(r) : void 0;
		if (s) {
			v({
				component: s.component,
				componentName: s.data.component,
				props: s.data.props,
				url: s.data.url,
				config: s.data.config || t.modalConfig || {},
				baseUrl: s.data.baseUrl,
				returnUrl: o,
				onClose: () => {
					o && typeof window < "u" && window.history.replaceState({}, "", o);
				}
			}), typeof window < "u" && window.history.pushState({}, "", s.data.url);
			return;
		}
		v({
			component: () => null,
			componentName: "",
			props: {},
			url: r,
			config: t.modalConfig || {},
			baseUrl: "",
			returnUrl: o,
			loading: !0,
			loadingComponent: t.loadingComponent
		}), f.visit(r, {
			method: i,
			data: t.data ?? {},
			preserveState: t.preserveState ?? !0,
			preserveScroll: t.preserveScroll ?? !0,
			...n({ headers: t.headers }, {
				url: r,
				baseUrl: o,
				returnUrl: o
			})
		});
	}, [
		T,
		a,
		v
	]), D = s((t, n) => {
		if (_.current.has(t) || h.current.has(t)) return;
		_.current.add(t);
		let r = {};
		n?.cacheFor !== void 0 && (r.cacheFor = n.cacheFor), e(t, { preserveState: !0 }, r), _.current.delete(t);
	}, []);
	l(() => {
		if (i) return f.on("prefetched", (e) => {
			let t = e.detail?.response, n = typeof t == "string" ? JSON.parse(t) : t, r = n?.props?._nb_modal;
			if (!r?.component) return;
			let a = r.component, o = r.url || n?.url;
			if (!o || h.current.has(o)) return;
			let s = g.current.get(a);
			s ? h.current.set(o, {
				data: {
					component: a,
					props: r.props || {},
					url: o,
					baseUrl: r.baseUrl || "",
					config: r.config
				},
				component: s,
				timestamp: Date.now()
			}) : i(a).then((e) => {
				g.current.set(a, e), h.current.set(o, {
					data: {
						component: a,
						props: r.props || {},
						url: o,
						baseUrl: r.baseUrl || "",
						config: r.config
					},
					component: e,
					timestamp: Date.now()
				});
			}).catch((e) => {
				console.warn("[ModalStack] Component preload failed:", a, e);
			});
		});
	}, [i]);
	let O = {
		modals: a,
		pushModal: v,
		popModal: b,
		clearModals: x,
		getModal: C,
		updateModal: w,
		visitModal: E,
		resolveComponent: i,
		prefetchModal: i ? D : void 0,
		getPrefetchedModal: T
	};
	return /* @__PURE__ */ p(y.Provider, {
		value: O,
		children: t
	}, void 0, !1, {
		fileName: m,
		lineNumber: 671,
		columnNumber: 10
	}, void 0);
};
//#endregion
export { v as ModalPageProvider, C as ModalStackProvider, C as default, g as useIsInModal, x as useModal, _ as useModalPageContext, b as useModalStack };
