import { router as inertiaRouter } from '@inertiajs/react';
export declare const router: {
    visit(url: Parameters<typeof inertiaRouter.visit>[0], options?: Parameters<typeof inertiaRouter.visit>[1]): void;
    get(url: Parameters<typeof inertiaRouter.get>[0], data?: Parameters<typeof inertiaRouter.get>[1], options?: Parameters<typeof inertiaRouter.get>[2]): void;
    post(url: Parameters<typeof inertiaRouter.post>[0], data?: Parameters<typeof inertiaRouter.post>[1], options?: Parameters<typeof inertiaRouter.post>[2]): void;
    put(url: Parameters<typeof inertiaRouter.put>[0], data?: Parameters<typeof inertiaRouter.put>[1], options?: Parameters<typeof inertiaRouter.put>[2]): void;
    patch(url: Parameters<typeof inertiaRouter.patch>[0], data?: Parameters<typeof inertiaRouter.patch>[1], options?: Parameters<typeof inertiaRouter.patch>[2]): void;
    delete(url: Parameters<typeof inertiaRouter.delete>[0], options?: Parameters<typeof inertiaRouter.delete>[1]): void;
    reload(options?: Parameters<typeof inertiaRouter.reload>[0]): void;
    form: typeof import('@inertiajs/vue3').useForm;
};
export default router;
//# sourceMappingURL=router.d.ts.map