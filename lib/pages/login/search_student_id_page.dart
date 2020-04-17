import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:ap_common/widgets/default_dialog.dart';

class SearchStudentIdPage extends StatefulWidget {
  static const String routerName = "/searchUsername";

  @override
  SearchStudentIdPageState createState() => SearchStudentIdPageState();
}

class SearchStudentIdPageState extends State<SearchStudentIdPage> {
  AppLocalizations app;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  var isAutoFill = true;

  FocusNode nameFocusNode;
  FocusNode idFocusNode;

  @override
  void initState() {
    FA.setCurrentScreen("SearchStudentIdPage", "search_student_id_page.dart");
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
    app = AppLocalizations.of(context);
    return OrientationBuilder(
      builder: (_, orientation) {
        return Scaffold(
          backgroundColor: ApTheme.of(context).blue,
          resizeToAvoidBottomPadding: orientation == Orientation.portrait,
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
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ]
        : <Widget>[
            Expanded(
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
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
          labelText: app.name,
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
          labelText: app.id,
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
                  app.autoFill,
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
            onTap: () => _onAutoFillChanged(!isAutoFill),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      Container(
        width: double.infinity,
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30.0),
            ),
          ),
          padding: EdgeInsets.all(14.0),
          onPressed: () {
            FA.logAction('search_student_id', 'click');
            _search();
          },
          color: Colors.white,
          child: Text(
            app.search,
            style: TextStyle(color: ApTheme.of(context).blue, fontSize: 18.0),
          ),
        ),
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
      ApUtils.showToast(context, app.doNotEmpty);
    } else {
      String result = await SelcrsHelper.instance.getUsername(
        name: _name.text,
        id: _id.text,
      );
      List<String> list = result.split('--');
      if (list.length == 2 && isAutoFill) {
        Navigator.pop(context, list[1]);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => DefaultDialog(
            title: app.searchResult,
            actionText: app.iKnow,
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
                      text: '\n\n${app.firstLoginHint}',
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
