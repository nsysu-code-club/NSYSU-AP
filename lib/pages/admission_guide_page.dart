import 'package:flutter/material.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdmissionGuidePage extends StatefulWidget {
  @override
  _AdmissionGuidePageState createState() => _AdmissionGuidePageState();
}

class _AdmissionGuidePageState extends State<AdmissionGuidePage> {
  AppLocalizations app;

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.admissionGuide),
        backgroundColor: Resource.Colors.blue,
      ),
      body: WebView(
        initialUrl: 'https://leslietsai1.wixsite.com/nsysufreshman',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          // _controller.complete(webViewController);
        },
      ),
    );
  }
}
