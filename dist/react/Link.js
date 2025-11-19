import { jsx as s } from "react/jsx-runtime";
import { Link as u } from "@inertiajs/react";
function n(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const o = t;
  return typeof o.url == "string" && typeof o.method == "string" && ["get", "post", "put", "patch", "delete", "head"].includes(o.method);
}
function p({ href: t, method: o, ...e }) {
  const i = n(t) ? t.url : t, r = n(t) && !o ? t.method : o;
  return /* @__PURE__ */ s(
    u,
    {
      href: i,
      method: r,
      ...e
    }
  );
}
export {
  p as Link,
  p as default
};
