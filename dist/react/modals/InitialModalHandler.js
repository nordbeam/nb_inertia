import { useModalStack as e } from "./modalStack.js";
import { useCallback as t, useEffect as n, useRef as r } from "react";
import { router as i, usePage as a } from "@inertiajs/react";
//#region priv/nb_inertia/react/modals/InitialModalHandler.tsx
function o({ resolveComponent: o }) {
	let s = a(), { props: c } = s, { pushModal: l, updateModal: u, clearModals: d, modals: f } = e(), p = r(!1), m = r(!1), h = r(null), g = r(/* @__PURE__ */ new Set()), _ = t((e, t) => () => {
		if (h.current = null, g.current.delete(e.url), !p.current && typeof window < "u") {
			let n = t || e.baseUrl;
			n && window.location.href !== n && window.history.replaceState({}, "", n);
		}
	}, []), v = t((e, t) => {
		let n = t || e.pageMetadata, r = e.url, i = f.find((e) => e.loading && e.url === r), a = f.find((e) => !e.loading && e.url === r);
		g.current.has(r) && !i && !a || (g.current.add(r), o(e.component).then((t) => {
			if (i) {
				if (!f.find((e) => e.id === i.id && e.loading)) {
					g.current.delete(r);
					return;
				}
				let a = i.returnUrl;
				u(i.id, {
					component: t,
					componentName: e.component,
					props: e.props,
					config: e.config || {},
					baseUrl: e.baseUrl,
					returnUrl: a,
					pageMetadata: n,
					onClose: _(e, a),
					loading: !1
				}), h.current = e;
			} else a ? (u(a.id, {
				component: t,
				componentName: e.component,
				props: e.props,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: n,
				onClose: a.onClose || _(e, a.returnUrl)
			}), h.current = e) : (h.current = e, l({
				component: t,
				componentName: e.component,
				props: e.props,
				url: e.url,
				config: e.config || {},
				baseUrl: e.baseUrl,
				pageMetadata: n,
				onClose: _(e)
			}));
		}).catch((t) => {
			g.current.delete(r), console.error("[InitialModalHandler] Failed to resolve modal component:", e.component, t);
		}));
	}, [
		o,
		l,
		u,
		f,
		_
	]);
	return n(() => {
		let e = c._nb_modal;
		e && !m.current && (m.current = !0, v(e, s));
	}, []), n(() => {
		let e = i.on("start", () => {
			p.current = !0;
		}), t = i.on("finish", () => {
			p.current = !1;
		}), n = i.on("navigate", (e) => {
			let t = e.detail.page.props?._nb_modal;
			if (!t) {
				d(), h.current = null, g.current.clear();
				return;
			}
			v(t, e.detail.page);
		});
		return () => {
			e(), t(), n();
		};
	}, [v, d]), null;
}
//#endregion
export { o as InitialModalHandler, o as default };
