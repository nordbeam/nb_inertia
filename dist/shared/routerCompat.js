import { router as e } from "@inertiajs/react";
//#region priv/nb_inertia/shared/routerCompat.ts
function t(t, n, r) {
	e.prefetch(t, n, r);
}
//#endregion
export { t as routerPrefetch };
