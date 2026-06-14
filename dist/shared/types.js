//#region priv/nb_inertia/shared/types.ts
function e(e) {
	if (typeof e != "object" || !e) return !1;
	let t = e;
	return typeof t.url == "string" && typeof t.method == "string" && [
		"get",
		"post",
		"put",
		"patch",
		"delete"
	].includes(t.method);
}
//#endregion
export { e as isRouteResult };
