import { ModalPageProvider as e, useModalStack as t } from "./modalStack.js";
import { CloseButton as n } from "./CloseButton.js";
import { mergeModalConfig as r } from "./types.js";
import { HeadlessModal as i } from "./HeadlessModal.js";
import "react";
import { Fragment as a, jsx as o, jsxs as s } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/ModalRenderer.tsx
var c = 50;
function l(e) {
	return c + e * 2;
}
function u({ modal: e, close: t, config: r, zIndex: i, backdropClassName: c, wrapperClassName: l }) {
	let u = e.component, d = r.closeButton !== !1, f = r.closeOnClickOutside !== !1;
	if (e.loading) {
		let u = e.loadingComponent;
		return /* @__PURE__ */ s(a, { children: [/* @__PURE__ */ o("div", {
			className: c,
			style: { zIndex: i },
			onClick: r.closeExplicitly || !f ? void 0 : t,
			"aria-hidden": "true"
		}), /* @__PURE__ */ o("div", {
			className: l,
			style: { zIndex: i + 1 },
			children: /* @__PURE__ */ s("div", {
				className: "relative",
				children: [d && /* @__PURE__ */ o(n, { onClick: t }), u ? /* @__PURE__ */ o(u, {}) : null]
			})
		})] });
	}
	return /* @__PURE__ */ s(a, { children: [/* @__PURE__ */ o("div", {
		className: c,
		style: { zIndex: i },
		onClick: r.closeExplicitly || !f ? void 0 : t,
		"aria-hidden": "true"
	}), /* @__PURE__ */ o("div", {
		className: l,
		style: { zIndex: i + 1 },
		role: "dialog",
		"aria-modal": "true",
		children: /* @__PURE__ */ s("div", {
			className: "relative",
			children: [d && /* @__PURE__ */ o(n, { onClick: t }), /* @__PURE__ */ o(u, {
				...e.props,
				close: t
			})]
		})
	})] });
}
var d = ({ renderModal: n, backdropClassName: s = "fixed inset-0 bg-black/50", wrapperClassName: c = "fixed inset-0 flex items-center justify-center" }) => {
	let { modals: d, popModal: f } = t();
	return d.length === 0 ? null : /* @__PURE__ */ o(a, { children: d.map((t, a) => {
		let d = l(a), p = r(t.config), m = () => f(t.id), h = {
			modal: t,
			close: m,
			config: p,
			zIndex: d,
			index: a
		};
		return /* @__PURE__ */ o(e, {
			component: t.componentName,
			props: t.props,
			url: t.url,
			baseUrl: t.baseUrl,
			returnUrl: t.returnUrl,
			children: /* @__PURE__ */ o(i, {
				modal: t,
				onClose: m,
				children: () => n ? n(h) : /* @__PURE__ */ o(u, {
					...h,
					backdropClassName: p.backdropClasses ? `${s} ${p.backdropClasses}` : s,
					wrapperClassName: c
				})
			})
		}, t.id);
	}) });
};
//#endregion
export { d as ModalRenderer, d as default };
