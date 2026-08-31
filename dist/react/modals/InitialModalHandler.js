import { useModalStack as e } from "./modalStack.js";
import { router as t, usePage as n } from "@inertiajs/react";
import { useCallback as r, useEffect as i, useRef as a } from "react";
import { jsx as o } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/InitialModalHandler.tsx
function s({ resolveComponent: n, initialPage: o }) {
	let { pushModal: s, updateModal: c, clearModals: l, modals: u } = e(), d = a(!1), f = a(!1), p = a(null), m = a(/* @__PURE__ */ new Set()), h = r((e, t) => () => {
		if (p.current = null, m.current.delete(e.url), !d.current && typeof window < "u") {
			let n = t || e.baseUrl;
			n && window.location.href !== n && window.history.replaceState({}, "", n);
		}
	}, []), g = r((e, t) => {
		let r = t || e.pageMetadata, i = e.url, a = u.find((e) => e.loading && e.url === i), o = u.find((e) => !e.loading && e.url === i);
		m.current.has(i) && !a && !o || (m.current.add(i), n(e.component).then((t) => {
			if (a) {
				if (!u.find((e) => e.id === a.id && e.loading)) {
					m.current.delete(i);
					return;
				}
				let n = a.returnUrl;
				c(a.id, {
					component: t,
					componentName: e.component,
					props: e.props,
					config: e.config || {},
					baseUrl: e.baseUrl,
					returnUrl: n,
					pageMetadata: r,
					onClose: h(e, n),
					loading: !1
				}), p.current = e;
			} else o ? (c(o.id, {
				component: t,
				componentName: e.component,
				props: e.props,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: r,
				onClose: o.onClose || h(e, o.returnUrl)
			}), p.current = e) : (p.current = e, s({
				component: t,
				componentName: e.component,
				props: e.props,
				url: e.url,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: r,
				onClose: h(e)
			}));
		}).catch((t) => {
			m.current.delete(i), console.error("[InitialModalHandler] Failed to resolve modal component:", e.component, t);
		}));
	}, [
		n,
		s,
		c,
		u,
		h
	]);
	return i(() => {
		let e = o?.props?._nb_modal;
		e && !f.current && (f.current = !0, g(e, o));
	}, []), i(() => {
		let e = t.on("start", () => {
			d.current = !0;
		}), n = t.on("finish", () => {
			d.current = !1;
		}), r = t.on("navigate", (e) => {
			let t = e.detail.page.props?._nb_modal;
			if (!t) {
				l(), p.current = null, m.current.clear();
				return;
			}
			g(t, e.detail.page);
		});
		return () => {
			e(), n(), r();
		};
	}, [g, l]), null;
}
function c({ resolveComponent: e }) {
	let t = n();
	return /* @__PURE__ */ o(s, {
		resolveComponent: e,
		initialPage: t
	});
}
function l({ resolveComponent: e, initialPage: t }) {
	return t ? /* @__PURE__ */ o(s, {
		resolveComponent: e,
		initialPage: t
	}) : /* @__PURE__ */ o(c, { resolveComponent: e });
}
//#endregion
export { l as InitialModalHandler, l as default };
