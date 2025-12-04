const o = {
  size: "md",
  position: "center",
  slideover: !1,
  closeButton: !0,
  closeExplicitly: !1
};
function t(e) {
  return {
    ...o,
    ...e
  };
}
export {
  o as DEFAULT_MODAL_CONFIG,
  t as mergeModalConfig
};
