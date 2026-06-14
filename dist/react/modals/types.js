//#region priv/nb_inertia/react/modals/types.ts
var e = {
	size: "md",
	position: "center",
	slideover: !1,
	closeButton: !0,
	closeExplicitly: !1,
	closeOnClickOutside: !0
};
function t(t) {
	return {
		...e,
		...t
	};
}
//#endregion
export { e as DEFAULT_MODAL_CONFIG, t as mergeModalConfig };
