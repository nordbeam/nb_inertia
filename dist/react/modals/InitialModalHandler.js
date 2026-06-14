import { useModalStack as e } from "./modalStack.js";
import { useCallback as t, useEffect as n, useRef as r } from "react";
import { router as i, usePage as a } from "@inertiajs/react";
//#region priv/nb_inertia/react/modals/InitialModalHandler.tsx
function o({ resolveComponent: o }) {
	let { props: s } = a(), { pushModal: c, updateModal: l, clearModals: u, modals: d } = e(), f = r(!1), p = r(!1), m = r(null), h = r(/* @__PURE__ */ new Set()), g = t((e, t) => () => {
		if (m.current = null, h.current.delete(e.url), !f.current && typeof window < "u") {
			let n = t || e.baseUrl;
			n && window.location.href !== n && window.history.replaceState({}, "", n);
		}
	}, []), _ = t((e) => {
		let t = e.url, n = d.find((e) => e.loading && e.url === t), r = d.find((e) => !e.loading && e.url === t);
		h.current.has(t) && !n && !r || (h.current.add(t), o(e.component).then((i) => {
			if (n) {
				if (!d.find((e) => e.id === n.id && e.loading)) {
					h.current.delete(t);
					return;
				}
				let r = n.returnUrl;
				l(n.id, {
					component: i,
					componentName: e.component,
					props: e.props,
					config: e.config || {},
					baseUrl: e.baseUrl,
					returnUrl: r,
					onClose: g(e, r),
					loading: !1
				}), m.current = e;
			} else r ? (l(r.id, {
				component: i,
				componentName: e.component,
				props: e.props,
				config: e.config || {},
				baseUrl: e.baseUrl,
				onClose: r.onClose || g(e, r.returnUrl)
			}), m.current = e) : (m.current = e, c({
				component: i,
				componentName: e.component,
				props: e.props,
				url: e.url,
				config: e.config || {},
				baseUrl: e.baseUrl,
				onClose: g(e)
			}));
		}).catch((n) => {
			h.current.delete(t), console.error("[InitialModalHandler] Failed to resolve modal component:", e.component, n);
		}));
	}, [
		o,
		c,
		l,
		d,
		g
	]);
	return n(() => {
		let e = s._nb_modal;
		e && !p.current && (p.current = !0, _(e));
	}, []), n(() => {
		let e = i.on("start", () => {
			f.current = !0;
		}), t = i.on("finish", () => {
			f.current = !1;
		}), n = i.on("navigate", (e) => {
			let t = e.detail.page.props?._nb_modal;
			if (!t) {
				u(), m.current = null, h.current.clear();
				return;
			}
			_(t);
		});
		return () => {
			e(), t(), n();
		};
	}, [_, u]), null;
}
//#endregion
export { o as InitialModalHandler, o as default };
