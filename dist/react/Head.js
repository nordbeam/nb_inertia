import { jsx as u } from "react/jsx-runtime";
import { useRef as o, useEffect as f } from "react";
import { Head as l } from "@inertiajs/react";
import { useIsInModal as i } from "./modals/modalStack.js";
const d = ({ title: r, children: n }) => {
  const t = i(), e = o(null);
  return f(() => {
    if (!(!t || !r))
      return e.current === null && (e.current = document.title), document.title = r, () => {
        e.current !== null && (document.title = e.current);
      };
  }, [t, r]), t ? null : /* @__PURE__ */ u(l, { title: r, children: n });
};
export {
  d as Head,
  d as default
};
