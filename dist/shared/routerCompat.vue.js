import { router as o } from "@inertiajs/vue3";
function u(e, t, f) {
  const r = o;
  return typeof r.prefetch == "function" ? (r.prefetch(e, t, f), !0) : !1;
}
export {
  u as routerPrefetch
};
