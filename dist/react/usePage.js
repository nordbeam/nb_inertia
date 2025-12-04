import { usePage as r } from "@inertiajs/react";
import { useModalPageContext as o } from "./modals/modalStack.js";
function n() {
  const e = o();
  return e ? {
    component: e.component,
    props: e.props,
    url: e.url,
    version: e.version || null,
    scrollRegions: e.scrollRegions || [],
    rememberedState: e.rememberedState || {},
    clearHistory: e.clearHistory || !1,
    encryptHistory: e.encryptHistory || !1
  } : r();
}
export {
  n as default,
  n as usePage
};
