// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get orchidHop => 'Orchid 跃点';

  @override
  String get orchidDisabled => 'Orchid 已禁用';

  @override
  String get trafficMonitoringOnly => '仅进行流量监控';

  @override
  String get orchidConnecting => '正在连接 Orchid';

  @override
  String get orchidDisconnecting => '正在断开连接 Orchid';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num 个已配置跃点',
      two: '二个已配置跃点',
      one: '一个已配置跃点',
      zero: '未配置跃点',
    );
    return '$_temp0';
  }

  @override
  String get delete => '删除';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => '跃点';

  @override
  String get traffic => '流量';

  @override
  String get curation => '数据监管';

  @override
  String get signerKey => '签名者密钥';

  @override
  String get copy => '复制';

  @override
  String get paste => '粘贴';

  @override
  String get deposit => '存款';

  @override
  String get curator => '数据提供者';

  @override
  String get ok => '好';

  @override
  String get settingsButtonTitle => '设置';

  @override
  String get confirmThisAction => '确认此操作';

  @override
  String get cancelButtonTitle => '取消';

  @override
  String get changesWillTakeEffectInstruction => '重新启动 VPN 后，更改将随之生效。';

  @override
  String get saved => '已保存';

  @override
  String get configurationSaved => '配置已保存';

  @override
  String get whoops => '糟糕';

  @override
  String get configurationFailedInstruction => '无法保存配置，请重试。';

  @override
  String get addHop => '添加跃点';

  @override
  String get scan => '扫描';

  @override
  String get invalidQRCode => '无效二维码';

  @override
  String get theQRCodeYouScannedDoesNot => '您扫描的二维码未包含有效帐户配置。';

  @override
  String get invalidCode => '无效代码';

  @override
  String get theCodeYouPastedDoesNot => '您粘贴的代码未包含有效帐户配置。';

  @override
  String get openVPNHop => 'OpenVPN 跃点';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get config => '配置';

  @override
  String get pasteYourOVPN => '请在此处粘贴 OVPN 配置';

  @override
  String get enterYourCredentials => '输入您的凭据';

  @override
  String get enterLoginInformationInstruction =>
      '输入以上 VPN 提供商的登录信息，然后粘贴提供商的 OpenVPN 配置文件内容至所提供的字段中。';

  @override
  String get save => '保存';

  @override
  String get help => '帮助';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get settings => '设置';

  @override
  String get version => '版本';

  @override
  String get noVersion => '无版本';

  @override
  String get orchidOverview => 'Orchid 概述';

  @override
  String get defaultCurator => '默认数据提供人';

  @override
  String get queryBalances => '查询余额';

  @override
  String get reset => '重置';

  @override
  String get manageConfiguration => '管理配置';

  @override
  String get warningThesefeature => '警告： 这些功能仅适用于高级用户。 请阅读所有说明。';

  @override
  String get exportHopsConfiguration => '导出跃点配置';

  @override
  String get export => '导出';

  @override
  String get warningExportedConfiguration =>
      '警告： 导出的配置包括已导出跃点的签名者私钥。 泄露私钥可能导致您损失相关 Orchid 帐户中的所有资金。';

  @override
  String get importHopsConfiguration => '导入跃点配置';

  @override
  String get import => '导入';

  @override
  String get warningImportedConfiguration =>
      '警告： 导入的配置将替换您在应用中创建的任何现有跃点。 以前在此设备上生成或导入的签名者密钥将保留，且仍然可用于创建新跃点，但所有其他配置（包括 OpenVPN 跃点配置）都将丢失。';

  @override
  String get configuration => '配置';

  @override
  String get saveButtonTitle => '保存';

  @override
  String get search => '搜索';

  @override
  String get newContent => '新内容';

  @override
  String get clear => '清除';

  @override
  String get connectionDetail => '连接详情';

  @override
  String get host => '主机';

  @override
  String get time => '时间';

  @override
  String get sourcePort => '源端口';

  @override
  String get destination => '目的地';

  @override
  String get destinationPort => '目的端口';

  @override
  String get generateNewKey => '生成新密钥';

  @override
  String get importKey => '导入密钥';

  @override
  String get nothingToDisplayYet => '尚无内容可供显示。存在可显示内容时，将于此处显示流量。';

  @override
  String get disconnecting => '断开连接...';

  @override
  String get connecting => '连接中';

  @override
  String get pushToConnect => '按下即可连接。';

  @override
  String get orchidIsRunning => '兰花正在运行中！';

  @override
  String get pacPurchaseWaiting => '购买等待';

  @override
  String get retry => '重试';

  @override
  String get getHelpResolvingIssue => '获取解决此问题的帮助。';

  @override
  String get copyDebugInfo => '复制调试信息';

  @override
  String get contactOrchid => '联系兰花';

  @override
  String get remove => '去掉';

  @override
  String get deleteTransaction => '删除交易';

  @override
  String get clearThisInProgressTransactionExplain =>
      '清除正在进行的操作。或无法退还您的应用内购买。您必须与Orchid联系以解决问题。';

  @override
  String get preparingPurchase => '准备购买';

  @override
  String get retryingPurchasedPAC => '重试购买中';

  @override
  String get retryPurchasedPAC => '重试购买';

  @override
  String get purchaseError => '购买错误';

  @override
  String get thereWasAnErrorInPurchasingContact => '购买时出错。请联系兰花支持。';

  @override
  String get importAnOrchidAccount => '导入兰花帐户';

  @override
  String get buyCredits => '购买积分';

  @override
  String get linkAnOrchidAccount => '关联兰花帐户';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      '很抱歉，这次购买将超出访问积分的每日购买限额。请稍后再试。';

  @override
  String get marketStats => '市场统计';

  @override
  String get balanceTooLow => '低余额';

  @override
  String get depositSizeTooSmall => '存款额太小';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      '您的最高使用价值目前受您的余额限制';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      '您的最高使用价值目前受您的存款限制';

  @override
  String get considerAddingOxtToYourAccountBalance => '考虑将OXT添加到您的帐户余额中。';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      '考虑将OXT添加到您的存款中，或将资金从余额中转移到您的存款中。';

  @override
  String get prices => '价格';

  @override
  String get ticketValue => '使用价值';

  @override
  String get costToRedeem => '兑换费用：';

  @override
  String get viewTheDocsForHelpOnThisIssue => '查看文档以获取相关问题的帮助。';

  @override
  String get goodForBrowsingAndLightActivity => '适合网页浏览和低带宽活动';

  @override
  String get learnMore => '了解更多……';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String get wireguardHop => 'WireGuard Hop';

  @override
  String get pasteYourWireguardConfigFileHere => '在此处粘贴您的WireGuard配置文件';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      '将WireGuard提供程序的凭据信息粘贴到上面的字段中。';

  @override
  String get wireguard => '线路保护';

  @override
  String get clearAllLogData => '清除所有日志数据？';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      '该日志调试为非永久性，并且在退出应用程序时会清除。';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      '它或包含隐私或个人识别信息。';

  @override
  String get loggingEnabled => '启用记录';

  @override
  String get cancel => '取消';

  @override
  String get logging => '记录中';

  @override
  String get loading => '载入中......';

  @override
  String get ethPrice => 'ETH价格：';

  @override
  String get oxtPrice => 'OXT价格：';

  @override
  String get gasPrice => 'gas费用：';

  @override
  String get maxFaceValue => '最大面值：';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get enterOpenvpnConfig => '输入 OpenVPN Config';

  @override
  String get enterWireguardConfig => '输入WireGuard®️ Config';

  @override
  String get starting => '启动中...';

  @override
  String get legal => '法律事项';

  @override
  String get whatsNewInOrchid => 'Orchid 更新摘要';

  @override
  String get orchidIsOnXdai => 'Orchid 已入驻 xDai！';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      '您现在可以在 xDai 上购买 Orchid 积分！只需 1 美元即可开始使用 VPN。';

  @override
  String get xdaiAccountsForPastPurchases => 'xDai 帐户亦可用于过去的购买';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      '针对今天之前进行的任何应用内购买，xDai 资金已添加到同一帐户密钥中。请安心使用带宽！';

  @override
  String get newInterface => '新界面';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      '现在，帐户于其关联的 Orchid 地址下进行管理。';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      '请在主页界面上查看您的活动帐户余额和带宽费用。';

  @override
  String get seeOrchidcomForHelp => '请登录 orchid.com 查看帮助。';

  @override
  String get payPerUseVpnService => '按使用付费 VPN 服务';

  @override
  String get notASubscriptionCreditsDontExpire => '无需订阅，且积分不会过期';

  @override
  String get shareAccountWithUnlimitedDevices => '可以在无限数量的设备上共享帐户';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Orchid Store 暂时不可用。请于几分钟后查看。';

  @override
  String get talkingToPacServer => '正在与 Orchid 帐户服务器通信中';

  @override
  String get advancedConfiguration => '高级配置';

  @override
  String get newWord => '新';

  @override
  String get copied => '已复制';

  @override
  String get efficiency => '效率';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return '可用的最低使用价值：$tickets';
  }

  @override
  String get transactionSentToBlockchain => '交易已发送到区块链';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      '您已完成购买，现在由 xDai 区块链处理，这可能需要一分钟，有时甚至需要更长时间。请下拉刷新，下方将显示余额更新后的帐户。';

  @override
  String get copyReceipt => '复制回执';

  @override
  String get manageAccounts => '管理帐户';

  @override
  String get configurationManagement => '配置管理';

  @override
  String get exportThisOrchidKey => '导出此 Orchid 密钥';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      '以下请见与此密钥关联的所有 Orchid 帐户的二维码和文本。';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      '在另一台设备上导入此密钥，以在与此 Orchid ID 关联的所有 Orchid 帐户中共享。';

  @override
  String get orchidAccountInUse => '在用的 Orchid 帐户';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      '此 Orchid 帐户正在使用中，无法删除。';

  @override
  String get pullToRefresh => '下拉刷新。';

  @override
  String get balance => '余额';

  @override
  String get active => '活动';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      '从剪贴板上粘贴 Orchid 密钥，以导入与该密钥关联的所有 Orchid 帐户。';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      '扫描或粘贴剪贴板上的 Orchid 密钥，以导入与该密钥关联的所有 Orchid 帐户。';

  @override
  String get account => '帐户';

  @override
  String get transactions => '交易';

  @override
  String get weRecommendBackingItUp => '我们建议您<link>备份</link>。';

  @override
  String get copiedOrchidIdentity => '已复制 Orchid ID';

  @override
  String get thisIsNotAWalletAddress => '这不是一个钱包地址。';

  @override
  String get doNotSendTokensToThisAddress => '不要将代币发送到此地址。';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      '您的 Orchid ID 是网络上识别您的唯一信息。';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      '了解更多关于您的 <link>Orchid ID</link> 的信息。';

  @override
  String get analyzingYourConnections => '正在分析连接数据';

  @override
  String get analyzeYourConnections => '分析连接数据';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      '网络分析使用您设备的 VPN 设施捕获数据包并分析您的流量。';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      '网络分析需要 VPN 权限，但其本身并不能保护您的数据或隐藏您的 IP 地址。';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      '要获得网络隐私保护，您必须从主页界面配置并激活 VPN 连接。';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      '打开此功能将增加 Orchid 应用的电池耗电量。';

  @override
  String get useAnOrchidAccount => '使用 Orchid 帐户';

  @override
  String get pasteAddress => '粘贴地址';

  @override
  String get chooseAddress => '选择地址';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop => '选择用于此跃点的 Orchid 帐户。';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      '如果在下面没有看到您的帐户，可使用帐户管理器导入、购买或创建一个新帐户。';

  @override
  String get selectAnOrchidAccount => '选择 Orchid 帐户';

  @override
  String get takeMeToTheAccountManager => '前往“帐户管理器”';

  @override
  String get funderAccount => '出资人帐户';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid 正在运行及分析';

  @override
  String get startingVpn => '（正在启动 VPN）';

  @override
  String get disconnectingVpn => '（正在断开 VPN）';

  @override
  String get orchidAnalyzingTraffic => 'Orchid 正在分析流量';

  @override
  String get vpnConnectedButNotRouting => '（VPN 已连接但未路由）';

  @override
  String get restarting => '正在进行重启';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      '更改监控状态需要重新启动 VPN，这可能会短暂中断隐私保护。';

  @override
  String get confirmRestart => '确认重新启动';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return '平均价格为每 GB $price 美元';
  }

  @override
  String get myOrchidConfig => '我的 Orchid 配置';

  @override
  String get noAccountSelected => '未选择帐户';

  @override
  String get inactive => '非活跃';

  @override
  String get tickets => '彩币';

  @override
  String get accounts => '帐户';

  @override
  String get orchidIdentity => 'Orchid ID';

  @override
  String get addFunds => '充值';

  @override
  String get addFunds2 => '增加资金';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => '美元/GB';

  @override
  String get hop => '跃点';

  @override
  String get circuit => '线路';

  @override
  String get clearAllAnalysisData => '清除所有分析数据？';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      '此操作将清除所有先前分析的流量连接数据。';

  @override
  String get clearAll => '全部清除';

  @override
  String get stopAnalysis => '停止分析';

  @override
  String get startAnalysis => '开始分析';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Orchid 帐户提供 7 天/24 小时客户支持，不限设备数量，并支持 <link2>xDai 加密货币</link2>。';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      '已购买的帐户将仅连接到我们的<link1>首选提供商</link1>。';

  @override
  String get refundPolicyCoveredByAppStores => '应用商店提供退款政策。';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid 目前无法显示 App 内购买功能。';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      '请确认此设备支持 App 内购买功能并经过适当配置。';

  @override
  String
      get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
          '请确认此设备支持 App 内购买功能并经过适当配置，或者使用我们去中心化的<link>帐户管理</link>系统。';

  @override
  String get buy => '购买';

  @override
  String get gbApproximately12 => '12GB（近似值）';

  @override
  String get gbApproximately60 => '60GB（近似值）';

  @override
  String get gbApproximately240 => '240GB（近似值）';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      '非常适合中期个人使用，包括网络浏览和轻度流媒体使用。';

  @override
  String get mostPopular => '最受欢迎！';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      '适合带宽要求大、长期使用或共享帐户。';

  @override
  String get total => '合计';

  @override
  String get pausingAllTraffic => '暂停所有流量...';

  @override
  String get queryingEthereumForARandom => '查询以太坊以获取随机提供商...';

  @override
  String get quickFundAnAccount => '快速为帐户充值！';

  @override
  String get accountFound => '已找到帐户';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      '我们找到了一个与您的 ID 相关联的帐户，并为其创建了一个单跃点 Orchid 线路。您现在可以开始使用 VPN。';

  @override
  String get welcomeToOrchid => '欢迎使用 Orchid！';

  @override
  String get fundYourAccount => '为您的帐户充值';

  @override
  String get processing => '正在处理...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'VPN 服务：免订阅、按需付费、去中心化、开源。';

  @override
  String getStartedFor1(String smallAmount) {
    return '仅需 $smallAmount 即可开始体验';
  }

  @override
  String get importAccount => '导入帐户';

  @override
  String get illDoThisLater => '暂时跳过';

  @override
  String
      get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
          'Orchid 帐户可共享、可再充值，您可以购买 VPN 积分来充值，以便自动连接到网络<link1>首选提供商</link1>。';

  @override
  String get confirmPurchase => '确认购买';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Orchid 帐户使用由 <link>xDAI 加密货币</link>提供支持的 VPN 积分，并提供 7 天/24 小时客户支持、无限设备共享和应用商店退款政策保障。';

  @override
  String get yourPurchaseIsInProgress => '您的购买正在处理中。';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      '此次购买的处理时间比预期的更长，可能遇到了错误。';

  @override
  String get thisMayTakeAMinute => '请稍候...';

  @override
  String get vpnCredits => 'VPN 积分';

  @override
  String get blockchainFee => '区块链费用';

  @override
  String get promotion => '促销';

  @override
  String get showInAccountManager => '在“帐户管理器”中显示';

  @override
  String get deleteThisOrchidIdentity => '删除此 Orchid ID';

  @override
  String get chooseIdentity => '选择 ID';

  @override
  String get updatingAccounts => '正在更新帐户';

  @override
  String get trafficAnalysis => '流量分析';

  @override
  String get accountManager => '帐户管理器';

  @override
  String get circuitBuilder => '线路生成器';

  @override
  String get exitHop => '出口跃点';

  @override
  String get entryHop => '入口跃点';

  @override
  String get addNewHop => '添加新跃点';

  @override
  String get newCircuitBuilder => '新的线路生成器！';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      '您现在可以使用 xDAI 支付多跃点 Orchid 线路的费用。多跃点界面现在支持 xDAI 和 OXT Orchid 帐户，并且仍然支持 OpenVPN 和 WireGuard 配置，它们可以串起来形成一个“洋葱路由”。';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      '您可以从“线路生成器”而非“帐户管理器”中管理您的连接。所有连接现在都使用零或多跃点的线路。任何现有配置都已迁移到“线路生成器”。';

  @override
  String quickStartFor1(String smallAmount) {
    return '仅需 $smallAmount 即可快速开启体验之旅';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      '我们增加了一种购买 Orchid 帐户的方法，并从主页创建单跃点线路，方便您更快上手。';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid 是一个独一无二的多跃点或洋葱路由客户端，支持多种 VPN 协议。您可以将以下受支持协议中的跃点链接在一起来建立连接。\n\n一个跃点就像一个普通的 VPN。选择三个跃点（用于高级用户）即是经典的洋葱路由。如果是零跃点，则允许在没有任何 VPN 隧道的情况下进行流量分析。';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      '删除 OpenVPN 和 Wireguard 跃点将丢失任何关联的凭据和连接配置。在继续之前，请务必备份所有信息。';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      '此操作无法撤消。要保存此 ID，请点击“取消”并使用“导出”选项';

  @override
  String get unlockTime => '解锁时间';

  @override
  String get chooseChain => '选择链';

  @override
  String get unlocking => '解锁';

  @override
  String get unlocked => '已解锁';

  @override
  String get orchidTransaction => 'Orchid 交易';

  @override
  String get confirmations => '确认';

  @override
  String get pending => '待定...';

  @override
  String get txHash => '交易哈希值：';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal => '您的所有资金均可提取。';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '您的 $totalFunds 综合资金中目前有 $maxWithdraw 可以提取。';
  }

  @override
  String get alsoUnlockRemainingDeposit => '同时解锁剩余存款';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      '如果您指定的金额少于总金额，资金将首先从您的余额中提取。';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel => '其他选项详见“高级”面板。';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      '如果您选择“解锁存款”选项，此交易将立即从您的余额中提取指定金额，并针对您剩余的存款启动解锁程序。';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      '在解锁之后，存款资金可在 24 小时内提取。';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      '从您的 Orchid 帐户提取资金到当前钱包。';

  @override
  String get withdrawAndUnlockFunds => '提取并解锁资金';

  @override
  String get withdrawFunds => '提取资金';

  @override
  String get withdrawFunds2 => '提款';

  @override
  String get withdraw => '提取';

  @override
  String get submitTransaction => '提交交易';

  @override
  String get move => '转移';

  @override
  String get now => '现在';

  @override
  String get amount => '金额';

  @override
  String get available => '可用';

  @override
  String get select => '选择';

  @override
  String get add => '添加';

  @override
  String get balanceToDeposit => '余额至存款';

  @override
  String get depositToBalance => '存款至余额';

  @override
  String get setWarnedAmount => '设置警告金额';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      '将资金添加到您的 Orchid 帐户余额和/或存款中。';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      '有关帐户金额大小的指南，详见 <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return '当前$tokenType预授权：$amount';
  }

  @override
  String get noWallet => '无钱包';

  @override
  String get noWalletOrBrowserNotSupported => '无钱包或浏览器不受支持。';

  @override
  String get error => '错误';

  @override
  String get failedToConnectToWalletconnect => '无法连接 WalletConnect。';

  @override
  String get unknownChain => '未知链';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Orchid 帐户管理器尚不支持此链。';

  @override
  String get orchidIsntOnThisChain => 'Orchid 未入驻此链！';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      '此链尚未部署 Orchid 合约。';

  @override
  String get moveFunds => '转移资金';

  @override
  String get moveFunds2 => '转移资金';

  @override
  String get lockUnlock => '锁定 / 解锁';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return '您的 $amount存款已解锁。';
  }

  @override
  String get locked => '已锁定';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return '您的 $amount存款已$unlockingOrUnlocked。';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return '资金可以在 \$$time 内提取。';
  }

  @override
  String get lockDeposit => '锁定存款';

  @override
  String get unlockDeposit => '解锁存款';

  @override
  String get advanced => '高级';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>了解更多有关 Orchid 帐户的信息</link>。';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return '创建一个效率为 $efficiency、价值为 $num 个彩币的 Orchid 帐户。';
  }

  @override
  String get chain => '区块链';

  @override
  String get token => '通证';

  @override
  String get minDeposit => '最低存款';

  @override
  String get minBalance => '最低余额';

  @override
  String get fundFee => '资金费';

  @override
  String get withdrawFee => '提取费';

  @override
  String get tokenValues => '通证价值';

  @override
  String get usdPrices => '美元价';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      '设置警告存款金额将会开启一个用于提取存款资金的 24 小时等待期，';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      '在该等待期内，资金不可作为 Orchid 网络中的有效存款。';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe => '通过减少警告金额可以随时重新锁定资金。';

  @override
  String get warn => '警告';

  @override
  String get totalWarnedAmount => '警告总金额';

  @override
  String get newIdentity => '新 ID';

  @override
  String get importIdentity => '导入 ID';

  @override
  String get exportIdentity => '导出 ID';

  @override
  String get deleteIdentity => '删除 ID';

  @override
  String get importOrchidIdentity => '导入 Orchid ID';

  @override
  String get funderAddress => '出资人地址';

  @override
  String get contract => '合约';

  @override
  String get txFee => '交易费';

  @override
  String get show => '显示';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => '错误';

  @override
  String get lastHour => '过去一小时';

  @override
  String get chainSettings => '链设置';

  @override
  String get price => '价格';

  @override
  String get failed => '失败';

  @override
  String get fetchGasPrice => '获取燃料价格';

  @override
  String get fetchLotteryPot => '获取余额';

  @override
  String get lines => '行';

  @override
  String get filtered => '已过滤';

  @override
  String get backUpYourIdentity => '备份您的身份';

  @override
  String get accountSetUp => '账户设置';

  @override
  String get setUpAccount => '设置帐号';

  @override
  String get generateIdentity => '生成身份';

  @override
  String get enterAnExistingOrchidIdentity =>
      '输入现有的 <account_link>Orchid 身份</account_link>';

  @override
  String get pasteTheWeb3WalletAddress => '在下面粘贴您将用于为您的帐户注资的 web3 钱包地址。';

  @override
  String get funderWalletAddress => '资助者钱包地址';

  @override
  String get yourOrchidIdentityPublicAddress => '您的兰花身份公共地址';

  @override
  String get continueButton => '继续';

  @override
  String get yesIHaveSavedACopyOf => '是的，我已将我的私钥副本保存在安全的地方。';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      '备份您的 Orchid Identity <bold>私钥</bold>。您将需要此密钥来共享、导入或恢复此身份和所有关联帐户。';

  @override
  String get locked1 => '锁定';

  @override
  String get unlockDeposit1 => '解锁存款';

  @override
  String get changeWarnedAmountTo => '将警告金额更改为';

  @override
  String get setWarnedAmountTo => '将警告金额设置为';

  @override
  String get currentWarnedAmount => '当前警告金额';

  @override
  String get allWarnedFundsWillBeLockedUntil => '所有被警告的资金将被锁定，直到';

  @override
  String get balanceToDeposit1 => '存款余额';

  @override
  String get depositToBalance1 => '存款余额';

  @override
  String get advanced1 => '高级';

  @override
  String get add1 => '加';

  @override
  String get lockUnlock1 => '锁定/解锁';

  @override
  String get viewLogs => '查看日志';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统预设';

  @override
  String get identiconStyle => '标识样式';

  @override
  String get blockies => '块状';

  @override
  String get jazzicon => '爵士乐';

  @override
  String get contractVersion => '合约版本';

  @override
  String get version0 => '版本 0';

  @override
  String get version1 => '版本 1';

  @override
  String get connectedWithMetamask => '与 Metamask 连接';

  @override
  String get blockExplorer => '区块浏览器';

  @override
  String get tapToMinimize => '点击以最小化';

  @override
  String get connectWallet => '连接钱包';

  @override
  String get checkWallet => '检查钱包';

  @override
  String get checkYourWalletAppOrExtensionFor => '检查您的电子钱包应用或扩展程序是否有待处理的请求。';

  @override
  String get test => '测试';

  @override
  String get chainName => '链名';

  @override
  String get rpcUrl => 'RPC 网址';

  @override
  String get tokenPrice => '代币价格';

  @override
  String get tokenPriceUsd => '代币价格 USD';

  @override
  String get addChain => '添加链';

  @override
  String get deleteChainQuestion => '删除链？';

  @override
  String get deleteUserConfiguredChain => '删除用户配置的链';

  @override
  String get fundContractDeployer => '基金合约部署者';

  @override
  String get deploySingletonFactory => '部署单例工厂';

  @override
  String get deployContract => '部署合约';

  @override
  String get about => '关于';

  @override
  String get dappVersion => 'Dapp版本';

  @override
  String get viewContractOnEtherscan => '在 Etherscan 上查看合约';

  @override
  String get viewContractOnGithub => '在 Github 上查看合约';

  @override
  String get accountChanges => '账户变更';

  @override
  String get name => '名称';

  @override
  String get step1 =>
      '<bold>第 1 步。</bold> 连接一个 ERC-20 钱包，其中有 <link>足够的令牌</link> 。';

  @override
  String get step2 =>
      '<bold>第 2 步。</bold> 从 Orchid 应用程序复制 Orchid 身份，方法是转到管理帐户，然后点按地址。';

  @override
  String get connectOrCreate => '连接或创建 Orchid 帐户';

  @override
  String get lockDeposit2 => '锁定存款';

  @override
  String get unlockDeposit2 => '解锁存款';

  @override
  String get enterYourWeb3 => '输入您的 web3 钱包地址。';

  @override
  String get purchaseComplete => '购买完成';

  @override
  String get generateNewIdentity => '生成新身份';

  @override
  String get copyIdentity => '复制身份';

  @override
  String get yourPurchaseIsComplete =>
      '您的购买已完成，现在正在由 xDai 区块链处理，这可能需要几分钟时间。已使用此帐户为您生成默认电路。您可以在主屏幕或账户管理器中监控可用余额。';

  @override
  String get circuitGenerated => '电路生成';

  @override
  String get usingYourOrchidAccount => '使用您的 Orchid 帐户，已生成单跳电路。您可以从电路构建器屏幕管理它。';
}
