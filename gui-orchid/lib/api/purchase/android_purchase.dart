import 'orchid_pac.dart';
import 'orchid_purchase.dart';

class AndroidOrchidPurchaseAPI implements OrchidPurchaseAPI {
  /// Default prod service endpoint configuration.
  /// May be overridden in configuration with e.g.
  /// 'pacs = {
  ///    enabled: true,
  ///    url: 'https://xxx.amazonaws.com/dev/apple',
  ///    verifyReceipt: false,
  ///    debug: true
  ///  }'
  static PacApiConfig prodAPIConfig = PacApiConfig(
    enabled: false,
    url: 'https://api.orchid.com/pac/google',
  );

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PacApiConfig> apiConfig() async {
    return OrchidPurchaseAPI.apiConfigWithOverrides(prodAPIConfig);
  }

  @override
  initStoreListener() {
    // TODO: implement initStoreListener
  }

  Future<void> purchase(PAC pac) {
    // TODO: implement purchase
  }

  @override
  Future<Map<String, PAC>> requestProducts({bool refresh = false}) {
    // TODO: implement requestProducts
    throw UnimplementedError();
  }
}
