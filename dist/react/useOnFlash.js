import { router as e } from "@inertiajs/react";
import { useEffect as t, useRef as n } from "react";
//#region priv/nb_inertia/react/useOnFlash.tsx
function r(r) {
	let i = n(r);
	i.current = r, t(() => e.on("flash", (e) => {
		let t = e.detail;
		i.current(t.flash);
	}), []);
}
//#endregion
export { r as default, r as useOnFlash };
