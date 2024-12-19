import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class SearchStudentIdPage extends StatefulWidget {
  static const String routerName = '/searchUsername';

  @override
  SearchStudentIdPageState createState() => SearchStudentIdPageState();
}

class SearchStudentIdPageState extends State<SearchStudentIdPage> {
  late ApLocalizations ap;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  bool isAutoFill = true;

  FocusNode nameFocusNode = FocusNode();
  FocusNode idFocusNode = FocusNode();

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('SearchStudentIdPage', 'search_student_id_page.dart');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  TextStyle _editTextStyle() => const TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        decorationColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return OrientationBuilder(
      builder: (_, Orientation orientation) {
        return Scaffold(
          backgroundColor: ApTheme.of(context).blue,
          resizeToAvoidBottomInset: orientation == Orientation.portrait,
          appBar: AppBar(
            backgroundColor: ApTheme.of(context).blue,
            elevation: 0.0,
          ),
          body: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
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

  List<Widget> _renderContent(Orientation orientation) {
    final List<Widget> list = orientation == Orientation.portrait
        ? <Widget>[
            const Center(
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
            const Expanded(
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
    final List<Widget> listB = <Widget>[
      TextField(
        controller: _name,
        textInputAction: TextInputAction.next,
        focusNode: nameFocusNode,
        onSubmitted: (String text) {
          nameFocusNode.unfocus();
          FocusScope.of(context).requestFocus(idFocusNode);
        },
        decoration: InputDecoration(
          labelText: ap.name,
        ),
        style: _editTextStyle(),
      ),
      TextField(
        textInputAction: TextInputAction.send,
        controller: _id,
        focusNode: idFocusNode,
        onSubmitted: (String text) {
          idFocusNode.unfocus();
          _search();
        },
        decoration: InputDecoration(
          labelText: ap.id,
        ),
        style: _editTextStyle(),
      ),
      const SizedBox(height: 8.0),
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
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            onTap: () => _onAutoFillChanged(!isAutoFill),
          ),
        ],
      ),
      const SizedBox(height: 8.0),
      ApButton(
        text: ap.search,
        onPressed: () {
          AnalyticsUtil.instance.logEvent('search_student_id_click');
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

  Future<void> _onAutoFillChanged(bool? value) async {
    if (value != null) {
      setState(() {
        isAutoFill = value;
      });
    }
  }

  Future<void> _search() async {
    if (_name.text.isEmpty || _id.text.isEmpty) {
      UiUtil.instance.showToast(context, ap.doNotEmpty);
    } else {
      try {
        final String result = await SelcrsHelper.instance.getUsername(
          name: _name.text,
          id: _id.text,
        );
        if (!mounted) return;
        final List<String> list = result.split('--');
        if (list.length == 2 && isAutoFill) {
          Navigator.pop(context, list[1]);
        } else {
          final AppLocalizations app = AppLocalizations.of(context);
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
                  children: <InlineSpan>[
                    TextSpan(
                      text: result,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
      } catch (e) {
        if (!mounted) return;
        switch (e) {
          case DioException():
            if (e.i18nMessage case final String message?) {
              UiUtil.instance.showToast(context, message);
            }
          case GeneralResponse():
            UiUtil.instance.showToast(context, e.message);
          default:
            UiUtil.instance.showToast(context, ap.unknownError);
        }
      }
    }
  }
}
