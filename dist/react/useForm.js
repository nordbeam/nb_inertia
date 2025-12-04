import { useForm as u } from "@inertiajs/react";
import { isRouteResult as s } from "../shared/types.js";
function a(t, o) {
  const r = u(t);
  return !o || !s(o) ? {
    ...r,
    transform(m) {
      return r.transform(m);
    }
  } : {
    ...r,
    submit(n) {
      return r.submit(o.method, o.url, n);
    },
    transform(n) {
      return r.transform(n);
    }
  };
}
export {
  a as default,
  a as useForm
};
