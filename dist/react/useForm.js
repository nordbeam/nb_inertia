import { useForm as m } from "@inertiajs/react";
import { isRouteResult as f } from "../shared/types.js";
function h(i, n) {
  const r = f(i), u = n !== void 0 && f(n);
  let e, t, s;
  r ? (s = i, t = i, e = n) : u ? (e = i, t = n) : e = i;
  let o;
  if (s ? o = m(
    s.method,
    s.url,
    e
  ) : o = m(e), !t)
    return o;
  const l = (b) => o.submit(t.method, t.url, b);
  return s ? {
    ...o,
    submit: l
  } : {
    ...o,
    submit: l
  };
}
function F(i, n, r) {
  const u = m(
    n.method,
    n.url,
    i
  );
  return r ? {
    ...u,
    submit: (t) => u.submit(r.method, r.url, t)
  } : u;
}
export {
  h as default,
  f as isRouteResult,
  h as useForm,
  F as useFormWithPrecognition
};
