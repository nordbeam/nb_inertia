/**
 * Compile-time coverage for the package-level React adapter.
 *
 * This fixture is included by the React package tsconfig and is intentionally
 * not imported at runtime. Keeping these checks next to the barrel catches a
 * missing export or an accidentally narrowed Inertia 3.7 type during builds.
 */

import type { ComponentProps } from 'react';
import {
  App,
  config,
  createInertiaApp,
  Deferred,
  Form,
  Head,
  http,
  InfiniteScroll,
  Link,
  router,
  useForm,
  useFormContext,
  useHttp,
  usePage,
  usePoll,
  usePrefetch,
  useRemember,
  WhenVisible,
} from './index';

type ProfileForm = {
  name: string;
  email: string;
};

type Assert<T extends true> = T;
type HasKey<T, K extends PropertyKey> = K extends keyof T ? true : false;

type FormState = ReturnType<typeof useForm<ProfileForm>>;
type PollState = ReturnType<typeof usePoll>;
type PrefetchState = ReturnType<typeof usePrefetch>;

export type _FormCanCancel = Assert<HasKey<FormState, 'cancel'>>;
export type _PollHasPolling = Assert<HasKey<PollState, 'polling'>>;
export type _PollCanStart = Assert<HasKey<PollState, 'start'>>;
export type _PollCanStop = Assert<HasKey<PollState, 'stop'>>;
export type _PrefetchHasState = Assert<HasKey<PrefetchState, 'isPrefetching'>>;
export type _PrefetchCanReportCompletion = Assert<HasKey<PrefetchState, 'isPrefetched'>>;

const formProps = {
  cancelOnUnmount: true,
  children: null,
} satisfies Partial<ComponentProps<typeof Form>>;

const deferredProps = {
  data: 'stats',
  fallback: null,
  children: null,
} satisfies ComponentProps<typeof Deferred>;

const infiniteScrollProps = {
  data: 'users',
  children: null,
} satisfies ComponentProps<typeof InfiniteScroll>;

const whenVisibleProps = {
  data: 'recommendations',
  fallback: null,
  children: null,
} satisfies ComponentProps<typeof WhenVisible>;

const route = {
  url: '/profiles/1',
  method: 'patch' as const,
};

// The native form surface includes cancellation and optimistic helpers.
declare const form: FormState;
form.cancel();
form.optimistic<{ profile: ProfileForm }>((props) => ({
  profile: props.profile,
}));

// Polling exposes lifecycle controls and state in the React adapter.
declare const poll: PollState;
poll.start();
poll.stop();
const polling: boolean = poll.polling;

// Prefetch/remember hooks retain their v3.7 return contracts.
declare const prefetch: PrefetchState;
const prefetching: boolean = prefetch.isPrefetching;
const prefetched: boolean = prefetch.isPrefetched;
const remembered = useRemember({ tab: 'activity' }, 'profile');

// Router v3.7 supports async/background visits, once-only lifecycle events,
// optimistic updates, client-side replacement, and prefetch/cache helpers.
router.visit('/profiles', { async: true, preserveState: true });
router.once('navigate', (event) => {
  void event;
});
router.optimistic<{ profile: ProfileForm }>((props) => ({
  profile: props.profile,
}));
router.replace({
  component: 'Profiles/Show',
  url: '/profiles/1',
  props: { profile: { name: 'Ada', email: 'ada@example.test' } },
});
router.prefetch('/profiles', { async: true }, { cacheFor: '30s', cacheTags: ['profiles'] });
router.getCached('/profiles', { async: true });
router.getPrefetching('/profiles', { async: true });
router.flush('/profiles', { async: true });
router.flushAll();
router.flushByCacheTags('profiles');

// Keep all imported symbols referenced so this fixture remains valid under
// the package's noUnusedLocals/type-aware lint settings.
void App;
void config;
void createInertiaApp;
void Head;
void http;
void Link;
void useFormContext;
void useHttp;
void usePage;
void formProps;
void deferredProps;
void infiniteScrollProps;
void whenVisibleProps;
void route;
void polling;
void prefetching;
void prefetched;
void remembered;
