import 'package:flutter/widgets.dart';
import 'package:multiple_localization/multiple_localization.dart';
import 'package:nsysu_ap/l10n/intl/messages_all.dart';
import 'package:nsysu_ap/l10n/l10n.dart';

export 'package:nsysu_ap/l10n/l10n.dart';

const _AppLocalizationsDelegate appDelegate = _AppLocalizationsDelegate();

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return MultipleLocalizations.load(
      initializeMessages,
      locale,
      (String l) => AppLocalizations.load(locale),
      setDefaultLocale: true,
    );
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
