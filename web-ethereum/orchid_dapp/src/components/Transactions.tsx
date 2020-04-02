import React, {FC, useEffect, useState} from "react";
import {OrchidAPI} from "../api/orchid-api";
import {keikiToOxtString} from "../api/orchid-eth";
import {EtherscanIO, LotteryPotUpdateEvent} from "../api/etherscan-io";
import './Transactions.css'
import {Col, Container, Row} from "react-bootstrap";
import {S} from "../i18n/S";

export const Transactions: FC = () => {
  const [events, setEvents] = useState<LotteryPotUpdateEvent[]>([]);

  useEffect(() => {
    let api = OrchidAPI.shared();
    let sub = api.transactions_wait.subscribe((events) => {
      setEvents(events);
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
              let balance = keikiToOxtString(ev.balance, 2);
              let date = ev.timeStamp.toLocaleDateString();
              let txHash = ev.transactionHash;
              let txLink = EtherscanIO.txLink(txHash);
              return (
                <div className="transactions-row" key={txHash}>
                  <label className="transactions-col">{date}</label>
                  <label className="transactions-col2">{balance} OXT</label>
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

