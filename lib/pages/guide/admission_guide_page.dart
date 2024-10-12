import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:webview_windows/webview_windows.dart';

class AdmissionGuidePage extends StatefulWidget {
  @override
  _AdmissionGuidePageState createState() => _AdmissionGuidePageState();
}

class _AdmissionGuidePageState extends State<AdmissionGuidePage> {
  late ApLocalizations ap;

  InAppWebViewController? webViewController;
  final WebviewController _windowsController = WebviewController();

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('AdmissionGuidePage', 'admission_guide_page.dart');
    if (!kIsWeb && Platform.isWindows) {
      initWindowsPlatformState();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.admissionGuide),
        backgroundColor: ApTheme.of(context).blue,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                if (await webViewController?.canGoBack() ?? false) {
                  webViewController?.goBack();
                }
              } else if (Platform.isWindows) {
                _windowsController.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                if (await webViewController?.canGoForward() ?? false) {
                  webViewController?.goForward();
                }
              } else if (Platform.isWindows) {
                _windowsController.goForward();
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            return InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(Constants.admissionGuideUrl),
              ),
              onWebViewCreated: (InAppWebViewController webViewController) {
                this.webViewController = webViewController;
                //_windowsController.complete(webViewController);
              },
            );
          } else if (Platform.isWindows) {
            return Webview(
              _windowsController,
            );
          } else {
            return HintContent(
              icon: ApIcon.apps,
              content: ap.platformError,
            );
          }
        },
      ),
    );
  }

  Future<void> initWindowsPlatformState() async {
    try {
      await _windowsController.initialize();
      _windowsController.url.listen((String url) {
        if (kDebugMode) {
          print(url);
        }
      });

      await _windowsController.setBackgroundColor(Colors.transparent);
      await _windowsController
          .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _windowsController.loadUrl(Constants.admissionGuideUrl);

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Code: ${e.code}'),
                Text('Message: ${e.message}'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      });
    }
  }
}
