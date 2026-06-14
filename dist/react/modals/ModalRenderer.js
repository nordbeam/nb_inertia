import { ModalPageProvider as e, useModalStack as t } from "./modalStack.js";
import { CloseButton as n } from "./CloseButton.js";
import { mergeModalConfig as r } from "./types.js";
import { HeadlessModal as i } from "./HeadlessModal.js";
import "react";
import { Fragment as a, jsxDEV as o } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/modals/ModalRenderer.tsx
var s = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/modals/ModalRenderer.tsx", c = 50;
function l(e) {
	return c + e * 2;
}
function u({ modal: e, close: t, config: r, zIndex: i, backdropClassName: c, wrapperClassName: l }) {
	let u = e.component, d = r.closeButton !== !1, f = r.closeOnClickOutside !== !1;
	if (e.loading) {
		let u = e.loadingComponent;
		return /* @__PURE__ */ o(a, { children: [/* @__PURE__ */ o("div", {
			className: c,
			style: { zIndex: i },
			onClick: r.closeExplicitly || !f ? void 0 : t,
			"aria-hidden": "true"
		}, void 0, !1, {
			fileName: s,
			lineNumber: 105,
			columnNumber: 9
		}, this), /* @__PURE__ */ o("div", {
			className: l,
			style: { zIndex: i + 1 },
			children: /* @__PURE__ */ o("div", {
				className: "relative",
				children: [d && /* @__PURE__ */ o(n, { onClick: t }, void 0, !1, {
					fileName: s,
					lineNumber: 113,
					columnNumber: 33
				}, this), u ? /* @__PURE__ */ o(u, {}, void 0, !1, {
					fileName: s,
					lineNumber: 114,
					columnNumber: 33
				}, this) : null]
			}, void 0, !0, {
				fileName: s,
				lineNumber: 112,
				columnNumber: 11
			}, this)
		}, void 0, !1, {
			fileName: s,
			lineNumber: 111,
			columnNumber: 9
		}, this)] }, void 0, !0, {
			fileName: s,
			lineNumber: 104,
			columnNumber: 7
		}, this);
	}
	return /* @__PURE__ */ o(a, { children: [/* @__PURE__ */ o("div", {
		className: c,
		style: { zIndex: i },
		onClick: r.closeExplicitly || !f ? void 0 : t,
		"aria-hidden": "true"
	}, void 0, !1, {
		fileName: s,
		lineNumber: 123,
		columnNumber: 7
	}, this), /* @__PURE__ */ o("div", {
		className: l,
		style: { zIndex: i + 1 },
		role: "dialog",
		"aria-modal": "true",
		children: /* @__PURE__ */ o("div", {
			className: "relative",
			children: [d && /* @__PURE__ */ o(n, { onClick: t }, void 0, !1, {
				fileName: s,
				lineNumber: 136,
				columnNumber: 31
			}, this), /* @__PURE__ */ o(u, {
				...e.props,
				close: t
			}, void 0, !1, {
				fileName: s,
				lineNumber: 137,
				columnNumber: 11
			}, this)]
		}, void 0, !0, {
			fileName: s,
			lineNumber: 135,
			columnNumber: 9
		}, this)
	}, void 0, !1, {
		fileName: s,
		lineNumber: 129,
		columnNumber: 7
	}, this)] }, void 0, !0, {
		fileName: s,
		lineNumber: 122,
		columnNumber: 5
	}, this);
}
var d = ({ renderModal: n, backdropClassName: c = "fixed inset-0 bg-black/50", wrapperClassName: d = "fixed inset-0 flex items-center justify-center" }) => {
	let { modals: f, popModal: p } = t();
	return f.length === 0 ? null : /* @__PURE__ */ o(a, { children: f.map((t, a) => {
		let f = l(a), m = r(t.config), h = () => p(t.id), g = {
			modal: t,
			close: h,
			config: m,
			zIndex: f,
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
				onClose: h,
				children: () => n ? n(g) : /* @__PURE__ */ o(u, {
					...g,
					backdropClassName: m.backdropClasses ? `${c} ${m.backdropClasses}` : c,
					wrapperClassName: d
				}, void 0, !1, {
					fileName: s,
					lineNumber: 182,
					columnNumber: 19
				}, void 0)
			}, void 0, !1, {
				fileName: s,
				lineNumber: 177,
				columnNumber: 13
			}, void 0)
		}, t.id, !1, {
			fileName: s,
			lineNumber: 169,
			columnNumber: 11
		}, void 0);
	}) }, void 0, !1, {
		fileName: s,
		lineNumber: 154,
		columnNumber: 5
	}, void 0);
};
//#endregion
export { d as ModalRenderer, d as default };
