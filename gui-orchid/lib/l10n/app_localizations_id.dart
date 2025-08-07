// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class SId extends S {
  SId([String locale = 'id']) : super(locale);

  @override
  String get orchidHop => 'Hop Orchid';

  @override
  String get orchidDisabled => 'Orchid dinonaktifkan';

  @override
  String get trafficMonitoringOnly => 'Pemantauan lalu lintas saja';

  @override
  String get orchidConnecting => 'Menghubungkan ke Orchid';

  @override
  String get orchidDisconnecting => 'Memutuskan dari Orchid';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hop dikonfigurasi',
      two: 'Dua hop dikonfigurasi',
      one: 'Satu hop dikonfigurasi',
      zero: 'Tidak ada hop yang dikonfigurasi',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Hapus';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Hop';

  @override
  String get traffic => 'Lalu lintas';

  @override
  String get curation => 'Kurasi';

  @override
  String get signerKey => 'Kunci penanda tangan';

  @override
  String get copy => 'Salin';

  @override
  String get paste => 'Tempel';

  @override
  String get deposit => 'Deposito';

  @override
  String get curator => 'Kurator';

  @override
  String get ok => 'Oke';

  @override
  String get settingsButtonTitle => 'PENGATURAN';

  @override
  String get confirmThisAction => 'Konfirmasi tindakan ini';

  @override
  String get cancelButtonTitle => 'Batal';

  @override
  String get changesWillTakeEffectInstruction =>
      'Perubahan akan diterapkan saat VPN dinyalakan kembali.';

  @override
  String get saved => 'Disimpan';

  @override
  String get configurationSaved => 'Konfigurasi tersimpan';

  @override
  String get whoops => 'Maaf';

  @override
  String get configurationFailedInstruction =>
      'Konfigurasi gagal disimpan. Silakan periksa sintaksisnya, lalu coba lagi.';

  @override
  String get addHop => 'Tambahkan hop';

  @override
  String get scan => 'Pindai';

  @override
  String get invalidQRCode => 'Kode QR tidak valid';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Kode QR yang dipindai tidak memiliki konfigurasi akun yang valid.';

  @override
  String get invalidCode => 'Kode tidak valid';

  @override
  String get theCodeYouPastedDoesNot =>
      'Kode yang dimasukan tidak memiliki konfigurasi akun yang valid.';

  @override
  String get openVPNHop => 'Hop OpenVPN';

  @override
  String get username => 'Nama pengguna';

  @override
  String get password => 'Kata sandi';

  @override
  String get config => 'Konfigurasi';

  @override
  String get pasteYourOVPN => 'Tempel berkas konfigurasi OVPN di sini';

  @override
  String get enterYourCredentials => 'Masukkan kredensial Anda';

  @override
  String get enterLoginInformationInstruction =>
      'Masukkan informasi akses ke penyedia VPN Anda di atas. Kemudian tempelkan isi berkas konfigurasi OpenVPN penyedia Anda di kotak yang telah disediakan.';

  @override
  String get save => 'Simpan';

  @override
  String get help => 'Bantuan';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get openSourceLicenses => 'Lisensi Open Source';

  @override
  String get settings => 'Pengaturan';

  @override
  String get version => 'Versi';

  @override
  String get noVersion => 'Tidak ada versi';

  @override
  String get orchidOverview => 'Ringkasan Orchid';

  @override
  String get defaultCurator => 'Kurator standar';

  @override
  String get queryBalances => 'Minta info saldo';

  @override
  String get reset => 'Atur ulang';

  @override
  String get manageConfiguration => 'Kelola konfigurasi';

  @override
  String get warningThesefeature =>
      'Peringatan: Fitur ini hanya ditujukan bagi pengguna tingkat lanjut. Silakan baca semua petunjuk.';

  @override
  String get exportHopsConfiguration => 'Ekspor konfigurasi hop';

  @override
  String get export => 'Ekspor';

  @override
  String get warningExportedConfiguration =>
      'Peringatan: Konfigurasi yang diekspor memuat rahasia kunci privat penanda tangan untuk hop yang diekspor. Menyingkapkan kunci privat dapat mengakibatkan hilangnya semua dana pada akun Orchid yang terkait.';

  @override
  String get importHopsConfiguration => 'Impor konfigurasi hop';

  @override
  String get import => 'Impor';

  @override
  String get warningImportedConfiguration =>
      'Peringatan: Konfigurasi yang diimpor akan menggantikan semua hop yang telah Anda buat di aplikasi ini. Kunci penanda tangan yang dibuat sebelumnya atau diimpor pada perangkat ini akan dipertahankan dan tetap dapat diakses untuk membuat hop baru. Namun konfigurasi lainnya, termasuk konfigurasi hop OpenVPN, akan hilang.';

  @override
  String get configuration => 'Konfigurasi';

  @override
  String get saveButtonTitle => 'SIMPAN';

  @override
  String get search => 'Telusuri';

  @override
  String get newContent => 'Konten baru';

  @override
  String get clear => 'Kosongkan';

  @override
  String get connectionDetail => 'Detail koneksi';

  @override
  String get host => 'Hos';

  @override
  String get time => 'Waktu';

  @override
  String get sourcePort => 'Porta sumber';

  @override
  String get destination => 'Destinasi';

  @override
  String get destinationPort => 'Porta destinasi';

  @override
  String get generateNewKey => 'Buat kunci baru';

  @override
  String get importKey => 'Impor kunci';

  @override
  String get nothingToDisplayYet =>
      'Tidak ada yang ditampilkan. Lalu lintas akan muncul di sini ketika ada sesuatu untuk ditampilkan.';

  @override
  String get disconnecting => 'Memutuskan...';

  @override
  String get connecting => 'Menghubungkan...';

  @override
  String get pushToConnect => 'Tekan untuk terhubung.';

  @override
  String get orchidIsRunning => 'Orchid sedang berjalan!';

  @override
  String get pacPurchaseWaiting => 'Pembelian ditunggu';

  @override
  String get retry => 'Coba lagi';

  @override
  String get getHelpResolvingIssue =>
      'Dapatkan bantuan untuk menyelesaikan masalah ini.';

  @override
  String get copyDebugInfo => 'Salin info debug';

  @override
  String get contactOrchid => 'Hubungi Orchid';

  @override
  String get remove => 'Hapus';

  @override
  String get deleteTransaction => 'Hapus transaksi';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Bersihkan transaksi yang sedang berlangsung. Tindakan ini tidak akan mengembalikan dana transaksi pembelian dalam aplikasi. Silahkan hubungi Orchid untuk menyelesaikan masalah ini.';

  @override
  String get preparingPurchase => 'Mempersiapkan pembelian';

  @override
  String get retryingPurchasedPAC => 'Mencoba ulang pembelian';

  @override
  String get retryPurchasedPAC => 'Coba ulang pembelian';

  @override
  String get purchaseError => 'Kesalahan pembelian';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Terjadi kesalahan dalam proses pembelian. Silakan hubungi Dukungan Orchid.';

  @override
  String get importAnOrchidAccount => 'Impor akun Orchid';

  @override
  String get buyCredits => 'Beli kredit';

  @override
  String get linkAnOrchidAccount => 'Hubungkan akun Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Maaf, pembelian tidak dapat dilanjutkan karena akan melebihi batas pembelian harian untuk kredit akses. Silakan coba lagi nanti.';

  @override
  String get marketStats => 'Statistik pasar';

  @override
  String get balanceTooLow => 'Saldo tidak mencukupi';

  @override
  String get depositSizeTooSmall => 'Jumlah deposito terlalu kecil';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Nilai tiket maksimum Anda saat ini dibatasi oleh saldo Anda:';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Nilai tiket maksimum Anda saat ini dibatasi oleh deposito Anda:';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Pertimbangkan untuk menambahkan OXT ke saldo akun Anda.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Pertimbangkan untuk menambahkan OXT ke deposito Anda, atau pindahkan dana dari saldo Anda ke deposito Anda.';

  @override
  String get prices => 'Harga';

  @override
  String get ticketValue => 'Nilai tiket';

  @override
  String get costToRedeem => 'Biaya untuk penukaran:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Lihat dokumen untuk bantuan tentang masalah ini.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Cocok untuk penjelajahan web dan aktivitas ringan';

  @override
  String get learnMore => 'Pelajari lebih lanjut.';

  @override
  String get connect => 'Hubungkan';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get wireguardHop => 'Hop WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Tempel berkas konfigurasi WireGuard®️ Anda di sini';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Tempel informasi kredensial untuk penyedia WireGuard®️ Anda ke bidang di atas.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Bersihkan semua data log?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Log debug ini hanya sementara dan dibersihkan saat keluar dari aplikasi.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Dapat berisi informasi rahasia atau identifikasi pribadi.';

  @override
  String get loggingEnabled => 'Pengelogan diaktifkan';

  @override
  String get cancel => 'Batal';

  @override
  String get logging => 'Mengelog';

  @override
  String get loading => 'Memuat ...';

  @override
  String get ethPrice => 'Harga ETH:';

  @override
  String get oxtPrice => 'Harga OXT:';

  @override
  String get gasPrice => 'Biaya transaksi Gas:';

  @override
  String get maxFaceValue => 'Nilai nominal maksimum:';

  @override
  String get confirmDelete => 'Konfirmasi penghapusan';

  @override
  String get enterOpenvpnConfig => 'Masukkan konfigurasi OpenVPN';

  @override
  String get enterWireguardConfig => 'Masukkan konfigurasi WireGuard®️';

  @override
  String get starting => 'Memulai...';

  @override
  String get legal => 'Hukum';

  @override
  String get whatsNewInOrchid => 'Apa yang baru di Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid ada di xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Anda sekarang dapat membeli kredit Orchid di xDai! Mulai gunakan VPN seharga AS\$1 saja.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Akun xDai untuk pembelian sebelumnya';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Dana xDai telah ditambahkan ke kunci akun yang sama untuk setiap pembelian dalam aplikasi yang dilakukan sebelum hari ini. Hadiah kami untuk Anda!';

  @override
  String get newInterface => 'Antarmuka baru';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Akun sekarang diatur dalam alamat Orchid yang terkait dengannya.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Lihat saldo aktif dan biaya bandwidth di layar beranda.';

  @override
  String get seeOrchidcomForHelp => 'Buka orchid.com untuk bantuan.';

  @override
  String get payPerUseVpnService => 'Layanan VPN bayar sesuai penggunaan';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Bukan langganan, kredit tidak kedaluwarsa';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Berbagi akun dengan perangkat tanpa batas';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Toko Orchid tidak tersedia untuk sementara waktu. Silakan periksa kembali dalam beberapa menit.';

  @override
  String get talkingToPacServer => 'Berkomunikasi dengan server akun Orchid';

  @override
  String get advancedConfiguration => 'Konfigurasi tingkat lanjut';

  @override
  String get newWord => 'Baru';

  @override
  String get copied => 'Disalin';

  @override
  String get efficiency => 'Efisiensi';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Tiket minimum yang tersedia: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Transaksi dikirim ke blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Pembelian Anda selesai dan sedang diproses oleh blockchain xDai dengan estimasi waktu sekitar satu menit atau lebih. Tarik ke bawah untuk menyegarkan dan akun Anda dengan saldo yang diperbarui akan muncul di bawah ini.';

  @override
  String get copyReceipt => 'Salin tanda terima';

  @override
  String get manageAccounts => 'Kelola akun';

  @override
  String get configurationManagement => 'Manajemen konfigurasi';

  @override
  String get exportThisOrchidKey => 'Ekspor kunci Orchid ini';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Kode QR dan teks untuk semua akun Orchid yang terkait dengan kunci ini tertera di bawah.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Impor kunci ini pada perangkat lain untuk membagikan semua akun Orchid yang terkait dengan Identitas Orchid ini.';

  @override
  String get orchidAccountInUse => 'Akun Orchid sedang digunakan';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Akun Orchid ini sedang digunakan dan tidak dapat dihapus.';

  @override
  String get pullToRefresh => 'Tarik untuk menyegarkan.';

  @override
  String get balance => 'Saldo';

  @override
  String get active => 'Aktif';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Tempel kunci Orchid dari papan klip untuk mengimpor semua akun Orchid yang terkait dengan kunci tersebut.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Pindai atau tempel kunci Orchid dari papan klip untuk mengimpor semua akun Orchid yang terkait dengan kunci tersebut.';

  @override
  String get account => 'Akun';

  @override
  String get transactions => 'Transaksi';

  @override
  String get weRecommendBackingItUp =>
      'Kami sarankan untuk <link>membuat cadangannya</link>.';

  @override
  String get copiedOrchidIdentity => 'Identitas Orchid yang disalin';

  @override
  String get thisIsNotAWalletAddress => 'Ini bukan alamat dompet.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Jangan kirim token ke alamat ini.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Identitas Orchid Anda secara unik mengidentifikasi Anda pada jaringan.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Pelajari lebih lanjut tentang <link>Identitas Orchid</link> Anda.';

  @override
  String get analyzingYourConnections => 'Menganalisa koneksi Anda';

  @override
  String get analyzeYourConnections => 'Analisa koneksi Anda';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'Analisis jaringan menggunakan kemampuan VPN perangkat Anda untuk menangkap paket dan menganalisa lalu lintas Anda.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'Analisis jaringan memerlukan izin VPN, tetapi tidak dengan sendirinya melindungi data atau menyembunyikan alamat IP Anda.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Untuk mendapatkan manfaat privasi jaringan, Anda harus mengkonfigurasi dan mengaktifkan koneksi VPN dari layar beranda.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Menyalakan fitur ini akan meningkatkan penggunaan baterai aplikasi Orchid.';

  @override
  String get useAnOrchidAccount => 'Gunakan akun Orchid';

  @override
  String get pasteAddress => 'Tempel alamat';

  @override
  String get chooseAddress => 'Pilih alamat';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Pilih akun Orchid yang akan digunakan dengan hop ini.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Jika akun Anda tidak terlihat di bawah ini, Anda dapat menggunakan pengelola akun untuk mengimpor, membeli, atau membuat akun baru.';

  @override
  String get selectAnOrchidAccount => 'Pilih akun Orchid';

  @override
  String get takeMeToTheAccountManager => 'Buka pengelola akun';

  @override
  String get funderAccount => 'Akun penyandang dana';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid berjalan dan menganalisa';

  @override
  String get startingVpn => '(Memulai VPN)';

  @override
  String get disconnectingVpn => '(Memutuskan VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid menganalisa lalu lintas';

  @override
  String get vpnConnectedButNotRouting =>
      '(VPN terhubung tetapi tanpa perutean)';

  @override
  String get restarting => 'Memulai ulang';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Untuk mengubah status pemantauan, VPN perlu dimulai ulang, yang dapat mengganggu perlindungan privasi untuk sesaat.';

  @override
  String get confirmRestart => 'Konfirmasi mulai ulang';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Harga rata-rata adalah $price USD per GB';
  }

  @override
  String get myOrchidConfig => 'Konfigurasi Orchid saya';

  @override
  String get noAccountSelected => 'Tidak ada akun yang dipilih';

  @override
  String get inactive => 'Tidak aktif';

  @override
  String get tickets => 'Tiket';

  @override
  String get accounts => 'Akun';

  @override
  String get orchidIdentity => 'Identitas Orchid';

  @override
  String get addFunds => 'TAMBAH DANA';

  @override
  String get addFunds2 => 'MENAMBAH DANA';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Hop';

  @override
  String get circuit => 'Sirkuit';

  @override
  String get clearAllAnalysisData => 'Hapus semua data analisis?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Tindakan ini akan menghapus semua data lalu lintas koneksi yang pernah dianalisa sebelumnya.';

  @override
  String get clearAll => 'HAPUS SEMUA';

  @override
  String get stopAnalysis => 'HENTIKAN ANALISIS';

  @override
  String get startAnalysis => 'MULAI ANALISIS';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Akun Orchid menyediakan layanan bantuan pelanggan 24/7, tanpa batasan jumlah perangkat, dan didukung oleh <link2>mata uang kripto xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Akun yang dibeli terhubung secara eksklusif ke <link1>penyedia pilihan</link1> kami.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Kebijakan pengembalian dana dicakup oleh toko aplikasi.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid tidak dapat menampilkan pembelian dalam aplikasi untuk saat ini.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Harap konfirmasi bahwa perangkat ini mendukung dan terkonfigurasi untuk pembelian dalam aplikasi.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Harap konfirmasi bahwa perangkat ini mendukung dan terkonfigurasi untuk pembelian dalam aplikasi, atau gunakan sistem <link>manajemen akun </link> terdesentralisasi kami.';

  @override
  String get buy => 'BELI';

  @override
  String get gbApproximately12 => '12GB (kira-kira)';

  @override
  String get gbApproximately60 => '60GB (kira-kira)';

  @override
  String get gbApproximately240 => '240GB (kira-kira)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Cocok untuk penggunaan individu jangka menengah yang mencakup penjelajahan dan streaming ringan.';

  @override
  String get mostPopular => 'Paling populer!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Penggunaan bandwidth berat, jangka panjang, atau akun bersama.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'Menjeda semua lalu lintas...';

  @override
  String get queryingEthereumForARandom =>
      'Meminta Ethereum untuk penyedia acak...';

  @override
  String get quickFundAnAccount => 'Danai akun dengan cepat!';

  @override
  String get accountFound => 'Akun ditemukan';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Kami menemukan akun yang terkait dengan identitas Anda dan telah membuat sirkuit Orchid dengan hop tunggal untuk akun tersebut. Anda sekarang siap menggunakan VPN.';

  @override
  String get welcomeToOrchid => 'Selamat datang di Orchid!';

  @override
  String get fundYourAccount => 'Danai akun Anda';

  @override
  String get processing => 'Memproses...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Bebas langganan, bayar sesuai penggunaan, terdesentralisasi, layanan VPN open source.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'MULAI CUMA DENGAN $smallAmount';
  }

  @override
  String get importAccount => 'IMPOR AKUN';

  @override
  String get illDoThisLater => 'Lain kali';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Terhubung secara otomatis ke salah satu <link1>penyedia pilihan</link1> jaringan dengan membeli kredit VPN untuk mendanai akun Orchid Anda yang dapat dibagikan dan diisi ulang.';

  @override
  String get confirmPurchase => 'KONFIRMASI PEMBELIAN';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Akun Orchid menggunakan kredit VPN yang didukung oleh <link>mata uang kripto xDAI</link>, menyediakan layanan bantuan pelanggan 24/7, memungkinkan Anda berbagi perangkat tanpa batas, dan dilindungi kebijakan pengembalian dana toko aplikasi.';

  @override
  String get yourPurchaseIsInProgress => 'Pembelian Anda sedang diproses.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Pembelian ini membutuhkan waktu lebih lama dari yang diperkirakan dan mungkin telah terjadi kesalahan.';

  @override
  String get thisMayTakeAMinute => 'Dapat memakan waktu satu menit...';

  @override
  String get vpnCredits => 'Kredit VPN';

  @override
  String get blockchainFee => 'Biaya blockchain';

  @override
  String get promotion => 'Promosi';

  @override
  String get showInAccountManager => 'Tampilkan di pengelola akun';

  @override
  String get deleteThisOrchidIdentity => 'Hapus Identitas Orchid ini';

  @override
  String get chooseIdentity => 'Pilih Identitas';

  @override
  String get updatingAccounts => 'Memperbarui akun';

  @override
  String get trafficAnalysis => 'Analisis lalu lintas';

  @override
  String get accountManager => 'Pengelola akun';

  @override
  String get circuitBuilder => 'Pembuat sirkuit';

  @override
  String get exitHop => 'Hop keluar';

  @override
  String get entryHop => 'Hop masuk';

  @override
  String get addNewHop => 'TAMBAHKAN HOP BARU';

  @override
  String get newCircuitBuilder => 'Pembuat sirkuit baru!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Anda sekarang dapat membayar untuk sirkuit Orchid multi-hop dengan xDAI. Antarmuka multi-hop sekarang mendukung akun xDAI dan OXT Orchid, dan masih mendukung konfigurasi OpenVPN dan WireGuard yang dapat dirangkai menjadi rute berlapis.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Kelola koneksi Anda dari pembuat sirkuit, bukan dari pengelola akun. Semua koneksi sekarang menggunakan sirkuit dengan nol hop atau lebih banyak hop. Setiap konfigurasi yang ada telah dimigrasikan ke pembuat sirkuit.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Mulai cepat cuma dengan $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Kami telah menambahkan cara untuk membeli akun Orchid dan membuat sirkuit dengan hop tunggal dari layar beranda untuk mempersingkat proses pengenalan.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid bersifat unik sebagai klien perutean berlapis atau multi-hop karena mendukung banyak protokol VPN. Anda dapat mengatur koneksi Anda dengan menggabungkan berbagai hop dari protokol yang didukung di bawah ini.\n\nSatu hop itu seperti VPN biasa. Tiga hop (bagi pengguna tingkat lanjut) adalah pilihan klasik untuk perutean berlapis. Nol hop memungkinkan analisis lalu lintas tanpa tunnel VPN apa pun.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Menghapus hop OpenVPN dan WireGuard akan menghilangkan kredensial dan konfigurasi koneksi yang terkait. Pastikan Anda telah membuat cadangan untuk informasi tersebut sebelum melanjutkan.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Tindakan ini tidak dapat dibatalkan. Untuk menyimpan identitas ini, tekan Batal dan gunakan opsi Ekspor';

  @override
  String get unlockTime => 'Waktu sampai terbuka';

  @override
  String get chooseChain => 'Pilih chain';

  @override
  String get unlocking => 'sedang dibuka';

  @override
  String get unlocked => 'Terbuka';

  @override
  String get orchidTransaction => 'Transaksi Orchid';

  @override
  String get confirmations => 'Konfirmasi';

  @override
  String get pending => 'Tertunda...';

  @override
  String get txHash => 'Hash Tx:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Semua dana Anda tersedia untuk ditarik.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw dari $totalFunds dana gabungan Anda tersedia untuk ditarik saat ini.';
  }

  @override
  String get alsoUnlockRemainingDeposit => 'Juga buka kunci deposito tersisa';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Jika kurang dari jumlah total ditentukan, dana akan ditarik dari saldo Anda lebih dahulu.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Untuk opsi tambahan, lihat panel LANJUTAN.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Jika Anda memilih opsi buka kunci deposito, transaksi ini akan segera menarik jumlah yang ditentukan dari saldo Anda dan juga memulai proses pembukaan kunci untuk deposito tersisa Anda.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Dana deposito tersedia untuk ditarik 24 jam setelah pembukaan kunci.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Tarik dana dari akun Orchid ke dompet yang Anda gunakan saat ini.';

  @override
  String get withdrawAndUnlockFunds => 'TARIK DAN BUKA KUNCI DANA';

  @override
  String get withdrawFunds => 'TARIK DANA';

  @override
  String get withdrawFunds2 => 'Tarik dana';

  @override
  String get withdraw => 'Tarik mata uang';

  @override
  String get submitTransaction => 'KIRIM TRANSAKSI';

  @override
  String get move => 'Pindah';

  @override
  String get now => 'Sekarang';

  @override
  String get amount => 'Jumlah';

  @override
  String get available => 'Tersedia';

  @override
  String get select => 'Pilih';

  @override
  String get add => 'TAMBAH';

  @override
  String get balanceToDeposit => 'SALDO KE DEPOSITO';

  @override
  String get depositToBalance => 'DEPOSITO KE SALDO';

  @override
  String get setWarnedAmount => 'Tetapkan jumlah yang diperingatkan';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Tambahkan dana ke saldo dan/atau deposito akun Orchid Anda.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Untuk panduan ukuran akun, kunjungi <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Pra-otorisasi $tokenType saat ini: $amount';
  }

  @override
  String get noWallet => 'Tidak ada dompet';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Tidak ada dompet atau browser tidak didukung.';

  @override
  String get error => 'Kesalahan';

  @override
  String get failedToConnectToWalletconnect =>
      'Gagal terhubung ke WalletConnect.';

  @override
  String get unknownChain => 'Chain tidak diketahui';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Pengelola akun Orchid belum mendukung chain ini.';

  @override
  String get orchidIsntOnThisChain => 'Orchid tidak ada pada chain ini.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Kontrak Orchid belum diterapkan pada chain ini.';

  @override
  String get moveFunds => 'PINDAHKAN DANA';

  @override
  String get moveFunds2 => 'Pindahkan Dana';

  @override
  String get lockUnlock => 'KUNCI / BUKA KUNCI';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Deposito Anda $amount terbuka.';
  }

  @override
  String get locked => 'terkunci';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Deposito Anda $amount $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Dana akan tersedia untuk ditarik dalam \$$time.';
  }

  @override
  String get lockDeposit => 'KUNCI DEPOSITO';

  @override
  String get unlockDeposit => 'BUKA KUNCI DEPOSITO';

  @override
  String get advanced => 'LANJUTAN';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Pelajari lebih lanjut tentang akun Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Biaya yang diperkirakan untuk membuat akun Orchid dengan efisiensi $efficiency dan $num tiket nilai.';
  }

  @override
  String get chain => 'Chain';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Deposito min.';

  @override
  String get minBalance => 'Saldo min.';

  @override
  String get fundFee => 'Biaya pendanaan';

  @override
  String get withdrawFee => 'Biaya penarikan';

  @override
  String get tokenValues => 'NILAI TOKEN';

  @override
  String get usdPrices => 'HARGA USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Menetapkan jumlah deposito yang diperingatkan memulai masa tunggu 24 jam yang diperlukan untuk menarik dana deposito.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Selama periode ini, dana tidak tersedia sebagai deposito valid di jaringan Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Dana dapat dikunci kembali kapan saja dengan mengurangi jumlah yang diperingatkan.';

  @override
  String get warn => 'Peringatkan';

  @override
  String get totalWarnedAmount => 'Jumlah total yang diperingatkan';

  @override
  String get newIdentity => 'Identitas baru';

  @override
  String get importIdentity => 'Impor identitas';

  @override
  String get exportIdentity => 'Ekspor identitas';

  @override
  String get deleteIdentity => 'Hapus identitas';

  @override
  String get importOrchidIdentity => 'Impor Identitas Orchid';

  @override
  String get funderAddress => 'Alamat penyandang dana';

  @override
  String get contract => 'Kontrak';

  @override
  String get txFee => 'Biaya Tx';

  @override
  String get show => 'Tampilkan';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Kesalahan';

  @override
  String get lastHour => 'Sejam terakhir';

  @override
  String get chainSettings => 'Pengaturan chain';

  @override
  String get price => 'Harga';

  @override
  String get failed => 'Gagal';

  @override
  String get fetchGasPrice => 'Ambil harga gas';

  @override
  String get fetchLotteryPot => 'Ambil pot lotre';

  @override
  String get lines => 'baris';

  @override
  String get filtered => 'disaring';

  @override
  String get backUpYourIdentity => 'Cadangkan Identitas Anda';

  @override
  String get accountSetUp => 'Pengaturan akun';

  @override
  String get setUpAccount => 'Siapkan Akun';

  @override
  String get generateIdentity => 'HASILKAN IDENTITAS';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Masukkan <account_link>Identitas Anggrek</account_link>yang ada';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Tempel alamat dompet web3 yang akan Anda gunakan untuk mendanai akun Anda di bawah ini.';

  @override
  String get funderWalletAddress => 'Alamat dompet pemberi dana';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Alamat publik Orchid Identity Anda';

  @override
  String get continueButton => 'Terus';

  @override
  String get yesIHaveSavedACopyOf =>
      'Ya, saya telah menyimpan salinan kunci pribadi saya di suatu tempat yang aman.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Cadangkan <bold>kunci pribadi</bold>Orchid Identity Anda. Anda akan memerlukan kunci ini untuk membagikan, mengimpor, atau memulihkan identitas ini dan semua akun terkait.';

  @override
  String get locked1 => 'Terkunci';

  @override
  String get unlockDeposit1 => 'Buka kunci deposit';

  @override
  String get changeWarnedAmountTo => 'Ubah Jumlah yang Diperingatkan Menjadi';

  @override
  String get setWarnedAmountTo => 'Setel Jumlah yang Diperingatkan Ke';

  @override
  String get currentWarnedAmount => 'Jumlah Peringatan Saat Ini';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Semua dana yang diperingatkan akan dikunci sampai';

  @override
  String get balanceToDeposit1 => 'Saldo untuk Deposit';

  @override
  String get depositToBalance1 => 'Setor ke Saldo';

  @override
  String get advanced1 => 'Maju';

  @override
  String get add1 => 'Menambahkan';

  @override
  String get lockUnlock1 => 'Kunci / Buka Kunci';

  @override
  String get viewLogs => 'Lihat Log';

  @override
  String get language => 'Bahasa';

  @override
  String get systemDefault => 'Default Sistem';

  @override
  String get identiconStyle => 'Gaya Identifikasi';

  @override
  String get blockies => 'Blokir';

  @override
  String get jazzicon => 'ikon jazz';

  @override
  String get contractVersion => 'Versi Kontrak';

  @override
  String get version0 => 'Versi 0';

  @override
  String get version1 => 'Versi 1';

  @override
  String get connectedWithMetamask => 'Terhubung dengan Metamask';

  @override
  String get blockExplorer => 'Blok Penjelajah';

  @override
  String get tapToMinimize => 'Ketuk untuk Meminimalkan';

  @override
  String get connectWallet => 'HUBUNGKAN DOMPET';

  @override
  String get checkWallet => 'Cek Dompet';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Periksa aplikasi atau ekstensi Wallet Anda untuk permintaan yang tertunda.';

  @override
  String get test => 'uji';

  @override
  String get chainName => 'Nama Rantai';

  @override
  String get rpcUrl => 'URL RPC';

  @override
  String get tokenPrice => 'Harga Token';

  @override
  String get tokenPriceUsd => 'Harga Token USD';

  @override
  String get addChain => 'Tambahkan Rantai';

  @override
  String get deleteChainQuestion => 'Hapus Rantai?';

  @override
  String get deleteUserConfiguredChain =>
      'Hapus rantai yang dikonfigurasi pengguna';

  @override
  String get fundContractDeployer => 'Penyebar Kontrak Dana';

  @override
  String get deploySingletonFactory => 'Sebarkan Pabrik Tunggal';

  @override
  String get deployContract => 'Menyebarkan Kontrak';

  @override
  String get about => 'Tentang';

  @override
  String get dappVersion => 'Versi Dapp';

  @override
  String get viewContractOnEtherscan => 'Lihat Kontrak di Etherscan';

  @override
  String get viewContractOnGithub => 'Lihat Kontrak di Github';

  @override
  String get accountChanges => 'Perubahan Akun';

  @override
  String get name => 'Nama';

  @override
  String get step1 =>
      '<bold>Langkah 1.</bold> Hubungkan dompet ERC-20 dengan <link>token yang cukup</link> di dalamnya.';

  @override
  String get step2 =>
      '<bold>Langkah 2.</bold> Salin Identitas Anggrek dari Aplikasi Anggrek dengan membuka Kelola Akun, lalu ketuk alamatnya.';

  @override
  String get connectOrCreate => 'Hubungkan atau buat Akun Anggrek';

  @override
  String get lockDeposit2 => 'Kunci Deposit';

  @override
  String get unlockDeposit2 => 'Buka kunci deposit';

  @override
  String get enterYourWeb3 => 'Masukkan alamat dompet web3 Anda.';

  @override
  String get purchaseComplete => 'Pembelian Selesai';

  @override
  String get generateNewIdentity => 'Menghasilkan Identitas baru';

  @override
  String get copyIdentity => 'Salin Identitas';

  @override
  String get yourPurchaseIsComplete =>
      'Pembelian Anda selesai dan sekarang sedang diproses oleh blockchain xDai, yang bisa memakan waktu beberapa menit. Sirkuit default telah dibuat untuk Anda menggunakan akun ini. Anda dapat memantau saldo yang tersedia di layar beranda atau di pengelola akun.';

  @override
  String get circuitGenerated => 'Sirkuit Dihasilkan';

  @override
  String get usingYourOrchidAccount =>
      'Menggunakan akun Orchid Anda, satu sirkuit hop telah dibuat. Anda dapat mengelola ini dari layar pembuat sirkuit.';
}
