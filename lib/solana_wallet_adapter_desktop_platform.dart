/// Imports
/// ------------------------------------------------------------------------------------------------

import 'dart:js' as js show JsObject;
import 'package:flutter/services.dart';
import 'package:solana_common/convert.dart' show base58Encode;
import 'package:solana_common/models.dart';
import 'package:solana_wallet_adapter_platform_interface/channels.dart' show WebListener;
import 'package:solana_wallet_adapter_platform_interface/models.dart';
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'desktop_browser_provider.dart';
import 'desktop_browser_scenario.dart';
import 'desktop_browser_session.dart';
import 'solana_wallet_adapter_web_platform.dart';


/// Solana Wallet Adapter Desktop Platform
/// ------------------------------------------------------------------------------------------------

/// A Solana wallet adapter for Desktop browsers.
class SolanaWalletAdapterDesktopPlatform extends SolanaWalletAdapterWebPlatform {
  
  /// The event callback handler.
  WebListener? _listener;

  @override
  StoreInfo get store => WebStore.instance;

  @override
  bool get isDesktopBrowser => true;

  @override
  Future<void> initializeWeb(
    final AuthorizeResult? result, 
    final WebListener listener,
  ) async {
    _listener = listener;
    final String? authToken = result?.authToken;
    final Uri? walletUriBase = result?.walletUriBase;
    if (authToken != null && walletUriBase != null) {
      try {
        const AppIdentity identity = AppIdentity();
        final DesktopBrowserScenario scenario = this.scenario();
        final DesktopBrowserSession session = await scenario.connect(walletUriBase: walletUriBase);
        await session.reauthorize(ReauthorizeParams(identity: identity, authToken: authToken));
      } catch (_) {
        // Ignore any errors. Attempts to reconnect the dApp when launched are done on a 
        // "best efforts" basis, the wallet extension may have been uninstalled.
        // print('INIT WEB ERROR $_');
      }
    }
  }

  @override
  void addListeners(final DesktopBrowserProvider provider) {
    final js.JsObject? object = provider.object();
    removeListeners(provider);
    object?.callMethod('on', ['connect', _onConnect]);
    object?.callMethod('on', ['disconnect', _onDisconnect]);
    object?.callMethod('on', ['accountChanged', _onAccountChanged]);
  }

  @override
  void removeListeners(final DesktopBrowserProvider provider) {
    final js.JsObject? object = provider.object();
    object?.callMethod('removeAllListeners');
  }

  /// The `on connect` callback handler.
  void _onConnect(final dynamic pubkey) {
    _listener?.onConnect(Account.fromBase58(pubkey.toString()));
  }

  /// The `on disconnect` callback handler.
  void _onDisconnect() {
    _listener?.onDisconnect();
  }

  /// The `on account changed` callback handler.
  void _onAccountChanged(final dynamic pubkey) {
    _listener?.onAccountChanged(Account.tryFromBase58(pubkey?.toString()));
  }
  
  @override
  DesktopBrowserScenario scenario({ 
    final Duration? timeLimit, 
  }) => DesktopBrowserScenario(
    timeLimit: timeLimit,
  );

  @override
  Future<bool> openWallet(
    final Uri uri, 
  ) => throw MissingPluginException(
    'Desktop browsers do not implement "openWallet".',
  );

  @override
  String encodeTransaction(
    final TransactionSerializableMixin transaction, {
    required final TransactionSerializableConfig config,
  }) => base58Encode(Uint8List.fromList(transaction.serializeMessage().toList(growable: false)));

  @override
  String encodeMessage(final String message) => message;

  @override
  String encodeAccount(final Account account) => account.toBase58();
}