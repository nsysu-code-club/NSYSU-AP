import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:ap_common/widgets/default_dialog.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class SearchStudentIdPage extends StatefulWidget {
  static const String routerName = "/searchUsername";

  @override
  SearchStudentIdPageState createState() => SearchStudentIdPageState();
}

class SearchStudentIdPageState extends State<SearchStudentIdPage> {
  ApLocalizations ap;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  var isAutoFill = true;

  FocusNode nameFocusNode;
  FocusNode idFocusNode;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("SearchStudentIdPage", "search_student_id_page.dart");
    nameFocusNode = FocusNode();
    idFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _editTextStyle() => TextStyle(
      color: Colors.white, fontSize: 18.0, decorationColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return OrientationBuilder(
      builder: (_, orientation) {
        return Scaffold(
          backgroundColor: ApTheme.of(context).blue,
          resizeToAvoidBottomInset: orientation == Orientation.portrait,
          appBar: AppBar(
            backgroundColor: ApTheme.of(context).blue,
            elevation: 0.0,
          ),
          body: Container(
            alignment: Alignment(0, 0),
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: orientation == Orientation.portrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.min,
                    children: _renderContent(orientation),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _renderContent(orientation),
                  ),
          ),
        );
      },
    );
  }

  _renderContent(Orientation orientation) {
    List<Widget> list = orientation == Orientation.portrait
        ? <Widget>[
            Center(
              child: Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    fontSize: 120,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ]
        : <Widget>[
            Expanded(
              child: Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    fontSize: 120,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ];
    List<Widget> listB = <Widget>[
      TextField(
        maxLines: 1,
        controller: _name,
        textInputAction: TextInputAction.next,
        focusNode: nameFocusNode,
        onSubmitted: (text) {
          nameFocusNode.unfocus();
          FocusScope.of(context).requestFocus(idFocusNode);
        },
        decoration: InputDecoration(
          labelText: ap.name,
        ),
        style: _editTextStyle(),
      ),
      TextField(
        maxLines: 1,
        textInputAction: TextInputAction.send,
        controller: _id,
        focusNode: idFocusNode,
        onSubmitted: (text) {
          idFocusNode.unfocus();
          _search();
        },
        decoration: InputDecoration(
          labelText: ap.id,
        ),
        style: _editTextStyle(),
      ),
      SizedBox(height: 8.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: Checkbox(
                    activeColor: Colors.white,
                    checkColor: ApTheme.of(context).blue,
                    value: isAutoFill,
                    onChanged: _onAutoFillChanged,
                  ),
                ),
                Text(
                  ap.autoFill,
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
            onTap: () => _onAutoFillChanged(!isAutoFill),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      ApButton(
        text: ap.search,
        onPressed: () {
          FirebaseAnalyticsUtils.instance
              .logAction('search_student_id', 'click');
          _search();
        },
      ),
    ];
    if (orientation == Orientation.portrait) {
      list.addAll(listB);
    } else {
      list.add(
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: listB,
          ),
        ),
      );
    }
    return list;
  }

  _onAutoFillChanged(bool value) async {
    setState(() {
      isAutoFill = value;
    });
  }

  _search() async {
    if (_name.text.isEmpty || _id.text.isEmpty) {
      ApUtils.showToast(context, ap.doNotEmpty);
    } else {
      SelcrsHelper.instance.getUsername(
        name: _name.text,
        id: _id.text,
        callback: GeneralCallback.simple(
          context,
          (String result) {
            List<String> list = result.split('--');
            if (list.length == 2 && isAutoFill) {
              Navigator.pop(context, list[1]);
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) => DefaultDialog(
                  title: ap.searchResult,
                  actionText: ap.iKnow,
                  actionFunction: () =>
                      Navigator.of(context, rootNavigator: true).pop('dialog'),
                  contentWidget: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: ApTheme.of(context).grey,
                        height: 1.3,
                        fontSize: 16.0,
                      ),
                      children: [
                        TextSpan(
                          text: result ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (list.length == 2)
                          TextSpan(
                            text:
                                '\n\n${AppLocalizations.of(context).firstLoginHint}',
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      );
    }
  }
}
