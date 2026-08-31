import { router as e, usePage as t } from "@inertiajs/react";
import { useCallback as n, useEffect as r, useMemo as i, useState as a } from "react";
//#region priv/nb_inertia/react/realtime/useRealtimeProps.ts
function o(o = {}) {
	let s = t().props, c = o.initialProps ?? s, [l, u] = a({}), d = i(() => JSON.stringify(c), [c]);
	r(() => {
		u({});
	}, [d]);
	let f = i(() => ({
		...c,
		...l
	}), [c, l]), p = i(() => Object.keys(l).length > 0, [l]);
	return {
		props: f,
		setProp: n((e, t) => {
			u((n) => {
				let r = {
					...c,
					...n
				}, i = typeof t == "function" ? t(r[e]) : t;
				return {
					...n,
					[e]: i
				};
			});
		}, [c]),
		setProps: n((e) => {
			u((t) => {
				let n = {
					...c,
					...t
				}, r = typeof e == "function" ? e(n) : e;
				return {
					...t,
					...r
				};
			});
		}, [c]),
		reload: n((t = {}) => {
			let { onSuccess: n, ...r } = t;
			e.reload({
				...r,
				onSuccess: (e) => {
					u({}), n?.(e);
				}
			});
		}, []),
		resetOptimistic: n(() => {
			u({});
		}, []),
		hasOptimisticUpdates: p
	};
}
//#endregion
export { o as default, o as useRealtimeProps };
