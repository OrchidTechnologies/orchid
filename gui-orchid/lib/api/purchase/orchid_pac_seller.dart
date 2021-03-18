import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/abi_encode.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';
import 'package:web3dart/crypto.dart';
import '../orchid_crypto.dart';
import '../orchid_log_api.dart';
import 'package:convert/convert.dart';
import 'dart:convert' show utf8;

class OrchidPacSeller {
  static final EthereumAddress pacSellerAddress =
      EthereumAddress.from('0xabEB207C9C82c80D2c03545A73F234d0544172A2');

  // edit(address,uint8,bytes32,bytes32,uint64,int256,int256,uint256,uint256)
  static String editMethodHash = '8b6c888f';

  // read(address)
  static String readMethodHash = 'a087a87e';

  /// Create a default funding transaction allocating the total usd value
  /// in USD among balance, deposit, and gas.  This method chooses a
  /// conservative gas price and exchange rate for the native currency.
  static Future<PacSubmitSellerTransaction> defaultFundingTransactionParams({
    Chain chain,
    StoredEthereumKey signerKey,
    USD totalUsdValue,
  }) async {
    var currency = chain.nativeCurrency;
    var signer = signerKey.address;

    // Gas
    var gasPriceMultiplier = 1.1;
    var gasPrice = (await OrchidEthereumV1().getGasPrice(chain))
        .multiplyDouble(gasPriceMultiplier);
    var gas = OrchidContractV1.lotteryMoveMaxGas;
    var gasCost = gasPrice.multiplyInt(gas);

    // Allocate value
    var usdToTokenRate = await OrchidPricing().usdToTokenRate(currency);
    var totalTokenValue =
        currency.fromDouble(totalUsdValue.value * usdToTokenRate);
    var useableTokenValue = totalTokenValue.subtract(gasCost);

    // TODO: We currently have no way of knowing if the account exists.
    // TODO: As a placeholder we will just always allocate a fraction to escrow.
    var escrowPercentage = 0.1;
    var escrow = useableTokenValue * escrowPercentage;

    log("eth: createFundingTransaction "
        "totalUsdValue = $totalUsdValue, "
        "usdToTokenRate = $usdToTokenRate, "
        "totalTokenValue = $totalTokenValue, "
        "useableTokenValue = $useableTokenValue, "
        "escrow = $escrow");

    var txParams = EthereumTransactionParams(
      from: signer,
      to: pacSellerAddress,
      gas: gas,
      gasPrice: gasPrice.intValue,
      value: useableTokenValue.intValue,
      chainId: chain.chainId,
    );

    return PacSubmitSellerTransaction(
        signerKey: signerKey.ref(),
        txParams: txParams,
        escrow: escrow.intValue);
  }

  /// Construct a seller edit transaction for the specified tx params
  /// including the inner signature arg covering the edit parameters.
  static EthereumTransaction sellerEditTransaction({
    @required StoredEthereumKey signerKey,
    @required EthereumTransactionParams params,
    @required int l2Nonce, // The tx nonce
    @required int l3Nonce, // The signed edit call nonce
    @required BigInt adjust,
    BigInt warn,
    BigInt refill,
    BigInt retrieve,
  }) {
    // defaults
    warn = warn ?? BigInt.zero;
    refill = refill ?? BigInt.one;
    retrieve = retrieve ?? BigInt.zero;

    var amount = params.value;

    // Signed params args to the edit call
    var packedEditParams = hex.decode(packedAbiEncodedEditParams(
      chainId: params.chainId,
      l3Nonce: l3Nonce,
      amount: amount,
      adjust: adjust,
      warn: warn,
      retrieve: retrieve,
      refill: refill,
    ));
    var sig = Web3DartUtils.web3Sign(keccak256(packedEditParams), signerKey);

    var tx = EthereumTransaction(
      params: params,
      data: abiEncodeSellerEdit(
          signer: signerKey.address,
          signature: sig,
          nonce: l2Nonce,
          adjust: adjust,
          warn: warn,
          retrieve: retrieve,
          refill: refill),
    );
    log("XXX: pac seller, unsigned tx = ${tx.toJson()}");
    return tx;
  }

  /// Render the transaction to an eip-191 string and sign it.
  // 0x19 + "Ethereum Signed Message:\n" + len(message)
  static MsgSignature signTransactionString(
      String txString, StoredEthereumKey signerKey) {
    var msg = '\x19' +
        "Ethereum Signed Message:\n" +
        txString.length.toString() +
        txString;
    print("XXX: signTransactionString: msg = $msg");

    var encoded = utf8.encode(msg);
    return Web3DartUtils.web3Sign(keccak256(encoded), signerKey);
  }

  /*
    function edit(
      address signer,
      uint8 v, bytes32 r, bytes32 s,
      uint64 nonce, int256 adjust, int256 warn, uint256 retrieve, uint256 refill) external payable {
   */
  static String abiEncodeSellerEdit({
    @required EthereumAddress signer,
    @required MsgSignature signature,
    @required int nonce,
    @required BigInt adjust,
    @required BigInt warn,
    BigInt retrieve,
    BigInt refill,
  }) {
    return '0x' +
        editMethodHash +
        AbiEncode.address(signer) +
        AbiEncode.uint8(signature.v) +
        AbiEncode.bytes32(signature.r) +
        AbiEncode.bytes32(signature.s) +
        AbiEncode.uint64(BigInt.from(nonce)) +
        AbiEncode.int256(adjust) +
        AbiEncode.int256(warn) +
        AbiEncode.uint256(retrieve ?? BigInt.zero) +
        AbiEncode.uint256(refill ?? BigInt.one);
  }

  /*
    EIP-191 encoded args:
    msg = encode_abi_packed(['bytes1', 'bytes1', 'address', 'uint256', 'uint64', 'address',
        'uint256', 'int256', 'int256', 'uint256', 'uint256'],
      [b'\x19', b'\x00', sellerContractAddress, chainid, l3nonce, tokenid,
        amount, adjust, lock, retrieve, refill])

     The seller contract verifies with:
        keccak256(abi.encodePacked(byte(0x19), byte(0x00), this(seller address),
          digest(chain id), l3nonce, token, amount, adjust, lock, retrieve, refill));
        address signer = ecrecover(digest, v, r, s);
      token -> 0x0000000000000000000000000000000000000000 (address)
   */

  /// Take the params to a call to the edit method on the PAC seller contract
  /// and sign them with the specified key.  These are signed and the sig is
  /// included in edit call.
  static String packedAbiEncodedEditParams({
    @required int chainId,
    @required int l3Nonce,
    EthereumAddress token,
    @required BigInt amount,
    @required BigInt adjust,
    @required BigInt warn,
    @required BigInt retrieve,
    @required BigInt refill,
  }) {
    var encoded = '' +
        AbiEncodePacked.bytes1(0x19) +
        AbiEncodePacked.bytes1(0x00) +
        AbiEncodePacked.address(pacSellerAddress) +
        AbiEncodePacked.uint256(BigInt.from(chainId)) +
        AbiEncodePacked.uint64(BigInt.from(l3Nonce)) +
        AbiEncodePacked.address(token ?? EthereumAddress.zero) +
        AbiEncodePacked.uint256(amount) +
        AbiEncodePacked.int256(adjust) +
        AbiEncodePacked.int256(warn) +
        AbiEncodePacked.uint256(retrieve) +
        AbiEncodePacked.uint256(refill);
    return encoded;
  }

  // acstat = seller.functions.read(acct.address).call()
  // l3nonce = int(('0'*16+hex(acstat)[2:])[-16:], 16)
  static Future<int> getL3Nonce({Chain chain, EthereumAddress signer}) async {
    var params = [
      {
        "to": "$pacSellerAddress",
        "data": "0x${readMethodHash}"
            "${AbiEncode.address(signer)}"
      },
      "latest"
    ];
    String result =
        await OrchidEthereumV1.ethCall(url: chain.providerUrl, params: params);
    var buff = HexStringBuffer(result);
    var nonce = buff.takeUint256().toUnsigned(64).toInt();
    print("XXX: getL3Nonce result = $result, nonce = $nonce");
    return nonce;
  }
}
