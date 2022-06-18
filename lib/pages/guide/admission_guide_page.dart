import 'dart:io';

import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:nsysu_ap/config/constants.dart';

class AdmissionGuidePage extends StatefulWidget {
  @override
  _AdmissionGuidePageState createState() => _AdmissionGuidePageState();
}

class _AdmissionGuidePageState extends State<AdmissionGuidePage> {
  ApLocalizations ap;

  InAppWebViewController webViewController;
  final WebviewController _windowsController = WebviewController();

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("AdmissionGuidePage", "admission_guide_page.dart");
    initWindowsPlatformState();
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
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                if ((await webViewController?.canGoBack() ?? false))
                  webViewController?.goBack();
              } else if (Platform.isWindows) {
                _windowsController.goBack();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                if ((await webViewController?.canGoForward() ?? false))
                  webViewController?.goForward();
              } else if (Platform.isWindows) {
                _windowsController.goForward();
              }
            },
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          return InAppWebView(
            initialUrlRequest: URLRequest(
              url: Uri.parse(Constants.admissionGuideUrl),
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
      }),
    );
  }

  Future<void> initWindowsPlatformState() async {
    try {
      await _windowsController.initialize();
      _windowsController.url.listen((url) {
        print(url);
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
                  title: Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }
}
