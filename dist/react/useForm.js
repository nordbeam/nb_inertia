import { useForm as u } from "@inertiajs/react";
function s(r) {
  if (typeof r != "object" || r === null)
    return !1;
  const t = r;
  return typeof t.url == "string" && typeof t.method == "string" && ["get", "post", "put", "patch", "delete", "head"].includes(t.method);
}
function i(r, t) {
  const o = u(r);
  return !t || !s(t) ? {
    ...o,
    transform(e) {
      return o.transform(e);
    }
  } : {
    ...o,
    submit(n) {
      return o.submit(t.method, t.url, n);
    },
    transform(n) {
      return o.transform(n);
    }
  };
}
export {
  i as default,
  i as useForm
};
