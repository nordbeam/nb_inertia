import { useCallback as e, useEffect as t, useMemo as n, useState as r } from "react";
import { router as i, usePage as a } from "@inertiajs/react";
//#region priv/nb_inertia/react/realtime/useRealtimeProps.ts
function o(o = {}) {
	let s = a().props, c = o.initialProps ?? s, [l, u] = r({}), d = n(() => JSON.stringify(c), [c]);
	t(() => {
		u({});
	}, [d]);
	let f = n(() => ({
		...c,
		...l
	}), [c, l]), p = n(() => Object.keys(l).length > 0, [l]);
	return {
		props: f,
		setProp: e((e, t) => {
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
		setProps: e((e) => {
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
		reload: e((e = {}) => {
			let { onSuccess: t, ...n } = e;
			i.reload({
				...n,
				onSuccess: (e) => {
					u({}), t?.(e);
				}
			});
		}, []),
		resetOptimistic: e(() => {
			u({});
		}, []),
		hasOptimisticUpdates: p
	};
}
//#endregion
export { o as default, o as useRealtimeProps };
