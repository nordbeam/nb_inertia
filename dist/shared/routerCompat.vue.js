import { router as e } from "@inertiajs/vue3";
//#region priv/nb_inertia/shared/routerCompat.vue.ts
function t(t, n, r) {
	e.prefetch(t, n, r);
}
//#endregion
export { t as routerPrefetch };
