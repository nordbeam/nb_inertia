const o = "__nb_inertia_modal_request_context_stack";
function i() {
  if (typeof window > "u")
    return [];
  const e = window[o];
  if (e)
    return e;
  const n = [];
  return window[o] = n, n;
}
function d(e, n) {
  if (typeof window > "u")
    return;
  const t = i(), r = t.findIndex((s) => s.id === e);
  r >= 0 ? t[r] = { id: e, context: n } : t.push({ id: e, context: n });
}
function a(e) {
  if (typeof window > "u")
    return;
  const n = i(), t = n.findIndex((r) => r.id === e);
  t >= 0 && n.splice(t, 1);
}
function c() {
  const e = i();
  return e[e.length - 1]?.context ?? null;
}
function u(e) {
  if (e)
    return e.returnUrl || e.baseUrl || e.url;
}
function f(e, n) {
  const t = u(n);
  return t ? {
    ...e ?? {},
    headers: {
      ...e?.headers ?? {},
      "x-inertia-modal": "true",
      "x-inertia-modal-base-url": t
    }
  } : e;
}
export {
  c as getCurrentModalRequestContext,
  f as mergeModalHeaders,
  d as registerModalRequestContext,
  u as resolveModalBaseUrl,
  a as unregisterModalRequestContext
};
