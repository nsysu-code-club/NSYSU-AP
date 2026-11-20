import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class AccountSheet extends StatelessWidget {
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final VoidCallback onLogout;

  const AccountSheet({
    super.key,
    required this.userInfo,
    required this.displayPicture,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.onLogout,
  });

  static Future<void> show({
    required BuildContext context,
    required UserInfo? userInfo,
    required bool displayPicture,
    required VoidCallback onOpenProfile,
    required VoidCallback onOpenSettings,
    required VoidCallback onOpenAbout,
    required VoidCallback onLogout,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return AccountSheet(
          userInfo: userInfo,
          displayPicture: displayPicture,
          onOpenProfile: () {
            Navigator.of(sheetContext).pop();
            onOpenProfile();
          },
          onOpenSettings: () {
            Navigator.of(sheetContext).pop();
            onOpenSettings();
          },
          onOpenAbout: () {
            Navigator.of(sheetContext).pop();
            onOpenAbout();
          },
          onLogout: () {
            Navigator.of(sheetContext).pop();
            onLogout();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final Color onSurface = theme.colorScheme.onSurface;
    final String? rawName = userInfo?.name;
    final String name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : ap.userInfo;
    final String id = userInfo?.id ?? '';
    final String dept = userInfo?.department ?? '';
    final String idAndDept = <String>[
      if (id.isNotEmpty) id,
      if (dept.isNotEmpty) dept,
    ].join(' · ');

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Material(
          color: theme.scaffoldBackgroundColor,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            app.accountSheetTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            ApIcon.cancel,
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: glass.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: glass.subtleBorderColor),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onOpenProfile,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: <Widget>[
                                _buildProfileAvatar(theme),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),
                                      if (idAndDept.isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 2),
                                        Text(
                                          idAndDept,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: onSurface.withValues(
                                              alpha: 0.64,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        app.viewProfileHint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  ApIcon.chevronRight,
                                  color: onSurface.withValues(alpha: 0.38),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppleGroupedSection(
                    children: <Widget>[
                      AppleGroupedTile(
                        icon: ApIcon.settings,
                        title: ap.settings,
                        onTap: onOpenSettings,
                      ),
                      AppleGroupedTile(
                        icon: ApIcon.face,
                        title: ap.about,
                        onTap: onOpenAbout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppleGroupedSection(
                    children: <Widget>[
                      AppleGroupedTile(
                        icon: ApIcon.powerSettingsNew,
                        iconColor: theme.colorScheme.error,
                        title: ap.logout,
                        titleColor: theme.colorScheme.error,
                        trailing: const SizedBox.shrink(),
                        onTap: onLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ThemeData theme) {
    final Uint8List? bytes = displayPicture ? userInfo?.pictureBytes : null;
    final String trimmed = userInfo?.name?.trim() ?? '';
    final String? initial = trimmed.isNotEmpty
        ? trimmed.characters.first
        : null;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.68),
          ],
        ),
      ),
      child: ClipOval(
        child: (bytes != null && bytes.isNotEmpty)
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Center(
                child: initial != null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : Icon(ApIcon.person, size: 28, color: Colors.white),
              ),
      ),
    );
  }
}
