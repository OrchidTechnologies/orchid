
import {Address} from "./orchid-types";
import {OrchidEthereumAPI, Signer, Wallet} from "./orchid-eth";
import {
  EthereumTransaction,
  OrchidTransaction,
  OrchidTransactionDetail, OrchidTransactionMonitor, OrchidTransactionMonitorListener,
  OrchidTransactionType
} from "./orchid-tx";

export class MockQuickSetup extends OrchidEthereumAPI {
  static MOCK_TX_FAIL = false;

  async orchidAddFunds(funder: Address, signer: Address, amount: BigInt, escrow: BigInt): Promise<string> {
    console.log("MOCK: Add funds  signer: ", signer, " amount: ", amount, " escrow: ", escrow);
    return new Promise<string>(async function (resolve, reject) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      if (MockQuickSetup.MOCK_TX_FAIL) {
        reject("tx error");
      } else {
        resolve('0x12341234123412341234123');
      }
    });
  }

  orchidCreateSigner(wallet: Wallet): Signer {
    return new Signer(wallet, "0x231d8129075898402053b3720c89DbD7B0D87C2d", "12345");
  }

  async orchidGetSigners(wallet: Wallet): Promise<Signer []> {
    // return [new Signer(wallet, "0x231d8129075898402053b3720c89DbD7B0D87C2d", "12345")];
    return [];
  }
}

export class MockTransactions {
  static mockAddFunds(): OrchidTransactionDetail {
    return new OrchidTransactionDetail(
      new OrchidTransaction(new Date(), OrchidTransactionType.AddFunds,
        [
          "0xdfa60d4e97c242c5222a11b485c051bbdeb133c99baccd34dc33ceae1dc0cd67",
          "0x1bbdeb133c99baccd34dc33ceae1dc0cd67dfa60d4e97c242c5222a11b485c05"
        ]),
      [
        // approve confirmed
        new EthereumTransaction(
          "0xdfa60d4e97c242c5222a11b485c051bbdeb133c99baccd34dc33ceae1dc0cd67",
          3, false
        ),
        // push pending
        EthereumTransaction.pending("0x1bbdeb133c99baccd34dc33ceae1dc0cd67dfa60d4e97c242c5222a11b485c05")
      ]
    );
  }
}

export class MockOrchidTransactionMonitor extends OrchidTransactionMonitor {
  mock_store: OrchidTransaction [] = [];

  init(listener: OrchidTransactionMonitorListener) {
    if (this.listener) { return }
    super.init(listener);
    this.add(MockTransactions.mockAddFunds());
  }

  // static test_tx: OrchidTransaction [] = [];
  load(): OrchidTransaction [] {
    return this.mock_store;
  }

  save(txs: OrchidTransaction []) {
    this.mock_store = txs;
  }

}
