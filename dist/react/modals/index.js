import { ModalPageProvider as r, ModalStackProvider as a, useIsInModal as t, useModal as d, useModalPageContext as l, useModalStack as M } from "./modalStack.js";
import { usePage as n } from "./usePage.js";
import { InitialModalHandler as s } from "./InitialModalHandler.js";
import { ClientModalLink as m } from "./ClientModalLink.js";
import { ModalLink as g } from "./ModalLink.js";
import { DEFAULT_MODAL_CONFIG as I, mergeModalConfig as P } from "./types.js";
import { isModalInterceptorRegistered as k, setupModalInterceptor as C } from "../preserveBackdrop.js";
export {
  m as ClientModalLink,
  I as DEFAULT_MODAL_CONFIG,
  s as InitialModalHandler,
  g as ModalLink,
  r as ModalPageProvider,
  a as ModalStackProvider,
  k as isModalInterceptorRegistered,
  P as mergeModalConfig,
  C as setupModalInterceptor,
  t as useIsInModal,
  d as useModal,
  l as useModalPageContext,
  M as useModalStack,
  n as usePage
};
