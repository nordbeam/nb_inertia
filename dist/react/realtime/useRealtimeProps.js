import { useState as d, useMemo as u, useEffect as g, useCallback as i } from "react";
import { usePage as y, router as b } from "@inertiajs/react";
function k() {
  const s = y().props, [r, n] = d({}), p = u(
    () => JSON.stringify(s),
    [s]
  );
  g(() => {
    n({});
  }, [p]);
  const f = u(
    () => ({ ...s, ...r }),
    [s, r]
  ), a = u(
    () => Object.keys(r).length > 0,
    [r]
  ), m = i(
    (t, o) => {
      n((e) => {
        const c = { ...s, ...e }, S = typeof o == "function" ? o(c[t]) : o;
        return { ...e, [t]: S };
      });
    },
    [s]
  ), l = i(
    (t) => {
      n((o) => {
        const e = { ...s, ...o }, c = typeof t == "function" ? t(e) : t;
        return { ...o, ...c };
      });
    },
    [s]
  ), O = i(
    (t = {}) => {
      const { onSuccess: o, ...e } = t;
      b.reload({
        ...e,
        onSuccess: (c) => {
          n({}), o?.(c);
        }
      });
    },
    []
  ), P = i(() => {
    n({});
  }, []);
  return {
    props: f,
    setProp: m,
    setProps: l,
    reload: O,
    resetOptimistic: P,
    hasOptimisticUpdates: a
  };
}
export {
  k as default,
  k as useRealtimeProps
};
