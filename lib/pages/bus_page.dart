import 'package:ap_common/ap_common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/pages/bus/bus_time_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class BusPage extends StatefulWidget {
  final Locale locale;
  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onAvatarTap;
  final DataState<List<BusInfo>>? initialState;

  const BusPage({
    super.key,
    required this.locale,
    required this.isLogin,
    required this.userInfo,
    required this.displayPicture,
    required this.onAvatarTap,
    this.initialState,
  });

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  late DataState<List<BusInfo>> _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? const DataLoading<List<BusInfo>>();
    if (widget.initialState == null) {
      _loadBusData();
    }
  }

  Future<void> _loadBusData() async {
    final ApiResult<List<BusInfo>?> result = await BusHelper.instance
        .getBusInfoList(
          languageCode: widget.locale.languageCode.contains('zh') ? 'zh' : 'en',
        );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<BusInfo>?>(:final List<BusInfo>? data):
        final List<BusInfo> list = data ?? <BusInfo>[];
        setState(() {
          _state = list.isEmpty
              ? const DataEmpty<List<BusInfo>>()
              : DataLoaded<List<BusInfo>>(list);
        });
      case ApiFailure<List<BusInfo>?>():
      case ApiError<List<BusInfo>?>():
        setState(() => _state = const DataError<List<BusInfo>>());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApPageScaffold.scrollable(
      title: ap.bus,
      isLogin: widget.isLogin,
      userInfo: widget.userInfo,
      displayPicture: widget.displayPicture,
      onAvatarTap: widget.onAvatarTap,
      onRefresh: _loadBusData,
      children: <Widget>[_buildContent(context)],
    );
  }

  Widget _buildContent(BuildContext context) {
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final ThemeData theme = Theme.of(context);

    return _state.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (String? hint) => _buildStateCard(
        context: context,
        glass: glass,
        icon: ApIcon.error,
        message: ap.clickToRetry,
        onTap: () {
          setState(() => _state = const DataLoading<List<BusInfo>>());
          _loadBusData();
        },
      ),
      empty: (String? hint) => _buildStateCard(
        context: context,
        glass: glass,
        icon: ApIcon.info,
        message: ap.busEmpty,
        onTap: _loadBusData,
      ),
      loaded: (List<BusInfo> data, String? hint) {
        return AppleGroupedSection(
          title: app.busRoutesSection,
          children: <Widget>[
            for (final BusInfo bus in data)
              AppleGroupedTile(
                icon: ApIcon.directionsBus,
                title: bus.name,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _BusStatusBadge(bus: bus),
                    const SizedBox(width: 6),
                    Icon(
                      ApIcon.chevronRight,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute<dynamic>(
                      builder: (_) =>
                          BusTimePage(busInfo: bus, locale: widget.locale),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildStateCard({
    required BuildContext context,
    required LiquidGlassTheme glass,
    required IconData icon,
    required String message,
    required VoidCallback onTap,
  }) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass.cardBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: glass.subtleBorderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Center(
              child: Column(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 40,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BusStatusBadge extends StatelessWidget {
  final BusInfo bus;

  const _BusStatusBadge({required this.bus});

  @override
  Widget build(BuildContext context) {
    final bool operating = bus.isOperating && bus.busIds.isNotEmpty;
    final Color badgeColor = operating
        ? const Color(0xFF34C759)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: operating
            ? const Color(0xFF34C759).withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              operating
                  ? app.busOperatingStatus(busId: bus.busIds.first)
                  : app.busNoLiveBus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
