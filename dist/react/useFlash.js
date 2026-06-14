import e from "./usePage.js";
import { useCallback as t, useMemo as n } from "react";
//#region priv/nb_inertia/react/useFlash.tsx
function r() {
	let r = e(), i = n(() => r.flash ?? {}, [r.flash]);
	return {
		flash: i,
		has: t((e) => i != null && e in i && !!i[e], [i]),
		get: t((e) => i?.[e], [i])
	};
}
//#endregion
export { r as default, r as useFlash };
