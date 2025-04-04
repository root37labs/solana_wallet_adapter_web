/// Imports
/// ------------------------------------------------------------------------------------------------

import 'dart:html';
import 'dart:js' as js show context, JsObject;
import 'package:flutter/foundation.dart' show protected;
import 'package:solana_jsonrpc/jsonrpc.dart' show JsonRpcException;
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'desktop_browser_interoperability.dart';


/// Desktop Browser Provider
/// ------------------------------------------------------------------------------------------------

/// An interface for browser wallet extensions.
abstract class DesktopBrowserProvider {

  /// Creates a wallet provider.
  const DesktopBrowserProvider(this.info);

  /// The wallet application's information.
  final AppInfo info;

  /// Returns the provider's javascript object or null if the provider is not installed.
  js.JsObject? object() => info.schemePath.split('.').fold(js.context, (object, key) => object?[key]);

  /// Processes a JSON RPC request and returns its result.
  Future<Map<String, dynamic>> _send(final dynamic promise) async {
    try {
      return await promiseToFutureAsMap(promise) ?? const {};
    } catch (error) {
      final dynamic json = jsToDart(error);
      final bool isErrorObject = json is Map<String, dynamic> && json.containsKey('message');
      return Future.error(isErrorObject ? JsonRpcException.fromJson(json) : error);
    }
  }

  /// Makes a JSON RPC [request] to the wallet provider.
  @protected
  dynamic request<T>(final ProviderRequest<T> request);

  /// Makes a request to connect the wallet provider.
  /// 
  /// After a web application connects to Phantom for the first time, it becomes trusted. Once 
  /// trusted, it's possible for the application to automatically connect to Phantom on subsequent 
  /// visits or page refreshes, without prompting the user for permission. This is referred to as 
  /// "eagerly connecting". To implement this, applications should pass an onlyIfTrusted option into 
  /// the connect() call.
  Future<Map<String, dynamic>> connect({ 
    final bool? onlyIfTrusted, 
  }) => _send(request(ProviderRequest( 
      method: 'connect', 
      params: ConnectParams(
        onlyIfTrusted: onlyIfTrusted ?? false,
      ), 
    )));

  /// Makes a request to disconnect the wallet provider.
  Future<Map<String, dynamic>> disconnect() 
    => _send(request(ProviderRequest( 
      method: 'disconnect', 
      params: DisconnectParams(), 
    )));
  
  /// Makes a request to sign a transaction [message].
  Future<Map<String, dynamic>> signTransaction(
    final String message, 
  ) => _send(request(ProviderRequest( 
      method: 'signTransaction', 
      params: SignTransactionParams(
        message: message,
      ),
    )));

  /// Makes a request to sign all transaction [messages].
  Future<Map<String, dynamic>> signAllTransactions(
    final List<String> messages, 
  ) => _send(request(ProviderRequest( 
      method: 'signAllTransactions', 
      params: SignAllTransactionsParams(
        messages: toJsArray(messages),
      ),
    )));

  /// Makes a request to sign and send a transaction [message] to the network.
  Future<Map<String, dynamic>> signAndSendTransaction(
    final String message, {
    final int? minContextSlot,
  }) => _send(request(ProviderRequest( 
      method: 'signAndSendTransaction', 
      params: SignAndSendTransactionParams(
        message: message, 
        options: SendOptions(
          minContextSlot: minContextSlot,
        ),
      ),
    )));

  /// Makes a request to sign a transaction [message] (hex or UTF-8 encoded string as a Uint8Array).
  Future<Map<String, dynamic>> signMessage(
    final List<int> message, [
    final String encoding = 'utf8',
  ]) {
    assert(
      encoding == 'hex' || encoding == 'utf8',
      'Unknown encoding "$encoding" for provider method [signMessage].',
    );
    return _send(request(ProviderRequest( 
      method: 'signMessage', 
      params: SignMessageParams(
        message: message,
        display: encoding,
      ),
    )));
  }
}