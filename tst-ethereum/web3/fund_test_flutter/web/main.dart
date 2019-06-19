@JS() // sets the context, in this case being `window`
library main; // required library declaration
import 'package:js/js.dart';
import 'package:flutter_web_ui/ui.dart' as ui;
import 'package:flutter_site/main.dart' as app;

main() async {
  await ui.webOnlyInitializePlatform();
  app.main();
  log('Hello world!');
}

@JS('console.log')
external void log(dynamic str);

