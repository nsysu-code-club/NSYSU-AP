import 'dart:io';

import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdmissionGuidePage extends StatefulWidget {
  @override
  _AdmissionGuidePageState createState() => _AdmissionGuidePageState();
}

class _AdmissionGuidePageState extends State<AdmissionGuidePage> {
  ApLocalizations ap;

  WebViewController webViewController;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("AdmissionGuidePage", "admission_guide_page.dart");
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
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
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if ((await webViewController?.canGoBack() ?? false))
                webViewController?.goBack();
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if ((await webViewController?.canGoForward() ?? false))
                webViewController?.goForward();
            },
          ),
        ],
      ),
      body: !kIsWeb && (Platform.isAndroid || Platform.isIOS)
          ? WebView(
              initialUrl: 'https://leslietsai1.wixsite.com/nsysufreshman',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                this.webViewController = webViewController;
                //_controller.complete(webViewController);
              },
            )
          : HintContent(
              icon: ApIcon.apps,
              content: ap.platformError,
            ),
    );
  }
}
