import 'dart:async';

import 'package:ap_common/api/imgur_helper.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/ap_network_image.dart';
import 'package:ap_common/widgets/option_dialog.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/tow_car_helper.dart';

import '../../models/tow_car_alert_data.dart';
import '../../utils/app_localizations.dart';
import 'tow_car_home_page.dart';

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

  final _formKey = GlobalKey<FormState>();

  var _title = TextEditingController();
  var _area = TextEditingController();
  var _description = TextEditingController();

  _ImgurUploadState imgurUploadState = _ImgurUploadState.no_file;

  String _imgUrl;

  int index = 0;

  @override
  void initState() {
    Future.microtask(_getData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final carParkAreas = TowCarConfig.of(context).carParkAreas;
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SizedBox(height: dividerHeight),
          TextFormField(
            maxLines: 1,
            maxLength: 20,
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
            maxLength: 100,
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
              onPressed: _submit,
            ),
          ),
        ],
      ),
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

  void _submit() async {
    if (_formKey.currentState.validate() &&
        imgurUploadState == _ImgurUploadState.done) {
      final data = TowCarAlert(
        title: _title.text,
        topic: TowCarConfig.of(context).carParkAreas[index].fcmTopic,
        message: _description.text,
        imageUrl: _imgUrl,
      );
      showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
          child: ProgressDialog(app.processing),
          onWillPop: () async {
            return false;
          },
        ),
        barrierDismissible: false,
      );
      TowCarHelper.instance.addApplication(
        data: data,
        callback: GeneralCallback(
          onSuccess: (Response<dynamic> data) {
            Navigator.pop(context);
            ApUtils.showToast(context, app.success);
          },
          onFailure: (DioError e) {
            Navigator.pop(context);
            ApUtils.showToast(context, e.i18nMessage);
          },
          onError: (GeneralResponse response) {
            Navigator.pop(context);
            ApUtils.showToast(context, ap.somethingError);
          },
        ),
      );
    }
    if (imgurUploadState != _ImgurUploadState.done)
      ApUtils.showToast(context, app.pleaseProvideImage);
  }

  FutureOr _getData() {
    setState(() {
      _area.text = TowCarConfig.of(context).carParkAreas[index].name;
    });
  }
}
