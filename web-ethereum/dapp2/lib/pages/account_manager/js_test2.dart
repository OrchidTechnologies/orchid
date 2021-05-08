// @JS('web3') // This puts a "web3." prefix on all calls below?
@JS()
library web3;

import 'package:js/js.dart';

@JS('window.ethereum')
external dynamic get ethereum;
