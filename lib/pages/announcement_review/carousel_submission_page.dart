import 'package:ap_common/ap_common.dart';
// Reuse the uploader used by the shared announcement package.
// ignore: implementation_imports
import 'package:ap_common_announcement_ui/src/api/imgbb_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as q;
import 'package:nsysu_ap/pages/announcement_review/carousel_article.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_body_editor.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class CarouselSubmissionPage extends StatefulWidget {
  const CarouselSubmissionPage({
    super.key,
    required this.client,
    this.pickImage,
    this.uploadImage,
  });

  final AnnouncementHelper client;
  final Future<XFile?> Function()? pickImage;
  final Future<ApiResult<String>> Function(XFile file)? uploadImage;

  @override
  State<CarouselSubmissionPage> createState() => _CarouselSubmissionPageState();
}

class _CarouselSubmissionPageState extends State<CarouselSubmissionPage> {
  final GlobalKey _expiryRow = GlobalKey();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _coverField =
      GlobalKey<FormFieldState<String>>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _link = TextEditingController();
  final q.QuillController _body = q.QuillController.basic(
    config: const q.QuillControllerConfig(
      // Embedded media belongs in the cover field. Paste text into the body.
      // ignore: experimental_member_use
      clipboardConfig: q.QuillClipboardConfig(enableExternalRichPaste: false),
    ),
  );
  final FocusNode _bodyFocus = FocusNode();
  DateTime? _expires;
  bool _uploading = false;
  bool _checking = false;
  String? _uploadError;

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _chooseCover() async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final XFile? file =
          await (widget.pickImage?.call() ?? MediaUtil.instance.pickImage());
      if (!mounted || file == null) return;
      final ApiResult<String> result =
          await (widget.uploadImage?.call(file) ??
              ImgbbHelper.instance!.uploadImage(file: file));
      if (!mounted) return;
      if (result case ApiSuccess<String>(
        :final String data,
      ) when carouselUrl(data) != null) {
        _coverField.currentState!.didChange(data);
        _coverField.currentState!.validate();
      } else {
        setState(() => _uploadError = app.carouselUploadFailed);
      }
    } on Exception {
      if (mounted) setState(() => _uploadError = app.carouselUploadFailed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickExpiry() async {
    final DateTime today = DateTime.now();
    final DateTime initial = _expires != null && _expires!.isAfter(today)
        ? _expires!
        : today.add(const Duration(days: 7));
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateUtils.dateOnly(today),
      lastDate: DateTime(2099, 12, 31),
    );
    if (!mounted || date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    setState(
      () => _expires = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _check() async {
    if (_checking || _uploading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final Set<FormFieldState<Object?>> invalid = _form.currentState!
        .validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(invalid.first.context, alignment: 0.15);
      return;
    }
    if (_expires != null && !_expires!.isAfter(DateTime.now())) {
      setState(() {});
      await Scrollable.ensureVisible(
        _expiryRow.currentContext!,
        alignment: 0.3,
      );
      return;
    }
    final String html = QuillDeltaToHtmlConverter(
      _body.document.toDelta().toJson(),
      ConverterOptions.forEmail(),
    ).convert();
    final Announcement item = Announcement.empty().copyWith(
      title: _title.text.trim(),
      url: _link.text.trim(),
      imgUrl: _coverField.currentState!.value!,
      description: '$carouselArticleTag$html</article>',
      expireTime: _expires?.toUtc().toIso8601String(),
      weight: 0,
      tags: <String>[],
    );
    setState(() => _checking = true);
    final bool? sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _CarouselPreview(item: item, client: widget.client),
      ),
    );
    if (!mounted) return;
    if (sent == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _checking = false);
    }
  }

  Widget _buildCoverField(ThemeData theme) => _Section(
    title: app.carouselCover,
    child: FormField<String>(
      key: _coverField,
      validator: (String? value) =>
          value == null ? app.carouselImageRequired : null,
      builder: (FormFieldState<String> field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (field.value != null) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CarouselCover(url: field.value!),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _uploading ? null : _chooseCover,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              field.value == null ? app.carouselPick : app.carouselReplace,
            ),
          ),
          if (_uploading) const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(app.carouselImageHint, style: theme.textTheme.bodySmall),
          if (_uploadError ?? field.errorText case final String error)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildEventDetails(ThemeData theme) {
    final bool expired = _expires != null && !_expires!.isAfter(DateTime.now());
    return _Section(
      title: app.carouselDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: ap.title),
            validator: (String? value) =>
                (value ?? '').trim().isEmpty ? ap.doNotEmpty : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _link,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: app.carouselLink,
              floatingLabelBehavior:
                  MediaQuery.textScalerOf(context).scale(16) >= 24
                  ? FloatingLabelBehavior.always
                  : FloatingLabelBehavior.auto,
            ),
            validator: (String? value) =>
                (value ?? '').trim().isNotEmpty && carouselUrl(value!) == null
                ? app.carouselLinkError
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            key: _expiryRow,
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickExpiry,
                  child: Text(
                    app.carouselSetExpiry,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  selected: _expires == null,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => setState(() => _expires = null),
                    icon: Icon(
                      _expires == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    label: Text(app.carouselNoExpiry),
                  ),
                ),
              ),
            ],
          ),
          if (_expires != null)
            Text(
              _expiryText(context, _expires!),
              style: theme.textTheme.bodyMedium,
            ),
          if (expired)
            Text(
              app.carouselExpired,
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(ap.addApplication)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildCoverField(theme),
                    _buildEventDetails(theme),
                    _Section(
                      title: app.carouselBody,
                      child: Localizations.override(
                        context: context,
                        delegates: const <LocalizationsDelegate<dynamic>>[
                          q.FlutterQuillLocalizations.delegate,
                        ],
                        child: CarouselBodyEditor(
                          controller: _body,
                          focus: _bodyFocus,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _uploading || _checking ? null : _check,
                      label: Text(app.carouselCheck),
                      icon: const Icon(Icons.preview_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _expiryText(BuildContext context, DateTime date) {
  final MaterialLocalizations locale = MaterialLocalizations.of(context);
  final String time = TimeOfDay.fromDateTime(date).format(context);
  return '${locale.formatMediumDate(date)} $time';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselPreview extends StatefulWidget {
  const _CarouselPreview({required this.item, required this.client});
  final Announcement item;
  final AnnouncementHelper client;
  @override
  State<_CarouselPreview> createState() => _CarouselPreviewState();
}

class _CarouselPreviewState extends State<_CarouselPreview> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_saving) return;
    final DateTime? expiry = DateTime.tryParse(widget.item.expireTime ?? '');
    if (expiry != null && !expiry.isAfter(DateTime.now())) {
      setState(() => _error = app.carouselExpired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ApiResult<Response<dynamic>> result = await widget.client
          .addApplication(data: widget.item);
      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _saving = false;
        _error = app.carouselSubmitFailed;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = app.carouselSubmitFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? expiry = DateTime.tryParse(
      widget.item.expireTime ?? '',
    )?.toLocal();
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(app.carouselPreview)),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CarouselArticle(item: widget.item),
                    const Divider(height: 32),
                    Text(
                      expiry == null
                          ? app.carouselNoExpiry
                          : '${ap.expireTime}  ${_expiryText(context, expiry)}',
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: Text(ap.submit),
                    ),
                    if (_saving) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
