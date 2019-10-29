import React from "react";

export enum Route {
  Overview, Balances, AddFunds, WithdrawFunds, Transactions,
  MoveFunds, LockFunds, ManageKeys, DebugPanel
}
export const RouteContext = React.createContext({
  route: Route.Overview,
  setRoute: (_: Route) => { }
});

