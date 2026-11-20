import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as q;
import 'package:nsysu_ap/utils/app_localizations.dart';

class CarouselBodyEditor extends StatelessWidget {
  const CarouselBodyEditor({
    super.key,
    required this.controller,
    required this.focus,
  });
  final q.QuillController controller;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListenableBuilder(
          listenable: controller,
          builder: (_, Widget? child) {
            final q.Style style = controller.getSelectionStyle();
            Widget toggle(
              q.Attribute<dynamic> attribute,
              IconData icon,
              String label,
            ) {
              final bool selected =
                  style.attributes[attribute.key] == attribute;
              return IconButton(
                isSelected: selected,
                style: selected
                    ? IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      )
                    : null,
                tooltip: label,
                icon: Icon(icon),
                onPressed: () {
                  focus.requestFocus();
                  controller.formatSelection(
                    selected ? q.Attribute.clone(attribute, null) : attribute,
                  );
                },
              );
            }

            return IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              child: Wrap(
                children: <Widget>[
                  toggle(q.Attribute.bold, Icons.format_bold, app.carouselBold),
                  toggle(
                    q.Attribute.italic,
                    Icons.format_italic,
                    app.carouselItalic,
                  ),
                  PopupMenuButton<String>(
                    tooltip: app.carouselSize,
                    icon: const Icon(Icons.format_size),
                    initialValue:
                        style.attributes[q.Attribute.size.key]?.value
                            ?.toString() ??
                        'normal',
                    itemBuilder: (_) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'small',
                        child: Text(app.carouselSmall),
                      ),
                      PopupMenuItem<String>(
                        value: 'normal',
                        child: Text(app.carouselNormal),
                      ),
                      PopupMenuItem<String>(
                        value: 'large',
                        child: Text(app.carouselLarge),
                      ),
                    ],
                    onSelected: (String value) {
                      focus.requestFocus();
                      controller.formatSelection(
                        q.SizeAttribute(value == 'normal' ? null : value),
                      );
                    },
                  ),
                  toggle(
                    q.Attribute.ul,
                    Icons.format_list_bulleted,
                    app.carouselBullet,
                  ),
                  toggle(
                    q.Attribute.ol,
                    Icons.format_list_numbered,
                    app.carouselOrdered,
                  ),
                  for (final bool increase in <bool>[false, true])
                    IconButton(
                      tooltip: increase
                          ? app.carouselIndent
                          : app.carouselOutdent,
                      icon: Icon(
                        increase
                            ? Icons.format_indent_increase
                            : Icons.format_indent_decrease,
                      ),
                      onPressed: () {
                        focus.requestFocus();
                        controller.indentSelection(increase);
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        Semantics(
          label: app.carouselBody,
          child: q.QuillEditor.basic(
            controller: controller,
            focusNode: focus,
            config: q.QuillEditorConfig(
              placeholder: app.carouselBodyHint,
              customStyles: q.DefaultStyles(
                placeHolder: q.DefaultTextBlockStyle(
                  Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  q.HorizontalSpacing.zero,
                  q.VerticalSpacing.zero,
                  q.VerticalSpacing.zero,
                  null,
                ),
              ),
              minHeight: 144,
              maxHeight: 360,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }
}
