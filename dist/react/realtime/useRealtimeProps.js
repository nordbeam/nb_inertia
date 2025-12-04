import { useState as O, useMemo as u, useEffect as v, useCallback as n } from "react";
import { usePage as g, router as b } from "@inertiajs/react";
function j() {
  const { props: t } = g(), [o, r] = O({}), p = u(
    () => JSON.stringify(t),
    [t]
  );
  v(() => {
    r({});
  }, [p]);
  const l = u(
    () => ({ ...t, ...o }),
    [t, o]
  ), a = u(
    () => Object.keys(o).length > 0,
    [o]
  ), f = n(
    (e, s) => {
      r((c) => {
        const i = { ...t, ...c }, y = typeof s == "function" ? s(i[e]) : s;
        return { ...c, [e]: y };
      });
    },
    [t]
  ), m = n(
    (e) => {
      r((s) => {
        const c = { ...t, ...s }, i = typeof e == "function" ? e(c) : e;
        return { ...s, ...i };
      });
    },
    [t]
  ), S = n(
    (e = {}) => {
      b.reload({
        only: e.only,
        preserveScroll: e.preserveScroll ?? !0,
        preserveState: e.preserveState ?? !0,
        onSuccess: () => {
          r({});
        }
      });
    },
    []
  ), P = n(() => {
    r({});
  }, []);
  return {
    props: l,
    setProp: f,
    setProps: m,
    reload: S,
    resetOptimistic: P,
    hasOptimisticUpdates: a
  };
}
export {
  j as default,
  j as useRealtimeProps
};
