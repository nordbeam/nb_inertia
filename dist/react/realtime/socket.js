import { useCallback as e, useEffect as t, useRef as n, useState as r } from "react";
import { Channel as i, Presence as a, Socket as o } from "phoenix";
//#region priv/nb_inertia/react/realtime/socket.ts
function s(e, t = {}) {
	return new o(e, {
		params: t.params ?? (() => ({ _csrf_token: document.querySelector("meta[name=\"csrf-token\"]")?.content })),
		logger: t.logger ?? ((e, t, n) => {
			console.debug(`[socket:${e}]`, t, n);
		}),
		reconnectAfterMs: t.reconnectAfterMs,
		heartbeatIntervalMs: t.heartbeatIntervalMs
	});
}
function c(e, r, i, a = {}) {
	let o = n(null), s = n(i), { enabled: c = !0 } = a;
	return s.current = i, t(() => {
		if (!e || !c || !r) return;
		e.connectionState() !== "open" && e.connect();
		let t = e.channel(r, a.params);
		return o.current = t, Object.keys(i).forEach((e) => {
			t.on(e, (t) => {
				s.current[e]?.(t);
			});
		}), t.join().receive("ok", (e) => {
			console.debug(`[channel] Joined ${r}`), a.onJoin?.(e);
		}).receive("error", (e) => {
			console.error(`[channel] Failed to join ${r}:`, e), a.onError?.(e);
		}), t.onClose(() => {
			console.debug(`[channel] Left ${r}`), a.onClose?.();
		}), () => {
			t.leave(), o.current = null;
		};
	}, [
		e,
		r,
		c,
		JSON.stringify(a.params)
	]), o.current;
}
function l(n, i, o = {}) {
	let [s, c] = r({}), { enabled: l = !0 } = o;
	return t(() => {
		if (!n || !l || !i) return;
		n.connectionState() !== "open" && n.connect();
		let e = n.channel(i, o.params), t = new a(e);
		return t.onSync(() => {
			c({ ...t.state }), o.onSync?.();
		}), o.onJoin && t.onJoin(o.onJoin), o.onLeave && t.onLeave(o.onLeave), e.join().receive("ok", (e) => {
			console.debug(`[presence] Joined ${i}`);
		}).receive("error", (e) => {
			console.error(`[presence] Failed to join ${i}:`, e), o.onError?.(e);
		}), () => {
			e.leave();
		};
	}, [
		n,
		i,
		l,
		JSON.stringify(o.params)
	]), {
		presences: s,
		list: e(() => Object.entries(s).map(([e, { metas: t }]) => ({
			id: e,
			metas: t
		})), [s]),
		getByKey: e((e) => s[e]?.metas, [s])
	};
}
//#endregion
export { i as Channel, a as Presence, o as Socket, s as createSocket, c as useChannel, l as usePresence };
