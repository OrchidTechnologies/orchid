import React from "react";
import {camelCase} from "../util/util";

export enum Route {
  Overview, Balances, AddFunds, CreateAccount, WithdrawFunds, Transactions,
  MoveFunds, LockFunds, DebugPanel, StakeFunds
}

export const RouteContext = React.createContext({
  route: Route.Overview,
  setNavEnabled: (_: boolean) => { },
  setRoute: (_: Route) => {
  }
});

export function pathToRoute(path: string | undefined): Route | undefined {
  if (path === undefined) {
    return undefined;
  }
  path = path.substr(1); // remove hash
  for (let route in Route) {
    if (route.toLowerCase() === path.toLowerCase()) {
      return Route[route as keyof typeof Route];
    }
  }
  return undefined;
}
export function routeToPath(route: Route): string {
  return "#"+camelCase(Route[route]);
}

export function setURL(route: Route) {
  window.history.pushState(route, '', routeToPath(route));
}
