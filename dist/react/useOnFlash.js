import { router as n } from "@inertiajs/react";
import { useRef as s, useEffect as f } from "react";
function i(e) {
  const r = s(e);
  r.current = e, f(() => n.on("flash", (t) => {
    const o = t.detail;
    r.current(o.flash);
  }), []);
}
export {
  i as default,
  i as useOnFlash
};
