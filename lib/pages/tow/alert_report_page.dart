import 'package:ap_common/api/imgur_helper.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/ap_network_image.dart';
import 'package:flutter/material.dart';

enum _ImgurUploadState { no_file, uploading, done }

class TowCarAlertReportPage extends StatefulWidget {
  @override
  _TowCarAlertReportPageState createState() => _TowCarAlertReportPageState();
}

class _TowCarAlertReportPageState extends State<TowCarAlertReportPage> {
  final dividerHeight = 16.0;

  ApLocalizations ap;

  var _title = TextEditingController();
  var _area = TextEditingController();
  var _description = TextEditingController();

  _ImgurUploadState imgurUploadState = _ImgurUploadState.no_file;

  String _imgUrl;

  @override
  void initState() {
    _area.text = '武嶺';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () {},
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
              labelText: '推播區域',
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
            Text('上傳圖片'),
            SizedBox(width: 4.0),
            Icon(Icons.upload_file),
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
            'Click to Upload',
            textAlign: TextAlign.center,
            style: TextStyle(color: ApTheme.of(context).grey),
          ),
        ];
    }
  }
}
