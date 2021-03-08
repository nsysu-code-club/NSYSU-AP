import 'dart:async';

import 'package:ap_common/api/imgur_helper.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/ap_network_image.dart';
import 'package:ap_common/widgets/option_dialog.dart';
import 'package:flutter/material.dart';

import '../../models/car_park_area.dart';
import '../../resources/image_assets.dart';
import '../../utils/app_localizations.dart';

enum _ImgurUploadState { no_file, uploading, done }

class TowCarAlertReportPage extends StatefulWidget {
  @override
  _TowCarAlertReportPageState createState() => _TowCarAlertReportPageState();
}

class _TowCarAlertReportPageState extends State<TowCarAlertReportPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final dividerHeight = 16.0;

  AppLocalizations app;
  ApLocalizations ap;

  var _title = TextEditingController();
  var _area = TextEditingController();
  var _description = TextEditingController();

  _ImgurUploadState imgurUploadState = _ImgurUploadState.no_file;

  String _imgUrl;

  List<CarParkArea> carParkAreas;

  int index = 0;

  @override
  void initState() {
    Future.microtask(_getData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SizedBox(height: dividerHeight),
        TextFormField(
          maxLines: 1,
          controller: _title,
          validator: (value) {
            if (value.isEmpty) {
              return ap.doNotEmpty;
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            fillColor: ApTheme.of(context).blueAccent,
            labelStyle: TextStyle(
              color: ApTheme.of(context).grey,
            ),
            labelText: ap.title,
          ),
        ),
        SizedBox(height: dividerHeight),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => SimpleOptionDialog(
                title: app.notificationArea,
                items: carParkAreas.map((e) => e.name).toList(),
                index: index,
                onSelected: (index) {
                  setState(() {
                    this.index = index;
                    _area.text = carParkAreas[index].name;
                  });
                },
              ),
            );
          },
          child: TextFormField(
            enabled: false,
            maxLines: 1,
            controller: _area,
            validator: (value) {
              if (value.isEmpty) {
                return ap.doNotEmpty;
              }
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: Icon(Icons.keyboard_arrow_down_sharp),
              border: OutlineInputBorder(),
              fillColor: ApTheme.of(context).blueAccent,
              disabledBorder: UnderlineInputBorder(),
              labelStyle: TextStyle(
                color: ApTheme.of(context).grey,
              ),
              labelText: app.notificationArea,
            ),
          ),
        ),
        SizedBox(height: dividerHeight),
        TextFormField(
          maxLines: 5,
          controller: _description,
          validator: (value) {
            if (value.isEmpty) {
              return ap.doNotEmpty;
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            fillColor: ApTheme.of(context).blueAccent,
            labelStyle: TextStyle(
              color: ApTheme.of(context).grey,
            ),
            labelText: ap.description,
          ),
        ),
        SizedBox(height: dividerHeight),
        Row(
          children: [
            Text(
              app.uploadImage,
              style: TextStyle(
                color: ApTheme.of(context).greyText,
              ),
            ),
            SizedBox(width: 4.0),
            Icon(
              Icons.upload_file,
              color: ApTheme.of(context).greyText,
            ),
          ],
        ),
        SizedBox(height: 12.0),
        InkWell(
          onTap: () async {
            PickedFile image = await ApUtils.pickImage();
            if (image != null) {
              setState(() => imgurUploadState = _ImgurUploadState.uploading);
              ImgurHelper.instance.uploadImageToImgur(
                file: image,
                callback: GeneralCallback(
                  onFailure: (dioError) {
                    ApUtils.showToast(context, dioError.message);
                    setState(() => imgurUploadState = _imgUrl.isEmpty
                        ? _ImgurUploadState.no_file
                        : _ImgurUploadState.done);
                  },
                  onError: (generalResponse) {
                    ApUtils.showToast(context, generalResponse.message);
                    setState(() => imgurUploadState = _imgUrl.isEmpty
                        ? _ImgurUploadState.no_file
                        : _ImgurUploadState.done);
                  },
                  onSuccess: (data) {
                    _imgUrl = data.link;
                    setState(() => imgurUploadState = _ImgurUploadState.done);
                  },
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: ApTheme.of(context).grey),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _imgurUploadWidget,
            ),
          ),
        ),
        SizedBox(height: dividerHeight),
        FractionallySizedBox(
          widthFactor: 0.7,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16.0,
              ),
              primary: ApTheme.of(context).blueAccent,
            ),
            child: Text(ap.submit),
            onPressed: () async {},
          ),
        ),
      ],
    );
  }

  List<Widget> get _imgurUploadWidget {
    switch (imgurUploadState) {
      case _ImgurUploadState.uploading:
        return [
          CircularProgressIndicator(),
          SizedBox(height: 8.0),
          Text(ap.uploading),
        ];
        break;
      case _ImgurUploadState.done:
        return [
          Text(ap.imagePreview),
          SizedBox(height: 8.0),
          SizedBox(
            height: 300,
            child: ApNetworkImage(url: _imgUrl),
          ),
          SizedBox(height: 8.0),
        ];
      case _ImgurUploadState.no_file:
      default:
        return [
          Icon(
            Icons.upload_file,
            size: 50.0,
            color: ApTheme.of(context).grey,
          ),
          SizedBox(height: 16.0),
          Text(
            ap.pickAndUploadToImgur,
            textAlign: TextAlign.center,
            style: TextStyle(color: ApTheme.of(context).grey),
          ),
        ];
    }
  }

  Future<FutureOr> _getData() async {
    final json = await FileAssets.carParkAreaData;
    carParkAreas = CarParkAreaData.fromJson(json).data;
    setState(() {
      _area.text = carParkAreas[index].name;
    });
  }
}
