import { router as router_2 } from '@inertiajs/react';
import { useForm } from '@inertiajs/vue3';

declare const router: {
    visit(url: Parameters<typeof router_2.visit>[0], options?: Parameters<typeof router_2.visit>[1]): void;
    get(url: Parameters<typeof router_2.get>[0], data?: Parameters<typeof router_2.get>[1], options?: Parameters<typeof router_2.get>[2]): void;
    post(url: Parameters<typeof router_2.post>[0], data?: Parameters<typeof router_2.post>[1], options?: Parameters<typeof router_2.post>[2]): void;
    put(url: Parameters<typeof router_2.put>[0], data?: Parameters<typeof router_2.put>[1], options?: Parameters<typeof router_2.put>[2]): void;
    patch(url: Parameters<typeof router_2.patch>[0], data?: Parameters<typeof router_2.patch>[1], options?: Parameters<typeof router_2.patch>[2]): void;
    delete(url: Parameters<typeof router_2.delete>[0], options?: Parameters<typeof router_2.delete>[1]): void;
    reload(options?: Parameters<typeof router_2.reload>[0]): void;
    form: useForm;
};
export default router;
export { router }

export { }
