/// Imports
/// ------------------------------------------------------------------------------------------------

import 'package:js/js.dart';
import '../desktop_browser_interoperability.dart';
import '../desktop_browser_provider.dart';
import '../desktop_browser_session.dart';


/// Solflare Javascript Methods
/// ------------------------------------------------------------------------------------------------

@JS('${SolflareDesktopBrowserProvider.key}.request')
external dynamic solflareRequest(final ProviderRequest request);


/// Solflare Desktop Browser Provider
/// ------------------------------------------------------------------------------------------------

class SolflareDesktopBrowserProvider extends DesktopBrowserProvider {

  SolflareDesktopBrowserProvider(super.info)
    : assert(info.schemePath == key);

  /// The Javascript Window key and unique id.
  static const String key = 'solflare';

  @override
  dynamic request<T>(final ProviderRequest<T> request) => solflareRequest(request);

  @override
  Future<Map<String, dynamic>> connect({final bool? onlyIfTrusted}) async {
    await super.connect(onlyIfTrusted: onlyIfTrusted);
    final key = DesktopBrowserSession.pubkeyKey;
    return { key: object()?[key] };
  }
}