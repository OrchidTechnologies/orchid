//
// Orchid Ethereum Contracts Lib
//
import Web3 from "web3";
import "../i18n/i18n_util";
import {EthAddress, LotteryPot, LotteryPotUpdateEvent, Signer, Wallet} from "./orchid-eth-types";
import {GasFunds, LotFunds, TokenType} from "./orchid-eth-token-types";
import {MarketConditionsSource} from "./orchid-market-conditions";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export {LotteryPot, Signer, Wallet}

export type Web3Wallet = any;

export const ORCHID_SIGNER_KEYS_WALLET = "orchid-signer-keys";

export interface OrchidEthereumAPI {

  // Using the V0 lottery contract (supporting small UI differences)
  isV0: boolean

  // todo: change to ChainInfo here
  chainId: number
  fundsTokenType: TokenType<LotFunds>
  gasTokenType: TokenType<GasFunds>

  orchidGetSigners(wallet: Wallet): Promise<Signer []>

  orchidGetSignerKeys(): Web3Wallet

  orchidCreateSigner(wallet: Wallet): Signer

  orchidGetWallet(): Promise<Wallet>

  orchidGetLotteryPot(funder: Wallet, signer: Signer): Promise<LotteryPot>

  orchidAddFunds(funder: EthAddress, signer: EthAddress, amount: LotFunds, escrow: LotFunds, wallet: Wallet): Promise<string>

  orchidMoveFundsToEscrow(funder: EthAddress, signer: EthAddress, amount: LotFunds, potBalance: LotFunds): Promise<string>

  orchidWithdrawFunds(funder: EthAddress, signer: EthAddress, targetAddress: EthAddress, amount: LotFunds, potBalance: LotFunds): Promise<string>

  orchidWithdrawFundsAndEscrow(pot: LotteryPot, targetAddress: EthAddress): Promise<string>

  orchidLock(pot: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string>

  orchidUnlock(pot: LotteryPot, funder: EthAddress, signer: EthAddress): Promise<string>

  orchidStakeFunds(funder: EthAddress, stakee: EthAddress, amount: LotFunds, wallet: Wallet, delay: BigInt): Promise<string>

  orchidGetStake(stakee: EthAddress): Promise<LotFunds>

  orchidReset(funder: Wallet): Promise<string>

  getGasPrice(): Promise<GasFunds>

  getAccountCreationGasRequired(): Promise<GasFunds>

  getLotteryUpdateEvents(funder: EthAddress, signer: EthAddress): Promise<LotteryPotUpdateEvent[]>

  marketConditions: MarketConditionsSource
  contractsOverridden: boolean
  requiredConfirmations: number

}

export class GasPricingStrategy {

  /// Choose a gas price taking into account current gas price and the wallet balance.
  /// This strategy uses a multiple of the current median gas price up to a hard limit on
  /// both gas price and fraction of the wallet's remaining gas funds balance.
  // Note: Some of the usage of BigInt in here is convoluted due to the need to import the polyfill.
  static chooseGasPrice(
    targetGasAmount: number, currentMedianGasPrice: GasFunds, currentGasFundsBalance: GasFunds): number | undefined {
    let maxPriceGwei = 200.0;
    let minPriceGwei = 5.0;
    let medianMultiplier = 1.2;
    let maxWalletFrac = 1.0;

    // Target our multiple of the median price
    let targetPrice: BigInt = currentMedianGasPrice.multiply(medianMultiplier).intValue;

    // Don't exceed max price
    let maxPrice: BigInt = BigInt(maxPriceGwei).multiply(1e9);
    if (maxPrice < targetPrice) {
      console.log("Gas price calculation: limited by max price to : ", maxPriceGwei)
    }
    targetPrice = BigInt.min(targetPrice, maxPrice);

    // Don't fall below min price
    let minPrice: BigInt = BigInt(minPriceGwei).multiply(1e9);
    if (minPrice > targetPrice) {
      console.log("Gas price calculation: limited by min price to : ", minPriceGwei)
    }
    targetPrice = BigInt.max(targetPrice, minPrice);

    // Don't exceed max wallet fraction
    let targetSpend: BigInt = BigInt(targetPrice).multiply(targetGasAmount);
    let maxSpend = BigInt(Math.floor(currentGasFundsBalance.floatValue * maxWalletFrac));
    if (targetSpend > maxSpend) {
      console.log("Gas price calculation: limited by wallet balance: ", currentGasFundsBalance)
    }
    targetSpend = BigInt.min(targetSpend, maxSpend);

    // Recalculate the price
    let price = BigInt(targetSpend).divide(targetGasAmount);

    console.log(`Gas price calculation, `
      + `targetGasAmount: ${targetGasAmount}, medianGasPrice: ${currentMedianGasPrice.floatValue}, ethBalance: ${currentGasFundsBalance}, chose price: ${BigInt(price).divide(1e9)}`
    );

    return price.toJSNumber();
  }
}

export function isEthAddress(str: string): boolean {
  return Web3.utils.isAddress(str)
}
