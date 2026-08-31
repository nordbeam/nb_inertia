import { useModalStack as e } from "./modalStack.js";
import { useCallback as t, useEffect as n, useRef as r } from "react";
import { router as i, usePage as a } from "@inertiajs/react";
import { jsx as o } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/InitialModalHandler.tsx
function s({ resolveComponent: a, initialPage: o }) {
	let { pushModal: s, updateModal: c, clearModals: l, modals: u } = e(), d = r(!1), f = r(!1), p = r(null), m = r(/* @__PURE__ */ new Set()), h = t((e, t) => () => {
		if (p.current = null, m.current.delete(e.url), !d.current && typeof window < "u") {
			let n = t || e.baseUrl;
			n && window.location.href !== n && window.history.replaceState({}, "", n);
		}
	}, []), g = t((e, t) => {
		let n = t || e.pageMetadata, r = e.url, i = u.find((e) => e.loading && e.url === r), o = u.find((e) => !e.loading && e.url === r);
		m.current.has(r) && !i && !o || (m.current.add(r), a(e.component).then((t) => {
			if (i) {
				if (!u.find((e) => e.id === i.id && e.loading)) {
					m.current.delete(r);
					return;
				}
				let a = i.returnUrl;
				c(i.id, {
					component: t,
					componentName: e.component,
					props: e.props,
					config: e.config || {},
					baseUrl: e.baseUrl,
					returnUrl: a,
					pageMetadata: n,
					onClose: h(e, a),
					loading: !1
				}), p.current = e;
			} else o ? (c(o.id, {
				component: t,
				componentName: e.component,
				props: e.props,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: n,
				onClose: o.onClose || h(e, o.returnUrl)
			}), p.current = e) : (p.current = e, s({
				component: t,
				componentName: e.component,
				props: e.props,
				url: e.url,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: n,
				onClose: h(e)
			}));
		}).catch((t) => {
			m.current.delete(r), console.error("[InitialModalHandler] Failed to resolve modal component:", e.component, t);
		}));
	}, [
		a,
		s,
		c,
		u,
		h
	]);
	return n(() => {
		let e = o?.props?._nb_modal;
		e && !f.current && (f.current = !0, g(e, o));
	}, []), n(() => {
		let e = i.on("start", () => {
			d.current = !0;
		}), t = i.on("finish", () => {
			d.current = !1;
		}), n = i.on("navigate", (e) => {
			let t = e.detail.page.props?._nb_modal;
			if (!t) {
				l(), p.current = null, m.current.clear();
				return;
			}
			g(t, e.detail.page);
		});
		return () => {
			e(), t(), n();
		};
	}, [g, l]), null;
}
function c({ resolveComponent: e }) {
	let t = a();
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
