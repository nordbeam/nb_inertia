import { useRef as m, useEffect as v, useState as S, useCallback as i } from "react";
import { Socket as h, Presence as g } from "phoenix";
import { Channel as E, Presence as M, Socket as O } from "phoenix";
function d(c, e = {}) {
  return new h(c, {
    params: e.params ?? (() => ({ _csrf_token: document.querySelector('meta[name="csrf-token"]')?.content })),
    logger: e.logger ?? ((r, s, u) => {
    }),
    reconnectAfterMs: e.reconnectAfterMs,
    heartbeatIntervalMs: e.heartbeatIntervalMs
  });
}
function j(c, e, n, r = {}) {
  const s = m(null), u = m(n), { enabled: f = !0 } = r;
  return u.current = n, v(() => {
    if (!c || !f || !e)
      return;
    c.connectionState() !== "open" && c.connect();
    const o = c.channel(e, r.params);
    return s.current = o, Object.keys(n).forEach((t) => {
      o.on(t, (l) => {
        u.current[t]?.(l);
      });
    }), o.join().receive("ok", (t) => {
      r.onJoin?.(t);
    }).receive("error", (t) => {
      console.error(`[channel] Failed to join ${e}:`, t), r.onError?.(t);
    }), o.onClose(() => {
      r.onClose?.();
    }), () => {
      o.leave(), s.current = null;
    };
  }, [c, e, f, JSON.stringify(r.params)]), s.current;
}
function k(c, e, n = {}) {
  const [r, s] = S({}), { enabled: u = !0 } = n;
  v(() => {
    if (!c || !u || !e)
      return;
    c.connectionState() !== "open" && c.connect();
    const a = c.channel(e, n.params), t = new g(a);
    return t.onSync(() => {
      s({ ...t.state }), n.onSync?.();
    }), n.onJoin && t.onJoin(n.onJoin), n.onLeave && t.onLeave(n.onLeave), a.join().receive("ok", (l) => {
    }).receive("error", (l) => {
      console.error(`[presence] Failed to join ${e}:`, l), n.onError?.(l);
    }), () => {
      a.leave();
    };
  }, [c, e, u, JSON.stringify(n.params)]);
  const f = i(() => Object.entries(r).map(([a, { metas: t }]) => ({ id: a, metas: t })), [r]), o = i(
    (a) => r[a]?.metas,
    [r]
  );
  return { presences: r, list: f, getByKey: o };
}
export {
  E as Channel,
  M as Presence,
  O as Socket,
  d as createSocket,
  j as useChannel,
  k as usePresence
};
