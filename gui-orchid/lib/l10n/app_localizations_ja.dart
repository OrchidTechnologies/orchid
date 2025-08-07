// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get orchidHop => 'Orchidホップ';

  @override
  String get orchidDisabled => 'Orchidが無効になっています';

  @override
  String get trafficMonitoringOnly => 'トラフィック モニタリングのみ';

  @override
  String get orchidConnecting => 'Orchid接続中';

  @override
  String get orchidDisconnecting => 'Orchid切断中';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num ホップが構成されました',
      two: '2 ホップが構成されました',
      one: '1 ホップが構成されました',
      zero: 'ホップが構成されていません',
    );
    return '$_temp0';
  }

  @override
  String get delete => '削除';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'ホップ';

  @override
  String get traffic => 'トラフィック';

  @override
  String get curation => 'キュレーション';

  @override
  String get signerKey => '署名者キー';

  @override
  String get copy => 'コピー';

  @override
  String get paste => '貼り付け';

  @override
  String get deposit => '預金';

  @override
  String get curator => 'キュレーター';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => '設定';

  @override
  String get confirmThisAction => 'このアクションを確認';

  @override
  String get cancelButtonTitle => 'キャンセル';

  @override
  String get changesWillTakeEffectInstruction => '変更はVPN が再起動されると有効になります。';

  @override
  String get saved => '保存されました';

  @override
  String get configurationSaved => '設定が保存されました';

  @override
  String get whoops => 'あらら';

  @override
  String get configurationFailedInstruction =>
      '設定を保存できませんでした。 構文を確認してもう一度お試しください。';

  @override
  String get addHop => 'ホップを追加';

  @override
  String get scan => 'スキャン';

  @override
  String get invalidQRCode => '無効なQRコード';

  @override
  String get theQRCodeYouScannedDoesNot => 'スキャンしたQRコードには有効なアカウント設定が含まれていません。';

  @override
  String get invalidCode => '無効なコード';

  @override
  String get theCodeYouPastedDoesNot => '貼り付けたQRコードには有効なアカウント設定が含まれていません。';

  @override
  String get openVPNHop => 'OpenVPN ホップ';

  @override
  String get username => 'ユーザー名';

  @override
  String get password => 'パスワード';

  @override
  String get config => '設定';

  @override
  String get pasteYourOVPN => 'OVPN設定ファイルをここに貼り付けてください';

  @override
  String get enterYourCredentials => '資格情報を入力してください';

  @override
  String get enterLoginInformationInstruction =>
      '上記のVPNプロバイダーのログイン情報を入力します。次に、提供されたフィールドにプロバイダーのOpenVPN設定ファイルの内容を貼り付けます。';

  @override
  String get save => '保存';

  @override
  String get help => 'ヘルプ';

  @override
  String get privacyPolicy => 'プライバシー ポリシー';

  @override
  String get openSourceLicenses => 'オープンソース ライセンス';

  @override
  String get settings => '設定';

  @override
  String get version => 'バージョン';

  @override
  String get noVersion => 'バージョンなし';

  @override
  String get orchidOverview => 'Orchidの概要';

  @override
  String get defaultCurator => 'デフォルトのキュレーター';

  @override
  String get queryBalances => '残高クエリ';

  @override
  String get reset => 'リセット';

  @override
  String get manageConfiguration => '構成の管理';

  @override
  String get warningThesefeature =>
      '警告：これらの機能は上級ユーザーのみを対象としています。すべての指示をお読みください。';

  @override
  String get exportHopsConfiguration => 'ホップ設定のエクスポート';

  @override
  String get export => 'エクスポート';

  @override
  String get warningExportedConfiguration =>
      '警告：エクスポートされる設定にはエクスポートされたホップの署名者秘密鍵が含まれます。 秘密鍵を公開すると、関連するOrchidアカウントのすべての資金が失われます。';

  @override
  String get importHopsConfiguration => 'ホップ設定のインポート';

  @override
  String get import => 'インポート';

  @override
  String get warningImportedConfiguration =>
      '警告：インポートされる設定はアプリで作成した既存のホップを置き換えます。 このデバイスで以前に生成またはインポートされた署名者キーは保持され、新しいホップを作成するためにアクセス可能なままになりますが、OpenVPNホップ設定を含むその他の設定はすべて失われます。';

  @override
  String get configuration => '設定';

  @override
  String get saveButtonTitle => '保存';

  @override
  String get search => '検索';

  @override
  String get newContent => '新しいコンテンツ';

  @override
  String get clear => '取り消し';

  @override
  String get connectionDetail => '接続の詳細';

  @override
  String get host => 'ホスト';

  @override
  String get time => '時間';

  @override
  String get sourcePort => 'ソース ポート';

  @override
  String get destination => '宛先';

  @override
  String get destinationPort => '宛先ポート';

  @override
  String get generateNewKey => '新しいキーを生成';

  @override
  String get importKey => 'キーをインポート';

  @override
  String get nothingToDisplayYet =>
      'まだ表示するものはありません。表示するものがあると、トラフィックはここに表示されます。';

  @override
  String get disconnecting => '切断しています...';

  @override
  String get connecting => '接続しています...';

  @override
  String get pushToConnect => '押して接続します。';

  @override
  String get orchidIsRunning => 'Orchid起動中！';

  @override
  String get pacPurchaseWaiting => '購入待機中';

  @override
  String get retry => 'リトライ';

  @override
  String get getHelpResolvingIssue => 'この問題の解決にご協力ください。';

  @override
  String get copyDebugInfo => 'コピーデバッグ情報';

  @override
  String get contactOrchid => 'Orchidに連絡する';

  @override
  String get remove => '削除する';

  @override
  String get deleteTransaction => 'トランザクションを削除';

  @override
  String get clearThisInProgressTransactionExplain =>
      'この進行中のトランザクションをクリアします。アプリ内購入の払い戻しはありません。この問題を解決するには、Orchidに連絡する必要があります。';

  @override
  String get preparingPurchase => '購入の準備';

  @override
  String get retryingPurchasedPAC => '購入を再試行します';

  @override
  String get retryPurchasedPAC => '購入を再試行';

  @override
  String get purchaseError => '購入エラー';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      '購入時にエラーが発生しました。Orchidサポートまでご連絡ください。';

  @override
  String get importAnOrchidAccount => 'Orchidアカウントをインポートする';

  @override
  String get buyCredits => 'クレジットを購入';

  @override
  String get linkAnOrchidAccount => 'Orchidアカウントをリンクする';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      '申し訳ありませんが、この購入はアクセスクレジットの1日の購入制限を超えます。後でもう一度やり直してください。';

  @override
  String get marketStats => '市場統計';

  @override
  String get balanceTooLow => '残高が低すぎる';

  @override
  String get depositSizeTooSmall => 'デポジットのサイズが小さすぎます';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      '最大チケット値は現在、残高によって制限されています。残高：';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      '最大チケット値は現在、預金によって制限されています。預金：';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'アカウント残高にOXTを追加することを検討してください。';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      '預金にOXTを追加するか、残高から預金に資金を移動することを検討してください。';

  @override
  String get prices => '価格';

  @override
  String get ticketValue => 'チケット価格';

  @override
  String get costToRedeem => '償還費用：';

  @override
  String get viewTheDocsForHelpOnThisIssue => 'この問題のヘルプについてはドキュメントをご覧ください。';

  @override
  String get goodForBrowsingAndLightActivity => 'ブラウジングや軽いアクティビティに最適';

  @override
  String get learnMore => 'もっと詳しく';

  @override
  String get connect => '交流する';

  @override
  String get disconnect => '切断する';

  @override
  String get wireguardHop => 'WireGuardホップ';

  @override
  String get pasteYourWireguardConfigFileHere => 'ここにWireGuard構成ファイルを貼り付けます';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'WireGuardプロバイダーの資格情報を上のフィールドに貼り付けます。';

  @override
  String get wireguard => 'WireGuard';

  @override
  String get clearAllLogData => 'すべてのログデータを消去しますか？';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'このデバッグログは永続的ではなく、アプリを終了するとクリアされます。';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      '秘密情報や個人を特定できる情報が含まれている場合があります。';

  @override
  String get loggingEnabled => 'ロギングが有効';

  @override
  String get cancel => 'キャンセル';

  @override
  String get logging => 'ロギング';

  @override
  String get loading => '読み込んでいます...';

  @override
  String get ethPrice => 'ETH価格：';

  @override
  String get oxtPrice => 'OXT価格：';

  @override
  String get gasPrice => 'ガス価格：';

  @override
  String get maxFaceValue => '最大額面：';

  @override
  String get confirmDelete => '削除を確認';

  @override
  String get enterOpenvpnConfig => 'OpenVPN設定入力';

  @override
  String get enterWireguardConfig => 'WireGuard®️設定入力';

  @override
  String get starting => '起動中...';

  @override
  String get legal => '法的情報';

  @override
  String get whatsNewInOrchid => 'Orchidの新機能';

  @override
  String get orchidIsOnXdai => 'OrchidはxDaiでご利用いただけます！';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'xDaiでOrchidクレジットをご購入いただけるようになりました！ わずか1ドルでVPNの使用を開始します。';

  @override
  String get xdaiAccountsForPastPurchases => '過去の購入のxDaiアカウント';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      '本日より前に行われたアプリ内購入では、xDai資金が同じアカウントキーに追加されています。Orchidで帯域幅をご購入ください！';

  @override
  String get newInterface => '新しいインターフェイス';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'アカウントは、関連付けられているOrchidアドレスの下に整理されます。';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'ホーム画面でアクティブなアカウントの残高と帯域幅のコストを確認します。';

  @override
  String get seeOrchidcomForHelp => 'ヘルプについてはorchid.comを参照してください。';

  @override
  String get payPerUseVpnService => '使用ごとのお支払いのVPNサービス';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'サブスクリプションはありません。クレジットに有効期限はありません。';

  @override
  String get shareAccountWithUnlimitedDevices => '無制限のデバイスでアカウントを共有できます';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Orchidストアは一時的にご利用いただけません。数分後に再度ご確認ください。';

  @override
  String get talkingToPacServer => 'Orchidアカウントサーバーに接続しています';

  @override
  String get advancedConfiguration => '高度な構成';

  @override
  String get newWord => '新規';

  @override
  String get copied => 'コピーされました';

  @override
  String get efficiency => '効率';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return '利用可能な最小チケット：$tickets';
  }

  @override
  String get transactionSentToBlockchain => 'ブロックチェーンに送信されたトランザクション';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      '購入が完了し、xDaiブロックチェーンによって処理されています。これには最大1分、場合によってはそれ以上かかることがあります。 プルダウンして更新すると、残高が更新されたアカウントが下に表示されます。';

  @override
  String get copyReceipt => '領収書をコピー';

  @override
  String get manageAccounts => 'アカウントの管理';

  @override
  String get configurationManagement => '構成管理';

  @override
  String get exportThisOrchidKey => 'このOrchidキーをエクスポート';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'このキーに関連付けられているすべてのOrchidアカウントのQRコードとテキストを以下に示します。';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'このキーを別のデバイスにインポートして、このOrchid IDに関連付けられているすべての Orchid アカウントを共有します。';

  @override
  String get orchidAccountInUse => '使用中のOrchidアカウント';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'このOrchidアカウントは使用中なので削除できません。';

  @override
  String get pullToRefresh => 'プルして更新します。';

  @override
  String get balance => '残高';

  @override
  String get active => 'アクティブ';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'クリップボードからOrchidキーを貼り付けて、そのキーに関連付けられているすべてのOrchidアカウントをインポートします。';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Orchidキーをスキャンするかクリップボードから貼り付けて、そのキーに関連付けられているすべてのOrchidアカウントをインポートします。';

  @override
  String get account => 'アカウント';

  @override
  String get transactions => 'トランザクション';

  @override
  String get weRecommendBackingItUp => '<link>bバックアップする</link>ことをお勧めします。';

  @override
  String get copiedOrchidIdentity => 'Orchidアイデンティティがコピーされました';

  @override
  String get thisIsNotAWalletAddress => 'これはウォレットアドレスではありません。';

  @override
  String get doNotSendTokensToThisAddress => 'このアドレスにトークンを送信しないでください。';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Orchidアイデンティティはネットワーク上でユーザーを一意に識別します。';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      '<link>Orchidアイデンティティ</link>の詳細をご覧ください。';

  @override
  String get analyzingYourConnections => '接続を分析しています';

  @override
  String get analyzeYourConnections => '接続の分析';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'ネットワーク分析では、デバイスのVPN機能を使用してパケットをキャプチャし、トラフィックを分析します。';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'ネットワーク分析にはVPN権限が必要ですが、それ自体ではデータを保護したり、IPアドレスを隠すことはありません。';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'ネットワークプライバシーのメリットを得るには、ホーム画面から VPN接続を設定してアクティブ化する必要があります。';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'この機能をオンにすると、Orchidアプリのバッテリー使用量が増加します。';

  @override
  String get useAnOrchidAccount => 'Orchidアカウントを使用する';

  @override
  String get pasteAddress => 'アドレスを貼り付け';

  @override
  String get chooseAddress => 'アドレスを選択してください';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'このホップで使用するOrchidアカウントを選択します。';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'アカウントが下に表示されない場合は、アカウントマネージャーを使用して、新しいアカウントをインポート、購入、作成できます。';

  @override
  String get selectAnOrchidAccount => 'Orchidアカウントを選択してください';

  @override
  String get takeMeToTheAccountManager => 'アカウントマネージャーに移動';

  @override
  String get funderAccount => '資金提供者アカウント';

  @override
  String get orchidRunningAndAnalyzing => 'Orchidが実行され分析しています';

  @override
  String get startingVpn => '(VPNを起動中)';

  @override
  String get disconnectingVpn => '(VPNを切断しています)';

  @override
  String get orchidAnalyzingTraffic => 'Orchidがトラフィックを分析しています';

  @override
  String get vpnConnectedButNotRouting => '(VPNは接続されていますがルーティングは行われていません)';

  @override
  String get restarting => '再起動しています';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      '監視ステータスを変更するにはVPNを再起動する必要があり、これによりプライバシー保護が一時的に中断されることがあります。';

  @override
  String get confirmRestart => '再起動を確認';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return '平均価格は 1GB あたり $price 米ドルです';
  }

  @override
  String get myOrchidConfig => 'Orchid の設定';

  @override
  String get noAccountSelected => 'アカウントが選択されていません';

  @override
  String get inactive => '非アクティブ';

  @override
  String get tickets => 'チケット';

  @override
  String get accounts => 'アカウント';

  @override
  String get orchidIdentity => 'Orchid アイデンティティ';

  @override
  String get addFunds => '資金を追加';

  @override
  String get addFunds2 => '資金を追加する';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'ホップ';

  @override
  String get circuit => '回路';

  @override
  String get clearAllAnalysisData => 'すべての分析データを消去しますか？';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'このアクションにより、以前に分析されたすべてのトラフィック接続データが消去されます。';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get stopAnalysis => '分析を停止';

  @override
  String get startAnalysis => '分析を開始';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Orchid アカウントには、24 時間年中無休のカスタマー サポート、無制限のデバイスが含まれ、<link2>0xDai 暗号通貨</link2>によって裏打ちされています。';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      '購入したアカウントは、当社の<link1>優先プロバイダー</link1>のみに接続されます。';

  @override
  String get refundPolicyCoveredByAppStores => 'アプリ ストアの対象となる払い戻しポリシー。';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      '現時点では、Orchidはアプリ内購入を表示できません。';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'このデバイスがアプリ内購入をサポートし、構成されていることを確認してください。';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'このデバイスがアプリ内購入をサポートおよび構成されていることを確認するか、分散型の<link>アカウント管理</link> システムを使用してください。';

  @override
  String get buy => '購入する';

  @override
  String get gbApproximately12 => '12GB (近似値)';

  @override
  String get gbApproximately60 => '60GB (近似値)';

  @override
  String get gbApproximately240 => '240GB (近似値)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'ブラウジングや軽いストリーミングを含む中期的な個人使用に理想的なサイズです。';

  @override
  String get mostPopular => '最も人気があります！';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      '帯域幅が多く、長期間の使用または共有アカウントに適しています。';

  @override
  String get total => '合計';

  @override
  String get pausingAllTraffic => 'すべてのトラフィックを一時停止しています...';

  @override
  String get queryingEthereumForARandom => 'イーサリアムにランダム プロバイダーを照会しています...';

  @override
  String get quickFundAnAccount => 'アカウントにすばやく資金を提供します！';

  @override
  String get accountFound => 'アカウントが見つかりました';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'あなたのIDに関連付けられたアカウントを見つけ、そのためのシングル ホップ Orchid サーキットを作成しました。これで、VPN を使用する準備が整いました。';

  @override
  String get welcomeToOrchid => 'Orchid にようこそ！';

  @override
  String get fundYourAccount => 'アカウントに資金を提供する';

  @override
  String get processing => '処理しています...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'サブスクリプションなし、従量課金制、分散型のオープンソース VPN サービス。';

  @override
  String getStartedFor1(String smallAmount) {
    return '$smallAmount で始める';
  }

  @override
  String get importAccount => 'アカウントをインポート';

  @override
  String get illDoThisLater => '後で行う';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'VPN クレジットを購入して、共有可能で補充可能な Orchid アカウントに資金を提供することにより、ネットワークの<link1>優先プロバイダー</link1>の 1 つに自動的に接続します。';

  @override
  String get confirmPurchase => '購入を確認';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Orchid アカウントは、<link>xDAI 暗号通貨</link>に裏打ちされた VPN クレジットを使用し、24 時間年中無休のカスタマー サポート、無制限のデバイス共有を含み、アプリ ストアの払い戻しポリシーの対象となります。';

  @override
  String get yourPurchaseIsInProgress => 'ご購入が進行中です。';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'この購入の処理には予想よりも時間がかかり、エラーが発生した可能性があります。';

  @override
  String get thisMayTakeAMinute => 'これには 1 分かかる場合があります...';

  @override
  String get vpnCredits => 'VPN クレジット';

  @override
  String get blockchainFee => 'ブロックチェーン料金';

  @override
  String get promotion => 'プロモーション';

  @override
  String get showInAccountManager => 'アカウント マネージャーに表示';

  @override
  String get deleteThisOrchidIdentity => 'この Orchid アイデンティティを削除';

  @override
  String get chooseIdentity => 'アイデンティティを選択';

  @override
  String get updatingAccounts => 'アカウントの更新';

  @override
  String get trafficAnalysis => 'トラフィック分析';

  @override
  String get accountManager => 'アカウント マネージャー';

  @override
  String get circuitBuilder => '回路ビルダー';

  @override
  String get exitHop => '出口ホップ';

  @override
  String get entryHop => 'エントリー ホップ';

  @override
  String get addNewHop => '新しいホップを追加';

  @override
  String get newCircuitBuilder => '新しい回路ビルダー！';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'これで、xDAI を使用してマルチホップ Orchid 回路の料金を支払うことができます。 マルチホップ インターフェイスは、xDAI および OXT Orchid アカウントをサポートするようになり、オニオン ルートにまとめることができる OpenVPN および WireGuard 構成を引き続きサポートします。';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'アカウント マネージャーではなく、回路ビルダーから接続を管理します。 すべての接続で、ホップ数が 0 以上の回路が使用されるようになりました。既存の構成はすべて回路ビルダーに移行されています。';

  @override
  String quickStartFor1(String smallAmount) {
    return '$smallAmount でクイック スタート';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Orchid アカウントを購入し、ホーム画面からシングル ホップ回路を作成してオンボーディング プロセスを短縮する方法を追加しました。';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid は、複数の VPN プロトコルをサポートするマルチホップまたはクラシック オニオン ルーティング クライアントとしてユニークです。以下のサポートされているプロトコルからのホップをチェーン化することにより、接続をセットアップできます。\n\n1 ホップは通常の VPN のようなものです。 3 ホップ (上級ユーザー向け) は、オニオン ルーティングの選択肢です。0 ホップにより、VPN トンネルなしでトラフィック分析が可能になります。';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'OpenVPN および Wireguard ホップを削除すると、関連する資格情報と接続構成が失われます。続行する前に、必ず情報をバックアップしてください。';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'これは、元に戻すことはできません。このアイデンティティを保存するには、[キャンセル] をクリックして、[エクスポート] オプションを使用します';

  @override
  String get unlockTime => 'ロック解除時間';

  @override
  String get chooseChain => 'チェーンを選択';

  @override
  String get unlocking => 'ロック解除';

  @override
  String get unlocked => 'ロック解除されています';

  @override
  String get orchidTransaction => 'Orchid トランザクション';

  @override
  String get confirmations => '確認';

  @override
  String get pending => '保留中...';

  @override
  String get txHash => 'Tx ハッシュ：';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal => 'あなたの資金はすべて引き出し可能です。';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '現在、合計資金 $totalFunds のうち $maxWithdraw を引き出すことができます。';
  }

  @override
  String get alsoUnlockRemainingDeposit => '残りの預金のロックを解除';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      '全額より少ない金額を指定した場合、最初に残高から資金が引き出されます。';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      '追加のオプションについては、詳細パネルを参照してください。';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      '預金のロック解除オプションを選択した場合、このトランザクションは指定された金額を残高からすぐに引き出し、残りの預金のロック解除プロセスも開始します。';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      '預金の資金は、ロックを解除してから 24 時間後に引き出すことができます。';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'あなたの Orchid アカウントから現在のウォレットに資金を引き出します。';

  @override
  String get withdrawAndUnlockFunds => '資金を引き出しロック解除';

  @override
  String get withdrawFunds => '資金を引き出す';

  @override
  String get withdrawFunds2 => '資金を引き出す';

  @override
  String get withdraw => '引き出し';

  @override
  String get submitTransaction => 'トランザクションを送信';

  @override
  String get move => '移動';

  @override
  String get now => '今';

  @override
  String get amount => '金額';

  @override
  String get available => '利用可能';

  @override
  String get select => '選択';

  @override
  String get add => '追加';

  @override
  String get balanceToDeposit => '残高から預金へ';

  @override
  String get depositToBalance => '預金から残高へ';

  @override
  String get setWarnedAmount => '警告額を設定';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Orchid アカウントおよび/または預金に資金を追加します。';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'アカウントのサイズ設定については、<link>orchid.com</link> をご覧ください。';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return '現在の $tokenType 事前承認：$amount';
  }

  @override
  String get noWallet => 'ウォレットがありません';

  @override
  String get noWalletOrBrowserNotSupported => 'ウォレットがないか、ブラウザがサポートされていません。';

  @override
  String get error => 'エラー';

  @override
  String get failedToConnectToWalletconnect => 'WalletConnect に接続できませんでした。';

  @override
  String get unknownChain => '不明なチェーン';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Orchid アカウント マネージャーは、まだこのチェーンをサポートしていません。';

  @override
  String get orchidIsntOnThisChain => 'Orchid はこのチェーンにはありません。';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Orchid の契約は、まだこのチェーンに展開されていません。';

  @override
  String get moveFunds => '資金を移動';

  @override
  String get moveFunds2 => '資金移動';

  @override
  String get lockUnlock => 'ロック / ロック解除';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return '預金 $amount のロックが解除されます。';
  }

  @override
  String get locked => 'ロックされています';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return '預金 $amount は$unlockingOrUnlocked。';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return '資金は \$$time で引き出し可能になります。';
  }

  @override
  String get lockDeposit => '預金をロック';

  @override
  String get unlockDeposit => '預金のロックを解除';

  @override
  String get advanced => '詳細設定';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Orchid アカウントについての詳細を見る</link>';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return '$efficiency の効率と $num 枚のチケットの価値を持つ Orchid アカウントを作成するための推定コスト。';
  }

  @override
  String get chain => 'チェーン';

  @override
  String get token => 'トークン';

  @override
  String get minDeposit => '最低預金額';

  @override
  String get minBalance => '最低残高';

  @override
  String get fundFee => '資金手数料';

  @override
  String get withdrawFee => '引き出し手数料';

  @override
  String get tokenValues => 'トークン価値';

  @override
  String get usdPrices => 'USD 価格';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      '警告預金額を設定すると、預金資金を引き出すために必要な 24 時間の待機期間が始まります。';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'この期間中、資金は Orchid ネットワークの有効な預金として利用できません。';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      '警告額を減らすことにより、いつでも資金を再ロックすることができます。';

  @override
  String get warn => '警告';

  @override
  String get totalWarnedAmount => '合計警告額';

  @override
  String get newIdentity => '新しいアイデンティティ';

  @override
  String get importIdentity => 'アイデンティティをインポート';

  @override
  String get exportIdentity => 'アイデンティティをエクスポート';

  @override
  String get deleteIdentity => 'アイデンティティを削除';

  @override
  String get importOrchidIdentity => 'Orchid アイデンティティのインポート';

  @override
  String get funderAddress => '資金提供者アドレス';

  @override
  String get contract => '契約';

  @override
  String get txFee => 'トランザクション\n手数料';

  @override
  String get show => '表示';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'エラー';

  @override
  String get lastHour => '前の 1 時間';

  @override
  String get chainSettings => 'チェーン設定';

  @override
  String get price => '価格';

  @override
  String get failed => '失敗';

  @override
  String get fetchGasPrice => 'ガス価格を取得';

  @override
  String get fetchLotteryPot => '残高を取得';

  @override
  String get lines => '行';

  @override
  String get filtered => 'フィルター済み';

  @override
  String get backUpYourIdentity => 'IDをバックアップします';

  @override
  String get accountSetUp => 'アカウントの設定';

  @override
  String get setUpAccount => 'アカウントを設定する';

  @override
  String get generateIdentity => 'IDを生成する';

  @override
  String get enterAnExistingOrchidIdentity =>
      '既存の <account_link>蘭のアイデンティティを入力してください</account_link>';

  @override
  String get pasteTheWeb3WalletAddress =>
      'アカウントの資金調達に使用するweb3ウォレットアドレスを以下に貼り付けてください。';

  @override
  String get funderWalletAddress => 'ファンダーウォレットアドレス';

  @override
  String get yourOrchidIdentityPublicAddress => 'OrchidIdentityのパブリックアドレス';

  @override
  String get continueButton => '持続する';

  @override
  String get yesIHaveSavedACopyOf => 'はい、秘密鍵のコピーを安全な場所に保存しました。';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'OrchidIdentity <bold>秘密鍵</bold>をバックアップします。このIDと関連するすべてのアカウントを共有、インポート、または復元するには、このキーが必要になります。';

  @override
  String get locked1 => 'ロック済み';

  @override
  String get unlockDeposit1 => 'デポジットのロックを解除する';

  @override
  String get changeWarnedAmountTo => '警告量をに変更';

  @override
  String get setWarnedAmountTo => '警告量をに設定';

  @override
  String get currentWarnedAmount => '現在の警告額';

  @override
  String get allWarnedFundsWillBeLockedUntil => '警告された資金はすべて、';

  @override
  String get balanceToDeposit1 => '入金する残高';

  @override
  String get depositToBalance1 => '残高への預金';

  @override
  String get advanced1 => '高度な';

  @override
  String get add1 => '追加';

  @override
  String get lockUnlock1 => '施錠開錠';

  @override
  String get viewLogs => 'ログを見る';

  @override
  String get language => '言語';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get identiconStyle => 'Identiconスタイル';

  @override
  String get blockies => 'ブロッキー';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => '契約バージョン';

  @override
  String get version0 => 'バージョン0';

  @override
  String get version1 => 'バージョン1';

  @override
  String get connectedWithMetamask => 'メタマスクに接続';

  @override
  String get blockExplorer => 'ブロックエクスプローラー';

  @override
  String get tapToMinimize => 'タップして最小化';

  @override
  String get connectWallet => 'ウォレットを接続';

  @override
  String get checkWallet => 'チェックウォレット';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      '保留中のリクエストについては、ウォレットアプリまたは拡張機能を確認してください。';

  @override
  String get test => 'テスト';

  @override
  String get chainName => 'チェーン名';

  @override
  String get rpcUrl => 'RPC URL';

  @override
  String get tokenPrice => 'トークン価格';

  @override
  String get tokenPriceUsd => 'トークン価格 USD';

  @override
  String get addChain => 'チェーンを追加';

  @override
  String get deleteChainQuestion => 'チェーンを削除しますか?';

  @override
  String get deleteUserConfiguredChain => 'ユーザー構成チェーンの削除';

  @override
  String get fundContractDeployer => '資金契約デプロイヤー';

  @override
  String get deploySingletonFactory => 'シングルトン ファクトリをデプロイする';

  @override
  String get deployContract => '契約を展開する';

  @override
  String get about => '約';

  @override
  String get dappVersion => 'Dapp バージョン';

  @override
  String get viewContractOnEtherscan => 'イーサスキャンで契約を見る';

  @override
  String get viewContractOnGithub => 'Github で契約を表示';

  @override
  String get accountChanges => 'アカウントの変更';

  @override
  String get name => '名';

  @override
  String get step1 =>
      '<bold>ステップ 1.</bold> ERC-20 ウォレットに <link>十分な数のトークン</link> を接続します。';

  @override
  String get step2 =>
      '<bold>ステップ 2.</bold> [アカウントの管理] に移動し、アドレスをタップして、Orchid アプリから Orchid ID をコピーします。';

  @override
  String get connectOrCreate => 'Orchid アカウントを接続または作成する';

  @override
  String get lockDeposit2 => 'ロックデポジット';

  @override
  String get unlockDeposit2 => 'デポジットのロックを解除する';

  @override
  String get enterYourWeb3 => 'web3 ウォレットのアドレスを入力します。';

  @override
  String get purchaseComplete => '購入完了';

  @override
  String get generateNewIdentity => '新しいアイデンティティを生成する';

  @override
  String get copyIdentity => 'ID をコピー';

  @override
  String get yourPurchaseIsComplete =>
      '購入が完了し、現在 xDai ブロックチェーンによって処理されています。これには数分かかる場合があります。このアカウントを使用して、デフォルトの回線が生成されました。ホーム画面またはアカウントマネージャーで利用可能な残高を監視できます。';

  @override
  String get circuitGenerated => '生成された回路';

  @override
  String get usingYourOrchidAccount =>
      'Orchid アカウントを使用して、シングル ホップ サーキットが生成されました。これは回路ビルダー画面から管理できます。';
}
