import { useCallback as e, useEffect as t, useMemo as n, useState as r } from "react";
import { router as i, usePage as a } from "@inertiajs/react";
//#region priv/nb_inertia/react/realtime/useRealtimeProps.ts
function o() {
	let o = a().props, [s, c] = r({});
	t(() => {
		c({});
	}, [n(() => JSON.stringify(o), [o])]);
	let l = n(() => ({
		...o,
		...s
	}), [o, s]), u = n(() => Object.keys(s).length > 0, [s]);
	return {
		props: l,
		setProp: e((e, t) => {
			c((n) => {
				let r = {
					...o,
					...n
				}, i = typeof t == "function" ? t(r[e]) : t;
				return {
					...n,
					[e]: i
				};
			});
		}, [o]),
		setProps: e((e) => {
			c((t) => {
				let n = {
					...o,
					...t
				}, r = typeof e == "function" ? e(n) : e;
				return {
					...t,
					...r
				};
			});
		}, [o]),
		reload: e((e = {}) => {
			let { onSuccess: t, ...n } = e;
			i.reload({
				...n,
				onSuccess: (e) => {
					c({}), t?.(e);
				}
			});
		}, []),
		resetOptimistic: e(() => {
			c({});
		}, []),
		hasOptimisticUpdates: u
	};
}
//#endregion
export { o as default, o as useRealtimeProps };
