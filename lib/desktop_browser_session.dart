/// Imports
/// ------------------------------------------------------------------------------------------------

import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;
import 'package:solana_wallet_adapter_platform_interface/models.dart';
import 'package:solana_wallet_adapter_platform_interface/sessions.dart';
import 'package:solana_wallet_adapter_platform_interface/stores.dart';
import 'package:solana_web3/buffer.dart';
import 'package:solana_web3/solana_web3.dart';
import 'desktop_browser_provider.dart';
import 'solana_wallet_adapter_web.dart';


/// Desktop Browser Session
/// ------------------------------------------------------------------------------------------------

/// Connects a web dApp to a desktop browser wallet extension.
class DesktopBrowserSession extends Session {

  /// Creates a desktop browser session for [provider].
  const DesktopBrowserSession(
    this.provider,
  );

  /// The web browser's wallet extension.
  final DesktopBrowserProvider provider;

  /// The public key's JSON key value.
  static String get pubkeyKey => 'publicKey';

  /// The transaction's JSON key value.
  static String get transactionKey => 'transaction';

  /// The payload's JSON key value.
  static String get payloadKey => 'payload';

  /// The payloads' JSON key value.
  static String get payloadsKey => 'payloads';

  /// The signature's JSON key value.
  static String get signatureKey => 'signature';

  /// The signatures' JSON key value.
  static String get signaturesKey => 'signatures';

  /// Generates a random string to be used as an auth token.
  String generateAuthToken() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<AuthorizeResult> authorize(
    final AuthorizeParams params, { 
    final bool? onlyIfTrusted, 
  }) async {
    SolanaWalletAdapterWeb.platform.addListeners(provider);
    final Map<String, dynamic> response = await provider.connect(onlyIfTrusted: onlyIfTrusted);
    final String address = response[pubkeyKey].toString();
    final AppInfo app = provider.info;
    return AuthorizeResult(
      accounts: [Account.fromBase58(address)], 
      authToken: generateAuthToken(), 
      walletUriBase: Uri.https(app.host, app.schemePath),
    );
  }

  @override
  Future<DeauthorizeResult> deauthorize(final DeauthorizeParams params) async {
    try {
      await provider.disconnect();
    } finally {
      SolanaWalletAdapterWeb.platform.removeListeners(provider);
    }
    return const DeauthorizeResult();
  }

  @override
  Future<ReauthorizeResult> reauthorize(
    final ReauthorizeParams params, 
  ) => authorize(
      AuthorizeParams(identity: params.identity, cluster: null), 
      onlyIfTrusted: true,
    );

  @override
  Future<GetCapabilitiesResult> getCapabilities() async 
    => const GetCapabilitiesResult(
      supportsCloneAuthorization: false, 
      supportsSignAndSendTransactions: true, 
      maxTransactionsPerRequest: 1, 
      maxMessagesPerRequest: 1,
    );

  @override
  Future<CloneAuthorizationResult> cloneAuthorization() async 
    => CloneAuthorizationResult(authToken: generateAuthToken());

  @override
  Future<SignTransactionsResult> signTransactions(
    final SignTransactionsParams params,
  ) => params.payloads.length == 1 ? _signTransaction(params) : _signAllTransactions(params);

  /// Signs a single transaction.
  /// 
  /// {@macro solana_wallet_adapter_platform_interface.Session.signTransactions}
  Future<SignTransactionsResult> _signTransaction(
    final SignTransactionsParams params,
  ) async {
    final String message = params.payloads.first;
    final Map<String, dynamic> response = await provider.signTransaction(message);
    return SignTransactionsResult(
      signedPayloads: [_signedPayload(message, response)],
    );
  }

  /// Signs a multiple transactions.
  /// 
  /// {@macro solana_wallet_adapter_platform_interface.Session.signTransactions}
  Future<SignTransactionsResult> _signAllTransactions(
    final SignTransactionsParams params,
  ) async {
    final List<String> messages = params.payloads;
    final Map<String, dynamic> response = await provider.signAllTransactions(messages);
    return SignTransactionsResult(
      signedPayloads: _signedPayloads(messages, response),
    );
  }

  @override
  Future<SignAndSendTransactionsResult> signAndSendTransactions(
    final SignAndSendTransactionsParams params,
  ) async {
    _checkSinglePayload(params.payloads, 'signAndSendTransactions');
    final Map<String, dynamic> response = await provider.signAndSendTransaction(
      params.payloads.first, 
      minContextSlot: params.options?.minContextSlot,
    );
    return SignAndSendTransactionsResult(
      signatures: [_encodeSignature(response)],
    );
  }

  @override
  Future<SignMessagesResult> signMessages(final SignMessagesParams params) async {
    _checkSinglePayload(params.payloads, 'signMessage');
    final Map<String, dynamic> response = await provider.signMessage(
      utf8.encode(params.payloads.first), 
    );
    return SignMessagesResult(
      signedPayloads: [_encodeSignature(response)],
    );
  }
  
  /// Checks that [method] is being called with a single item in [payloads].
  /// 
  /// Throws a [JsonRpcException] with error code [JsonRpcExceptionCode.methodNotFound] if 
  /// [payloads] does not contain exactly 1 item.
  void _checkSinglePayload(
    final Iterable payloads, 
    final String method, 
  ) => checkThrow(
      payloads.length == 1, 
      () => JsonRpcException(
        "The current platform's implementation of [$method] does not support multiple payloads.",
        code: JsonRpcExceptionCode.methodNotFound,
      ),
    );
  
  /// Encodes a base-58 encoded signature to base-64.
  String _encodeSignature(final dynamic response)
    => base58To64Encode(response is String ? response : response[signatureKey]);

  /// Encodes a base-58 encoded transaction to base-64.
  String _encodeTransaction(final dynamic payload)
    => base58To64Encode(payload is String ? payload : payload[transactionKey]);

  /// Serializes [message] and [signatures] into an encoded transaction.
  String _serializeTransaction(final String message, final List<String> signatures) {
    final Message decodedMessage = Message.fromBase58(message);
    final List<Uint8List> decodedSignatures = signatures.map(
      (signature) => Uint8List.fromList(base58.decode(signature)),
    ).toList(growable: false);
    final Transaction tx = Transaction(signatures: decodedSignatures, message: decodedMessage);
    const config = TransactionSerializableConfig(requireAllSignatures: false);
    return tx.serialize(config).getString(BufferEncoding.base64);
  }

  /// Converts [response] into a signed transaction payload.
  String _signedPayload(
    final String message, 
    final Map<String, dynamic> response,
  ) {
    if (response.containsKey(payloadKey)) {
      return _encodeTransaction(response[payloadKey]);
    } else if (response.containsKey(signatureKey)) {
      final String signature = response[signatureKey];
      return _serializeTransaction(message, [signature]);
    } else {
      throw const FormatException('Unknown wallet adapter response.');
    }
  }

  /// Converts [response] into a signed transaction payload.
  List<String> _signedPayloads(
    final List<String> messages, 
    final Map<String, dynamic> response,
  ) {
    if (response.containsKey(payloadsKey)) {
      final List payloads = response[payloadsKey];
      return payloads.map(_encodeTransaction).toList(growable: false);
    } else if (response.containsKey(signaturesKey)) {
      final List<String> signedPayloads = [];
      final List signatures = response[signaturesKey];
      for (int i = 0; i < messages.length; ++i) {
        final String message = messages[i];
        final String signature = signatures[i];
        signedPayloads.add(_serializeTransaction(message, [signature]));
      }
      return signedPayloads;
    } else {
      throw const FormatException('Unknown wallet adapter response.');
    }
  }
}