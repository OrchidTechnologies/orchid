import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: 'Flutter Web3 Example', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  static const OPERATING_CHAIN = 1;

  final wc = WalletConnectProvider.binance();

  Web3Provider web3wc;

  connectProvider() async {
    if (Ethereum.isSupported) {
      final accs = await ethereum.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        currentChain = await ethereum.getChainId();
        // testContract();
      }

      update();
    }
  }

  connectWC() async {
    await wc.connect();
    if (wc.connected) {
      currentAddress = wc.accounts.first;
      currentChain = 56;
      wcConnected = true;
      web3wc = Web3Provider.fromWalletConnect(wc);
    }

    update();
  }

  clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;
    web3wc = null;

    update();
  }

  init() {
    if (Ethereum.isSupported) {
      // connectProvider();

      ethereum.onAccountsChanged((accs) {
        clear();
      });

      ethereum.onChainChanged((chain) {
        clear();
      });
    }
  }

  void testContract() async {
    print("xxx test contract");
    const erc20Abi = [
      // Some details about the token
      "function name() view returns (string)",
      "function symbol() view returns (string)",

      // Get the account balance
      "function balanceOf(address) view returns (uint)",

      // Send some of your tokens to someone else
      "function transfer(address to, uint amount)",

      // An event triggered whenever anyone transfers to someone else
      "event Transfer(address indexed from, address indexed to, uint amount)"
    ];
    var contractAddress = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb';
    var web3 = Web3Provider.fromEthereum(Ethereum.provider);
    var contract = Contract(contractAddress, erc20Abi, web3);
    print("xxx: contract = $contract");
    // call balanceOf function

    var address = '0x405BC10E04e3f487E9925ad5815E4406D78B769e';
    var balance = await contract.call("balanceOf", [address]);
    print("balance = $balance");

    // to make a write transaction, first get the signer (this will use metamask/wallet)
    // contract = contract.connect(web3.getSigner()); // uses the connected wallet as signer

    // then call the function:
    // var res = await promiseToFuture(callMethod(contract, "transfer", [
    //     '0x39C5190c09ec04cF09C782bA4311C469473Ffe83',
    //     "0x" + amount.toString()).toRadixString(16)])
    // );
  }

  getLatestBlock() async {
    // print(await provider.getLastestBlock());
    // print(await provider.getLastestBlockWithTransaction());

    var web3 = Web3Provider.fromEthereum(Ethereum.provider);
    Block block = await web3.getLastestBlock();
    print("xxx: latest block = $block");
  }

  testProvider() async {
    final rpcProvider = JsonRpcProvider('https://bsc-dataseed.binance.org/');
    print(rpcProvider);
    print(await rpcProvider.getNetwork());
  }

  void test() async {
    print("xxx test:");
    testContract();
  }

  testSwitchChain() async {
    await ethereum.walletSwitchChain(97, () async {
      await ethereum.walletAddChain(
        chainId: 97,
        chainName: 'Binance Testnet',
        nativeCurrency:
            CurrencyParams(name: 'BNB', symbol: 'BNB', decimals: 18),
        rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
      );
    });
  }

  @override
  void onInit() {
    init();

    super.onInit();
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (h) => Scaffold(
        body: Center(
          child: Column(children: [
            Container(height: 10),
            Builder(builder: (_) {
              var shown = '';
              if (h.isConnected && h.isInOperatingChain)
                shown = 'You\'re connected!';
              else if (h.isConnected && !h.isInOperatingChain)
                shown = 'Wrong chain! Please connect to BSC. (56)';
              else if (Ethereum.isSupported)
                return OutlinedButton(
                    child: Text('Connect'), onPressed: h.connectProvider);
              else
                shown = 'xYour browser is not supported!';

              return Text(shown,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20));
            }),
            Container(height: 30),
            if (h.isConnected && h.isInOperatingChain) ...[
              TextButton(
                  onPressed: h.getLatestBlock,
                  child: Text('get lastest block')),
              Container(height: 10),
              TextButton(
                  onPressed: h.testProvider,
                  child: Text('test binance rpc provider')),
              Container(height: 10),
              TextButton(onPressed: h.test, child: Text('test')),
              Container(height: 10),
              TextButton(
                  onPressed: h.testSwitchChain,
                  child: Text('test switch chain')),
            ],
            Container(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Wallet Connect connected: ${h.wcConnected}'),
                Container(width: 10),
                OutlinedButton(
                    child: Text('Connect to WC'), onPressed: h.connectWC)
              ],
            ),
            Container(height: 30),
            if (h.wcConnected && h.wc.connected) ...[
              Text(h.wc.walletMeta.toString()),
            ],
          ]),
        ),
      ),
    );
  }
}
