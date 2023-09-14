import 'dart:async';
import 'dart:typed_data';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/abi_encode.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'orchid_pac_transaction.dart';
import 'package:orchid/util/hex.dart';
import 'package:web3dart/crypto.dart';
import 'package:convert/convert.dart';
import 'dart:convert' show utf8;

class OrchidPacSeller {
  // TODO: This is only valid for xDai.  The server will maintain a list.
  static final EthereumAddress sellerContractAddress =
      EthereumAddress.from('0x7dFae1C74a946FCb50e7376Ff40fe2Aa3A2F9B2b');

  // edit(address,uint8,bytes32,bytes32,uint64,int256,int256,uint256,uint256)
  static String editMethodHash = '8b6c888f';

  // read(address)
  static String readMethodHash = 'a087a87e';

  /// Create a default funding transaction allocating the total usd value
  /// in USD among balance, deposit, and gas.  This method chooses a
  /// conservative gas price and exchange rate for the native currency.
  static Future<PacSubmitSellerTransaction> defaultFundingTransactionParams({
    required Chain chain,
    required StoredEthereumKey signerKey,
    required USD totalUsdValue,
  }) async {
    final currency = chain.nativeCurrency;
    final signer = signerKey.address;

    // Gas
    const gasPriceMultiplier = 1.1;
    final gasPrice = (await OrchidEthereumV1().getGasPrice(chain))
        .multiplyDouble(gasPriceMultiplier);
    final gas = OrchidContractV1.lotteryMoveMaxGas;
    final gasCost = gasPrice.multiplyInt(gas);

    // Allocate value
    final usdToTokenRate = await OrchidPricing().usdToTokenRate(currency);
    final totalTokenValue =
        currency.fromDouble(totalUsdValue.value * usdToTokenRate);
    const useableTokenValueFudgeFactor = 0.98;
    final useableTokenValue =
        totalTokenValue.subtract(gasCost) * useableTokenValueFudgeFactor;

    // TODO: We currently have no way of knowing if the account exists.
    // TODO: As a placeholder we will just always allocate a fraction to escrow.
    // Set escrow
    const escrowPercentage = 0.1;
    final escrowMax = currency.fromDouble(USD(0.25).value * usdToTokenRate);
    final escrow = Token.min(useableTokenValue * escrowPercentage, escrowMax);

    log('pac: createFundingTransaction '
        'totalUsdValue = $totalUsdValue, '
        'usdToTokenRate = $usdToTokenRate, '
        'totalTokenValue = $totalTokenValue, '
        'gasCost = gasPrice * gas = $gasPrice * $gas = $gasCost, '
        'useableTokenValueFudgeFactor = $useableTokenValueFudgeFactor, '
        'useableTokenValue = (total - gas) * fudge = $useableTokenValue, '
        'escrow = useableTokenValue * $escrowPercentage capped at $escrowMax = $escrow');

    final txParams = EthereumTransactionParams(
      from: signer,
      to: sellerContractAddress,
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
    required StoredEthereumKey signerKey,
    required EthereumTransactionParams params,
    required int l2Nonce, // The tx nonce
    required int l3Nonce, // The signed edit call nonce
    required BigInt adjust,
    BigInt? warn,
    BigInt? refill,
    BigInt? retrieve,
  }) {
    // defaults
    warn = warn ?? BigInt.zero;
    refill = refill ?? BigInt.one;
    retrieve = retrieve ?? BigInt.zero;

    var amount = params.value;

    // Signed params args to the seller edit call
    var packedEditParams = hex.decode(packedAbiEncodedEditParams(
      chainId: params.chainId,
      l3Nonce: l3Nonce,
      amount: amount,
      adjust: adjust,
      warn: warn,
      retrieve: retrieve,
      refill: refill,
    ));
    var sig = Web3DartUtils.web3Sign(
        keccak256(Uint8List.fromList(packedEditParams)), signerKey);

    // The abi encoded seller edit call tx data
    var encodedSellerEditCall = abiEncodeSellerEdit(
        signer: signerKey.address,
        signature: sig,
        l3Nonce: l3Nonce,
        adjust: adjust,
        warn: warn,
        retrieve: retrieve,
        refill: refill);

    // The pac server transaction with encoded pac seller edit call
    var tx = EthereumTransaction(
      params: params,
      data: encodedSellerEditCall,
      nonce: l2Nonce,
    );
    log('pac: pac seller, unsigned tx = ${tx.toJson()}');

    return tx;
  }

  /// Render the transaction to an eip-191 string and sign it.
  // 0x19 + 'Ethereum Signed Message:\n' + len(message)
  static MsgSignature signTransactionString(
      String txString, StoredEthereumKey signerKey) {
    var msg = '\x19' +
        'Ethereum Signed Message:\n' +
        txString.length.toString() +
        txString;
    log('pac: signTransactionString: msg = $msg');

    var encoded = utf8.encode(msg);
    Uint8List uint8list = Uint8List.fromList(encoded);
    return Web3DartUtils.web3Sign(keccak256(uint8list), signerKey);
  }

  /*
    function edit(
      address signer,
      uint8 v, bytes32 r, bytes32 s,
      uint64 nonce, int256 adjust, int256 warn, uint256 retrieve, uint256 refill) external payable {
   */
  static String abiEncodeSellerEdit({
    required EthereumAddress signer,
    required MsgSignature signature,
    required int l3Nonce,
    required BigInt adjust,
    required BigInt warn,
    BigInt? retrieve,
    BigInt? refill,
  }) {
    log("pac: return '0x' +"
            "editMethodHash = $editMethodHash" +
        '\n' +
        "AbiEncode.address(signer) = ${AbiEncode.address(signer)}" +
        '\n' +
        "AbiEncode.uint8(signature.v) = ${AbiEncode.uint8(signature.v)}" +
        '\n' +
        "AbiEncode.bytes32(signature.r) = ${AbiEncode.bytes32(signature.r)}" +
        '\n' +
        "AbiEncode.bytes32(signature.s) = ${AbiEncode.bytes32(signature.s)}" +
        '\n' +
        "AbiEncode.uint64(BigInt.from(nonce)) = ${AbiEncode.uint64(BigInt.from(l3Nonce))}" +
        '\n' +
        "AbiEncode.int256(adjust) = ${AbiEncode.int256(adjust)}" +
        '\n' +
        "AbiEncode.int256(warn) = ${AbiEncode.int256(warn)}" +
        '\n' +
        "AbiEncode.uint256(retrieve ?? BigInt.zero) = ${AbiEncode.uint256(retrieve ?? BigInt.zero)}" +
        '\n' +
        "AbiEncode.uint256(refill ?? BigInt.one) = ${AbiEncode.uint256(refill ?? BigInt.one)}" +
        '\n');

    return '0x' +
        editMethodHash +
        AbiEncode.address(signer) +
        AbiEncode.uint8(signature.v) +
        AbiEncode.bytes32(signature.r) +
        AbiEncode.bytes32(signature.s) +
        AbiEncode.uint64(BigInt.from(l3Nonce)) +
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
    required int chainId,
    required int l3Nonce,
    EthereumAddress? token,
    required BigInt amount,
    required BigInt adjust,
    required BigInt warn,
    required BigInt retrieve,
    required BigInt refill,
  }) {
    log("pac: packedAbiEncodedEditParams:\n"
            "AbiEncodePacked.bytes1(0x19) = ${AbiEncodePacked.bytes1(0x19)}\n" +
        "AbiEncodePacked.bytes1(0x00) = ${AbiEncodePacked.bytes1(0x00)}\n" +
        "AbiEncodePacked.address(pacSellerAddress) = ${AbiEncodePacked.address(sellerContractAddress)}\n" +
        "AbiEncodePacked.uint256(BigInt.from(chainId)) = ${AbiEncodePacked.uint256(BigInt.from(chainId))}\n" +
        "AbiEncodePacked.uint64(BigInt.from(l3Nonce)) = ${AbiEncodePacked.uint64(BigInt.from(l3Nonce))}\n" +
        "AbiEncodePacked.address(token ?? EthereumAddress.zero) = ${AbiEncodePacked.address(token ?? EthereumAddress.zero)}\n" +
        "AbiEncodePacked.uint256(amount) = ${AbiEncodePacked.uint256(amount)}\n" +
        "AbiEncodePacked.int256(adjust) = ${AbiEncodePacked.int256(adjust)}\n" +
        "AbiEncodePacked.int256(warn) = ${AbiEncodePacked.int256(warn)}\n" +
        "AbiEncodePacked.uint256(retrieve) = ${AbiEncodePacked.uint256(retrieve)}\n" +
        "AbiEncodePacked.uint256(refill) = ${AbiEncodePacked.uint256(refill)}\n");

    var encoded = '' +
        AbiEncodePacked.bytes1(0x19) +
        AbiEncodePacked.bytes1(0x00) +
        AbiEncodePacked.address(sellerContractAddress) +
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
  static Future<int> getL3Nonce({required Chain chain, required EthereumAddress signer}) async {
    var params = [
      {
        'to': '$sellerContractAddress',
        'data': '0x$readMethodHash${AbiEncode.address(signer)}'
      },
      'latest'
    ];
    String result =
        await EthereumJsonRpc.ethCall(url: chain.providerUrl, params: params);
    var buff = HexStringBuffer(result);
    var nonce = buff.takeUint256().toUnsigned(64).toInt();
    log('pac: getL3Nonce result = $result, nonce = $nonce');
    return nonce;
  }
}
