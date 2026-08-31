import e from "./usePage.js";
import { PagePropsComponentMismatchError as t, createPagePropsHook as n } from "../shared/pageProps.js";
//#region priv/nb_inertia/react/usePageProps.ts
function r() {
	return e();
}
function i(e = {}) {
	return n(r, e);
}
var a = i();
function o(e) {
	return a(String(e));
}
//#endregion
export { t as PagePropsComponentMismatchError, i as createUsePageProps, o as default, o as usePageProps };
