import { createInertiaApp as e, router as t } from "@inertiajs/react";
//#region priv/nb_inertia/react/createInertiaApp.ts
var n = "__NB_INERTIA_PAGE_SCHEMA_RUNTIME__";
function r() {
	try {
		return globalThis[n];
	} catch {
		return;
	}
}
function i(e) {
	if (e === !1 || !e || typeof e != "object") return !1;
	let t = e;
	return t.enabled !== !1 && t.mode !== "off" && t.policy !== "off" && t.registry != null;
}
function a(e) {
	if (!e) return i(r());
	let t = e.schemaRuntime ?? e.pageSchemaRuntime;
	return t === !1 || t && typeof t == "object" && (t.enabled === !1 || t.mode === "off" || t.policy === "off" || "registry" in t && t.registry == null) ? !1 : t && i(t) || e.pageSchemas != null ? !0 : i(r());
}
function o(e) {
	let { schemaRuntime: t, pageSchemaRuntime: n, pageSchemas: r, ...i } = e;
	return i;
}
function s(e) {
	try {
		e === void 0 ? delete globalThis[n] : globalThis[n] = e;
	} catch {}
	return e;
}
function c() {
	return r();
}
function l() {
	s(void 0);
}
async function u(n) {
	if (!n) return e();
	if (!a(n)) return e(o(n));
	let { createSchemaAwareInertiaApp: r } = await import("../shared/schemaRuntime.js");
	return r(e, n, t);
}
var d = u;
//#endregion
export { l as clearPageSchemaRuntimeConfig, s as configurePageSchemaRuntime, d as createInertiaApp, d as default, c as getPageSchemaRuntimeConfig };
