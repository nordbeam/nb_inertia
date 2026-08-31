import { mergeModalHeaders as e } from "./requestContext.js";
import { useModalStack as t } from "./modalStack.js";
import { mergeModalConfig as n } from "./types.js";
import { createContext as r, forwardRef as i, useCallback as a, useContext as o, useEffect as s, useImperativeHandle as c, useMemo as l, useRef as u } from "react";
import { router as d } from "@inertiajs/react";
import { Fragment as f, jsx as p } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/HeadlessModal.tsx
var m = r(null);
m.displayName = "NbInertiaCurrentModalContext";
function h() {
	let e = o(m);
	if (!e) throw Error("useCurrentModal must be used within a HeadlessModal");
	return e;
}
var g = i(function({ children: e }, t) {
	let n = h();
	return c(t, () => n, [n]), typeof e == "function" ? /* @__PURE__ */ p(f, { children: e(n) }) : /* @__PURE__ */ p(f, { children: e });
}), _ = i(function({ modal: r, onClose: i, isOpen: o = !0, children: f }, h) {
	let g = u(!1), _ = n(r.config), { modals: v, popModal: y } = t(), b = a(() => {
		g.current || (g.current = !0, i(), setTimeout(() => {
			g.current = !1;
		}, 0));
	}, [i]), x = a((t, n) => {
		d.visit(t.url, e({
			...n,
			preserveState: n?.preserveState ?? !0,
			preserveScroll: n?.preserveScroll ?? !0
		}, {
			url: t.url,
			baseUrl: t.returnUrl || t.baseUrl,
			returnUrl: t.returnUrl
		}));
	}, []), S = a((e) => {
		let t = v.findIndex((t) => t.id === e.id);
		return t === -1 ? null : {
			modal: e,
			id: e.id,
			index: t,
			onTopOfStack: t === v.length - 1,
			isOpen: e.id !== r.id || o,
			config: n(e.config),
			close: () => y(e.id),
			setOpen: (t) => {
				t || y(e.id);
			},
			reload: (t) => x(e, t),
			getParentModal: () => {
				let e = v[t - 1];
				return e ? S(e) : null;
			},
			getChildModal: () => {
				let e = v[t + 1];
				return e ? S(e) : null;
			}
		};
	}, [
		o,
		r.id,
		v,
		y,
		x
	]), C = l(() => S(r), [S, r]);
	return c(h, () => {
		if (!C) throw Error("Cannot create modal ref for a modal that is not in the stack");
		return C;
	}, [C]), s(() => {
		if (_.closeExplicitly) return;
		function e(e) {
			e.key === "Escape" && (e.preventDefault(), b());
		}
		return document.addEventListener("keydown", e), () => document.removeEventListener("keydown", e);
	}, [_.closeExplicitly, b]), C ? /* @__PURE__ */ p(m.Provider, {
		value: C,
		children: f(C)
	}) : null;
});
//#endregion
export { _ as HeadlessModal, _ as default, g as Modal, h as useCurrentModal };
