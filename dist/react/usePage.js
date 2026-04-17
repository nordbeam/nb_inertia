import { usePage as r } from "@inertiajs/react";
import { useModalPageContext as o } from "./modals/modalStack.js";
function n() {
  const e = o();
  return e ? {
    component: e.component,
    props: e.props,
    url: e.url,
    version: e.version || null,
    flash: e.flash || {},
    scrollRegions: e.scrollRegions || [],
    rememberedState: e.rememberedState || {},
    clearHistory: e.clearHistory,
    encryptHistory: e.encryptHistory,
    preserveFragment: e.preserveFragment
  } : r();
}
export {
  n as default,
  n as usePage
};
