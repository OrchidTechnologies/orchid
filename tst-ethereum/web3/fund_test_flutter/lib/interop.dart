@JS() // sets the context, in this case being `window`
library main; // required library declaration
import 'package:js/js.dart';

typedef Callback<T> = void Function(T arg);

@JS()
class Promise<T> {
  external Promise<T> then(Callback<T> successCallback, [Function errorCallback]);
  external Promise<T> catchIt(Function errorCallback);
}

