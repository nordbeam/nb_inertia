import { jsx as f, Fragment as l } from "react/jsx-runtime";
import { useRef as u, useCallback as a, useEffect as d } from "react";
import { mergeModalConfig as m } from "./types.js";
function y({ modal: i, onClose: r, children: s }) {
  const e = u(!1), t = m(i.config), n = a(() => {
    e.current || (e.current = !0, r(), setTimeout(() => {
      e.current = !1;
    }, 0));
  }, [r]);
  return d(() => {
    if (t.closeExplicitly) return;
    function o(c) {
      c.key === "Escape" && (c.preventDefault(), n());
    }
    return document.addEventListener("keydown", o), () => document.removeEventListener("keydown", o);
  }, [t.closeExplicitly, n]), /* @__PURE__ */ f(l, { children: s({ close: n, config: t }) });
}
export {
  y as HeadlessModal,
  y as default
};
