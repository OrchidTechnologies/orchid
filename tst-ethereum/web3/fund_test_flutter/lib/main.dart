@JS() // sets the context, in this case being `window`
library main; // required library declaration

import 'package:flutter_web/material.dart';
import 'package:js/js.dart';
import 'interop.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Orchid'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> accounts = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text( 'Accounts:',
              style: Theme.of(context).textTheme.title,
            ),
            Text(
              '${accounts}',
              style: Theme.of(context).textTheme.body1,
            ),
            SizedBox(height: 24),
            RaisedButton(
              child: Text("Fetch Accounts"),
              onPressed: () {
                getAccounts().then((List<String> arg) {
                  debugPrint("here: accounts: $arg");
                  setState(() {
                    accounts = arg;
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

@JS('getAccounts')
external Promise<List<String>> getAccounts();


