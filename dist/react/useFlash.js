import { usePage as a } from "@inertiajs/react";
import { useMemo as u, useCallback as e } from "react";
function f() {
  const t = a(), s = u(() => t.props?.flash ?? {}, [t.props?.flash]), o = e(
    (r) => s != null && r in s && !!s[r],
    [s]
  ), n = e(
    (r) => s?.[r],
    [s]
  );
  return { flash: s, has: o, get: n };
}
export {
  f as default,
  f as useFlash
};
