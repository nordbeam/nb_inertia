import { useModalPageContext as e } from "./modals/modalStack.js";
import { usePage as t } from "@inertiajs/react";
//#region priv/nb_inertia/react/usePage.tsx
function n() {
	let n = e();
	return n ? {
		component: n.component,
		props: n.props,
		url: n.url,
		version: n.version ?? null,
		flash: n.flash || {},
		scrollRegions: n.scrollRegions || [],
		rememberedState: n.rememberedState || {},
		clearHistory: n.clearHistory,
		encryptHistory: n.encryptHistory,
		preserveFragment: n.preserveFragment,
		deferredProps: n.deferredProps,
		initialDeferredProps: n.initialDeferredProps,
		rescuedProps: n.rescuedProps ?? [],
		mergeProps: n.mergeProps,
		prependProps: n.prependProps,
		deepMergeProps: n.deepMergeProps,
		matchPropsOn: n.matchPropsOn,
		sharedProps: n.sharedProps,
		scrollProps: n.scrollProps,
		onceProps: n.onceProps,
		optimisticUpdatedAt: n.optimisticUpdatedAt
	} : t();
}
//#endregion
export { n as default, n as usePage };
