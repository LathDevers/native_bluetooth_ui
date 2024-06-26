library native_bluetooth_ui;

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_bluetooth_ui/adaptive_circular_progress_indicator.dart';
import 'package:native_bluetooth_ui/adaptive_navigator.dart';
import 'package:native_bluetooth_ui/adaptive_scrollbar.dart';
import 'package:native_bluetooth_ui/iterable_extensions.dart';
import 'package:native_bluetooth_ui/my_scan_result.dart';
import 'package:native_bluetooth_ui/adaptive_listtile.dart';

const double _kDefaultTileHeight = 48;

Future<void> showNativeBluetoothDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ScanDialog(),
  );
}

/// A tile widget with a single scan result device.
class ScanResultTile extends StatefulWidget {
  const ScanResultTile({
    super.key,
    required this.result,
    this.dense = false,
    this.contentPadding = EdgeInsets.zero,
    this.leadingOnlyBiVital = false,
  });

  final MyScanResult result;
  final bool dense;
  final EdgeInsetsGeometry contentPadding;
  final bool leadingOnlyBiVital;

  @override
  ScanResultTileState createState() => ScanResultTileState();
}

class ScanResultTileState extends State<ScanResultTile> {
  final ConnectingPopUp connectingPopUp = ConnectingPopUp();

  static const double iconSize = 35;

  @override
  void dispose() {
    connectingPopUp.stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).primaryColor.withOpacity(.3);
    final bool isBIVital = widget.result.isBIVital;
    return Material(
      color: Colors.transparent,
      child: AdaptiveListTile.icon(
        dense: widget.dense,
        title: widget.result.deviceNameNullable != null
            ? Text(
                widget.result.deviceName,
                style: TextStyle(
                  color: isBIVital ? null : secondaryColor,
                  fontSize: 18,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.result.device.remoteId.toString(),
                  style: TextStyle(color: secondaryColor, fontSize: 18),
                  textAlign: TextAlign.start,
                ),
              ),
        subtitle: widget.result.deviceNameNullable != null && !isCupertino
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.result.device.remoteId.toString(),
                  style: TextStyle(
                    color: isBIVital ? null : secondaryColor,
                    fontSize: 16,
                  ),
                ),
              )
            : null,
        leadingIcon: isBIVital
            ? Icon(AdaptiveIcons.bivital, color: Theme.of(context).primaryColor, size: iconSize)
            : !widget.leadingOnlyBiVital
                ? Icon(AdaptiveIcons.bluetooth, color: secondaryColor, size: iconSize - 8)
                : null,
        contentPadding: widget.contentPadding,
        onTap: () => isBIVital
            ? addDeviceToList(widget.result.device)
            : showBIVitalDialog<void>(
                context: context,
                barrierDismissible: false,
                title: Text(AppLocalizations.of(context)!.warning),
                content: (context) => Text(AppLocalizations.of(context)!.noBIVdesc),
                actions: [
                  AdaptiveDialogAction(
                    onPressed: AdaptiveNavigator.pop,
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ), // Cancel
                  AdaptiveDialogAction(
                    child: Text(AppLocalizations.of(context)!.connect),
                    onPressed: (context) {
                      addDeviceToList(widget.result.device);
                      AdaptiveNavigator.pop(context);
                    },
                  ), // Connect
                ],
              ),
      ),
    );
  }

  Future<void> addDeviceToList(BluetoothDevice device) async {
    connectingPopUp.startDialog(context, device);
    await device.connect();
    if (Platform.isAndroid) await device.requestMtu(512);
    await ConnectedDevicesList.add(device);
    if (!mounted) return;
    connectingPopUp.stopDialog(context);
    unawaited(MyToast.showToast(message: '${device.deviceName} ${AppLocalizations.of(context)!.connected}'));
    await FlutterBluePlus.stopScan();
    if (mounted) AdaptiveNavigator.pop(context);
  }
}

class _ScanDialog extends StatefulWidget {
  const _ScanDialog();

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog> {
  bool onlyBIVital = false;

  @override
  Widget build(BuildContext context) {
    if (!isCupertino) {
      return MaterialDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SearchingTitle(
              AppLocalizations.of(context)!.searchBTtitle,
              fontSize: 23,
            ),
            IconButton(
              onPressed: () => setState(() => onlyBIVital = !onlyBIVital),
              icon: Icon(onlyBIVital ? AdaptiveIcons.filter_off : AdaptiveIcons.filter_on),
            ),
          ],
        ),
        content: _buildScanResultList(context),
        actions: [
          AdaptiveDialogAction(
            onPressed: AdaptiveNavigator.pop,
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      );
    }
    final Color separatorColor = ColorByBrightness(lightColor: const Color(0x483C3C43), darkColor: Colors.grey.shade800).resolveFrom(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        contentPadding: EdgeInsets.zero,
        buttonPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: ColoredBox(
              color: const ColorByBrightness(lightColor: Color(0xC5EEEDED), darkColor: Color(0xB31D1D1D)).resolveFrom(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 13),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(AdaptiveIcons.bluetooth, size: 26),
                              SearchingTitle(
                                AppLocalizations.of(context)!.searchBTtitle,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => setState(() => onlyBIVital = !onlyBIVital),
                              icon: Icon(onlyBIVital ? AdaptiveIcons.filter_off : AdaptiveIcons.filter_on),
                            ),
                            const CupertinoActivityIndicator(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: separatorColor,
                  ),
                  _buildScanResultList(
                    context,
                    separatorColor: separatorColor,
                  ),
                  Divider(
                    height: 1,
                    color: separatorColor,
                  ),
                  CupertinoDialogAction(
                    onPressed: () => AdaptiveNavigator.pop(context),
                    isDefaultAction: true,
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.normal,
                      ),
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

  Widget _buildScanResultList(BuildContext context, {Color? separatorColor}) {
    final double resultsListHeight = MediaQuery.sizeOf(context).height * .5;
    return SizedBox(
      height: resultsListHeight,
      child: Padding(
        padding: EdgeInsets.zero,
        child: StreamBuilder<List<MyScanResult>>(
          stream: MyFlutterBlue.scanResults,
          initialData: const [],
          builder: (BuildContext context, AsyncSnapshot<List<MyScanResult>> snapshot) {
            if (snapshot.data != null) {
              Iterable<MyScanResult> filtered = snapshot.data!;
              if (isCupertino) filtered = filtered.where((scan) => scan.device.deviceNameNullable != null);
              if (onlyBIVital) filtered = filtered.where((scan) => scan.isBIVital);
              final double difference = (resultsListHeight - ((filtered.length - 1) * _kDefaultTileHeight)) / _kDefaultTileHeight;
              final List<ScanResultTile> tiles = filtered
                  .map((scan) => ScanResultTile(
                        result: scan,
                        contentPadding: isCupertino ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
                        leadingOnlyBiVital: isCupertino,
                      ))
                  .toList();
              return AdaptiveScrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...tiles,
                      if (difference > 0)
                        ...List.generate(
                          difference.ceil(),
                          (_) => AdaptiveListTile(
                            title: const SizedBox.shrink(),
                            contentPadding: isCupertino ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
                          ),
                        ),
                    ]
                        .insertDividers(
                          enable: isCupertino,
                          indent: 20,
                          dividerColor: separatorColor,
                        )
                        .toList(),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// A platform-adaptive circular progress indicator, that can be started (show) and stopped (hide).
class ConnectingPopUp {
  /// Show window.
  void startDialog(BuildContext context, BluetoothDevice device) {
    showBIVitalDialog<void>(
      context: context,
      barrierDismissible: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${AppLocalizations.of(context)!.connecting}...'),
          const AdaptiveCircularProgressIndicator.indeterminate(),
        ],
      ),
      content: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFirstMessage(),
          _buildSecondMessage(device),
        ],
      ),
    );
  }

  Future<void> _firstMessage() => Future.delayed(const Duration(seconds: 4));

  Future<void> _secondMessage() => Future.delayed(const Duration(seconds: 10));

  FutureBuilder<void> _buildFirstMessage() {
    return FutureBuilder(
      future: _firstMessage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else {
          return Text(
            AppLocalizations.of(context)!.stalling,
            style: const TextStyle(fontSize: 13, height: 1),
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  FutureBuilder<void> _buildSecondMessage(BluetoothDevice device) {
    return FutureBuilder(
      future: _secondMessage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else {
          return Text(
            '${AppLocalizations.of(context)!.advice} ${device.remoteId.toString().substring(6, 8)}${device.remoteId.toString().substring(9, 11)}',
            style: const TextStyle(fontSize: 13, height: 1),
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  /// Hide window.
  void stopDialog(BuildContext context) {
    AdaptiveNavigator.pop(context);
    stopTimer();
  }

  void stopTimer() {
    _firstMessage().ignore();
    _secondMessage().ignore();
  }
}

class SearchingTitle extends StatefulWidget {
  const SearchingTitle(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.textAlign,
    this.fontStyle,
    this.dots = 4,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final FontStyle? fontStyle;
  final int dots;

  @override
  State<SearchingTitle> createState() => _SearchingTitleState();
}

class _SearchingTitleState extends State<SearchingTitle> {
  late Timer _timer;
  int count = 0;

  @override
  void initState() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) {
        addCount();
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String dots = '.' * count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
          ),
        ),
        SizedBox(
          width: widget.fontSize * 1.5,
          child: Text(
            dots,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              fontStyle: widget.fontStyle,
            ),
            overflow: TextOverflow.visible,
            maxLines: 1,
            textAlign: widget.textAlign,
          ),
        ),
      ],
    );
  }

  void addCount() {
    count++;
    if (count > widget.dots) count = 0;
  }
}

class ConnectedDeviceTile extends StatefulWidget implements SettingsSectionChild {
  const ConnectedDeviceTile({
    super.key,
    required this.device,
    this.dense = false,
    this.enableBleUUIDPage = false,
    this.disable = false,
    this.disabledColor,
  });

  final BluetoothDevice device;
  final bool dense;
  final bool enableBleUUIDPage;
  final bool disable;
  final Color? disabledColor;

  @override
  State<ConnectedDeviceTile> createState() => _ConnectedDeviceTileState();
}

class _ConnectedDeviceTileState extends State<ConnectedDeviceTile> {
  bool animate = false;
  String aniDevUUID = '';

  @override
  Widget build(BuildContext context) {
    return BiSlidable(
      enabled: !widget.disable,
      actions: <BiAction>[
        BiAction(
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: AdaptiveIcons.open_external,
          onPressed: widget.enableBleUUIDPage
              ? (context) => AdaptiveNavigator.push(
                    context,
                    builder: (context) => BleUUID(device: widget.device, previousPageTitle: AppLocalizations.of(context)!.settings),
                  )
              : null,
        ),
        BiAction(
          backgroundColor: Theme.of(context).colorScheme.error,
          icon: AdaptiveIcons.delete_fill,
          onPressed: (context) => dismissItem(context, widget.device),
        ),
      ],
      builder: (context) => buildTile(context, widget.device),
    );
  }

  Widget buildTile(BuildContext context, BluetoothDevice device) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        AdaptiveListTile(
          enabled: !widget.disable,
          dense: widget.dense,
          onTap: () {
            setState(() {
              animate = !animate;
              aniDevUUID = device.remoteId.toString();
            });
            Timer(const Duration(milliseconds: 500), () => setState(() => animate = !animate));
          },
          title: Row(
            children: [
              Text(
                device.deviceName,
                style: TextStyle(
                  color: widget.disable ? widget.disabledColor ?? Theme.of(context).disabledColor : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 15),
              if (!kDebugMode) MyBatteryIndicator(device: device),
            ],
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          right: (animate && aniDevUUID == device.remoteId.toString()) ? 40 : 15,
          curve: animate ? Curves.easeOut : Curves.bounceOut,
          child: Icon(AdaptiveIcons.chevron_left, color: widget.disable ? widget.disabledColor ?? Theme.of(context).disabledColor : Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Future<void> dismissItem(BuildContext context, BluetoothDevice device) async {
    await device.disconnect();
    if (!context.mounted) return;
    unawaited(MyToast.showToast(message: '${device.deviceName} ${AppLocalizations.of(context)!.disconnected}'));
  }
}
