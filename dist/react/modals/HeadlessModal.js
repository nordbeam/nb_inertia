import { mergeModalHeaders as e } from "./requestContext.js";
import { useModalStack as t } from "./modalStack.js";
import { mergeModalConfig as n } from "./types.js";
import { createContext as r, forwardRef as i, useCallback as a, useContext as o, useEffect as s, useImperativeHandle as c, useMemo as l, useRef as u } from "react";
import { router as d } from "@inertiajs/react";
import { Fragment as f, jsxDEV as p } from "react/jsx-dev-runtime";
//#region priv/nb_inertia/react/modals/HeadlessModal.tsx
var m = "/Users/assim/Projects/nb/nb_inertia/.cas/worktrees/task_c2aa559a3477a2d9/priv/nb_inertia/react/modals/HeadlessModal.tsx", h = r(null);
h.displayName = "NbInertiaCurrentModalContext";
function g() {
	let e = o(h);
	if (!e) throw Error("useCurrentModal must be used within a HeadlessModal");
	return e;
}
var _ = i(function({ children: e }, t) {
	let n = g();
	return c(t, () => n, [n]), typeof e == "function" ? /* @__PURE__ */ p(f, { children: e(n) }, void 0, !1, {
		fileName: m,
		lineNumber: 69,
		columnNumber: 12
	}, this) : /* @__PURE__ */ p(f, { children: e }, void 0, !1, {
		fileName: m,
		lineNumber: 72,
		columnNumber: 10
	}, this);
}), v = i(function({ modal: r, onClose: i, isOpen: o = !0, children: f }, g) {
	let _ = u(!1), v = n(r.config), { modals: y, popModal: b } = t(), x = a(() => {
		_.current || (_.current = !0, i(), setTimeout(() => {
			_.current = !1;
		}, 0));
	}, [i]);
	a((e) => {
		e || x();
	}, [x]);
	let S = a((t, n) => {
		d.visit(t.url, e({
			...n ?? {},
			preserveState: n?.preserveState ?? !0,
			preserveScroll: n?.preserveScroll ?? !0
		}, {
			url: t.url,
			baseUrl: t.returnUrl || t.baseUrl,
			returnUrl: t.returnUrl
		}));
	}, []), C = a((e) => {
		let t = y.findIndex((t) => t.id === e.id);
		return t === -1 ? null : {
			modal: e,
			id: e.id,
			index: t,
			onTopOfStack: t === y.length - 1,
			isOpen: e.id === r.id ? o : !0,
			config: n(e.config),
			close: () => b(e.id),
			setOpen: (t) => {
				t || b(e.id);
			},
			reload: (t) => S(e, t),
			getParentModal: () => {
				let e = y[t - 1];
				return e ? C(e) : null;
			},
			getChildModal: () => {
				let e = y[t + 1];
				return e ? C(e) : null;
			}
		};
	}, [
		o,
		r.id,
		y,
		b,
		S
	]), w = l(() => C(r), [C, r]);
	return c(g, () => {
		if (!w) throw Error("Cannot create modal ref for a modal that is not in the stack");
		return w;
	}, [w]), s(() => {
		if (v.closeExplicitly) return;
		function e(e) {
			e.key === "Escape" && (e.preventDefault(), x());
		}
		return document.addEventListener("keydown", e), () => document.removeEventListener("keydown", e);
	}, [v.closeExplicitly, x]), w ? /* @__PURE__ */ p(h.Provider, {
		value: w,
		children: f(w)
	}, void 0, !1, {
		fileName: m,
		lineNumber: 207,
		columnNumber: 5
	}, this) : null;
});
//#endregion
export { v as HeadlessModal, v as default, _ as Modal, g as useCurrentModal };
