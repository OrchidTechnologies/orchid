// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class STr extends S {
  STr([String locale = 'tr']) : super(locale);

  @override
  String get orchidHop => 'Orchid Ağ Atlaması';

  @override
  String get orchidDisabled => 'Orchid devre dışı';

  @override
  String get trafficMonitoringOnly => 'Sadece trafik izleme';

  @override
  String get orchidConnecting => 'Orchid bağlanıyor';

  @override
  String get orchidDisconnecting => 'Orchid bağlantısı kesiliyor';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num atlama yapılandırıldı',
      two: 'İki atlama yapılandırıldı',
      one: 'Bir atlama yapılandırıldı',
      zero: 'Yapılandırılmış atlama yok',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Sil';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Ağ Atlaması';

  @override
  String get traffic => 'Trafik';

  @override
  String get curation => 'Kürasyon';

  @override
  String get signerKey => 'İmzacı Anahtar';

  @override
  String get copy => 'Kopyala';

  @override
  String get paste => 'Yapıştır';

  @override
  String get deposit => 'Depozito';

  @override
  String get curator => 'Küratör';

  @override
  String get ok => 'Tamam';

  @override
  String get settingsButtonTitle => 'AYARLAR';

  @override
  String get confirmThisAction => 'Eylemi doğrulayın';

  @override
  String get cancelButtonTitle => 'İPTAL';

  @override
  String get changesWillTakeEffectInstruction =>
      'Değişiklikler, VPN yeniden başlatıldığında geçerli olacaktır.';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get configurationSaved => 'Yapılandırma kaydedildi';

  @override
  String get whoops => 'Eyvah';

  @override
  String get configurationFailedInstruction =>
      'Yapılandırma kaydedilemedi. Lütfen söz dizimini kontrol edin ve tekrar deneyin.';

  @override
  String get addHop => 'Ağ Atlaması Ekle';

  @override
  String get scan => 'Tara';

  @override
  String get invalidQRCode => 'Geçersiz QR Kodu';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Tarattığınız QR kodu, geçerli bir hesap yapılandırması içermiyor.';

  @override
  String get invalidCode => 'Geçersiz Kod';

  @override
  String get theCodeYouPastedDoesNot =>
      'Yapıştırdığınız kod, geçerli bir hesap yapılandırması içermiyor.';

  @override
  String get openVPNHop => 'OpenVPN Ağ Atlaması';

  @override
  String get username => 'Kullanıcı Adı';

  @override
  String get password => 'Parola';

  @override
  String get config => 'Yapılandırma';

  @override
  String get pasteYourOVPN => 'OVPN yapılandırma dosyanızı buraya yapıştırın';

  @override
  String get enterYourCredentials => 'Kimlik bilgilerinizi girin';

  @override
  String get enterLoginInformationInstruction =>
      'VPN sağlayıcınızın giriş bilgilerini yukarıya girin. Daha sonra sağlayıcınızın OpenVPN yapılandırma dosyasının içeriğini, verilen alana yapıştırın.';

  @override
  String get save => 'Kaydet';

  @override
  String get help => 'Yardım';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get openSourceLicenses => 'Açık Kaynak Lisansları';

  @override
  String get settings => 'Ayarlar';

  @override
  String get version => 'Sürüm';

  @override
  String get noVersion => 'Sürüm yok';

  @override
  String get orchidOverview => 'Orchid\'e Genel Bakış';

  @override
  String get defaultCurator => 'Varsayılan Küratör';

  @override
  String get queryBalances => 'Bakiyeleri Sorgula';

  @override
  String get reset => 'Sıfırla';

  @override
  String get manageConfiguration => 'Yapılandırmayı Yönet';

  @override
  String get warningThesefeature =>
      'Uyarı: Bu özellikler ileri düzey kullanıcılara yöneliktir. Lütfen tüm talimatları okuyun.';

  @override
  String get exportHopsConfiguration =>
      'Ağ Atlaması Yapılandırmasını Dışarı Aktarın';

  @override
  String get export => 'Dışarı Aktar';

  @override
  String get warningExportedConfiguration =>
      'Uyarı: Dışarı aktarılan yapılandırmalar, dışa aktarılan ağ atlamaları için imzalama işlemini yapan gizli anahtarları da içerir. Bu gizli anahtarların açığa çıkması, ilişkili Orchid hesaplarındaki tüm fonların kaybıyla sonuçlanabilir.';

  @override
  String get importHopsConfiguration =>
      'Ağ Atlaması Yapılandırmasını İçeri Aktarın';

  @override
  String get import => 'İçeri Aktar';

  @override
  String get warningImportedConfiguration =>
      'Uyarı: İçe aktarılan yapılandırmalar, uygulama içinde oluşturduğunuz mevcut tüm ağ atlamalarının yerine geçecektir. Daha önce oluşturulan ya da bu cihaza aktarılan, imza işlemini yapan anahtarlar korunacaktır ve yeni ağ atlamaları oluşturmak için erişilebilir olmaya devam edecektir. Ancak OpenVPN ağ atlama yapılandırması da dâhil olmak üzere tüm diğer yapılandırmalar kaybolacaktır.';

  @override
  String get configuration => 'Yapılandırma';

  @override
  String get saveButtonTitle => 'KAYDET';

  @override
  String get search => 'Ara';

  @override
  String get newContent => 'Yeni İçerik';

  @override
  String get clear => 'Temizle';

  @override
  String get connectionDetail => 'Bağlantı Detayı';

  @override
  String get host => 'Sunucu';

  @override
  String get time => 'Zaman';

  @override
  String get sourcePort => 'Kaynak Port';

  @override
  String get destination => 'Hedef';

  @override
  String get destinationPort => 'Hedef Port';

  @override
  String get generateNewKey => 'Yeni anahtar oluştur';

  @override
  String get importKey => 'Anahtarı içe aktar';

  @override
  String get nothingToDisplayYet =>
      'Henüz gösterilecek bir şey yok. Gösterilecek bir şeyler olduğunda trafik burada görüntülenecek.';

  @override
  String get disconnecting => 'Bağlantı kesiliyor...';

  @override
  String get connecting => 'Bağlanıyor...';

  @override
  String get pushToConnect => 'Bağlanmak için basın.';

  @override
  String get orchidIsRunning => 'Orchid çalışıyor!';

  @override
  String get pacPurchaseWaiting => 'Satın Alma Bekleniyor';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get getHelpResolvingIssue => 'Bu sorunu çözmek için yardım alın.';

  @override
  String get copyDebugInfo => 'Hata İçeriğini Kopyala';

  @override
  String get contactOrchid => 'Orchid ile İletişime Geç';

  @override
  String get remove => 'Kaldır';

  @override
  String get deleteTransaction => 'İşlemi Sil';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Devam eden bu işlemi silin. Bu işlem, uygulama içi satın alımınızı iade etmez. Sorunu çözmek için Orchid ile iletişime geçmelisiniz.';

  @override
  String get preparingPurchase => 'Satın Alma Hazırlanıyor';

  @override
  String get retryingPurchasedPAC => 'Satın Alma Tekrar Deneniyor';

  @override
  String get retryPurchasedPAC => 'Satın Almayı Tekrar Dene';

  @override
  String get purchaseError => 'Satın Alma Hatası';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Satın almada bir hata oluştu. Lütfen Orchid Destek ekibi ile iletişime geçin.';

  @override
  String get importAnOrchidAccount => 'Bir Orchid Hesabını İçeri Aktarın';

  @override
  String get buyCredits => 'Kredi Satın Alın';

  @override
  String get linkAnOrchidAccount => 'Orchid Hesabını Bağla';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Üzgünüz ancak bu satın alma, erişim kredilerinin günlük satın alma limitini aşıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get marketStats => 'Piyasa İstatistikleri';

  @override
  String get balanceTooLow => 'Bakiye çok düşük';

  @override
  String get depositSizeTooSmall => 'Yatırılan miktar çok az';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Maksimum bilet değeriniz şu anda şu öğenin limitiyle sınırlıdır: ';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Maksimum bilet değeriniz şu anda şu öğenin bakiyesiyle sınırlıdır: ';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Hesap bakiyenize OXT eklemeyi değerlendirin.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Yatırılan miktara OXT eklemeyi ya da bakiyenizden bir miktar fonu yatırmayı düşünün.';

  @override
  String get prices => 'Fiyatlar';

  @override
  String get ticketValue => 'Bilet Değeri';

  @override
  String get costToRedeem => 'Kullanım maliyeti:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Bu konuyla ilgili yardım almak için belgeleri görüntüleyin.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Gezinmek ve düşük aktivite için uygundur';

  @override
  String get learnMore => 'Daha fazla bilgi edinin.';

  @override
  String get connect => 'Bağlanın';

  @override
  String get disconnect => 'Bağlantıyı Kes';

  @override
  String get wireguardHop => 'WireGuard®️ Ağ Atlaması';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'WireGuard®️ yapılandırma dosyanızı buraya yapıştırın';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'WireGuard®️ sağlayıcınızdan edindiğiniz kimlik bilgisini yukarıdaki alana yapıştırın.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Veri günlüğü tamamen temizlensin mi?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Bu hata ayıklama günlüğü kalıcı değildir ve uygulamadan çıkıldığında temizlenir.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Gizli veya kişisel olarak tanımlayıcı bilgiler içerebilir.';

  @override
  String get loggingEnabled => 'Kayıt tutma etkin';

  @override
  String get cancel => 'İPTAL';

  @override
  String get logging => 'Kaydediliyor';

  @override
  String get loading => 'Yükleniyor ...';

  @override
  String get ethPrice => 'ETH fiyatı:';

  @override
  String get oxtPrice => 'OXT fiyatı:';

  @override
  String get gasPrice => 'İşlem maliyeti:';

  @override
  String get maxFaceValue => 'Maksimum nominal değer:';

  @override
  String get confirmDelete => 'Silme İşlemini Onayla';

  @override
  String get enterOpenvpnConfig => 'OpenVPN Yapılandırmasını Girin';

  @override
  String get enterWireguardConfig => 'WireGuard®️ Yapılandırmasını Girin';

  @override
  String get starting => 'Başlatılıyor...';

  @override
  String get legal => 'Yasal';

  @override
  String get whatsNewInOrchid => 'Orchid\'deki yenilikler';

  @override
  String get orchidIsOnXdai => 'Orchid, xDai\'de!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Artık xDai üzerinden Orchid kredileri satın alabilirsiniz! 1 Amerikan Doları gibi düşük bir fiyatla VPN\'yi kullanmaya başlayın.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Geçmiş satın almalar için xDai hesapları';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Bugünden önce yapılan tüm uygulama içi satın alımlar için xDai fonları aynı hesap anahtarına eklendi. Bant genişliği bizden olsun!';

  @override
  String get newInterface => 'Yeni arayüz';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Hesaplar artık ilişkili oldukları Orchid Adresi altında düzenlenmiştir.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Ana ekranda, etkin hesap bakiyenizi ve bant genişliğinizi görün.';

  @override
  String get seeOrchidcomForHelp => 'Yardım için orchid.com adresine gidin.';

  @override
  String get payPerUseVpnService => 'Kullandıkça Ödemeli VPN Hizmeti';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Abonelik değildir, kredilerin süresi dolmaz';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Hesabı sınırsız cihazla paylaşın';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Orchid Mağazası geçici olarak kullanılamıyor. Lütfen birkaç dakika içinde tekrar kontrol edin.';

  @override
  String get talkingToPacServer => 'Orchid Hesap Sunucusuyla konuşuluyor';

  @override
  String get advancedConfiguration => 'Gelişmiş Yapılandırma';

  @override
  String get newWord => 'Yeni';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get efficiency => 'Verim';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Minimum mevcut Bilet: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'İşlem Blokzincir\'e gönderildi';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Satın alma işleminiz tamamlandı ve şu anda xDai blockchain tarafından işleniyor. Bu işlem bir dakika ya da bazen daha uzun sürebilir. Yenilemek için aşağı çekin ve hesabınız, güncel bakiyeyle aşağıda görünecektir.';

  @override
  String get copyReceipt => 'Makbuzu Kopyalayın';

  @override
  String get manageAccounts => 'Hesapları Yönet';

  @override
  String get configurationManagement => 'Yapılandırma Yönetimi';

  @override
  String get exportThisOrchidKey => 'Bu Orchid Anahtarını dışarı aktarın';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Bu anahtarla ilişkili tüm Orchid hesapları için bir QR kod ve metin aşağıdadır.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Bu Orchid kimliğiyle ilişkili tüm Orchid hesaplarını paylaşmak için bu anahtarı başka bir cihazda içe aktarın.';

  @override
  String get orchidAccountInUse => 'Kullanımdaki Orchid Hesabı';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Orchid Hesabı kullanımda ve silinemez.';

  @override
  String get pullToRefresh => 'Yenilemek için çekin.';

  @override
  String get balance => 'Bakiye';

  @override
  String get active => 'Etkin';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'O hesapla ilişkili tüm Orchid hesaplarını içeri aktarmak için panodan bir Orchid anahtarı yapıştırın.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'O hesapla ilişkili tüm Orchid hesaplarını içeri aktarmak için panodan bir Orchid anahtarı taratın ya da yapıştırın.';

  @override
  String get account => 'Hesap';

  @override
  String get transactions => 'İşlemler';

  @override
  String get weRecommendBackingItUp => '<link>Yedeklemenizi</link> öneriyoruz.';

  @override
  String get copiedOrchidIdentity => 'Orchid Kimliği Kopyalandı';

  @override
  String get thisIsNotAWalletAddress => 'Bu bir cüzdan adresi değildir.';

  @override
  String get doNotSendTokensToThisAddress => 'Bu adrese token göndermeyin.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Orchid Kimliği\'niz, sizi ağda benzersiz olarak tanımlar.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      '<link>Orchid Kimliğiniz</link> hakkında daha fazlasını öğrenin.';

  @override
  String get analyzingYourConnections => 'Bağlantılarınız Analiz Ediliyor';

  @override
  String get analyzeYourConnections => 'Bağlantılarınızı Analiz Edin';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'Ağ analizi, cihazınızın VPN yeteneğini kullanarak paketleri yakalar ve trafiğinizi analiz eder.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'Ağ analizi, VPN izinleri gerektirir ancak kendi başına verinizi korumaz ya da IP adresinizi gizlemez.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Ağ gizliliğinin avantajlarından yararlanmak için ana ekrandan bir VPN bağlantısı yapılandırmalı ve onu etkinleştirmelisiniz.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Bu özelliği açmak, Orchid Uygulaması\'nın pil kullanımını artıracaktır.';

  @override
  String get useAnOrchidAccount => 'Bir Orchid Hesabı Kullan';

  @override
  String get pasteAddress => 'Adresi Yapıştır';

  @override
  String get chooseAddress => 'Adres Seçin';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Bu ağ zıplaması ile kullanmak için bir Orchid hesabı seçin.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Eğer hesabınızı aşağıda göremiyorsanız içe aktarmak, satın almak ya da yeni bir tane oluşturmak için hesap yöneticisini kullanabilirsiniz.';

  @override
  String get selectAnOrchidAccount => 'Bir Orchid Hesabı Seçin';

  @override
  String get takeMeToTheAccountManager => 'Beni Hesap Yöneticisi\'ne götür';

  @override
  String get funderAccount => 'Fon Sağlayıcı Hesabı';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid çalışıyor ve analiz ediyor';

  @override
  String get startingVpn => '(VPN başlatılıyor)';

  @override
  String get disconnectingVpn => '(VPN bağlantısı kesiliyor)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid trafiği analiz ediyor';

  @override
  String get vpnConnectedButNotRouting => '(VPN bağlı ancak yönlendirmiyor)';

  @override
  String get restarting => 'Yeniden Başlatılıyor';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'İzleme durumunu değiştirmek için VPN\'nin yeniden başlatılması gerekir, bu da gizlilik korumanızı kısa süreliğine kesintiye uğratabilir.';

  @override
  String get confirmRestart => 'Yeniden Başlatmayı Onayla';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Ortalama fiyat GB başına $price USD\'dir';
  }

  @override
  String get myOrchidConfig => 'Orchid Yapılandırmam';

  @override
  String get noAccountSelected => 'Seçili hesap yok';

  @override
  String get inactive => 'Etkin değil';

  @override
  String get tickets => 'Biletler';

  @override
  String get accounts => 'Hesaplar';

  @override
  String get orchidIdentity => 'Orchid Kimliği';

  @override
  String get addFunds => 'FON EKLE';

  @override
  String get addFunds2 => 'Para Ekle';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Atlama';

  @override
  String get circuit => 'Devre';

  @override
  String get clearAllAnalysisData => 'Analiz verileri tamamen temizlensin mi?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Bu işlem, daha önce analiz edilmiş tüm trafik bağlantısı verisini temizleyecektir.';

  @override
  String get clearAll => 'HEPSİNİ TEMİZLE';

  @override
  String get stopAnalysis => 'ANALİZİ DURDUR';

  @override
  String get startAnalysis => 'ANALİZİ BAŞLAT';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Orchid hesaplarına 7/24 müşteri desteği, sınırsız cihaz dâhildir ve <link2>xDai kripto para birimi</link2> ile desteklenir.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Satın alınmış hesaplar, özel olarak <link1>tercih edilen sağlayıcılarımıza</link1> bağlanırlar.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Uygulama mağazalarının geri ödeme politikalarına tabidir.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid şu anda uygulama içi satın alımları görüntüleyemiyor.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Lütfen bu cihazın uygulama içi satın alımları desteklediğini ve buna uygun şekilde ayarlandığını onaylayın.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Lütfen bu cihazın uygulama içi satın alımları desteklediğini ve buna uygun şekilde ayarlandığını onaylayın ya da merkezi olmayan <link>hesap yönetimi</link> sistemimizi kullanın.';

  @override
  String get buy => 'SATIN AL';

  @override
  String get gbApproximately12 => '12GB (yaklaşık)';

  @override
  String get gbApproximately60 => '60GB (yaklaşık)';

  @override
  String get gbApproximately240 => '240GB (yaklaşık)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Gezinmeyi ve düşük yoğunlukta içerik oynatmayı da içeren orta vadeli, bireysel kullanım için idealdir.';

  @override
  String get mostPopular => 'En Popüler!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Bant genişliği yoğunluklu, uzun vadeli kullanım ya da paylaşılan hesaplar.';

  @override
  String get total => 'Toplam';

  @override
  String get pausingAllTraffic => 'Tüm trafik duraklatılıyor...';

  @override
  String get queryingEthereumForARandom =>
      'Rastgele bir sağlayıcı için Ethereum sorgusu gönderiliyor...';

  @override
  String get quickFundAnAccount => 'Bir hesaba hızlıca fon ekleyin!';

  @override
  String get accountFound => 'Hesap Bulundu';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Kimlik bilgilerinizle ilişkili bir hesap bulduk ve onun için bir tek Orchid devresi oluşturduk. Artık VPN kullanmaya hazırsınız.';

  @override
  String get welcomeToOrchid => 'Orchid\'e Hoş Geldiniz!';

  @override
  String get fundYourAccount => 'Hesabınızı Fonlayın';

  @override
  String get processing => 'İşlem sürüyor...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Aboneliksiz, kullandıkça ödeme yapılan, merkezî olmayan, açık kaynak VPN hizmeti.';

  @override
  String getStartedFor1(String smallAmount) {
    return '$smallAmount İLE BAŞLAYIN';
  }

  @override
  String get importAccount => 'HESAP İÇE AKTARMA';

  @override
  String get illDoThisLater => 'Bunu daha sonra yapacağım';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Paylaşılabilir, yeniden doldurulabilir Orchid hesabınızı VPN kredileri satın alarak fonlamak için ağın <link1>tercih edilen sağlayıcılarından</link1> birine otomatik olarak bağlanın.';

  @override
  String get confirmPurchase => 'SATIN ALMAYI ONAYLA';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Orchid hesabı <link>xDAI kripto para birimiyle</link> desteklenen VPN kredilerini kullanır. 7/24 müşteri desteği, sınırsız cihaz paylaşımı hizmete dâhildir ve uygulama mağazalarının geri ödeme politikalarıyla korunmaktadır.';

  @override
  String get yourPurchaseIsInProgress => 'Satın alma işleminiz devam ediyor.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Bu satın alma işlemi beklenenden uzun sürüyor ve bir hatayla karşılaşılmış olabilir.';

  @override
  String get thisMayTakeAMinute => 'Bu işlem bir dakika sürebilir...';

  @override
  String get vpnCredits => 'VPN Kredileri';

  @override
  String get blockchainFee => 'Blokzincir aracı ücreti';

  @override
  String get promotion => 'Promosyon';

  @override
  String get showInAccountManager => 'Hesap Yöneticisi\'nde Göster';

  @override
  String get deleteThisOrchidIdentity => 'Bu Orchid Kimliğini sil';

  @override
  String get chooseIdentity => 'Kimliği Seç';

  @override
  String get updatingAccounts => 'Hesaplar Güncelleniyor';

  @override
  String get trafficAnalysis => 'Trafik Analizi';

  @override
  String get accountManager => 'Hesap Yöneticisi';

  @override
  String get circuitBuilder => 'Devre Oluşturucu';

  @override
  String get exitHop => 'Çıkış Atlaması';

  @override
  String get entryHop => 'Giriş Atlaması';

  @override
  String get addNewHop => 'YENİ AĞ ATLAMASI EKLE';

  @override
  String get newCircuitBuilder => 'Yeni devre oluşturucu!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Artık xDAI ile çoklu atlama Orchid devresi için ödeme yapabilirsiniz. Çoklu atlama arayüzü artık xDAI ve OXT Orchid hesaplarını destekliyor ve soğan yönlendirme oluşturmak için birleştirilebilinen OpenVPN ve WireGuard yapılandırmalarını da hâlen desteklemektedir.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Bağlantınızı, hesap yöneticisi yerine devre oluşturucuyla yönetin. Tüm bağlantılar artık sıfır ya da daha fazla atlamalı devreleri kullanıyor. Mevcut yapılandırmalar, devre oluşturucuya taşındı.';

  @override
  String quickStartFor1(String smallAmount) {
    return '$smallAmount ile hızlı başlangıç';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Başlangıç süresini kısaltmak için bir Orchid hesabı satın almak ve ana ekrandan tek bir atlama devresi oluşturmak için bir yöntem ekledik.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid, birden fazla VPN protokolünü destekleyen bir çoklu atlama ya da soğan yönlendirmesi istemcisiyle eşsizdir. Aşağıdaki desteklenen protokollerden atlamaları bir araya getirerek bağlantınızı kurabilirsiniz.\n\nTek atlama, normal bir VPN gibidir. Üç atlama (gelişmiş kullanıcılar için) klasik soğan yönlendirmesi seçimidir. Sıfır atlama, herhangi bir VPN tüneli kullanmadan trafik analizine izin verir.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'OpenVPN ve Wireguard atlamalarını silmek, ilişkili tüm giriş bilgilerinin ve bağlantı yapılandırmalarının kaybedilmesine neden olur. Devam etmeden önce tüm bilgileri yedeklediğinizden emin olun.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Bu işlem geri alınamaz. Bu kimliği kaydetmek için İptal\'i seçin ve Dışarı Aktar seçeneğini kullanın';

  @override
  String get unlockTime => 'Kilit Açılma Zamanı';

  @override
  String get chooseChain => 'Zincir Seç';

  @override
  String get unlocking => 'kilit açılma';

  @override
  String get unlocked => 'Kilit açıldı';

  @override
  String get orchidTransaction => 'Orchid İşlemi';

  @override
  String get confirmations => 'Doğrulamalar';

  @override
  String get pending => 'Sürüyor...';

  @override
  String get txHash => 'İşlem Hash\'i:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Fonlarınızın tümü çekme işlemi için hazır.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$totalFunds toplam fondan $maxWithdraw kadarı şu anda çekilebilir.';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'Kalan depozitonun da kilidi açılsın';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Toplam tutardan daha azını belirtirseniz fonlarınız ilk olarak bakiyeden çekilecek.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Ek seçenekler için GELİŞMİŞ paneline bakın.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Depozitonun kilidini açma seçeneğini seçerseniz bu işlem hemen belirtilen tutarı bakiyenizden çekecek ve kalan depozitonuz için de kilit açma işlemini başlatacak.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Depozito fonlar, kilit açıldıktan 24 saat sonra çekilebilir.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Orchid Hesabınızdan mevcut cüzdanınıza fonlarınızı çekin.';

  @override
  String get withdrawAndUnlockFunds => 'FONLARIN KİLİDİNİ AÇ VE ÇEK';

  @override
  String get withdrawFunds => 'FONLARI ÇEK';

  @override
  String get withdrawFunds2 => 'Para çekme';

  @override
  String get withdraw => 'Çek';

  @override
  String get submitTransaction => 'İŞLEMİ GÖNDER';

  @override
  String get move => 'Eylem';

  @override
  String get now => 'Şimdi';

  @override
  String get amount => 'Tutar';

  @override
  String get available => 'Mevcut';

  @override
  String get select => 'Seç';

  @override
  String get add => 'EKLE';

  @override
  String get balanceToDeposit => 'BAKİYEDEN DEPOZİTOYA';

  @override
  String get depositToBalance => 'DEPOZİTODAN BAKİYEYE';

  @override
  String get setWarnedAmount => 'Uyarı Tutarı Ayarla';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Orchid Hesabı bakiyenize fon ekleyin ve/veya yatırın.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Hesabınızı kalibre etmede rehberlik almak için <link>orchid.com</link> adresine göz atın';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Mevcut $tokenType ön provizyon: $amount';
  }

  @override
  String get noWallet => 'Cüzdan Yok';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Cüzdan Yok ya da Tarayıcı Desteklenmiyor.';

  @override
  String get error => 'Hata';

  @override
  String get failedToConnectToWalletconnect =>
      'WalletConnect\'e bağlanılamadı.';

  @override
  String get unknownChain => 'Bilinmeyen Zincir';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Orchid Hesap Yöneticisi bu zinciri henüz desteklemiyor.';

  @override
  String get orchidIsntOnThisChain => 'Orchid bu zincirde değil.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Orchid sözleşmesi bu zincirde henüz bulunmuyor.';

  @override
  String get moveFunds => 'FONLARI TAŞI';

  @override
  String get moveFunds2 => 'Fonları Taşı';

  @override
  String get lockUnlock => 'KİLİTLE / KİLİDİNİ AÇ';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return '$amount tutarındaki depozitonuzun kilidi açıldı.';
  }

  @override
  String get locked => 'kilitli';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return '$amount tutarındaki depozitonuzun $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Fonlar \$$time içinde çekilebilecek.';
  }

  @override
  String get lockDeposit => 'DEPOZİTOYU KİLİTLE';

  @override
  String get unlockDeposit => 'DEPOZİTONUN KİLİDİNİ AÇ';

  @override
  String get advanced => 'GELİŞMİŞ';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Orchid Hesapları hakkında daha fazla bilgi edinin</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return '$efficiency verimle ve $num bilet değeriyle bir Orchid Hesabı açmanın ortalama maliyeti.';
  }

  @override
  String get chain => 'Zincir';

  @override
  String get token => 'Jeton';

  @override
  String get minDeposit => 'Min. Depozito';

  @override
  String get minBalance => 'Min. Bakiye';

  @override
  String get fundFee => 'Fon Ücreti';

  @override
  String get withdrawFee => 'Çekim Ücreti';

  @override
  String get tokenValues => 'JETON DEĞERLERİ';

  @override
  String get usdPrices => 'USD FİYATLARI';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Bir uyarı depozito tutarı ayarlamak, depozito fonlarını çekmek için gerekli olan 24 saatlik bekleme sürecini başlatır.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Bu süreçte fonlar, Orchid ağında geçerli bir depozito olarak sayılmayacaktır.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Fonlar, uyarı tutarı azaltılarak dilediğiniz zaman yeniden kilitlenebilir.';

  @override
  String get warn => 'Uyarı';

  @override
  String get totalWarnedAmount => 'Toplam Uyarı Tutarı';

  @override
  String get newIdentity => 'Yeni Kimlik';

  @override
  String get importIdentity => 'Kimliği İçe Aktar';

  @override
  String get exportIdentity => 'Kimliği Dışa Aktar';

  @override
  String get deleteIdentity => 'Kimliği Sil';

  @override
  String get importOrchidIdentity => 'Orchid Kimliğini İçe Aktar';

  @override
  String get funderAddress => 'Fon Sağlayıcı Adresi';

  @override
  String get contract => 'Sözleşme';

  @override
  String get txFee => 'İşlem Ücreti';

  @override
  String get show => 'Göster';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Hata';

  @override
  String get lastHour => 'Son Saat';

  @override
  String get chainSettings => 'Zincir Ayarları';

  @override
  String get price => 'Ücret';

  @override
  String get failed => 'Başarısız';

  @override
  String get fetchGasPrice => 'İşlem maliyetini getir';

  @override
  String get fetchLotteryPot => 'Loto ikramiyesini getir';

  @override
  String get lines => 'satır';

  @override
  String get filtered => 'filtrelenmiş';

  @override
  String get backUpYourIdentity => 'Kimliğinizi yedekleyin';

  @override
  String get accountSetUp => 'Hesap kurulumu';

  @override
  String get setUpAccount => 'HESAP AÇMAK';

  @override
  String get generateIdentity => 'KİMLİK OLUŞTUR';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Mevcut bir <account_link>Orkide Kimliği</account_link>girin';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Hesabınıza para yatırmak için kullanacağınız web3 cüzdan adresini aşağıya yapıştırın.';

  @override
  String get funderWalletAddress => 'Fon veren cüzdan adresi';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Orkide Kimliğinizin genel adresi';

  @override
  String get continueButton => 'Devam et';

  @override
  String get yesIHaveSavedACopyOf =>
      'Evet, özel anahtarımın bir kopyasını güvenli bir yere kaydettim.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Orchid Identity <bold>özel anahtarınızı</bold>yedekleyin. Bu kimliği ve tüm ilişkili hesapları paylaşmak, içe aktarmak veya geri yüklemek için bu anahtara ihtiyacınız olacak.';

  @override
  String get locked1 => 'Kilitli';

  @override
  String get unlockDeposit1 => 'Depozito kilidini aç';

  @override
  String get changeWarnedAmountTo => 'Uyarı Tutarı Değiştir';

  @override
  String get setWarnedAmountTo => 'Uyarı Tutarı Ayarla';

  @override
  String get currentWarnedAmount => 'Mevcut Uyarı Tutarı';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Uyarılan tüm fonlar şu tarihe kadar kilitlenecektir:';

  @override
  String get balanceToDeposit1 => 'Mevduat Bakiyesi';

  @override
  String get depositToBalance1 => 'Bakiye Yatır';

  @override
  String get advanced1 => 'İleri';

  @override
  String get add1 => 'Eklemek';

  @override
  String get lockUnlock1 => 'Kilitle / Kilidi Aç';

  @override
  String get viewLogs => 'Günlükleri Görüntüle';

  @override
  String get language => 'dil';

  @override
  String get systemDefault => 'Sistem varsayılanı';

  @override
  String get identiconStyle => 'Kimlik Stili';

  @override
  String get blockies => 'Bloklar';

  @override
  String get jazzicon => 'caz ikonu';

  @override
  String get contractVersion => 'Sözleşme Sürümü';

  @override
  String get version0 => 'Sürüm 0';

  @override
  String get version1 => 'Versiyon 1';

  @override
  String get connectedWithMetamask => 'Metamask ile bağlantılı';

  @override
  String get blockExplorer => 'Gezgini Engelle';

  @override
  String get tapToMinimize => 'Küçültmek için dokunun';

  @override
  String get connectWallet => 'Cüzdanı Bağla';

  @override
  String get checkWallet => 'Cüzdanı Kontrol Et';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Bekleyen bir istek için Cüzdan uygulamanızı veya uzantınızı kontrol edin.';

  @override
  String get test => 'ölçek';

  @override
  String get chainName => 'Zincir Adı';

  @override
  String get rpcUrl => 'RPC URL\'si';

  @override
  String get tokenPrice => 'Jeton Fiyatı';

  @override
  String get tokenPriceUsd => 'Jeton Fiyatı USD';

  @override
  String get addChain => 'Zincir Ekle';

  @override
  String get deleteChainQuestion => 'Zincir Silinsin mi?';

  @override
  String get deleteUserConfiguredChain =>
      'Kullanıcı tarafından yapılandırılan zinciri sil';

  @override
  String get fundContractDeployer => 'Fon Sözleşmesi Uygulamacısı';

  @override
  String get deploySingletonFactory => 'Singleton Factory\'yi dağıtın';

  @override
  String get deployContract => 'Dağıtım Sözleşmesi';

  @override
  String get about => 'hakkında';

  @override
  String get dappVersion => 'Dapp Sürümü';

  @override
  String get viewContractOnEtherscan => 'Etherscan\'de Sözleşmeyi Görüntüle';

  @override
  String get viewContractOnGithub => 'Github\'da Sözleşmeyi Görüntüle';

  @override
  String get accountChanges => 'Hesap Değişiklikleri';

  @override
  String get name => 'isim';

  @override
  String get step1 =>
      '<bold>1. Adım.</bold> İçinde <link>yeterli jeton</link> bulunan bir ERC-20 cüzdanı bağlayın.';

  @override
  String get step2 =>
      '<bold>Adım 2.</bold> Hesapları Yönet\'e gidip adrese dokunarak Orkide Uygulamasından Orkide Kimliğini kopyalayın.';

  @override
  String get connectOrCreate => 'Bağlanın veya Orkide Hesabı oluşturun';

  @override
  String get lockDeposit2 => 'Depozitoyu Kilitle';

  @override
  String get unlockDeposit2 => 'Depozito kilidini aç';

  @override
  String get enterYourWeb3 => 'web3 cüzdan adresinizi girin.';

  @override
  String get purchaseComplete => 'Satın Alma İşlemi Tamamlandı';

  @override
  String get generateNewIdentity => 'Yeni bir Kimlik oluştur';

  @override
  String get copyIdentity => 'Kimlik Kopyala';

  @override
  String get yourPurchaseIsComplete =>
      'Satın alma işleminiz tamamlandı ve şu anda xDai blok zinciri tarafından işleniyor, bu işlem birkaç dakika sürebilir. Bu hesabı kullanarak sizin için varsayılan bir devre oluşturuldu. Kullanılabilir bakiyeyi ana ekranda veya hesap yöneticisinde izleyebilirsiniz.';

  @override
  String get circuitGenerated => 'Devre Oluşturuldu';

  @override
  String get usingYourOrchidAccount =>
      'Orchid hesabınız kullanılarak tek bir sekme devresi oluşturuldu. Bunu devre oluşturucu ekranından yönetebilirsiniz.';
}
