/**
 * Compile-time coverage for the package-level Vue 3 adapter.
 *
 * This fixture is included by the Vue package tsconfig and is intentionally
 * not imported at runtime. Keeping these checks next to the barrel catches a
 * missing export or an accidentally narrowed Inertia 3.7 type during builds.
 */

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
type FormProps = InstanceType<typeof Form>['$props'];
type DeferredProps = InstanceType<typeof Deferred>['$props'];
type InfiniteScrollProps = InstanceType<typeof InfiniteScroll>['$props'];
type WhenVisibleProps = InstanceType<typeof WhenVisible>['$props'];
type FormState = ReturnType<typeof useForm<ProfileForm>>;
type PollState = ReturnType<typeof usePoll>;
type PrefetchState = ReturnType<typeof usePrefetch>;

export type _FormCanCancel = Assert<HasKey<FormState, 'cancel'>>;
export type _FormSupportsUnmountCancellation = Assert<HasKey<FormProps, 'cancelOnUnmount'>>;
export type _DeferredSupportsData = Assert<HasKey<DeferredProps, 'data'>>;
export type _InfiniteScrollSupportsData = Assert<HasKey<InfiniteScrollProps, 'data'>>;
export type _WhenVisibleSupportsData = Assert<HasKey<WhenVisibleProps, 'data'>>;
export type _PollHasPolling = Assert<HasKey<PollState, 'polling'>>;
export type _PollCanStart = Assert<HasKey<PollState, 'start'>>;
export type _PollCanStop = Assert<HasKey<PollState, 'stop'>>;
export type _PrefetchHasState = Assert<HasKey<PrefetchState, 'isPrefetching'>>;
export type _PrefetchCanReportCompletion = Assert<HasKey<PrefetchState, 'isPrefetched'>>;

const formProps = {
  cancelOnUnmount: true,
} satisfies Partial<FormProps>;

const deferredProps = {
  data: 'stats',
} satisfies Partial<DeferredProps>;

const infiniteScrollProps = {
  data: 'users',
} satisfies Partial<InfiniteScrollProps>;

const whenVisibleProps = {
  data: 'recommendations',
} satisfies Partial<WhenVisibleProps>;

// The native form surface includes cancellation and optimistic helpers.
declare const form: FormState;
form.cancel();
form.optimistic<{ profile: ProfileForm }>((props) => ({
  profile: props.profile,
}));

// Polling exposes lifecycle controls and state in the Vue adapter.
declare const poll: PollState;
poll.start();
poll.stop();
const polling = poll.polling.value;

// Prefetch/remember composables retain their v3.7 return contracts.
declare const prefetch: PrefetchState;
const prefetching = prefetch.isPrefetching.value;
const prefetched = prefetch.isPrefetched.value;
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
void Deferred;
void Head;
void http;
void InfiniteScroll;
void Link;
void useFormContext;
void useHttp;
void usePage;
void usePoll;
void usePrefetch;
void useRemember;
void WhenVisible;
void formProps;
void deferredProps;
void infiniteScrollProps;
void whenVisibleProps;
void polling;
void prefetching;
void prefetched;
void remembered;
