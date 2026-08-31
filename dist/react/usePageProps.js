import { PagePropsComponentMismatchError as e, createPagePropsHook as t } from "../shared/pageProps.js";
import { usePage as n } from "@inertiajs/react";
//#region priv/nb_inertia/react/usePageProps.ts
function r() {
	return n();
}
function i(e = {}) {
	return t(r, e);
}
var a = i();
function o(e) {
	return a(String(e));
}
//#endregion
export { e as PagePropsComponentMismatchError, i as createUsePageProps, o as default, o as usePageProps };
