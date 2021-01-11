import React, {FC, useContext, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {EtherscanIO} from "../api/etherscan-io";
import './Transactions.css'
import {Col, Container, Row} from "react-bootstrap";
import {S} from "../i18n/S";
import {LotteryPotUpdateEvent} from "../api/orchid-eth-types";
import {WalletProviderContext} from "../index";

export const Transactions: FC = () => {
  const [events, setEvents] = useState<LotteryPotUpdateEvent[]>([]);
  let walletStatus = useContext(WalletProviderContext)

  useEffect(() => {
    let api = OrchidAPI.shared();
    let sub = api.transactions.subscribe((events) => {
      setEvents(events ?? []);
    });
    return () => {
      sub.unsubscribe();
    };
  }, []);

  return (
    <Container className="form-style wide">
      <Row>
        <Col>
          <label className="title">{S.transactions}</label>
          <div className="transactions-list">
            <div className="transactions-header-row">
              <label className="transactions-col">{S.date}</label>
              <label className="transactions-col2">{S.balance}</label>
              <label className="transactions-col3">{S.tx}</label>
            </div>
            <hr/>
            {!events.length && <div className="loading">{S.loading}...</div>}
            {events.map((ev) => {
              let balance = (ev.balance ? ev.balance.formatCurrency(4) : null)
                ?? (ev.balanceChange ? "+"+ev.balanceChange.toFixedLocalized(4) : "");
              let date = ev.timeStamp.getTime() > 0 ? ev.timeStamp.toLocaleDateString() : "";
              let txHash = ev.transactionHash;
              let isMainNet = walletStatus.chainInfo?.isEthereumMainNet
              let txLink = isMainNet ? EtherscanIO.txLink(txHash) : undefined;
              return (
                <div className="transactions-row" key={txHash}>
                  <label className="transactions-col">{date}</label>
                  <label className="transactions-col2">{balance}</label>
                  <label className="transactions-col3">
                    <a target="_blank" rel="noopener noreferrer"
                       href={txLink}>{txHash}</a></label>
                </div>
              );
            })}
          </div>
        </Col>
      </Row>
    </Container>
  );
}

