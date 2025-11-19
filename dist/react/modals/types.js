const s = {
  size: "md",
  position: "center",
  slideover: !1,
  closeButton: !0,
  closeExplicitly: !1,
  maxWidth: "",
  paddingClasses: "p-6",
  panelClasses: "bg-white rounded-lg shadow-xl",
  backdropClasses: "bg-black/50"
};
function l(e) {
  return {
    ...s,
    ...e
  };
}
export {
  s as DEFAULT_MODAL_CONFIG,
  l as mergeModalConfig
};
