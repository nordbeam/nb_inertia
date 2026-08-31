//#region priv/nb_inertia/shared/schemaRuntime.ts
var e = class extends Error {
	constructor(e) {
		let t = e.prop ? `${e.component}.${e.prop}` : e.component, n = e.kind === "validation" ? "failed validation" : "failed decoding/transform";
		super(`Inertia page ${t} ${n}`), this.name = "PageSchemaRuntimeError", this.failure = e;
	}
}, t = Symbol.for("nb_inertia.page_schema_runtime"), n = "__NB_INERTIA_PAGE_SCHEMA_RUNTIME__";
function r() {
	return globalThis[n];
}
var i = r(), a = /* @__PURE__ */ new WeakMap();
function o(e) {
	i = e;
	try {
		e === void 0 ? delete globalThis[n] : globalThis[n] = e;
	} catch {}
	return i;
}
function s() {
	return r() ?? i;
}
function c() {
	i = void 0;
	try {
		delete globalThis[n];
	} catch {}
}
function l(e) {
	return { get(t) {
		return e[t];
	} };
}
function u(t) {
	return t instanceof e;
}
function d(e) {
	return typeof e == "object" && !!e || typeof e == "function";
}
function f(e) {
	return typeof e == "object" && !!e && !Array.isArray(e);
}
function p(e, t) {
	return Object.prototype.hasOwnProperty.call(e, t);
}
function m() {
	return globalThis.process?.env?.NODE_ENV === "production";
}
function h() {
	return m() ? "off" : "throw";
}
function g(e, t) {
	let n = r() ?? i;
	if (e === !1) return {
		enabled: !1,
		mode: "off"
	};
	let a = e || (n === !1 ? void 0 : n) || {}, o = e && e.registry !== void 0 ? e.registry : t ?? a.registry;
	return {
		...a,
		registry: o,
		mode: a.mode || a.policy || h(),
		enabled: a.enabled !== !1
	};
}
function _(e, t, n) {
	if (!e) return;
	if (n.has(t)) return n.get(t) || void 0;
	let r;
	try {
		typeof e == "function" ? r = e(t) : typeof e.get == "function" ? r = e.get(t) : typeof e.lookup == "function" ? r = e.lookup(t) : typeof e.getPageSchema == "function" ? r = e.getPageSchema(t) : f(e.pages) ? r = e.pages[t] : f(e) && (r = e[t]);
	} catch {
		r = void 0;
	}
	return n.set(t, r || null), r;
}
function v(e) {
	if (typeof e == "function") return { parse: e };
	if (!d(e)) return;
	let t = a.get(e);
	if (t) return t;
	let n = e, r = n.schema;
	if (r !== void 0 && !S(n) && !y(n)) {
		let t = v(r);
		if (!t) return;
		if (n.transforms === !0 || n.decodeEnabled === !0 || n.isTransform === !0) {
			let n = {
				...t,
				transforms: !0
			};
			return a.set(e, n), n;
		}
		return a.set(e, t), t;
	}
	return a.set(e, n), n;
}
function y(e) {
	let t = e;
	for (let e of [
		"fields",
		"props",
		"shape",
		"propertySchemas",
		"properties"
	]) {
		if (!p(t, e)) continue;
		let n = t[e];
		if (f(n)) return n;
	}
}
function b(e) {
	let t = d(e) && ("_def" in e || "def" in e) && (typeof e.safeParse == "function" || typeof e.parse == "function");
	return e.transforms === !0 || e.decodeEnabled === !0 || e.isTransform === !0 || typeof e.transform == "function" && !t || x(e) || typeof e.decode == "function" && !t;
}
function x(e, t = /* @__PURE__ */ new Set(), n = 0) {
	if (!d(e) || n > 12 || t.has(e)) return !1;
	t.add(e);
	let r = e;
	if (r.__nb_inertia_transform__ === !0 || r.__nb_transform__ === !0) return !0;
	let i = r._def ?? r.def;
	if (!d(i)) return Object.values(r).some((e) => x(e, t, n + 1));
	let a = i.type;
	if (a === "transform" || a === "codec" || a === "preprocess") return !0;
	if (a === "pipe" && d(i.in) && d(i.out)) return x(i.in, t, n + 1) || x(i.out, t, n + 1) || typeof i.transform == "function" || typeof i.reverseTransform == "function" || typeof i.decode == "function" || typeof i.encode == "function";
	if (i.coerce === !0) return !0;
	for (let e of [
		"in",
		"out",
		"innerType",
		"schema",
		"element",
		"items",
		"left",
		"right",
		"valueType",
		"keyType",
		"options"
	]) {
		let r = i[e];
		if (Array.isArray(r)) {
			if (r.some((e) => x(e, t, n + 1))) return !0;
		} else if (x(r, t, n + 1)) return !0;
	}
	let o = i.shape;
	if (typeof o == "function") try {
		return x(o(), t, n + 1);
	} catch {
		return !1;
	}
	return x(o, t, n + 1);
}
function S(e) {
	return typeof e.safeParse == "function" || typeof e.parse == "function" || typeof e.decode == "function" || typeof e.transform == "function" || typeof e.validate == "function" || typeof e.type == "string" || Array.isArray(e.type) || Array.isArray(e.enum) || f(e.properties) || !!e.items;
}
function C(e) {
	if (e == null || e === !0) return { ok: !0 };
	if (e === !1) return { ok: !1 };
	if (f(e)) {
		if (e.success === !1 || e.valid === !1 || e.ok === !1) {
			let t = e.error;
			return {
				ok: !1,
				error: t,
				issues: e.issues || e.errors || (f(t) ? t.issues : void 0)
			};
		}
		if (e.success === !0 || e.valid === !0 || e.ok === !0) return { ok: !0 };
		if ("error" in e && e.error !== void 0 && e.error !== null) return {
			ok: !1,
			error: e.error,
			issues: e.issues || e.errors || (f(e.error) ? e.error.issues : void 0)
		};
		if (Array.isArray(e.issues) && e.issues.length > 0) return {
			ok: !1,
			issues: e.issues
		};
		if (Array.isArray(e.errors) && e.errors.length > 0) return {
			ok: !1,
			issues: e.errors
		};
	}
	return Array.isArray(e) && e.length > 0 ? {
		ok: !1,
		issues: e
	} : { ok: !0 };
}
function w(e) {
	if (!f(e)) return {
		ok: !0,
		value: e
	};
	if (e.success === !1 || e.ok === !1) {
		let t = e.error;
		return {
			ok: !1,
			error: t,
			issues: e.issues || e.errors || (f(t) ? t.issues : void 0)
		};
	}
	return e.success === !0 ? {
		ok: !0,
		value: "data" in e ? e.data : e.value
	} : e.ok === !0 ? {
		ok: !0,
		value: "value" in e ? e.value : e.data
	} : "error" in e && e.error !== void 0 && e.error !== null ? {
		ok: !1,
		error: e.error,
		issues: e.issues || e.errors || (f(e.error) ? e.error.issues : void 0)
	} : {
		ok: !0,
		value: e
	};
}
function T(e, t, n) {
	return d(t) ? e.objectCache.get(t)?.get(n) : e.primitiveCache.get(t)?.get(n);
}
function E(e, t, n, r) {
	if (d(t)) {
		let i = e.objectCache.get(t);
		i || (i = /* @__PURE__ */ new WeakMap(), e.objectCache.set(t, i)), i.set(n, r);
		return;
	}
	let i = e.primitiveCache.get(t);
	i || (i = /* @__PURE__ */ new WeakMap(), e.primitiveCache.set(t, i)), i.set(n, r);
}
function D(e, t, n) {
	let r = [];
	if (Array.isArray(t.enum) && !t.enum.some((t) => Object.is(t, e))) return r.push({
		path: n,
		message: "must be one of the declared enum values"
	}), r;
	if (t.type) {
		let i = Array.isArray(t.type) ? t.type : [t.type];
		if (!i.some((t) => {
			switch (t) {
				case "null": return e === null;
				case "array": return Array.isArray(e);
				case "object": return f(e);
				case "integer": return typeof e == "number" && Number.isInteger(e);
				case "number": return typeof e == "number" && Number.isFinite(e);
				case "boolean": return typeof e == "boolean";
				case "string": return typeof e == "string";
				default: return !0;
			}
		})) return r.push({
			path: n,
			message: `expected ${i.join(" or ")}`
		}), r;
	}
	if (Array.isArray(e) && t.items && e.forEach((e, i) => {
		r.push(...D(e, t.items, `${n}[${i}]`));
	}), f(e) && t.properties) for (let [i, a] of Object.entries(t.properties)) p(e, i) ? r.push(...D(e[i], a, `${n}.${i}`)) : a.required && r.push({
		path: `${n}.${i}`,
		message: "is required"
	});
	return r;
}
function O(e) {
	if (typeof e.safeParse == "function") return {
		kind: "safeParse",
		fn: e.safeParse.bind(e)
	};
	if (typeof e.decode == "function") return {
		kind: b(e) ? "decode" : "parse",
		fn: e.decode.bind(e)
	};
	if (typeof e.parse == "function") return {
		kind: "parse",
		fn: e.parse.bind(e)
	};
	if (typeof e.transform == "function") return {
		kind: "transform",
		fn: e.transform.bind(e)
	};
}
function k(e, t, n) {
	let r = T(e, n, t);
	if (r) return r;
	let i = (e, t, n) => ({
		ok: !1,
		failure: {
			kind: e,
			stage: e,
			error: t,
			issues: n
		}
	});
	if (typeof t.validate == "function" && !O(t)) try {
		let r = C(t.validate(n));
		if (!r.ok) {
			let a = i("validation", r.error, r.issues);
			return E(e, n, t, a), a;
		}
	} catch (r) {
		let a = i("validation", r);
		return E(e, n, t, a), a;
	}
	else if (typeof t.validate == "function") try {
		let r = C(t.validate(n));
		if (!r.ok) {
			let a = i("validation", r.error, r.issues);
			return E(e, n, t, a), a;
		}
	} catch (r) {
		let a = i("validation", r);
		return E(e, n, t, a), a;
	}
	if (!S(t)) {
		let r = {
			ok: !0,
			value: n
		};
		return E(e, n, t, r), r;
	}
	let a = D(n, t, "$");
	if (a.length > 0) {
		let r = i("validation", void 0, a);
		return E(e, n, t, r), r;
	}
	let o = O(t);
	if (!o) {
		let r = {
			ok: !0,
			value: n
		};
		return E(e, n, t, r), r;
	}
	try {
		let r = w(o.fn(n));
		if (!r.ok) {
			let a = i(b(t) || o.kind === "decode" || o.kind === "transform" ? "decode" : "validation", r.error, r.issues);
			return E(e, n, t, a), a;
		}
		let a = {
			ok: !0,
			value: r.value
		};
		return E(e, n, t, a), a;
	} catch (r) {
		let a = i(b(t) || o.kind === "decode" || o.kind === "transform" ? "decode" : "validation", r);
		return E(e, n, t, a), a;
	}
}
function A(e, t) {
	let n = /* @__PURE__ */ new Set([...Object.keys(e), ...Object.keys(t)]);
	for (let r of n) if (!Object.is(e[r], t[r])) return !1;
	return !0;
}
function j(e) {
	let t = /* @__PURE__ */ new Set(), n = /* @__PURE__ */ new Set([
		"__proto__",
		"prototype",
		"constructor"
	]);
	if (!Array.isArray(e)) return t;
	for (let r of e) if (f(r)) {
		let e = r.path;
		if (typeof e == "string") {
			let r = e.replace(/^\$\.?/, "").split(/[.[\]]/)[0];
			r && !n.has(r) && t.add(r);
		}
		Array.isArray(e) && typeof e[0] == "string" && e[0] && !n.has(e[0]) && t.add(e[0]);
	}
	return t;
}
function M(e, t) {
	e !== t && Object.assign(e, t);
}
function N(e) {
	return e !== "partial" && e !== "deferred";
}
function P(e, t) {
	return e.required === !0 || Array.isArray(e.required) && e.required.includes(t);
}
function F(n, r) {
	let i = n.enabled !== !1 && n.mode !== "off" && !!n.registry, a = n.mode || h(), o = {
		phase: "navigation",
		disposed: !1,
		pageCache: /* @__PURE__ */ new WeakMap(),
		registryCache: /* @__PURE__ */ new Map(),
		objectCache: /* @__PURE__ */ new WeakMap(),
		primitiveCache: /* @__PURE__ */ new Map(),
		unsubs: []
	}, s = (e) => {
		try {
			(n.onFailure || n.reporter)?.(e);
		} catch (e) {
			if (a === "throw") throw e;
		}
		if (a === "report") {
			try {
				n.overlay?.(e);
			} catch {}
			!n.onFailure && !n.reporter && typeof console < "u" && console.error("[nb_inertia] page schema failure", e);
		}
	}, c = (t) => {
		if (s(t), a === "throw") throw new e(t);
	}, l = (e, t, n, r, i) => ({
		...e.failure,
		kind: e.failure.kind,
		stage: e.failure.kind,
		component: t,
		prop: n,
		path: n ? `${t}.${n}` : t,
		phase: r,
		value: i
	}), u = (e, t, n, r, i) => {
		let a = k(o, r, n);
		return a.ok ? a : {
			ok: !1,
			failure: l(a, e, t, i, n)
		};
	}, m = (e, t, r, i) => {
		let s = v(i || _(n.registry, e, o.registryCache));
		if (!s || !f(t)) return t;
		let d = y(s), m = s.required, h = (t, n) => {
			let i = t;
			for (let [o, s] of Object.entries(d || {})) {
				let l = v(s);
				if (!l) continue;
				if (!p(t, o)) {
					if (n && N(r) && (P(l, o) || Array.isArray(m) && m.includes(o))) {
						let t = {
							kind: "validation",
							stage: "validation",
							component: e,
							prop: o,
							path: `${e}.${o}`,
							phase: r,
							issues: [{
								path: `$.${o}`,
								message: "is required"
							}]
						};
						c(t);
					}
					continue;
				}
				let d = t[o], f = u(e, o, d, l, r);
				if (!f.ok) {
					c(f.failure), a === "report" && (i === t && (i = { ...t }), delete i[o]);
					continue;
				}
				Object.is(f.value, d) || (i === t && (i = { ...t }), i[o] = f.value);
			}
			return A(t, i) ? t : i;
		};
		if (d) {
			if (N(r) && typeof s.validate == "function") {
				let n = k(o, { validate: s.validate }, t);
				if (!n.ok) {
					let i = l(n, e, void 0, r, t);
					if (c(i), a === "report") {
						let e = j(i.issues);
						if (e.size === 0) return {};
						let n = { ...t };
						for (let t of e) p(n, t) && delete n[t];
						return h(n, !1);
					}
				}
			}
			return h(t, !0);
		}
		if (!N(r)) return t;
		let g = v(s.fullSchema ?? s.wireSchema ?? s.schema) || s, b = u(e, void 0, t, g, r);
		if (b.ok) {
			if (!f(b.value)) return b.value;
			let e = b.value;
			if (A(t, e)) return t;
			let n = { ...t };
			for (let r of Object.keys(e)) n[r] = Object.is(e[r], t[r]) ? t[r] : e[r];
			return n;
		}
		if (c(b.failure), a !== "report") return t;
		let x = j(b.failure.issues);
		if (x.size === 0) return {};
		let S = { ...t };
		for (let e of x) p(S, e) && delete S[e];
		return S;
	}, g = (e) => {
		let t = e._nb_modal;
		if (!f(t) || typeof t.component != "string" || !f(t.props)) return e;
		let r = v(_(n.registry, t.component, o.registryCache));
		if (!r) return e;
		let i = m(t.component, t.props, "modal", r);
		return Object.is(i, t.props) ? e : {
			...e,
			_nb_modal: {
				...t,
				props: i
			}
		};
	}, b = (e, t = o.phase) => {
		if (!i || o.disposed || !d(e)) return e;
		let r = e, a = o.pageCache.get(e);
		if (a !== void 0) return a;
		if (typeof r.component != "string" || !f(r.props)) return e;
		let s = r.component, c = v(_(n.registry, s, o.registryCache)), l = c ? m(s, r.props, t, c) : r.props;
		f(l) && (l = g(l));
		let u = Object.is(l, r.props) ? e : {
			...r,
			props: l
		};
		return o.pageCache.set(e, u), u;
	}, x = (e) => o.phase, S = (t, n) => {
		let r = b(t, n);
		if (r !== t && f(t) && f(r)) try {
			return M(t, r), t;
		} catch (r) {
			if (a !== "throw") {
				let i = {
					kind: "decode",
					stage: "decode",
					component: typeof t.component == "string" ? t.component : "<unknown>",
					phase: n,
					error: r
				};
				throw s(i), new e(i);
			}
			throw r;
		}
		return r;
	}, C = (e) => {
		if (!f(e) || !f(e.detail)) return;
		let t = e.detail, n = t.response;
		if (!f(n)) return;
		let r = n.data, i = r, a = !1;
		if (typeof r == "string") try {
			i = JSON.parse(r), a = !0;
		} catch {
			return;
		}
		let o = b(i, "prefetch");
		o !== i && (a ? n.data = JSON.stringify(o) : t.response = o);
	}, w = {
		enabled: i,
		mode: a,
		registry: n.registry,
		router: r,
		processPage: b,
		processProps: m,
		phaseForPage: x,
		dispose() {
			if (!o.disposed) {
				o.disposed = !0;
				for (let e of o.unsubs.splice(0)) try {
					e();
				} catch {}
			}
		}
	};
	if (!i || !r) return w;
	if (typeof r.init == "function") {
		let e = r.init, n = function(t) {
			let n = S(t.initialPage, "initial"), r = t.resolveComponent, i = (e, t) => {
				let n = t && S(t, x(t));
				return r(e, n);
			};
			return e.call(this, {
				...t,
				initialPage: n,
				resolveComponent: i
			});
		};
		try {
			r.init = n;
			let i = r;
			i[t] = {
				originalInit: e,
				runtime: w
			}, o.unsubs.push(() => {
				r.init === n && (r.init = e), i[t]?.runtime === w && delete i[t];
			});
		} catch {}
	}
	if (typeof r.on == "function" && typeof document < "u") {
		let e = (e, t) => {
			try {
				let n = r.on?.(e, t);
				typeof n == "function" && o.unsubs.push(n);
			} catch {}
		};
		e("start", (e) => {
			let t = f(e) && f(e.detail) ? e.detail.visit : void 0;
			f(t) && t.deferredProps === !0 ? o.phase = "deferred" : f(t) && (Array.isArray(t.only) && t.only.length > 0 || Array.isArray(t.except) && t.except.length > 0) ? o.phase = "partial" : f(t) && t.instant === !0 ? o.phase = "instant" : o.phase = "navigation";
		}), e("beforeUpdate", (e) => {
			let t = f(e) && f(e.detail) ? e.detail.page : void 0;
			t && S(t, o.phase);
		}), e("success", (e) => {
			let t = f(e) && f(e.detail) ? e.detail.page : void 0;
			t && S(t, o.phase);
		}), e("navigate", (e) => {
			let t = f(e) && f(e.detail) ? e.detail.page : void 0;
			t && S(t, o.phase), o.phase = "navigation";
		}), e("prefetched", C), e("finish", () => {
			o.phase !== "history" && (o.phase = "navigation");
		});
		let t = () => {
			o.phase = "history";
		};
		window.addEventListener("popstate", t), o.unsubs.push(() => window.removeEventListener("popstate", t));
	}
	return w;
}
function I(e) {
	return F(g(e));
}
function L(e, n) {
	let r = g(e), i = n;
	if (i) {
		let e = i[t];
		if (e?.runtime) return e.runtime;
	}
	return F(r, i);
}
function R(e = {}) {
	if (e.schemaRuntime !== void 0) return e.schemaRuntime !== !1 && {
		...e.schemaRuntime,
		registry: e.schemaRuntime.registry === void 0 ? e.pageSchemas : e.schemaRuntime.registry
	};
	if (e.pageSchemaRuntime !== void 0) return e.pageSchemaRuntime !== !1 && {
		...e.pageSchemaRuntime,
		registry: e.pageSchemaRuntime.registry === void 0 ? e.pageSchemas : e.pageSchemaRuntime.registry
	};
	if (e.pageSchemas !== void 0) return { registry: e.pageSchemas };
}
function z(e, t, n) {
	let r = R(t), i = L(r !== !1 && r, n), { schemaRuntime: a, pageSchemaRuntime: o, pageSchemas: s, ...c } = t;
	if (!i.enabled) return e(c);
	let l = c.resolve;
	return e({
		...c,
		...typeof l == "function" ? { resolve: (e, t) => l(e, t && i.processPage(t, i.phaseForPage(t))) } : {}
	});
}
//#endregion
export { e as PageSchemaRuntimeError, c as clearPageSchemaRuntimeConfig, o as configurePageSchemaRuntime, l as createPageSchemaRegistry, I as createPageSchemaRuntime, z as createSchemaAwareInertiaApp, s as getPageSchemaRuntimeConfig, L as installPageSchemaRuntime, u as isPageSchemaRuntimeError, R as resolvePageSchemaRuntimeOptions };
