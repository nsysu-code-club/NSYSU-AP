import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/options.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';

import 'dialog_option.dart';

typedef SemesterCallback = void Function(Options semester, int index);

class SemesterPicker extends StatefulWidget {
  final Function getData;
  final SemesterCallback onSelect;

  const SemesterPicker({Key key, this.getData, this.onSelect})
      : super(key: key);

  @override
  SemesterPickerState createState() => SemesterPickerState();
}

class SemesterPickerState extends State<SemesterPicker> {
  List<Options> options;
  Options selected;

  @override
  void initState() {
    _getSemester();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () {
        if (options != null) pickSemester();
        FA.logAction('pick_yms', 'click');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            selected?.text ?? '',
            style: TextStyle(
              color: Resource.Colors.semesterText,
              fontSize: 18.0,
            ),
          ),
          SizedBox(width: 8.0),
          Icon(
            Icons.keyboard_arrow_down,
            color: Resource.Colors.semesterText,
          )
        ],
      ),
    );
  }

  void _getSemester() async {
    options = await widget.getData();
    if (mounted) {
      widget.onSelect(options[0], 0);
      setState(() {
        selected = options[0];
      });
    }
  }

  void pickSemester() {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(AppLocalizations.of(context).picksSemester),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        children: [
          for (var i = 0; i < options.length; i++) ...[
            DialogOption(
                text: options[i].text,
                check: options[i].text == selected.text,
                onPressed: () {
                  Navigator.pop(context, i);
                }),
            Divider(
              height: 6.0,
            )
          ]
        ],
      ),
    ).then<void>((int position) async {
      if (position != null) {
        widget.onSelect(options[position], position);
        setState(() {
          selected = options[position];
        });
      }
    });
  }
}
