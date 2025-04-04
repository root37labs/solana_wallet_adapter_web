/// Imports
/// ------------------------------------------------------------------------------------------------

import 'package:solana_wallet_adapter_platform_interface/channels.dart' show WindowTarget;
import 'package:solana_wallet_adapter_platform_interface/scenarios.dart';
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'solana_wallet_adapter_web_platform.dart';


/// Solana Wallet Adapter iOS Platform
/// ------------------------------------------------------------------------------------------------

/// A Solana wallet adapter for iOS mobile browsers.
class SolanaWalletAdapterIosPlatform extends SolanaWalletAdapterWebPlatform {

  @override
  StoreInfo get store => AppStore.instance;
  
  @override
  Scenario scenario({ 
    final Duration? timeLimit, 
  }) => MobileAssociationScenario(
    timeLimit: timeLimit,
  );
  
  @override
  Future<bool> openWallet(final Uri uri) => openUri(uri, WindowTarget.blank);
}