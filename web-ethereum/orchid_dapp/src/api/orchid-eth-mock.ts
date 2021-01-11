import {LotteryPot, Signer, Wallet} from "./orchid-eth";
import {
  EthereumTransaction,
  OrchidTransaction,
  OrchidTransactionDetail, OrchidTransactionMonitor, OrchidTransactionMonitorListener,
  OrchidTransactionType
} from "./orchid-tx";
import {EthAddress} from "./orchid-eth-types";
import {GasFunds, LotFunds, TokenType} from "./orchid-eth-token-types";
import {OrchidEthereumApiV0Impl} from "./v0/orchid-eth-v0";
import {EVMChains} from "./chains/chains";

// Override parts of the Orchid Ethereum API with fake data
export class MockQuickSetup extends OrchidEthereumApiV0Impl {
  static MOCK_TX_FAIL = false;

  async orchidAddFunds(
    funder: EthAddress, signer: EthAddress, amount: LotFunds, escrow: LotFunds, wallet: Wallet
  ): Promise<string> {
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
    //return [Mocks.signer()]
    return [];
  }
}

export class MockTransactions {
  static mockAddFunds(): OrchidTransactionDetail {
    return new OrchidTransactionDetail(
      new OrchidTransaction(
        new Date(), OrchidTransactionType.AddFunds,
        EVMChains.ETHEREUM_MAIN_NET,
        [
          "0xdfa60d4e97c242c5222a11b485c051bbdeb133c99baccd34dc33ceae1dc0cd67",
          "0x1bbdeb133c99baccd34dc33ceae1dc0cd67dfa60d4e97c242c5222a11b485c05"
        ]),
      [
        // approve confirmed
        new EthereumTransaction(
          "0xdfa60d4e97c242c5222a11b485c051bbdeb133c99baccd34dc33ceae1dc0cd67",
          1, 3, false
        ),
        // push pending
        EthereumTransaction.pending("0x1bbdeb133c99baccd34dc33ceae1dc0cd67dfa60d4e97c242c5222a11b485c05")
      ]
    );
  }
}

export class MockOrchidTransactionMonitor extends OrchidTransactionMonitor {
  mock_store: OrchidTransaction [] = [];

  initIfNeeded(listener: OrchidTransactionMonitorListener) {
    if (this.listener) {
      return
    }
    super.initIfNeeded(listener);
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

export class Mocks {
  fundsTokenType: TokenType<LotFunds>
  gasTokenType: TokenType<GasFunds>

  constructor(fundsTokenType: TokenType<LotFunds>, gasTokenType: TokenType<GasFunds>) {
    this.fundsTokenType = fundsTokenType;
    this.gasTokenType = gasTokenType;
  }

  public wallet(): Wallet {
    return new Wallet(this.fundsTokenType.zero, this.gasTokenType.zero)
  }

  public signer(): Signer {
    return new Signer(this.wallet(), "0x231d8129075898402053b3720c89DbD7B0D87C2d", "12345");
  }

  public lotteryPot(
    balance: number = 1.0, deposit: number = 1.0
  ): LotteryPot {
    return new LotteryPot(
      this.signer(),
      this.fundsTokenType.fromNumber(balance * 1e18),
      this.fundsTokenType.fromNumber(deposit * 1e18), null)
  }
}
