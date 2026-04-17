import { useMemo as o, useCallback as r } from "react";
import { usePage as u } from "./usePage.js";
function c() {
  const e = u(), s = o(() => e.flash ?? {}, [e.flash]), n = r(
    (t) => s != null && t in s && !!s[t],
    [s]
  ), a = r(
    (t) => s?.[t],
    [s]
  );
  return { flash: s, has: n, get: a };
}
export {
  c as default,
  c as useFlash
};
