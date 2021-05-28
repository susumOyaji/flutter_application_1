import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/Clipper.dart';
import 'shared_prefs.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'dart:io';
import 'MarketStandard.dart';
import 'PortFolio.dart';
//import 'maining.dart';
import 'package:intl/intl.dart';
import 'icons.dart';

//Shift + Alt + F
//6758,200,1665
//6976,300,1801
//4755,400,1137
//
//void main() async {
//debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
//  runApp(MyApp1());
//}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false, // <- Debug の 表示を OFF
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride =
        TargetPlatform.android; // ←　Linux/Windowsデスクトップ向けはこれが必要！
  } else if (Platform.isFuchsia) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  /*
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
  */
}

//カンマ区切り文字列を整数に変換
int toIntger(String char) {
  String row = "";
  List<String> sp = char.split(",");

  if (char == "---") return 0;
  for (int i = 0; i < (sp.length); ++i) {
    row += sp[i];
  }

  int num = int.parse(row);
  return num;
}

String separation(int number) {
  final matcher = new RegExp(r'(\d+)(\d{3})');

  String first_part = number.toString();
  while ((first_part).contains(matcher)) {
    first_part =
        (first_part.replaceAllMapped(matcher, (m) => '${m[1]},${m[2]}'));
  }
  debugPrint('separation-out: $first_part');
  return first_part;
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List widgets = []; // new List<Price>.filled(1, Price());

  ////////////////////////////////
  List<String> codeItems = []; //codekey
  List<String> stockItems = []; //stock
  List<String> valueItems = []; //value
  List<String> benefits = []; //損益
  //List<String> stdcodeItems = ['998407.O', '^DJI']; //Nikkei And Dw

  List<String> acquiredAssetsItems = []; //取得資産 stock x value
  List<String> valuableAssetsItems = []; //評価資産 stock X presentvalue
  String acquiredAssetsSumString = '0';
  String valuableAssetsSumString = '0';
  int acquiredAssetsSum = 0; //取得資産合計
  int valuableAssetsSum = 0; //評価資産合計

  String valueSum = '';
  String presentvalueSUm = '';
  String openTime = '';

  bool _validateCode = false;
  bool _validateStock = false;
  bool _validateValue = false;

  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController valueCtrl = TextEditingController();

  static List<String> dow_responce = []; //dow propaty
  static List<String> nikkei_responce = []; //dow propaty

  static List<String> code = []; //
  static List<String> presentvalue = []; //現在値
  static List<String> changePriceRate = []; //前日比%
  static List<String> changePriceValue = []; //前日比¥
  static List<bool> signalstate = []; //Each to Up and Down
  static List<bool> percentcheng = [];
  DateTime now = DateTime.now();
  String currentmonth = DateFormat('\n EEE d MMM\n').format(DateTime
      .now()); //DateFormat('kk:mm:ss \n EEE d MMM').format(now);//DateTime.now().month.toString();

  //int count;
  static bool isUpDown = false;
  String codename = ''; //="Null to String";
  int intprice = 0;
  int index = 0;
  //bool purchase = false;
  String stringprice = "";
  String gain = "0";
  bool _active = false;

  void _init() async {
    await SharePrefs.setInstance();

    codeItems = SharePrefs.getCodeItems();
    stockItems = SharePrefs.getStockItems();
    valueItems = SharePrefs.getValueItems();
    acquiredAssetsItems = SharePrefs.getacquiredAssetsItems(); //取得資産
    valuableAssetsItems = SharePrefs.getvaluableAssetsItems();
  }

  @override
  void initState() {
    Timer.periodic(const Duration(minutes: 1), _timer);

    _init();
    super.initState();
    /*
    Timer(
        Duration(seconds: 3),
        () => Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen())));
    */
    _setTargetPlatformForDesktop();
    reload1();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getBody() {
    if (showLoadingDialog()) {
      return getProgressDialog();
    } else {
      return setupDisp();
    }
  }

  getProgressDialog() {
    return new Center(child: new CircularProgressIndicator());
  }

  showLoadingDialog() {
    if (widgets.length == 0) {
      return true;
    }
    return false;
  }

  setupDisp() {
    return base();
  }

  void _timer(Timer timer) {
    reload();
  }

  void reload() async {
    reload1();
    base();
  }

  void reload1() async {
    //await fetch(stdcodeItems);
    dow_responce = [];
    nikkei_responce = [];
    //dow_responce = await get_dowhtmls();
    nikkei_responce = await get_nikkeihtmls();

    if (!codeItems.isEmpty) {
      await fetch(codeItems);
    }

    setState(() {
      widgets = dow_responce; //codeItems; // widgets;
    });
  }

  /*
  void _showScaffold(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
  
  void _changeSwitch(bool e) => setState(() => _active = e);
  */

  //*************************************** */
  //
  Future get_dowhtmls() async {
    List<String> dow = [];

    //var url = Uri.parse('https://finance.yahoo.co.jp/quote/%5EDJI');
    //var response = await http.post(url);

    //final uri = Uri.https(
    //    'https://finance.yahoo.co.jp/quote/%5EDJI', 'api/public/user');
    
    var url =
      Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});

  // Await the http get response, then decode the json-formatted response.
  var response = await http.get(url);


    //final response = await http.get(Uri.parse('https://finance.yahoo.co.jp/quote/%5EDJI')); //^DJI
    //print('Response body: ${response.body}');

    String json = response.body;

    RegExp changePriceRate = RegExp(r'<span class="_3BGK5SVf">.*?</span>');

    List<String> changepriceRate = changePriceRate
        .allMatches(json)
        .map((match) => match.group(0))
        .toList()
        .cast();

    List<String> tmp = [];
    for (int i = 0; i < changepriceRate.length; i++) {
      tmp.add(changepriceRate[i].replaceAll(RegExp("_3BGK5SVf"), ""));
    }

    for (int i = 0; i < 3; i++) {
      dow.add(tmp[i].replaceAll(RegExp("[^-+0-9,.]"), ""));
    }

    RegExp regpola = RegExp(r'<span class="_3HWBPedk"><span>.*?</span>');
    List<String> pola =
        regpola.allMatches(json).map((match) => match.group(0)).toList().cast();
    String sig = pola[0].replaceAll(RegExp("[^-+]"), "");
    dow[1] = sig + dow[1];
    dow[2] = sig + dow[2];
    RegExp ing = RegExp(r'\+');
    String sigpola = ing.hasMatch(sig).toString();
    dow.add(sigpola);

    print("Return Dow: $dow");
    return dow;
  }

  Future get_nikkeihtmls() async {
    List<String> nikkei = [];

    //final response = await http
    //    .get('https://stocks.finance.yahoo.co.jp/stocks/detail/?code=998407.O');
    final response = await http.get(Uri.parse(
        'https://stocks.finance.yahoo.co.jp/stocks/detail/?code=998407.O')); //^DJI
    //print('Response body: ${response.body}');
    String json = response.body;

    RegExp regExp = RegExp(r'> --.*?<');
    openTime = regExp.stringMatch(json).toString(); //name
    openTime = openTime.replaceAll("> --", "");
    openTime = openTime.replaceAll("<", "");
    debugPrint("OpenTime:" + openTime);

    RegExp regprice = RegExp(r'<td class=".*?</td>');
    List<String> price = regprice
        .allMatches(json)
        .map((match) => match.group(0))
        .toList()
        .cast();

    List<String> tmp = [];
    for (int i = 0; i < 2; i++) {
      tmp.add(price[i].replaceAll(RegExp(r'[^-+0-9,.（%]'), ""));
    }

    List tmp1 = tmp[1].split('（');
    for (int i = 0; i < 2; i++) {
      tmp1.add(tmp[i].replaceAll(RegExp(r'[^-+0-9,.%]'), ""));
    }

    String sig = tmp1[1].replaceAll(RegExp("[^-+]"), "");
    RegExp ing = RegExp(r'\+');
    String sigpola = ing.hasMatch(sig).toString();

    nikkei.add(tmp[0]);
    nikkei.add(tmp1[0]);
    nikkei.add(tmp1[1]);
    nikkei.add(sigpola);
    print("Return Nikkei: $nikkei");
    return nikkei;
  }

  Future fetch(List<String> items) async {
    index = 0;
    acquiredAssetsSum = 0;
    valuableAssetsSum = 0;

    acquiredAssetsItems = [];
    valuableAssetsItems = [];
    code = [];
    presentvalue = [];
    changePriceValue = [];
    changePriceRate = [];
    benefits = [];
    signalstate = [];
    percentcheng = [];

    //List<String> responce = items; //"998407.O,0,0\n^DJI,0,0\n";

    for (String item in items) {
      //final response =
      //    await http.get("https://finance.yahoo.co.jp/quote/$item");
      //final response = await http.get(
      //    "https://stocks.finance.yahoo.co.jp/stocks/detail/?code=998407.O");

      final response = await http
          .get(Uri.parse('https://finance.yahoo.co.jp/quote/$item')); //^DJI
      final String json = response.body;

      String codename;
      RegExp regExp = RegExp(r'<title>.+【');
      codename = regExp.stringMatch(json).toString(); //name
      codename = codename.replaceAll("<title>", "");

      List<String> valuelist = [];

      RegExp regPrice = RegExp(r'<span class="_3rXWJKZF">.*?</span>'); //現在値
      List<String> price = regPrice
          .allMatches(json)
          .map((match) => match.group(0))
          .toList()
          .cast();

      List<String> tmp = [];
      for (int i = 0; i < price.length; i++) {
        tmp.add(price[i].replaceAll(RegExp("_3rXWJKZF"), ""));
      }

      for (int i = 0; i < 3; i++) {
        valuelist.add(tmp[i].replaceAll(RegExp("[^-+0-9,.]"), ""));
      }

      String value = valuelist[0];

      debugPrint("StockPrice : " + value);
      //debugPrint("string to int : " + intprice.toString());
      debugPrint("hasMatch : " + regExp.hasMatch(json).toString());

      regExp = RegExp(r'[+-][0-9]{1,}'); //時価（小数点なし）
      String changevalue = valuelist[1];
      debugPrint("Changevalue : " + changevalue);
      debugPrint("Changevalue : " + regExp.hasMatch(json).toString());

      String changerate = valuelist[2]; //前日比%

      code.add(codename.replaceAll("【", ""));
      debugPrint("code-name : " + code[index]);

      if (value == "null" || value == "---") {
        value = "0";
      }
      presentvalue.add(value);
      debugPrint("code-presentValue : " + presentvalue[index]);

      if (changerate == "null" || changerate == "---") {
        changerate = "0";
      }

      changePriceRate.add(changerate);
      debugPrint("code-changePriceRate : " + changePriceRate[index]);

      changevalue = changevalue;
      changePriceValue.add(changevalue);
      debugPrint("code-changePriceValue : " + changePriceValue[index]);

      debugPrint("Change : " + regExp.hasMatch(json).toString());
      debugPrint("ChangeValue: " + regExp.hasMatch(json).toString());

      acquiredAssetsItems.add(
          (int.parse(stockItems[index]) * int.parse(valueItems[index]))
              .toString()); //取得資産
      try {
        valuableAssetsItems.add((int.parse(value.replaceAll(",", "")) *
                int.parse(stockItems[index]))
            .toString()); //評価資産
      } catch (exception) {
        valuableAssetsItems.add("0");
      }

      // setState(() {
      acquiredAssetsSum =
          acquiredAssetsSum + int.parse(acquiredAssetsItems[index]); //取得資産合計
      valueSum = separation(acquiredAssetsSum); //insert ','
      acquiredAssetsSumString = (valueSum.toString());

      valuableAssetsSum =
          valuableAssetsSum + int.parse(valuableAssetsItems[index]); //評価資産
      presentvalueSUm = separation(valuableAssetsSum);
      valuableAssetsSumString = (presentvalueSUm.toString());

      gain = separation(valuableAssetsSum - acquiredAssetsSum); //損益
      // });

      if (valuableAssetsSum < acquiredAssetsSum) {
        //Investment損益シグナル
        isUpDown = false;
      } else {
        isUpDown = true;
      }

      var sel = int.parse(presentvalue[index].replaceAll(",", "")) -
          int.parse(valueItems[index]);
      benefits.add(separation(sel));
      index++;

      percentcheng.add(false);

      String sig = price[1].replaceAll(RegExp("[^-+]"), "");
      RegExp ing = RegExp(r'\+');
      String signal = ing.hasMatch(sig).toString();

      if (signal == "false") {
        signalstate.add(false);
        debugPrint("Green-Down"); //Down
      } else {
        signalstate.add(true);
        debugPrint("Red-Up"); //Up
      }
      debugPrint("Signal : " + signal);

      //count++;
    } //for
  }

////////////////////////////////////////////////////

  GridView gridView() => new GridView.builder(
      scrollDirection: Axis.vertical,
      itemCount: codeItems.length, //+20,//<-- setState()
      gridDelegate:
          new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) {
        return new GestureDetector(
          child: new Card(
            margin: const EdgeInsets.all(5.0),
            color: Colors.grey[850],
            elevation: 5.0,
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        top: 0.0, right: 0.0, bottom: 0.0, left: 50.0),
                    child: InkWell(
                      onTap: () {
                        _deleteCard(index);
                        debugPrint("index No:${index}to Delet clicked");
                      },
                      child: Icon(
                        Icons.delete,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Text(
                    "(${codeItems[index]}) " + "${code[index + 2]}",
                    style: TextStyle(
                        fontFamily: 'Roboto-Thin',
                        fontSize: 8.0,
                        color: Colors.orange),
                  ),
                  Text(
                    "Present ${presentvalue[index + 2]}",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 8.0,
                        color: Colors.blue),
                  ),
                  Text(
                    "Profit　${benefits[index]}",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 8.0,
                        color: Colors.yellow),
                  ),
                  Text(
                    "Loss　${separation(int.parse(valuableAssetsItems[index]))}",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 8.0,
                        color: Colors.orange),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: 8.0, right: 0.0, bottom: 0.0, left: 0.0),
                    child: SizedBox(
                      height: 15.0,
                      width: 65.0,
                      child: RaisedButton(
                        padding: EdgeInsets.all(0.0),
                        disabledColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2.0)),
                        ),
                        color:
                            signalstate[index + 2] ? Colors.red : Colors.green,
                        child: new Text(
                          signalstate[index]
                              ? '${changePriceValue[index + 2]}'
                              : '${changePriceRate[index + 2]}',
                          style: TextStyle(fontSize: 8.0, color: Colors.black),
                        ),
                        onPressed: () => setState(() {
                          //widgets[index].percentcheng = !widgets[index].percentcheng;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });

  //////////////////////////////////////////////////////////////////////

  ListView listView() => ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: codeItems.length, //+20,//<-- setState()
      //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          child: Container(
              margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    //Color(0xffb43af7),
                    //Color(0x0B52067),
                    //Color(0xff6d2af7),
                    Colors.black,
                    Colors.grey.shade800,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  //mainAxisSize: MainAxisSize.max,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    //Column(
                    //mainAxisAlignment: MainAxisAlignment.start,
                    //mainAxisSize: MainAxisSize.min,
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    // children:<Widget>[
                    Expanded(
                      flex: 2,
                      child:
                          //Padding(
                          //  padding: EdgeInsets.only(top: 0.0, right: 0.0, bottom: 0.0, left: 0.0),

                          //child:
                          RaisedButton(
                        child: Text("${codeItems[index]}",
                            style:
                                TextStyle(fontSize: 10.0, color: Colors.grey)),
                        color: Colors.purple,
                        shape: CircleBorder(
                            /*
                          side: BorderSide(
                            color: Colors.black,
                            width: 0.0,
                            style: BorderStyle.solid,
                          ),
                          */
                            ),
                        onPressed: () {
                          _asyncEditDialog(context, index);
                        },
                        onLongPress: () {
                          alertDialog(index);
                        },
                      ),

                      /*
                          FloatingActionButton(
                        mini: true,
                        child: Text("${codeItems[index]}",
                            style:
                                TextStyle(fontSize: 10.0, color: Colors.grey)),
                        backgroundColor: Colors.purple,
                        onPressed: () {
                          _asyncEditDialog(context, index);
                        },
                         
                      ),
                      */
                      //),
                    ),

                    //  ]
                    // ),

                    //SizedBox(width: 15.0,),
                    Expanded(
                      flex: 6,
                      child: Column(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        //mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "${code[index]}",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            strutStyle: StrutStyle(
                              fontSize: 10.0,
                              height: 2.0,
                            ),
                          ),
                          Text("Market  ${presentvalue[index]}",
                              style: TextStyle(
                                  //fontFamily: 'Roboto',
                                  fontSize: 12.0,
                                  color: Colors.blue),
                              textAlign: TextAlign.left),
                          Text(
                            "Benefits　${benefits[index]}",
                            style: TextStyle(
                                //fontFamily: 'Roboto',
                                fontSize: 12.0,
                                color: Colors.yellow),
                          ),
                          Text(
                            "Evaluation ${separation(int.parse(valuableAssetsItems[index]))}",
                            style: TextStyle(
                                //fontFamily: 'Roboto',
                                fontSize: 12.0,
                                color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                    //SizedBox(width: 50.0,),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 0.0, right: 0.0, bottom: 0.0, left: 0.0),
                        //child: //SizedBox(
                        //height: 30.0,
                        //width: 60.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(0.0),
                          disabledColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(2.0)),
                          ),
                          color: signalstate[index] ? Colors.red : Colors.green,
                          child: Text(
                            percentcheng[index] //signalstate[index]
                                ? '${changePriceRate[index]}'
                                : '${changePriceValue[index]}',
                            style:
                                TextStyle(fontSize: 13.0, color: Colors.black),
                          ),
                          onPressed: () => setState(() {
                            percentcheng[index] = !percentcheng[index];
                          }),
                        ),
                        //),
                      ),
                    ),
                  ])),
        );
      });

  void alertDialog(int _index) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Check"),
          content: Text("${code[_index]}" + " to Can I delete it?"),
          actions: <Widget>[
            // ボタン領域
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
                child: Text("OK"),
                onPressed: () {
                  _deleteCard(_index);
                  Navigator.pop(context);
                } //Navigator.pop(context),
                ),
          ],
        );
      },
    );
  }

  void _deleteCard(int _index) {
    setState(() {
      codeItems.removeAt(_index);
      stockItems.removeAt(_index);
      valueItems.removeAt(_index);
      SharePrefs.setCodeItems(codeItems);
      SharePrefs.setStockItems(stockItems);
      SharePrefs.setValueItems(valueItems);
    });
  }

  Future _asyncInputDialog(BuildContext context) async {
    showDialog<String>(
      context: context,
      barrierDismissible:
          false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey,
          title: Text('Enter an investment estimate'),
          content: Column(
            children: <Widget>[
              Expanded(
                  child: TextField(
                      controller: codeCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Code Namber',
                          hintText: 'Enter the number of 4 digits'),
                      onSubmitted: (text) {
                        if (text.isEmpty) {
                          _validateCode = true;
                          setState(() {});
                        } else {
                          _validateCode = false;
                          codeItems.add(text);
                          codeCtrl.clear();
                        }
                      })),
              Expanded(
                  child: TextField(
                controller: stockCtrl,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: 'Stock', hintText: 'Enter the number of shares'),
                onSubmitted: (text) {
                  if (text.isEmpty) {
                    _validateStock = true;
                    //setState(() {});
                  } else {
                    _validateStock = false;
                    stockItems.add(text);
                    SharePrefs.setStockItems(stockItems).then((_) {
                      //setState(() {});
                    });
                    stockCtrl.clear();
                  }
                },
              )),
              Expanded(
                  child: TextField(
                      controller: valueCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Value',
                          hintText: 'Enter the amount acquired per share'),
                      onChanged: (value) {
                        //teamName = value;
                      },
                      onSubmitted: (text) {
                        //TextFieldからの他のコールバック
                        if (text.isEmpty) {
                          _validateValue = true;
                          setState(() {});
                        } else {
                          _validateValue = false;
                          valueItems.add(text);
                          SharePrefs.setValueItems(valueItems).then((_) {
                            setState(() {});
                          });
                          valueCtrl.clear();
                        }
                      }))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                if (/*eCtrl.text.isEmpty ||*/ codeCtrl.text.isEmpty ||
                    stockCtrl.text.isEmpty ||
                    valueCtrl.text.isEmpty) {
                  //if (eCtrl.text.isEmpty) _validate = true;
                  if (codeCtrl.text.isEmpty) _validateCode = true;
                  if (stockCtrl.text.isEmpty) _validateStock = true;
                  if (valueCtrl.text.isEmpty) _validateValue = true;
                  setState(() {});
                } else {
                  _validateCode = false;
                  _validateStock = false;
                  _validateValue = false;
                  codeItems.add(codeCtrl.text);
                  stockItems.add(stockCtrl.text);
                  valueItems.add(valueCtrl.text);
                  SharePrefs.setCodeItems(codeItems);
                  SharePrefs.setStockItems(stockItems);
                  SharePrefs.setValueItems(valueItems);
                  //setState(() {
                  //(codeCtrl.text);

                  //});

                  codeCtrl.clear();
                  stockCtrl.clear();
                  valueCtrl.clear();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future _asyncEditDialog(BuildContext context, int index) async {
    final TextEditingController _codeFieldController =
        TextEditingController(text: codeItems[index]);
    final TextEditingController _stackFieldController =
        TextEditingController(text: stockItems[index]);
    final TextEditingController _valueFieldController =
        TextEditingController(text: valueItems[index]);

    showDialog<String>(
      context: context,
      barrierDismissible:
          false, // dialog is dismissible with a tap on the barrier

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey,
          title: Text('Edit an investment Data'),
          content: Column(
            children: <Widget>[
              Expanded(
                  child: TextField(
                      controller: _codeFieldController,
                      //autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Code : ',
                          border: OutlineInputBorder(),
                          hintText: 'If you want to change it, enter a value'),
                      onSubmitted: (text) {
                        debugPrint(text);
                        if (text.isEmpty) {
                          _validateCode = true;
                          setState(() {});
                        } else {
                          _validateCode = false;
                          codeItems[index] = text;
                          SharePrefs.setStockItems(codeItems).then((_) {
                            setState(() {
                              codeCtrl.clear();
                            });
                          });
                          //codeCtrl.clear();
                        }
                      })),
              Expanded(
                  child: TextField(
                controller: _stackFieldController,
                //autofocus: true,
                decoration: InputDecoration(
                    labelText: 'Stock : ',
                    border: OutlineInputBorder(),
                    hintText: 'If you want to change it, enter a value'),
                onSubmitted: (text) {
                  if (text.isEmpty) {
                    setState(() {
                      _validateStock = true;
                    });
                  } else {
                    _validateStock = false;
                    stockItems[index] = text;
                    SharePrefs.setStockItems(stockItems).then((_) {
                      setState(() {
                        stockCtrl.clear();
                      });
                    });
                    //stockCtrl.clear();
                  }
                },
              )),
              Expanded(
                  child: TextField(
                      controller: _valueFieldController,
                      //autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Value : ',
                          border: OutlineInputBorder(),
                          hintText: 'If you want to change it, enter a value'),
                      onSubmitted: (text) {
                        //TextFieldからの他のコールバック
                        if (text.isEmpty) {
                          _validateValue = true;
                          setState(() {});
                        } else {
                          _validateValue = false;
                          valueItems[index] = text;
                          SharePrefs.setValueItems(valueItems).then((_) {
                            setState(() {
                              valueCtrl.clear();
                            });
                          });
                          valueCtrl.clear();
                        }
                      }))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Return'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  todayDate() {
    //new DateFormat.M();
    var now = new DateTime.now();
    var formatter = new DateFormat('LLLLL-yyyy');
    String formattedTime = DateFormat('kk:mm:a').format(now);
    String formattedDate = formatter.format(now);
    //String formattedMouth = new DateFormat.M();
    debugPrint(formattedTime);
    debugPrint(formattedDate);
    //debugPrint(formattedMouth);
  }

  Widget base() {
    return Column(
      children: <Widget>[
        Container(
          //width: 280,
          margin: EdgeInsets.all(0.0),
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          child: Stack(
            children: <Widget>[
              Container(
                  padding: EdgeInsets.all(10),
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: SafeArea(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(
                            child: ClipPath(
                              clipper: MyCustomClipper(),
                              child: Container(
                                  //margin: EdgeInsets.only(top: 0.0, right: 0.0),
                                  padding: EdgeInsets.only(
                                      top: 0.0,
                                      left: 20.0,
                                      right: 0.0,
                                      bottom: 10.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        //Color(0xffb43af7),
                                        //Color(0x0B52067),
                                        Colors.white,
                                        //Colors.grey[800],
                                        Colors.grey.shade800,

                                        //Color(0xff6d2af7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    //mainAxisAlignment: MainAxisAlignment.start,
                                    //mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Column(
                                        //mainAxisAlignment: MainAxisAlignment.start,
                                        //mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Stocks",
                                            style: TextStyle(
                                              fontSize: 30.0,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(top: 10.0, right: 0.0),
                              padding: EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    //Color(0xffb43af7),
                                    //Color(0x0B52067),
                                    Colors.black,
                                    Colors.grey.shade800,

                                    //Color(0xff6d2af7),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                //mainAxisAlignment: MainAxisAlignment.start,
                                //mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.trending_up,
                                    size: 42,
                                    color: Colors.grey,
                                  ),
                                  Column(
                                    //mainAxisAlignment: MainAxisAlignment.start,
                                    //mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      /*
                                      Text(
                                        "Future Vaiue",
                                        style: TextStyle(
                                          fontSize: 30.0,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),*/

                                      MaketStandard(
                                          dow_Value: dow_responce,
                                          nikkei_Value: nikkei_responce),
                                    ],
                                  ),
                                ],
                              )),
                          Container(
                              margin: EdgeInsets.only(
                                  top: 10.0, right: 0.0, bottom: 0.0),
                              padding: EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    //Color(0xffb43af7),
                                    //Color(0x0B52067),
                                    Colors.black,
                                    Colors.grey.shade800,

                                    //Color(0xff6d2af7),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    openTime,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )),
                          GestureDetector(
                            child: Container(
                                margin: EdgeInsets.only(top: 5.0, right: 0.0),
                                padding: EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      //Color(0xffb43af7),
                                      //Color(0x0B52067),
                                      //Color(0xff6d2af7),
                                      Colors.black,
                                      Colors.grey.shade800,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                    //mainAxisAlignment: MainAxisAlignment.start,
                                    //mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        MyFlutterApp.yen,
                                        //Icons.attach_money,
                                        size: 35,
                                        color: Colors.grey,
                                      ),
                                      Column(
                                        //mainAxisAlignment: MainAxisAlignment.start,
                                        //mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Market capitalization", //"Investment",
                                            style: TextStyle(
                                              fontSize: 20.0,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          PortFolio(
                                            portassetPrice:
                                                valuableAssetsSumString, //presentvalueSUm,
                                            portassetTotal:
                                                acquiredAssetsSumString, //valueSum,
                                            portassetvalue: gain,
                                            signal: isUpDown,
                                          ),
                                        ],
                                      ),
                                    ])),
                          ),
                        ]),
                  )),
              Positioned(
                left: 150.0,
                top: 4.0,
                child: Text(currentmonth /*+ '  ' + now.month.toString()*/,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: 5.0,
                top: 10.0,
                child: ClipOval(
                  child: Material(
                    color: Colors.orange, // button color
                    child: InkWell(
                      splashColor: Colors.red, // inkwell color
                      child: SizedBox(
                          width: 45, height: 45, child: Icon(Icons.autorenew)),
                      onTap: () {
                        reload();
                      },
                    ),
                  ),
                ),
              ),
              //Positioned(
              //  right: 0.0,
              //  top: 10.0,
              //  child: CountDownTimer(),
              //),
              Positioned(
                right: 5.0,
                bottom: 35.0,
                child: IconButton(
                  icon: Icon(Icons.grain),
                  color: Colors.blueGrey,
                  iconSize: 40,
                  onPressed: () {
                    _asyncInputDialog(context);
                    //todayDate();

                    //Navigator.push(
                    //    context,
                    //    MaterialPageRoute(
                    //        builder:
                    //            (context) => /*Stocks(codeItems: codeItems,stockItems:stockItems,valueItems:valueItems)));*/ NewRoutePage()));
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            //color: Colors.black54,
            child: listView(), //gridView1(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF02BB9F),
        primaryColorDark: const Color(0xFF167F67),
        accentColor: const Color(0xFF02BB9F),
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        //Color.fromARGB(0xFF, 0x04, 0x5B, 0x5B), //008A83//Colors.grey,
        //appBar: new AppBar(
        //  title: new Text("widget.title"),
        //),

        body: SafeArea(
          child: getBody(),
          //floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }
}
