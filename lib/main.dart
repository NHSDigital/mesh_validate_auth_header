import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

RegExp _numeric = RegExp(r'^[0-9]+$');
RegExp _timestamp = RegExp(r'^[1-9][0-9]{3}(?:0[1-9]|1[0-2])(?:[0-2][0-9]|3[0-1])(?:0[0-9]|1[0-9]|2[0-3])(?:[0-5][0-9])$');

/// check if the string contains only numbers
bool isNumeric(String str) {
  return _numeric.hasMatch(str);
}

bool validTimestamp(String str) {
  return _timestamp.hasMatch(str);
}

final Uri _docsUri = Uri.parse('https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api#api-description__mesh-authorization-header');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NHS Digital MESH auth header validator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Generate or Validate a MESH authorisation header'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  final _paddingEight = const EdgeInsets.symmetric(horizontal: 8, vertical: 8);

  final _mailboxId = TextEditingController();
  final _sharedKey = TextEditingController();
  final _mailboxPassword = TextEditingController();
  final _nonce = TextEditingController();
  final _nonceCount = TextEditingController();
  final _timestamp = TextEditingController();
  final _generatedToken = TextEditingController();
  final _generateForm = GlobalKey<FormState>();

  final _validateToken = TextEditingController();
  final _validateForm = GlobalKey<FormState>();
  String _validationResult = "";
  Color _validationResultColor = Colors.red;


  Future<void> _openApiDocs() async {
    if (!await launchUrl(_docsUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_docsUri';
    }
  }

  Future<void> _clearGenerated(String any) async {
    setState(() {
      _generatedToken.text = "";
    });
  }

  Future<void> _clearValidationResult(String any) async {
    setState(() {
      _validationResult = "";
    });
  }

  Future<void> _generateFormSubmit() async {
    if (_generateForm.currentState!.validate()) {
      String mb = _mailboxId.text;
      String n = _nonce.text;
      String nc = _nonceCount.text;
      String p = _mailboxPassword.text;
      String ts = _timestamp.text;
      String message = "$mb:$n:$nc:$p:$ts";

      List<int> key = utf8.encode(_sharedKey.text);
      Digest digest = Hmac(sha256, key).convert(ascii.encode(message));
      String mac = digest.toString();
      setState(() {
        _generatedToken.text = "NHSMESH $mb:$n:$nc:$ts:$mac";
      });
    }
  }

  Future<void> _validateFormSubmit() async {
    if (_validateForm.currentState!.validate()) {

      setState(() {
        _validationResult = "";
        _validationResultColor = Colors.red;
      });
      String token = _validateToken.text.trim();
      if (!token.startsWith("NHSMESH ")) {
        setState(() {
          _validationResult = "token invalid, missing auth scheme (NHSMESH)\nexpecting: NHSMESH {mailbox_id}:{nonce}:{nonce_count}:{timestamp}:{hmac_hex_digest}";
        });
        return;
      }
      token = token.substring(8);
      List<String> parts = token.split(":");
      if (parts.length<5) {
        setState(() {
          _validationResult = "token invalid, not enough parts\nexpecting: NHSMESH {mailbox_id}:{nonce}:{nonce_count}:{timestamp}:{hmac_hex_digest}";
        });
        return;
      }

      if (parts.length>5) {
        setState(() {
          _validationResult = "token invalid, too many parts\nexpecting: NHSMESH {mailbox_id}:{nonce}:{nonce_count}:{timestamp}:{hmac_hex_digest}";
        });
        return;
      }

      String mb = parts[0];
      String n = parts[1];
      String nc = parts[2];
      String p = _mailboxPassword.text;
      String ts = parts[3];
      String tokenMac = parts[4];

      List<String> errors = [];

      if (mb.isEmpty) {
        errors.add("mailbox_id is empty");
      }

      String mailboxUpper = mb.toUpperCase();
      if (mailboxUpper != mb) {
        errors.add("mailbox_id should be uppercase");
      }
      if (_mailboxId.text!=mb) {
        errors.add("token mailbox does not match your mailbox id");
      }

      if (n.isEmpty) {
        errors.add("nonce is empty");
      }

      if (nc.isEmpty) {
        errors.add("nonce_count is empty");
      }

      if (ts.isEmpty) {
        errors.add("timestamp is empty");
      }

      if (tokenMac.isEmpty) {
        errors.add("hmac_hex_digest is empty");
      }

      if (!validTimestamp(ts)) {
        errors.add("timestamp does not match  yyyyMMddHHmm");
      }

      if (!isNumeric(nc)) {
        errors.add("nonce_count should be numeric");
        return;
      }

      if (errors.isNotEmpty) {
        String errorsStr = errors.join("\n");
        setState(() {
          _validationResult = "token invalid:\n$errorsStr\nexpecting: NHSMESH {mailbox_id}:{nonce}:{nonce_count}:{timestamp}:{hmac_hex_digest}";
        });
        return;
      }


      String message = "$mb:$n:$nc:$p:$ts";

      List<int> key = utf8.encode(_sharedKey.text);
      Digest digest = Hmac(sha256, key).convert(ascii.encode(message));
      String mac = digest.toString();
      if (mac==parts[4]) {
        setState(() {
          _validationResult = "token is valid! and hmac matches mailbox password and shared key";
          _validationResultColor = Colors.green;
        });
        return;
      } else {
        setState(() {
          _validationResult = "token invalid, hmac does not match!\nexpecting: NHSMESH {mailbox_id}:{nonce}:{nonce_count}:{timestamp}:{hmac_hex_digest}";
        });
        return;
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'generate header'),
                Tab(text: 'validate header'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _openApiDocs,
                          child: const Text(
                            'click to open mesh api docs, opens in browser',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          key:  const Key('generate_page'),
                          constraints: const BoxConstraints(minHeight: 100),
                          child: Form(
                            key: _generateForm,
                            child: Column(
                              children: <Widget>[
                                const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    child: Text('generate an auth header')
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('mailbox_id'),
                                    controller: _mailboxId,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'your mesh mailbox id e.g. X2601HC213',
                                      labelText: 'mesh mailbox',
                                    ),
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'mailbox is required';
                                      }
                                      String mailboxUpper = value.toUpperCase();
                                      if (mailboxUpper != value) {
                                        return 'mailbox should be upper case';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('mailbox_password'),
                                    controller: _mailboxPassword,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'your mesh mailbox password e.g. abcDef123das',
                                      labelText: 'mesh mailbox password',
                                    ),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'mailbox password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('shared_key'),
                                    controller: _sharedKey,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'shared key, not your mailbox password e.g. SharedSecret',
                                      labelText: 'shared key',
                                    ),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'shared key is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('nonce'),
                                    controller: _nonce,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'a UUID e.g. 2c001608-5f09-4840-9611-bea43e666a30',
                                      labelText: 'nonce',
                                    ),
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'nonce is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('nonce_count'),
                                    controller: _nonceCount,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'number of times the nonce has been used e.g. 1',
                                      labelText: 'nonce count',
                                    ),
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'nonce count is required';
                                      }
                                      if(!isNumeric(value)) {
                                        return 'nonce count should be numeric';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('timestamp'),
                                    controller: _timestamp,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'current datetime yyyyMMddHHmm format, e.g. 202212311759',
                                      labelText: 'timestamp',
                                    ),
                                    onChanged: _clearGenerated,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'timestamp is required';
                                      }
                                      if(!validTimestamp(value)) {
                                        return 'timestamp does not match format yyyyMMddHHmm';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: ElevatedButton(
                                    key: const Key("generate_button"),
                                    onPressed: _generateFormSubmit,
                                    child: const Text('generate auth header'),
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextField(
                                    key: const Key("generated_token"),
                                    controller: _generatedToken,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'generated header',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ]
                  )
              ),
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _openApiDocs,
                          child: const Text(
                            'click to open mesh api docs, opens in browser',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          key:  const Key('validate_page'),
                          constraints: const BoxConstraints(minHeight: 100),
                          child: Form(
                            key: _validateForm,
                            child: Column(
                              children: <Widget>[
                                const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    child: Text('validate an auth header')
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('mailbox_id'),
                                    controller: _mailboxId,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'your mesh mailbox id e.g. X2601HC213',
                                      labelText: 'mesh mailbox',
                                    ),
                                    onChanged: _clearValidationResult,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'mailbox is required';
                                      }
                                      String mailboxUpper = value.toUpperCase();
                                      if (mailboxUpper != value) {
                                        return 'mailbox should be upper case';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('mailbox_password'),
                                    controller: _mailboxPassword,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'your mesh mailbox password e.g. abcDef123das',
                                      labelText: 'mesh mailbox password',
                                    ),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onChanged: _clearValidationResult,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'mailbox password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('shared_key'),
                                    controller: _sharedKey,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'shared key, not your mailbox password e.g. SharedSecret',
                                      labelText: 'shared key',
                                    ),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    onChanged: _clearValidationResult,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'shared key is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: TextFormField(
                                    key: const Key('token'),
                                    controller: _validateToken,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'e.g. NHSMESH NONFUNC01:2c001608-5f09-4840-9611-bea43e666a30:1:201511201038:3cded68a9e0f9b83f2c5de1b79fc4dac45004523e6658d46145156fa6a03eced',
                                      labelText: 'auth header to validate',
                                    ),
                                    onChanged: _clearValidationResult,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'auth header is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: ElevatedButton(
                                    key: const Key("validate_button"),
                                    onPressed: _validateFormSubmit,
                                    child: const Text('validate auth header'),
                                  ),
                                ),
                                Padding(
                                  padding: _paddingEight,
                                  child: Text(
                                      _validationResult,
                                  style: TextStyle(
                                    color: _validationResultColor,
                                  )),
                                )
                              ],
                            ),
                          ),
                        ),
                      ]
                  )
              )
            ],
          ),
        )
    );
  }
}
