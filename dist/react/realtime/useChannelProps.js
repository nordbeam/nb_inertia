import { useMemo as j } from "react";
import { useChannel as w } from "./socket.js";
import { useRealtimeProps as I } from "./useRealtimeProps.js";
function R(b, y, h, P) {
  const m = I(), { props: d, setProp: o, setProps: l, reload: f } = m, g = j(() => {
    const i = {};
    for (const [k, p] of Object.entries(h)) {
      if (!p) continue;
      if (typeof p == "function") {
        i[k] = ((t) => {
          p(t, {
            props: d,
            setProp: o,
            setProps: l,
            reload: f
          });
        });
        continue;
      }
      const r = p, { prop: n, strategy: x } = r;
      i[k] = ((t) => {
        switch (x) {
          case "append":
            o(n, ((e) => [
              ...e,
              r.transform(t)
            ]));
            break;
          case "prepend":
            o(n, ((e) => [
              r.transform(t),
              ...e
            ]));
            break;
          case "remove":
            o(n, ((e) => e.filter((s) => !r.match(s, t))));
            break;
          case "update":
            o(n, ((e) => {
              const s = r.transform(t), a = r.key;
              return e.map(
                (c) => c[a] === s[a] ? s : c
              );
            }));
            break;
          case "upsert":
            o(n, ((e) => {
              const s = r.transform(t), a = r.key, c = e.findIndex(
                (u) => u[a] === s[a]
              );
              return c >= 0 ? e.map((u, C) => C === c ? s : u) : [...e, s];
            }));
            break;
          case "replace":
            o(n, r.transform(t));
            break;
          case "reload":
            f({ only: r.only });
            break;
        }
      });
    }
    return i;
  }, [d, o, l, f]);
  return w(b, y, g, P), m;
}
export {
  R as default,
  R as useChannelProps
};
