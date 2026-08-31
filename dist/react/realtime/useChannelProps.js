import { useChannel as e } from "./socket.js";
import t from "./useRealtimeProps.js";
import { useMemo as n } from "react";
//#region priv/nb_inertia/react/realtime/useChannelProps.ts
function r(r, i, a, o) {
	let s = t({ initialProps: o?.initialProps }), { props: c, setProp: l, setProps: u, reload: d } = s, f = n(() => {
		let e = {};
		for (let [t, n] of Object.entries(a)) {
			if (!n) continue;
			if (typeof n == "function") {
				e[t] = ((e) => {
					n(e, {
						props: c,
						setProp: l,
						setProps: u,
						reload: d
					});
				});
				continue;
			}
			let r = n, { prop: i, strategy: a } = r;
			e[t] = ((e) => {
				switch (a) {
					case "append":
						l(i, ((t) => [...t, r.transform(e)]));
						break;
					case "prepend":
						l(i, ((t) => [r.transform(e), ...t]));
						break;
					case "remove":
						l(i, ((t) => t.filter((t) => !r.match(t, e))));
						break;
					case "update":
						l(i, ((t) => {
							let n = r.transform(e), i = r.key;
							return t.map((e) => e[i] === n[i] ? n : e);
						}));
						break;
					case "upsert":
						l(i, ((t) => {
							let n = r.transform(e), i = r.key, a = t.findIndex((e) => e[i] === n[i]);
							return a >= 0 ? t.map((e, t) => t === a ? n : e) : [...t, n];
						}));
						break;
					case "replace":
						l(i, r.transform(e));
						break;
					case "reload": d({ only: r.only });
				}
			});
		}
		return e;
	}, [
		c,
		l,
		u,
		d
	]);
	return e(r, i, f, o), s;
}
//#endregion
export { r as default, r as useChannelProps };
