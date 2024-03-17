import 'package:ap_common/scaffold/image_viewer_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/resources/image_assets.dart';

class SchoolMapPage extends StatefulWidget {
  @override
  _SchoolMapPageState createState() => _SchoolMapPageState();
}

class _SchoolMapPageState extends State<SchoolMapPage> {
  @override
  Widget build(BuildContext context) {
    return ImageViewerScaffold(
      title: ApLocalizations.of(context).schoolMap,
      imageViewers: <ImageViewer>[
        ImageViewer(
          title: '',
          assetName: ImageAssets.schoolMap,
        ),
      ],
    );
  }
}
