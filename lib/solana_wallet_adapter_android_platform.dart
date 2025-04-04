/// Imports
/// ------------------------------------------------------------------------------------------------

import 'package:solana_wallet_adapter_platform_interface/channels.dart' show WindowTarget;
import 'package:solana_wallet_adapter_platform_interface/scenarios.dart';
import 'package:solana_wallet_adapter_platform_interface/solana_wallet_adapter_platform.dart';
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'solana_wallet_adapter_web_platform.dart';


/// Solana Wallet Adapter Android Platform
/// ------------------------------------------------------------------------------------------------

/// A Solana wallet adapter for Android mobile browsers.
class SolanaWalletAdapterAndroidPlatform extends SolanaWalletAdapterWebPlatform {

  @override
  StoreInfo get store => PlayStore.instance;
  
  @override
  Scenario scenario({ 
    final Duration? timeLimit, 
  }) => MobileAssociationScenario(
    timeLimit: timeLimit,
  );
  
  @override
  Future<bool> openWallet(final Uri uri) {
    final String scheme = uri.scheme;
    final RegExp pattern = RegExp('^$scheme:(//)?');
    final String path = uri.toString().replaceFirst(pattern, '');
    final Uri intent = Uri.parse(
      'intent:'
        '$path'
        '#Intent;'
          'action=android.intent.action.VIEW;'
          'category=android.intent.category.BROWSABLE;'
          'scheme=$scheme;'
        'end;'
    );
    return SolanaWalletAdapterPlatform.instance.openUri(intent, WindowTarget.blank);
  }
}