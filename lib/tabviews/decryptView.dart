import 'dart:convert';

import 'package:CipherMonkey/en-de-crypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';
import 'package:CipherMonkey/model.dart';

class DecryptView extends StatefulWidget {
  DecryptView({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DecryptViewState createState() => _DecryptViewState();
}

class _DecryptViewState extends State<DecryptView> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  String plainText = "";
  String from = "";
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //    DefaultTabController.of(context).animateTo(0);
    return SingleChildScrollView(
        //controller: controller,
        child: Form(
            key: _formKey,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      fillColor: Colors.amberAccent,
                      filled: true,
                      border: OutlineInputBorder(),
                      hintText: 'Password',
                    ),
                    validator: (value) {
                      Pattern pattern = r'^.{6,20}$';
                      RegExp regex = new RegExp(pattern);
                      if (!regex.hasMatch(value.trim())) {
                        return 'Password is 6~20';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                  ),
                  RaisedButton(
                    child: Text('Decrypt From Clipboard',
                        style: TextStyle(color: Colors.white)),
                    color: Colors.blue,
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        final String password = passwordController.text;
                        ClipboardData clipboard =
                            await Clipboard.getData("text/plain");
                        String encryptText;
                        try {
                          //1 base64解码
                          encryptText = String.fromCharCodes(base64Decode(
                              clipboard.text
                                  .replaceAll(new RegExp(r'\[.+\]'), "")
                                  .trim()));
                        } catch (e) {
                          Toast.show(
                              "Clipboard Text Can't be Decrypt!!", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.red);
                          return;
                        }

                        final reportTextList = encryptText.split(";");

                        if (reportTextList.length != 3) {
                          Toast.show("Wrong Decrypt Text", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.red);
                          return;
                        }
                        final encryptedKey = reportTextList[0];
                        final sign = reportTextList[1];
                        final encryptedText = reportTextList[2];

                        //2 解码密钥
                        final List<CMKey> prikeys =
                            await DB.queryKeys(type: "private");

                        if (prikeys.length != 1) {
                          Toast.show("PrivateKey error", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.red);
                          return;
                        }
                        //用密码解密私钥
                        var privatekeyPem;
                        try {
                          privatekeyPem = aesDecrypt(prikeys[0].value,
                              base64Encode(md5String(password).codeUnits));
                        } catch (e) {
                          Toast.show("Password is wrong!", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.red);
                          return;
                        }

                        try {
                          //从pem格式转换成私钥对象
                          final privatekey =
                              parsePrivateKeyFromPem(privatekeyPem);
                          //得到密钥
                          final secretKey =
                              rsaDecrypt(privatekey, encryptedKey);

                          //得到文本
                          final reportText =
                              aesDecrypt(encryptedText, secretKey);

                          //检查签名来自哪里
                          List<CMKey> pubkeys =
                              await DB.queryKeys(type: "public");
                          from = "From: Unknow";
                          for (var i = 0; i < pubkeys.length; i++) {
                            final publickey =
                                parsePublicKeyFromPem(pubkeys[i].value);
                            if (rsaVerify(
                                publickey, sha256String(reportText), sign)) {
                              from =
                                  "From: ${pubkeys[i].remark == null ? pubkeys[i].name : pubkeys[i].remark + "(" + pubkeys[i].name + ")"}";

                              break;
                            }
                          }

                          //解压文本。
                          //plainText = zlibDecode(reportText);
                          plainText = reportText;
                        } catch (e) {
                          Toast.show("Decrypt error!!", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.red);
                        }

                        //rsaVerify(publickey, sha256String(reportText), sign);

                        setState(() {});
                      }
                    },
                  ),
                  Divider(
                    thickness: 2,
                    color: Colors.green,
                  ),
                  Text(
                    "🐒 Plain Text 🐒",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "$from",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 5, bottom: 5),
                    padding: EdgeInsets.all(5),
                    decoration: new BoxDecoration(
                      border: new Border.all(
                          color: Colors.blue, width: 1), // 边色与边宽度
                      color: Colors.lightGreen, // 底色
                      // 也可控件一边圆角大��
                    ),
                    child: Text(
                      "$plainText",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  RaisedButton(
                    child: Text('Copy Plain Text to Clipboard',
                        style: TextStyle(color: Colors.white)),
                    color: Colors.green,
                    onPressed: () {
                      if (plainText.length > 0) {
                        Future<void> clipboard =
                            Clipboard.setData(ClipboardData(text: plainText));

                        clipboard.then((noValue) {
                          Toast.show("Copy to Clipboard Successed!!", context,
                              duration: Toast.LENGTH_LONG,
                              gravity: Toast.CENTER,
                              backgroundColor: Colors.blueGrey);
                        });
                      } else {
                        Toast.show("Decrypt first", context,
                            duration: Toast.LENGTH_LONG,
                            gravity: Toast.CENTER,
                            backgroundColor: Colors.red);
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            )));
  }
}
