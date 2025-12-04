import i from "axios";
const p = "x-inertia-modal";
let n = !1;
async function s() {
  try {
    const { router: e } = await import("@inertiajs/react");
    if (e.page)
      return {
        component: e.page.component,
        props: e.page.props
      };
  } catch (e) {
    console.error("[nb-inertia] Failed to get current page:", e);
  }
  return null;
}
function l() {
  if (!(typeof window > "u")) {
    if (n) {
      console.warn("[nb-inertia] Modal interceptor already registered, skipping duplicate setup");
      return;
    }
    i.interceptors.response.use(
      async (e) => {
        if (!(e.headers[p] === "true"))
          return e;
        const t = await s();
        if (!t)
          return console.debug("[nb-inertia] No current page for backdrop preservation (expected on direct URL access)"), e;
        let r = e.data;
        if (typeof r == "string")
          try {
            r = JSON.parse(r);
          } catch (a) {
            return console.error("[nb-inertia] Failed to parse modal response:", a), e;
          }
        const o = {
          ...JSON.parse(JSON.stringify(t.props)),
          ...r.props
        };
        return r.component = t.component, r.props = o, e.data = r, e;
      },
      (e) => Promise.reject(e)
    ), n = !0;
  }
}
function f() {
  return n;
}
export {
  l as default,
  f as isModalInterceptorRegistered,
  l as setupModalInterceptor
};
