import { jsx as u } from "react/jsx-runtime";
import { useState as d, useEffect as M } from "react";
import { Link as a } from "@inertiajs/react";
import { ModalLink as k } from "./ModalLink.js";
function y({
  href: t,
  children: o,
  className: n,
  modalConfig: s,
  loadingComponent: e,
  prefetch: r,
  cacheFor: i,
  cacheTags: f
}) {
  const [m, l] = d(!1);
  if (M(() => {
    l(!0);
  }, []), !m) {
    const p = typeof t == "string" ? t : t.url;
    return /* @__PURE__ */ u(
      a,
      {
        href: p,
        className: n,
        prefetch: r,
        cacheFor: i,
        children: o
      }
    );
  }
  return /* @__PURE__ */ u(
    k,
    {
      href: t,
      className: n,
      modalConfig: s,
      loadingComponent: e,
      prefetch: r,
      cacheFor: i,
      cacheTags: f,
      children: o
    }
  );
}
export {
  y as ClientModalLink,
  y as default
};
