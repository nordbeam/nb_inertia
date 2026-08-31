import { mergeModalHeaders as e } from "./requestContext.js";
import { useModalStack as t } from "./modalStack.js";
import { mergeModalConfig as n } from "./types.js";
import { router as r } from "@inertiajs/react";
import { createContext as i, forwardRef as a, useCallback as o, useContext as s, useEffect as c, useImperativeHandle as l, useMemo as u, useRef as d } from "react";
import { Fragment as f, jsx as p } from "react/jsx-runtime";
//#region priv/nb_inertia/react/modals/HeadlessModal.tsx
var m = i(null);
m.displayName = "NbInertiaCurrentModalContext";
function h() {
	let e = s(m);
	if (!e) throw Error("useCurrentModal must be used within a HeadlessModal");
	return e;
}
var g = a(function({ children: e }, t) {
	let n = h();
	return l(t, () => n, [n]), typeof e == "function" ? /* @__PURE__ */ p(f, { children: e(n) }) : /* @__PURE__ */ p(f, { children: e });
}), _ = a(function({ modal: i, onClose: a, isOpen: s = !0, children: f }, h) {
	let g = d(!1), _ = n(i.config), { modals: v, popModal: y } = t(), b = o(() => {
		g.current || (g.current = !0, a(), setTimeout(() => {
			g.current = !1;
		}, 0));
	}, [a]), x = o((t, n) => {
		r.visit(t.url, e({
			...n,
			preserveState: n?.preserveState ?? !0,
			preserveScroll: n?.preserveScroll ?? !0
		}, {
			url: t.url,
			baseUrl: t.returnUrl || t.baseUrl,
			returnUrl: t.returnUrl
		}));
	}, []), S = o((e) => {
		let t = v.findIndex((t) => t.id === e.id);
		return t === -1 ? null : {
			modal: e,
			id: e.id,
			index: t,
			onTopOfStack: t === v.length - 1,
			isOpen: e.id !== i.id || s,
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
		s,
		i.id,
		v,
		y,
		x
	]), C = u(() => S(i), [S, i]);
	return l(h, () => {
		if (!C) throw Error("Cannot create modal ref for a modal that is not in the stack");
		return C;
	}, [C]), c(() => {
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
