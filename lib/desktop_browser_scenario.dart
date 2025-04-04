/// Imports
/// ------------------------------------------------------------------------------------------------

import 'package:solana_wallet_adapter_platform_interface/exceptions.dart';
import 'package:solana_wallet_adapter_platform_interface/scenarios.dart';
import 'package:solana_wallet_adapter_platform_interface/solana_wallet_adapter_platform.dart';
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'desktop_browser_provider.dart';
import 'desktop_browser_session.dart';
import 'providers/phantom_desktop_browser_provider.dart';
import 'providers/solflare_desktop_browser_provider.dart';


/// Desktop Browser Scenario
/// ------------------------------------------------------------------------------------------------

/// A scenario that connects a web dApp to a desktop wallet application.
class DesktopBrowserScenario extends Scenario {
  
  /// Creates a Desktop browser scenario.
  DesktopBrowserScenario({
    final Duration? timeLimit,
  }): super(timeLimit: timeLimit);

  @override
  Future<void> dispose() async {}

  @override
  Future<DesktopBrowserSession> connect({
    final Duration? timeLimit, 
    final Uri? walletUriBase,
  }) async {
    
    final AppInfo? info = _info(walletUriBase);

    if (info == null) {
      throw _walletNotFound('The wallet application does not exist.');
    }

    final DesktopBrowserProvider? provider = _provider(info);

    if (provider == null || provider.object() == null) {
      throw _walletNotFound('The wallet application is not installed.');
    }

    return DesktopBrowserSession(provider);
  }

  /// Returns the application information for [walletUriBase].
  AppInfo? _info(final Uri? walletUriBase) {
    final RegExp trimLeadingSlashes = RegExp(r'^\s*/*');
    final String? path = walletUriBase?.path.replaceFirst(trimLeadingSlashes, '');
    final List<AppInfo> apps = SolanaWalletAdapterPlatform.instance.store.apps;
    if (path == null) apps.isEmpty ? null : apps.first;
    return apps.isEmpty ? null : apps.firstWhere(
      (app) => path == app.schemePath, 
      orElse: () => apps.first,
    );
  }

  /// Returns the wallet provider for app [info].
  DesktopBrowserProvider? _provider(final AppInfo info) {
    switch (info.app) {
      case App.phantom:
        return PhantomDesktopBrowserProvider(info);
      case App.solflare:
        return SolflareDesktopBrowserProvider(info);
    }
  }

  /// Creates a `walletNotFound` exception.
  SolanaWalletAdapterException _walletNotFound(
    final String message, 
  ) => SolanaWalletAdapterException(
      message,
      code: SolanaWalletAdapterExceptionCode.walletNotFound,
    );
}