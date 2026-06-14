import { getCurrentModalRequestContext as e, mergeModalHeaders as t } from "./modals/requestContext.js";
import { router as n } from "@inertiajs/react";
//#region priv/nb_inertia/react/router.ts
function r(n) {
	return t(n, e());
}
var i = {
	...n,
	visit(e, t) {
		return n.visit(e, r(t));
	},
	get(e, t, i) {
		return n.get(e, t, r(i));
	},
	post(e, t, i) {
		return n.post(e, t, r(i));
	},
	put(e, t, i) {
		return n.put(e, t, r(i));
	},
	patch(e, t, i) {
		return n.patch(e, t, r(i));
	},
	delete(e, t) {
		return n.delete(e, r(t));
	},
	reload(e) {
		return n.reload(r(e));
	}
};
//#endregion
export { i as default, i as router };
