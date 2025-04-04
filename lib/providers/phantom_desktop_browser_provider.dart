/// Imports
/// ------------------------------------------------------------------------------------------------

import 'package:js/js.dart';
import '../desktop_browser_interoperability.dart';
import '../desktop_browser_provider.dart';


/// Phantom Javascript Methods
/// ------------------------------------------------------------------------------------------------

@JS('${PhantomDesktopBrowserProvider.key}.request')
external dynamic phantomRequest(final ProviderRequest request);


/// Phantom Desktop Browser Provider
/// ------------------------------------------------------------------------------------------------

class PhantomDesktopBrowserProvider extends DesktopBrowserProvider {

  PhantomDesktopBrowserProvider(super.info)
    : assert(info.schemePath == key);

  /// The Javascript Window key and unique id.
  static const String key = 'phantom.solana';

  @override
  dynamic request<T>(final ProviderRequest<T> request) => phantomRequest(request);
}