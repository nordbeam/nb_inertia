import { useModalPageContext as e } from "./modalStack.js";
import { usePage as t } from "@inertiajs/react";
//#region priv/nb_inertia/react/modals/usePage.tsx
function n() {
	let n = e();
	return n ? {
		component: n.component,
		props: n.props,
		url: n.url,
		version: n.version || null,
		flash: n.flash || {},
		scrollRegions: n.scrollRegions || [],
		rememberedState: n.rememberedState || {},
		clearHistory: n.clearHistory,
		encryptHistory: n.encryptHistory,
		preserveFragment: n.preserveFragment
	} : t();
}
//#endregion
export { n as default, n as usePage };
