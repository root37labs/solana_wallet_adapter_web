/// Imports
/// ------------------------------------------------------------------------------------------------

import 'dart:html' show window;
import 'package:solana_wallet_adapter_platform_interface/channels.dart' show WindowTarget;
import 'package:solana_wallet_adapter_platform_interface/solana_wallet_adapter_platform.dart';
import 'desktop_browser_provider.dart';


/// Solana Wallet Adapter Web Platform
/// ------------------------------------------------------------------------------------------------

/// The interface for web based Solana wallet adapter platforms.
abstract class SolanaWalletAdapterWebPlatform extends SolanaWalletAdapterPlatform {

  /// Adds event listeners to the wallet [provider].
  void addListeners(final DesktopBrowserProvider provider) {
    /// See [SolanaWalletAdapterDesktopPlatform].
  }

  /// Removes event listeners from the wallet [provider].
  void removeListeners(final DesktopBrowserProvider provider) {
    /// See [SolanaWalletAdapterDesktopPlatform].
  }

  @override
  Future<bool> openUri(final Uri uri, [final String? target]) {
    final String uriString = uri.toString();
    final String targetName = target ?? WindowTarget.self;
    switch(targetName) {
      case WindowTarget.self:
        window.location.assign(uriString);
        break;
      case WindowTarget.blank:
      case WindowTarget.parent:
      case WindowTarget.top:
        window.open(uriString, targetName);
        break;
    }
    return Future.value(true);
  }
}