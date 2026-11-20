import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_surface.dart';

class AppleContentContainer extends StatelessWidget {
  static const double maxContentWidth = 760.0;

  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppleContentContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class ApplePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onAvatarTap;
  final Widget? trailing;

  const ApplePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isLogin,
    required this.userInfo,
    this.displayPicture = true,
    required this.onAvatarTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (trailing != null) ...<Widget>[
                trailing!,
                const SizedBox(width: 10),
              ],
              ProfileAvatarButton(
                isLogin: isLogin,
                userInfo: userInfo,
                displayPicture: displayPicture,
                onTap: onAvatarTap,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.15,
                color: textColor,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.64),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileAvatarButton extends StatefulWidget {
  static const Key buttonKey = ValueKey<String>('profile_avatar_button');

  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onTap;

  const ProfileAvatarButton({
    super.key = buttonKey,
    required this.isLogin,
    required this.userInfo,
    this.displayPicture = true,
    required this.onTap,
  });

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  bool _isPressed = false;

  String? _extractInitial(String? name) {
    if (name == null) return null;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final String? initial = _extractInitial(widget.userInfo?.name);
    final Uint8List? pictureBytes = widget.displayPicture
        ? widget.userInfo?.pictureBytes
        : null;
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final String? rawName = widget.userInfo?.name;
    final String semanticsLabel = widget.isLogin
        ? ((rawName != null && rawName.isNotEmpty) ? rawName : ap.userInfo)
        : ap.login;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: AnimatedScale(
              scale: _isPressed ? 0.92 : 1.0,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 110),
              child: SizedBox(
                width: 42,
                height: 42,
                child: LiquidGlassSurface(
                  borderRadius: BorderRadius.circular(21),
                  padding: const EdgeInsets.all(4),
                  showShadow: false,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          primary.withValues(alpha: 0.85),
                          primary.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatarInner(pictureBytes, initial),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarInner(Uint8List? pictureBytes, String? initial) {
    if (widget.isLogin && pictureBytes != null && pictureBytes.isNotEmpty) {
      return Image.memory(
        pictureBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
      );
    }
    return _buildFallbackInitial(initial);
  }

  Widget _buildFallbackInitial(String? initial) {
    if (widget.isLogin && initial != null) {
      return Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}
