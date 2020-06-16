
import 'orchid_pac.dart';
import 'orchid_purchase.dart';

class AndroidOrchidPurchaseAPI implements OrchidPurchaseAPI {

  /// Default prod service endpoint configuration.
  /// May be overridden in configuration with e.g.
  /// 'pacs = {
  ///    enabled: true,
  ///    url: 'https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev/apple',
  ///    verifyReceipt: false,
  ///    debug: true
  ///  }'
  static PACApiConfig prodAPIConfig = PACApiConfig(
      enabled: false,
      url: 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/google');

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PACApiConfig> apiConfig() async {
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
  Future<Map<String,PAC>> requestProducts() {
    // TODO: implement requestProducts
    throw UnimplementedError();
  }
}

