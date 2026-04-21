import { router as e } from "@inertiajs/react";
import { mergeModalHeaders as n, getCurrentModalRequestContext as a } from "./modals/requestContext.js";
function u(r) {
  return n(r, a());
}
const p = {
  ...e,
  visit(r, t) {
    return e.visit(r, u(t));
  },
  get(r, t, o) {
    return e.get(r, t, u(o));
  },
  post(r, t, o) {
    return e.post(r, t, u(o));
  },
  put(r, t, o) {
    return e.put(r, t, u(o));
  },
  patch(r, t, o) {
    return e.patch(r, t, u(o));
  },
  delete(r, t) {
    return e.delete(r, u(t));
  },
  reload(r) {
    return e.reload(u(r));
  }
};
export {
  p as default,
  p as router
};
