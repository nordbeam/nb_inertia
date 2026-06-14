import { routerPrefetch as e } from "../../shared/routerCompat.js";
import { isRouteResult as t } from "../../shared/types.js";
import { mergeModalHeaders as n, registerModalRequestContext as r, unregisterModalRequestContext as i } from "./requestContext.js";
import a, { createContext as o, useCallback as s, useContext as c, useEffect as l, useRef as u, useState as d } from "react";
import { router as f } from "@inertiajs/react";
import { jsx as p } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/modalStack.tsx
var m = o(null);
m.displayName = "NbInertiaModalPageContext";
function h() {
	return c(m) !== null;
}
function g() {
	return c(m);
}
var _ = ({ component: e, props: t, url: n, baseUrl: o, returnUrl: s, children: c }) => {
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
	]), /* @__PURE__ */ p(m.Provider, {
		value: d,
		children: c
	});
}, v = o(null), y = () => {
	let e = c(v);
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
var S = ({ children: t, onStackChange: r, resolveComponent: i }) => {
	let [a, o] = d([]), c = u(0), m = u(/* @__PURE__ */ new Map()), h = u(/* @__PURE__ */ new Map()), g = u(/* @__PURE__ */ new Set()), _ = s((e) => {
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
	}, [r]), y = s((e) => {
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
	}, [r]), b = s((e) => {
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
	}, [r]), S = s((e) => a.find((t) => t.id === e), [a]), C = s((e, t) => {
		o((n) => {
			let i = n.map((n) => n.id === e ? {
				...n,
				...t
			} : n);
			return r && r(i), i;
		});
	}, [r]), w = s((e) => {
		let t = m.current.get(e);
		if (t) {
			if (Date.now() - t.timestamp > 3e4) {
				m.current.delete(e);
				return;
			}
			return t;
		}
	}, []), T = s((e, t = {}) => {
		let { url: r, method: i } = x(e, t.method);
		if (a.find((e) => e.url === r)) return;
		let o = t.returnUrl || (typeof window < "u" ? window.location.href : ""), s = i === "get" ? w(r) : void 0;
		if (s) {
			_({
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
		_({
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
		w,
		a,
		_
	]), E = s((t, n) => {
		if (g.current.has(t) || m.current.has(t)) return;
		g.current.add(t);
		let r = {};
		n?.cacheFor !== void 0 && (r.cacheFor = n.cacheFor), e(t, { preserveState: !0 }, r), g.current.delete(t);
	}, []);
	l(() => {
		if (i) return f.on("prefetched", (e) => {
			let t = e.detail?.response, n = typeof t == "string" ? JSON.parse(t) : t, r = n?.props?._nb_modal;
			if (!r?.component) return;
			let a = r.component, o = r.url || n?.url;
			if (!o || m.current.has(o)) return;
			let s = h.current.get(a);
			s ? m.current.set(o, {
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
				h.current.set(a, e), m.current.set(o, {
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
	let D = {
		modals: a,
		pushModal: _,
		popModal: y,
		clearModals: b,
		getModal: S,
		updateModal: C,
		visitModal: T,
		resolveComponent: i,
		prefetchModal: i ? E : void 0,
		getPrefetchedModal: w
	};
	return /* @__PURE__ */ p(v.Provider, {
		value: D,
		children: t
	});
};
//#endregion
export { _ as ModalPageProvider, S as ModalStackProvider, S as default, h as useIsInModal, b as useModal, g as useModalPageContext, y as useModalStack };
