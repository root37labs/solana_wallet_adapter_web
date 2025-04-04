/// Imports
/// ------------------------------------------------------------------------------------------------

// In order to *not* need this ignore, consider extracting the "web" version of your plugin as a 
// separate package, instead of inlining it in the same package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' show window;
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:solana_wallet_adapter_platform_interface/channels.dart';
import 'package:solana_wallet_adapter_platform_interface/solana_wallet_adapter_platform.dart';
import 'solana_wallet_adapter_android_platform.dart';
import 'solana_wallet_adapter_desktop_platform.dart';
import 'solana_wallet_adapter_ios_platform.dart';
import 'solana_wallet_adapter_web_platform.dart';


/// Solana Wallet Adapter Web
/// ------------------------------------------------------------------------------------------------

/// A Solana wallet adapter for Web.
abstract class SolanaWalletAdapterWeb implements SolanaWalletAdapterPlatform {

  /// 
  static SolanaWalletAdapterWebPlatform get platform 
    => SolanaWalletAdapterPlatform.instance as SolanaWalletAdapterWebPlatform;
  
  /// Creates a [SolanaWalletAdapterWeb] and sets it as the [SolanaWalletAdapterPlatform.instance].
  static void registerWith(final Registrar registrar) {
    SolanaWalletAdapterPlatform.instance = _createSolanaWalletAdapterWebPlatform();
    // Setup the web/javascript side of the method channel...
    const String name = SolanaWalletAdapterPlatform.channelName;
    final MethodChannel channel = MethodChannel(name, const StandardMethodCodec(), registrar);
    channel.setMethodCallHandler(_methodCall);
  }
  
  /// Creates a web/javascript platform handler.
  static SolanaWalletAdapterWebPlatform _createSolanaWalletAdapterWebPlatform() {
    final userAgent = window.navigator.userAgent.toLowerCase();
    if (RegExp(r'(iphone|ipad)').hasMatch(userAgent)) return SolanaWalletAdapterIosPlatform();
    if(userAgent.contains('android')) return SolanaWalletAdapterAndroidPlatform();
    return SolanaWalletAdapterDesktopPlatform();
  }

  /// Maps incoming method channel calls (Flutter -> Platform) to the platform handler.
  static Future _methodCall(final MethodCall call) {
    switch(MethodName.values.byName(call.method)) {
      case MethodName.openUri:
        final arguments = OpenUriArguments.fromJson(call.arguments);
        return SolanaWalletAdapterPlatform.instance.openUri(arguments.uri, arguments.target);
      case MethodName.openWallet:
        final arguments = OpenWalletArguments.fromJson(call.arguments);
        return SolanaWalletAdapterPlatform.instance.openWallet(arguments.uri);
    }
  }
}