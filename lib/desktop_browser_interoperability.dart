/// Imports
/// ------------------------------------------------------------------------------------------------

import 'dart:typed_data' show ByteBuffer;
import 'package:js/js.dart' show anonymous, JS;
import 'package:js/js_util.dart' show getProperty;


/// Desktop Extension Javascript Mappings
/// ------------------------------------------------------------------------------------------------

@JS('Object.keys')
external List<String> objectKeys(value);

@JS('Array.prototype.slice.call')
external dynamic toJsArray(value);

/// Returns true if value is a basic scalar data type.
bool _isBasicType(final dynamic value)
  => value == null || value is num || value is bool || value is String;

/// Converts a javascript object to a dart type.
dynamic jsToDart(final dynamic jsObject) {

  if (_isBasicType(jsObject)) {
    return jsObject;
  }

  if (jsObject is ByteBuffer) {
    return jsObject.asUint8List();
  }

  if (jsObject is Iterable) {
    return List.from(jsObject);
  }

  final keys = objectKeys(jsObject);
  final result = <String, dynamic>{};
  for (final String key in keys) {
    result[key] = jsToDart(getProperty(jsObject, key));
  }
  return result;
}

@JS()
@anonymous
class ProviderRequest<T> {
  external factory ProviderRequest({ method, params });
  external String get method;
  external T get params;
}

@JS()
@anonymous
class ConnectParams {
  external factory ConnectParams({ onlyIfTrusted });
  external bool? get onlyIfTrusted;
}

@JS()
@anonymous
class DisconnectParams {
  external factory DisconnectParams();
}

@JS()
@anonymous
class SignTransactionParams {
  external factory SignTransactionParams({ message });
  external String get message;
}

@JS()
@anonymous
class SignAllTransactionsParams {
  external factory SignAllTransactionsParams({ messages });
  external dynamic get messages;
}

@JS()
@anonymous
class SignAndSendTransactionParams {
  external factory SignAndSendTransactionParams({ message, options });
  external String get message;
  external SendOptions get options;
}

@JS()
@anonymous
class SendOptions {
  external factory SendOptions({ minContextSlot });
  external int? get minContextSlot;
}

@JS()
@anonymous
class SignMessageParams {
  external factory SignMessageParams({ message, display });
  external List<int> get message;
  external String get display;
}