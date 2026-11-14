import 'package:flutter/material.dart';
import 'package:nsysu_ap/resources/image_assets.dart';
import 'package:photo_view/photo_view.dart';

class SchoolMapViewer extends StatelessWidget {
  const SchoolMapViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: const AssetImage(ImageAssets.schoolMap),
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      minScale: PhotoViewComputedScale.contained,
      initialScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
    );
  }
}
