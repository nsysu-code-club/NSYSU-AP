import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_ap/config/constants.dart';

class AdmissionGuidePage extends StatefulWidget {
  @override
  _AdmissionGuidePageState createState() => _AdmissionGuidePageState();
}

class _AdmissionGuidePageState extends State<AdmissionGuidePage> {
  late ApLocalizations ap;

  InAppWebViewController? webViewController;

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('AdmissionGuidePage', 'admission_guide_page.dart');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.admissionGuide),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                if (await webViewController?.canGoBack() ?? false) {
                  webViewController?.goBack();
                }
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
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (!kIsWeb &&
              (Platform.isAndroid ||
                  Platform.isIOS ||
                  Platform.isMacOS ||
                  Platform.isWindows)) {
            return InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(Constants.admissionGuideUrl),
              ),
              onWebViewCreated: (InAppWebViewController webViewController) {
                this.webViewController = webViewController;
                //_windowsController.complete(webViewController);
              },
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
}
