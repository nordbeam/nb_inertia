import { useEffect as e, useRef as t } from "react";
import { router as n } from "@inertiajs/react";
//#region priv/nb_inertia/react/useOnFlash.tsx
function r(r) {
	let i = t(r);
	i.current = r, e(() => n.on("flash", (e) => {
		let t = e.detail;
		i.current(t.flash);
	}), []);
}
//#endregion
export { r as default, r as useOnFlash };
