import React from "react";
import {camelCase} from "../util/util";

export enum Route {
  None, Overview, Info, AddFunds, CreateAccount, WithdrawFunds, Transactions,
  MoveFunds, LockFunds, DebugPanel, StakeFundsTest
}

export interface RouteContextType {
  route: Route,
  setRoute: (_: Route) => void
}

export const RouteContext = React.createContext<RouteContextType>({
  route: Route.Overview,
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
  return route === Route.None ? ' ' : "#" + camelCase(Route[route]);
}

export function setURL(route: Route) {
  window.history.pushState(route, '', routeToPath(route));
}
