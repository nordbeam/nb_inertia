import { router as inertiaRouter } from '@inertiajs/react';
/**
 * Keep the native Router instance as the target so prototype methods, getters,
 * own state, and `instanceof Router` all continue to work. Every function is
 * invoked with the native instance as `this`; only request options are
 * adjusted for the active modal context.
 */
export declare const router: typeof inertiaRouter;
export default router;
//# sourceMappingURL=router.d.ts.map