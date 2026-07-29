import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/captcha_ocr/captcha_ocr.dart';

class CaptchaOcrDebugPage extends StatefulWidget {
  const CaptchaOcrDebugPage({super.key});

  static const String routerName = '/debug/captcha-ocr';

  @override
  State<CaptchaOcrDebugPage> createState() => _CaptchaOcrDebugPageState();
}

class _CaptchaOcrDebugPageState extends State<CaptchaOcrDebugPage> {
  final TextEditingController _passwordController = TextEditingController();
  final NsysuEnrollCaptchaClient _captchaClient = NsysuEnrollCaptchaClient();
  final CaptchaOcr _captchaOcr = CaptchaOcr();

  Uint8List? _captchaBytes;
  Uri? _captchaUri;
  String _recognizedText = '';
  String _message = '';
  bool _isLoadingCaptcha = false;
  bool _isRecognizing = false;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _captchaClient.close();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Captcha OCR Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '密碼',
              helperText: '僅供本機手動測試，不會送出或儲存',
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  if (_captchaBytes == null)
                    SizedBox(
                      height: 72,
                      child: Center(
                        child: _isLoadingCaptcha
                            ? const CircularProgressIndicator()
                            : const Text('尚未載入驗證碼'),
                      ),
                    )
                  else
                    Image.memory(
                      _captchaBytes!,
                      height: 72,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  if (_captchaUri != null) ...<Widget>[
                    const SizedBox(height: 12),
                    SelectableText(
                      _captchaUri.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingCaptcha ? null : _loadCaptcha,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新載入驗證碼'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _captchaBytes == null || _isRecognizing
                      ? null
                      : _recognizeCaptcha,
                  icon: _isRecognizing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: const Text('辨識'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('辨識結果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            _recognizedText.isEmpty ? '-' : _recognizedText,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(_message, style: TextStyle(color: colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _isLoadingCaptcha = true;
      _message = '';
      _recognizedText = '';
    });

    try {
      final NsysuEnrollCaptchaImage captcha = await _captchaClient
          .fetchCaptcha();
      if (!mounted) return;
      setState(() {
        _captchaBytes = captcha.bytes;
        _captchaUri = captcha.imageUri;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = '載入驗證碼失敗：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCaptcha = false;
        });
      }
    }
  }

  Future<void> _recognizeCaptcha() async {
    final Uint8List? captchaBytes = _captchaBytes;
    if (captchaBytes == null) return;

    setState(() {
      _isRecognizing = true;
      _message = '';
      _recognizedText = '';
    });

    File? captchaFile;
    try {
      final NsysuEnrollCaptchaImage captcha = NsysuEnrollCaptchaImage(
        bytes: captchaBytes,
        imageUri: _captchaUri ?? NsysuEnrollCaptchaClient.enrollUri,
        cookieHeader: '',
        contentType: 'image/bmp',
      );
      captchaFile = await captcha.writeToTemporaryFile();
      final String text = await _captchaOcr.recognizeTextFromImagePath(
        captchaFile.path,
      );
      if (!mounted) return;
      setState(() {
        _recognizedText = text;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'OCR 辨識失敗：$e';
      });
    } finally {
      try {
        await captchaFile?.parent.delete(recursive: true);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }
}
