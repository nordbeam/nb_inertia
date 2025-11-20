import { jsx as r } from "react/jsx-runtime";
import { Link as u } from "@inertiajs/react";
function n(t) {
  if (typeof t != "object" || t === null)
    return !1;
  const o = t;
  return typeof o.url == "string" && typeof o.method == "string" && ["get", "post", "put", "patch", "delete", "head", "options"].includes(o.method);
}
function l({ href: t, method: o, ...e }) {
  const i = n(t) ? t.url : t, s = n(t) && !o ? t.method : o;
  return /* @__PURE__ */ r(
    u,
    {
      href: i,
      method: s,
      ...e
    }
  );
}
export {
  l as Link,
  l as default
};
