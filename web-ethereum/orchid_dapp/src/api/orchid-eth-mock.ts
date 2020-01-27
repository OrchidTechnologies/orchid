
import {Address} from "./orchid-types";
import {OrchidEthereumAPI, Signer, Wallet} from "./orchid-eth";

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


