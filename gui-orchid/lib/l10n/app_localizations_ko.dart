// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class SKo extends S {
  SKo([String locale = 'ko']) : super(locale);

  @override
  String get orchidHop => 'Orchid 홉';

  @override
  String get orchidDisabled => 'Orchid 비활성화 상태';

  @override
  String get trafficMonitoringOnly => '트래픽 모니터링만';

  @override
  String get orchidConnecting => 'Orchid 연결 중';

  @override
  String get orchidDisconnecting => 'Orchid 연결 해제 중';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num개의 홉이 구성되었습니다',
      two: '2개의 홉이 구성되었습니다',
      one: '1개의 홉이 구성되었습니다',
      zero: '구성된 홉이 없습니다',
    );
    return '$_temp0';
  }

  @override
  String get delete => '삭제';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => '홉';

  @override
  String get traffic => '트래픽';

  @override
  String get curation => '큐레이션';

  @override
  String get signerKey => '서명자 키';

  @override
  String get copy => '복사';

  @override
  String get paste => '붙여넣기';

  @override
  String get deposit => '예치금';

  @override
  String get curator => '큐레이터';

  @override
  String get ok => '확인';

  @override
  String get settingsButtonTitle => '설정';

  @override
  String get confirmThisAction => '해당 활동 승인하기';

  @override
  String get cancelButtonTitle => '취소';

  @override
  String get changesWillTakeEffectInstruction => 'VPN을 다시 시작하시면 변경 사항이 적용됩니다.';

  @override
  String get saved => '저장됨';

  @override
  String get configurationSaved => '구성 저장됨';

  @override
  String get whoops => '뭔가 잘못 되었네요!';

  @override
  String get configurationFailedInstruction =>
      '구성을 저장하지 못했습니다. 구문을 확인한 후 다시 시도하세요.';

  @override
  String get addHop => '홉 추가';

  @override
  String get scan => '스캔';

  @override
  String get invalidQRCode => '잘못된 QR 코드입니다';

  @override
  String get theQRCodeYouScannedDoesNot => '스캔하신 QR 코드는 유효한 계정 구성이 아닙니다.';

  @override
  String get invalidCode => '잘못된 코드';

  @override
  String get theCodeYouPastedDoesNot => '유효한 계정 구성이 아닙니다.';

  @override
  String get openVPNHop => 'OpenVPN 홉';

  @override
  String get username => '사용자 이름';

  @override
  String get password => '비밀번호';

  @override
  String get config => '구성';

  @override
  String get pasteYourOVPN => '여기에 OVPN 구성 파일을 붙여넣으세요';

  @override
  String get enterYourCredentials => '자격 증명을 입력하세요';

  @override
  String get enterLoginInformationInstruction =>
      '위의 VPN 제공업체에 대한 로그인 정보를 입력하세요. 그 후, 해당 업체의 OpenVPN 구성 파일 내용을 입력하세요.';

  @override
  String get save => '저장하기';

  @override
  String get help => '도움말';

  @override
  String get privacyPolicy => '개인정보 보호정책';

  @override
  String get openSourceLicenses => '오픈 소스 라이선스';

  @override
  String get settings => '설정';

  @override
  String get version => '버전';

  @override
  String get noVersion => '버전 없음';

  @override
  String get orchidOverview => 'Orchid 개요';

  @override
  String get defaultCurator => '기본설정 큐레이터';

  @override
  String get queryBalances => '잔액 보기';

  @override
  String get reset => '재설정';

  @override
  String get manageConfiguration => '구성 관리';

  @override
  String get warningThesefeature =>
      '경고: 이 기능은 고급 사용자를 위한 기능 합니다. 모든 설명을 읽어 보시기 바랍니다.';

  @override
  String get exportHopsConfiguration => '구성한 홉 내보내기';

  @override
  String get export => '내보내기';

  @override
  String get warningExportedConfiguration =>
      '경고: 내보내기 된 구성사항에 홉에 대한 서명자 개인 키 암호가 포함되어 있습니다. 개인 키가 노출되면 연결된 Orchid 계정 안의 모든 자금을 잃을 수 있습니다.';

  @override
  String get importHopsConfiguration => '홉 구성 가져오기';

  @override
  String get import => '가져오기';

  @override
  String get warningImportedConfiguration =>
      '경고: 불러온 구성이 앱에 생성된 기존 홉을 대체합니다. 이 기기에서 이전에 생성되거나 가져온 서명자 키는 유지되고, 새로운 홉 생성 시 여전히 접속 가능하지만, OpenVPN 홉 구성을 포함한 다른 모든 구성은 삭제됩니다.';

  @override
  String get configuration => '구성';

  @override
  String get saveButtonTitle => '저장';

  @override
  String get search => '검색';

  @override
  String get newContent => '신규 콘텐츠';

  @override
  String get clear => '지우기';

  @override
  String get connectionDetail => '연결 세부 정보';

  @override
  String get host => '호스트';

  @override
  String get time => '시간';

  @override
  String get sourcePort => '원본 포트';

  @override
  String get destination => '대상';

  @override
  String get destinationPort => '대상 포트';

  @override
  String get generateNewKey => '새 키 생성';

  @override
  String get importKey => '키 가져오기';

  @override
  String get nothingToDisplayYet => '표시할 항목이 없습니다. 표시할 항목이 생기면 여기에 트래픽이 표시됩니다.';

  @override
  String get disconnecting => '연결 해제 중 ...';

  @override
  String get connecting => '연결 중 ...';

  @override
  String get pushToConnect => '클릭 해 연결하기';

  @override
  String get orchidIsRunning => 'Orchid가 실행 중 입니다!';

  @override
  String get pacPurchaseWaiting => '구매 대기 중';

  @override
  String get retry => '다시하기';

  @override
  String get getHelpResolvingIssue => ' 문제 해결 도움 받기.';

  @override
  String get copyDebugInfo => '디버그 정보 복사';

  @override
  String get contactOrchid => '오키드에 문의하기';

  @override
  String get remove => '삭제하기';

  @override
  String get deleteTransaction => '거래 삭제하기';

  @override
  String get clearThisInProgressTransactionExplain =>
      '진행중인 트랜잭션을 삭제하기. 인앱 구매는 환불되지 않습니다. 오키드에 문의해 문제를 해결하실 수 있습니다.';

  @override
  String get preparingPurchase => '구매 준비';

  @override
  String get retryingPurchasedPAC => '다시 구매 시도 중';

  @override
  String get retryPurchasedPAC => '다시 구매 시도';

  @override
  String get purchaseError => '구매 오류';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      '구매 중에 오류가 발생했습니다. 오키드 지원 센터에 문의하십시오.';

  @override
  String get importAnOrchidAccount => '오키드 계정 불러오기';

  @override
  String get buyCredits => '크레딧 구매하기';

  @override
  String get linkAnOrchidAccount => '오키드 계정 연결하기';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      '죄송합니다. 접속 크레딧 일일 구매 한도를 초과합니다. 나중에 다시 시도해 주세요.';

  @override
  String get marketStats => '시장 현황';

  @override
  String get balanceTooLow => '잔액이 너무 적습니다';

  @override
  String get depositSizeTooSmall => '예치액이 너무 적습니다';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      '현재 잔고에 따라 최대 티켓 가격이 제한되었습니다';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      '현재 예치금에 따라 최대 티켓 가격이 제한되었습니다';

  @override
  String get considerAddingOxtToYourAccountBalance => '계정 잔고에 OXT를 추가해 주세요.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      '추가 OXT를 예치하시거나 잔고에서 예치금으로의 이동을 고려하시기 바랍니다.';

  @override
  String get prices => '가격';

  @override
  String get ticketValue => '티켓 가치';

  @override
  String get costToRedeem => '상환 비용 :';

  @override
  String get viewTheDocsForHelpOnThisIssue => '해당 문서를 참고하시기 바랍니다.';

  @override
  String get goodForBrowsingAndLightActivity => '탐색 및 가벼운 활동에 적합';

  @override
  String get learnMore => '더 알아보기.';

  @override
  String get connect => '연결';

  @override
  String get disconnect => '분리';

  @override
  String get wireguardHop => '와이어 가드 홉';

  @override
  String get pasteYourWireguardConfigFileHere =>
      '여기에 WireGuard 구성 파일을 붙여 넣으십시오.';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'WireGuard 제공업체의 자격 증명 정보를 위의 필드에 붙여 넣습니다.';

  @override
  String get wireguard => '와이어 가드';

  @override
  String get clearAllLogData => '모든 로그 데이터를 지우시겠습니까?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      '디버그 로그는 지속적이지 않으며 앱 종료 시 삭제됩니다.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      '비밀번호 또는 개인 식별 정보를 포함 할 수 있습니다.';

  @override
  String get loggingEnabled => '로깅 가능';

  @override
  String get cancel => '취소';

  @override
  String get logging => '로깅 중';

  @override
  String get loading => '로드 중 ...';

  @override
  String get ethPrice => 'ETH 가격 :';

  @override
  String get oxtPrice => 'OXT 가격 :';

  @override
  String get gasPrice => '가스 비용 :';

  @override
  String get maxFaceValue => '최대 액면가 :';

  @override
  String get confirmDelete => '삭제 확인';

  @override
  String get enterOpenvpnConfig => 'OpenVPN 구성 입력하기';

  @override
  String get enterWireguardConfig => 'WireGuard® 구성 입력하기';

  @override
  String get starting => '실행 중...';

  @override
  String get legal => '법적 고지';

  @override
  String get whatsNewInOrchid => 'Orchid의 새로운 기능';

  @override
  String get orchidIsOnXdai => 'Orchid가 xDai에서 지원됩니다!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      '이제 xDaiOrchid에서 Orchid 크레딧을 구입하실 수 있습니다. 단 USD \$1의 저렴한 가격에 VPN을 사용해 보세요.';

  @override
  String get xdaiAccountsForPastPurchases => '과거 xDai 구매 기록이 있는 계정';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      '오늘 이전의 인-앱 구매 항목에 대해 xDai를 동일한 계정 키에 추가하였습니다. 광대한 대역폭의 혜택을 누려보세요!';

  @override
  String get newInterface => '새로운 인터페이스';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      '계정목록이 이제 연결된 Orchid 주소 아래에 나타납니다.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      '홈 화면에서 현재 계정 잔액 및 대역폭 비용을 확인하세요.';

  @override
  String get seeOrchidcomForHelp => 'orchid.com에서 자세한 정보를 확인하세요.';

  @override
  String get payPerUseVpnService => '사용량 기준 결제 방식 VPN 서비스';

  @override
  String get notASubscriptionCreditsDontExpire => '정기구독이 없으며, 크레딧이 만료되지 않습니다';

  @override
  String get shareAccountWithUnlimitedDevices => '제한 없이 다른 기기와 계정을 공유할 수 있습니다';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Orchid 스토어가 일시적으로 이용불가 합니다. 잠시 후에 다시 확인해 주세요.';

  @override
  String get talkingToPacServer => 'Orchid 계정 서버에 접속하는 중';

  @override
  String get advancedConfiguration => '고급 설정';

  @override
  String get newWord => '신규단어';

  @override
  String get copied => '복사됨';

  @override
  String get efficiency => '효율';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return '사용 가능한 최소 티켓: $tickets';
  }

  @override
  String get transactionSentToBlockchain => '블록체인으로 트랜잭션 전송 완료';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      '구매가 완료되었으며 현재 xDai 블록체인에서 처리 중입니다. 이 작업은 최대 1분이 소요되며, 더 오래 걸릴 수도 있습니다. 화면을 아래로 당겨서 새로 고치면, 잔액이 업데이트된 계정이 아래에 표시됩니다.';

  @override
  String get copyReceipt => '영수증 복사';

  @override
  String get manageAccounts => '계정 관리';

  @override
  String get configurationManagement => '설정 관리';

  @override
  String get exportThisOrchidKey => '이 Orchid 키 내보내기';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      '해당 키와 연결된 모든 Orchid 계정의 QR 코드 및 텍스트는 다음과 같습니다.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      '해당 Orchid ID와 연결된 모든 Orchid 계정을 공유하려면 다른 기기에서 이 키를 가져오세요.';

  @override
  String get orchidAccountInUse => '사용 중인 Orchid 계정입니다';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      '해당 Orchid 계정은 사용 중인 계정으로 삭제할 수 없습니다.';

  @override
  String get pullToRefresh => '당겨서 새로 고침.';

  @override
  String get balance => '잔고';

  @override
  String get active => '활성';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      '클립보드에서 Orchid 키를 붙여넣어 해당 키와 연결된 모든 Orchid 계정을 가져옵니다.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      '스캔하거나 클립보드에서 Orchid 키를 붙여넣어 해당 키와 연결된 모든 Orchid 계정을 가져옵니다.';

  @override
  String get account => '계정';

  @override
  String get transactions => '트랜잭션';

  @override
  String get weRecommendBackingItUp => '<link>백업</link>하실 것을 권장합니다.';

  @override
  String get copiedOrchidIdentity => 'Orchid ID 복사 완료';

  @override
  String get thisIsNotAWalletAddress => '지갑 주소가 아닙니다.';

  @override
  String get doNotSendTokensToThisAddress => '이 주소로 토큰을 전송하지 마십시오.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Orchid ID를 통해 네트워크에서 고유식별이 가능해 집니다.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      '<link>Orchid ID</link>에 대하여 자세히 알아보기.';

  @override
  String get analyzingYourConnections => '연결 상태 분석 중';

  @override
  String get analyzeYourConnections => '연결 상태 분석';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      '네트워크 분석은 기기의 VPN 기능을 사용해 패킷 캡처 및 트래픽 분석을 진행합니다.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      '네트워크 분석에 VPN 권한이 요구되지만, 이 기능은 자체적으로 데이터를 보호하거나 IP 주소를 숨기지는 않습니다.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      '홈 화면에서 VPN을 연결하고 활성화해야 네트워크 개인 정보 보호가 진행됩니다.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      '해당 기능을 활성화하면 Orchid 앱의 배터리 사용량이 증가합니다.';

  @override
  String get useAnOrchidAccount => 'Orchid 계정 사용하기';

  @override
  String get pasteAddress => '주소 붙여넣기';

  @override
  String get chooseAddress => '주소 선택';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      '해당 홉을 통해 사용할 Orchid 계정을 선택합니다.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      '아래에 계정이 나타나지 않으면 계정 관리자를 사용해 계정을 불러오거나, 신규 계정을 구입 또는 생성하실 수 있습니다.';

  @override
  String get selectAnOrchidAccount => 'Orchid 계정 선택';

  @override
  String get takeMeToTheAccountManager => '계정 관리자로 이동';

  @override
  String get funderAccount => '자금 제공자 계정';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid 실행 및 분석 중';

  @override
  String get startingVpn => '(VPN 시작 중)';

  @override
  String get disconnectingVpn => '(VPN 연결 해제 중)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid가 트래픽 분석 중';

  @override
  String get vpnConnectedButNotRouting => '(VPN이 연결되었지만 라우팅되지 않음)';

  @override
  String get restarting => '재시작 중';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      '모니터링 상태를 변경하려면 VPN을 재시작해야 하며, 이때 개인 정보 보호가 잠시 중단될 수 있습니다.';

  @override
  String get confirmRestart => '재시작 확인';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return '평균 가격은 GB당 $price USD입니다';
  }

  @override
  String get myOrchidConfig => '나의 Orchid 설정';

  @override
  String get noAccountSelected => '선택한 계정이 없습니다';

  @override
  String get inactive => '비활성';

  @override
  String get tickets => '티켓';

  @override
  String get accounts => '계정';

  @override
  String get orchidIdentity => 'Orchid ID';

  @override
  String get addFunds => '자금 추가';

  @override
  String get addFunds2 => '자금 추가';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => '홉';

  @override
  String get circuit => '순환';

  @override
  String get clearAllAnalysisData => '모든 분석 데이터를 지우시겠습니까?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      '이 작업은 이전에 분석된 모든 트래픽 연결 데이터를 지웁니다.';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get stopAnalysis => '분석 중지';

  @override
  String get startAnalysis => '분석 시작';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Orchid 계정에는 연중무휴 고객 지원, 무제한 장치가 포함되며 <link2>xDai 암호화폐</link2>로 지원됩니다.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      '유료 계정은 <link1>우선 제공업체</link1>에 독점적으로 연결됩니다.';

  @override
  String get refundPolicyCoveredByAppStores => '앱 스토어에서 적용되는 환불 정책.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid는 현재 인앱 구매를 표시할 수 없습니다.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      '이 기기가 인앱 구매를 지원하고 설정되어 있는지 확인하세요.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      '이 기기가 인앱 구매를 지원하고 설정되어 있는지 확인하거나, 당사의 분산식 <link>계정 관리</link> 시스템을 사용하세요.';

  @override
  String get buy => '구입';

  @override
  String get gbApproximately12 => '12GB (대략)';

  @override
  String get gbApproximately60 => '60GB (대략)';

  @override
  String get gbApproximately240 => '240GB (대략)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      '브라우징 및 가벼운 스트리밍을 포함하는 중단기 개인적인 사용에 이상적인 크기입니다.';

  @override
  String get mostPopular => '가장 인기!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      '대역폭을 많이 사용하는 장기간 사용 또는 공유 계정.';

  @override
  String get total => '총계';

  @override
  String get pausingAllTraffic => '모든 트래픽 일시 중지 중...';

  @override
  String get queryingEthereumForARandom => '이더리움에서 임의의 공급자 쿼리 중...';

  @override
  String get quickFundAnAccount => '계정에 빠르게 자금을 입금하세요!';

  @override
  String get accountFound => '계정을 찾았습니다';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      '회원님의 신원과 관련된 계정을 찾았으며 이에 대해 단일 홉 Orchid 서킷을 생성했습니다. 이제 VPN을 사용할 준비가 되셨습니다.';

  @override
  String get welcomeToOrchid => 'Orchid에 오신 것을 환영합니다!';

  @override
  String get fundYourAccount => '계정에 자금 입금';

  @override
  String get processing => '처리 중...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      '구독이 필요 없고, 사용한 만큼만 지불하는 분산형 오픈 소스 VPN 서비스.';

  @override
  String getStartedFor1(String smallAmount) {
    return '$smallAmount에 시작하기';
  }

  @override
  String get importAccount => '계정 가져오기';

  @override
  String get illDoThisLater => '나중에 할게요';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'VPN 크레딧을 구입하여 공유 및 재충전 가능한 Orchid 계정에 자금을 입금하고 네트워크의 <link1>우선 제공업체</link1> 중 하나에 자동으로 연결하세요.';

  @override
  String get confirmPurchase => '구매 확인';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Orchid 계정은 <link>xDAI 암호화폐</link>에 기반한 VPN 크레딧을 사용하고, 연중무휴 고객 지원, 무제한 기기 공유를 지원하며, 앱 스토어 환불 정책의 적용을 받습니다.';

  @override
  String get yourPurchaseIsInProgress => '구매가 진행 중입니다.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      '이 구매를 처리하는 데 예상보다 시간이 오래 걸리고 있습니다. 오류가 발생했을 수 있습니다.';

  @override
  String get thisMayTakeAMinute => '이 작업은 1분 정도 걸릴 수 있습니다...';

  @override
  String get vpnCredits => 'VPN 크레딧';

  @override
  String get blockchainFee => '블록체인 수수료';

  @override
  String get promotion => '프로모션';

  @override
  String get showInAccountManager => '계정 관리자에 표시';

  @override
  String get deleteThisOrchidIdentity => '이 Orchid ID 삭제';

  @override
  String get chooseIdentity => 'ID 선택';

  @override
  String get updatingAccounts => '계정 업데이트 중';

  @override
  String get trafficAnalysis => '트래픽 분석';

  @override
  String get accountManager => '계정 관리자';

  @override
  String get circuitBuilder => '서킷 빌더';

  @override
  String get exitHop => '출구 홉';

  @override
  String get entryHop => '입구 홉';

  @override
  String get addNewHop => '새 홉 추가';

  @override
  String get newCircuitBuilder => '새 서킷 빌더!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      '이제 xDAI를 사용해 멀티 홉 Orchid 서킷 비용을 지불할 수 있습니다. 현재, 멀티 홉 인터페이스는 xDAI 및 OXT Orchid 계정을 지원하고, 어니언 라우팅으로 함께 연결할 수 있는 OpenVPN 및 WireGuard 구성을 계속 지원합니다.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      '계정 관리자 대신 서킷 빌더에서 연결을 관리하세요. 이제 모든 연결은 0개 이상의 홉이 있는 서킷을 사용합니다. 기존의 모든 구성은 서킷 빌더로 이전되었습니다.';

  @override
  String quickStartFor1(String smallAmount) {
    return '$smallAmount에 빠르게 시작하기';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      '시작 과정을 단축하기 위하여 Orchid 계정을 구매하고 홈 화면에서 단일 홉 서킷을 생성할 수 있는 방법을 추가했습니다.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid는 여러 개의 VPN 프로토콜을 지원하는 다중 홉 또는 어니언 라우팅 클라이언트입니다. 아래와 같이 지원되는 프로토콜에서 홉들을 서로 묶어서 연결을 설정할 수 있습니다.\n\n한 개의 홉은 일반적인 VPN과 같습니다. (고급 사용자를 위한) 세 개의 홉은 전통적인 어니언 라우팅 옵션입니다. 제로 홉은  VPN 터널 없이 트래픽 분석을 가능하게 합니다.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'OpenVPN 및 Wireguard 홉을 삭제하면 관련된 모든 자격 증명 및 연결 구성이 손실됩니다. 계속 진행하기 전에 정보를 백업하세요.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      '이 작업은 취소할 수 없습니다. 이 ID를 저장하려면 \'취소\'를 누르고 \'내보내기\' 옵션을 사용하세요';

  @override
  String get unlockTime => '잠금 해제 시간';

  @override
  String get chooseChain => '체인 선택';

  @override
  String get unlocking => '잠금 해제';

  @override
  String get unlocked => '잠금 해제됨';

  @override
  String get orchidTransaction => 'Orchid 트랜잭션';

  @override
  String get confirmations => '확인';

  @override
  String get pending => '대기 중...';

  @override
  String get txHash => 'Tx 해시:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal => '모든 자금을 인출할 수 있습니다.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '현재, 총 $totalFunds의 자금 중 $maxWithdraw을(를) 인출할 수 있습니다.';
  }

  @override
  String get alsoUnlockRemainingDeposit => '남은 예치금도 잠금 해제';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      '전체 금액보다 적은 금액을 지정하면 먼저 잔고에서 자금이 인출됩니다.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      '추가 옵션을 보려면 \'고급\' 패널을 참조하세요.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      '\'예치금 잠금 해제\' 옵션을 선택하면 이 트랜잭션은 잔고에서 지정된 금액을 즉시 인출하고, 동시에 남은 예치금에 대한 잠금 해제 과정이 시작됩니다.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      '예치금 자금은 잠금 해제 후 24시간 동안 인출할 수 있습니다.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      '귀하의 Orchid 계정에서 현재 지갑으로 자금을 인출합니다.';

  @override
  String get withdrawAndUnlockFunds => '자금 인출 및 잠금 해제';

  @override
  String get withdrawFunds => '자금 인출';

  @override
  String get withdrawFunds2 => '자금 인출';

  @override
  String get withdraw => '인출';

  @override
  String get submitTransaction => '트랜잭션 제출';

  @override
  String get move => '이동';

  @override
  String get now => '지금';

  @override
  String get amount => '잔고';

  @override
  String get available => '사용 가능';

  @override
  String get select => '선택';

  @override
  String get add => '추가';

  @override
  String get balanceToDeposit => '잔고에서 예치금으로';

  @override
  String get depositToBalance => '예치금에서 잔고로';

  @override
  String get setWarnedAmount => '경고 금액 설정';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      '귀하의 Orchid 계정 잔고 및/또는 예치금에 자금을 추가합니다.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      '계정 규모 설정에 대한 사항은 <link>orchid.com</link>을 참조하세요';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return '현재 $tokenType 사전 승인: $amount';
  }

  @override
  String get noWallet => '지갑 없음';

  @override
  String get noWalletOrBrowserNotSupported => '지원되는 지갑 또는 브라우저가 없습니다.';

  @override
  String get error => '오류';

  @override
  String get failedToConnectToWalletconnect => 'WalletConnect에 연결하지 못했습니다.';

  @override
  String get unknownChain => '알 수 없는 체인';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Orchid 계정 관리자가 이 체인을 아직 지원하지 않습니다.';

  @override
  String get orchidIsntOnThisChain => 'Orchid가 이 체인에 없습니다.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Orchid 컨트랙트가 이 체인에 아직 배포되지 않았습니다.';

  @override
  String get moveFunds => '자금 이동';

  @override
  String get moveFunds2 => '자금 이동';

  @override
  String get lockUnlock => '잠금 / 잠금 해제';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return '$amount의 예치금이 잠금 해제되었습니다.';
  }

  @override
  String get locked => '잠겨 있음';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return '$amount의 예치금이 $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return '$time 후 자금을 인출할 수 있습니다.';
  }

  @override
  String get lockDeposit => '예치금 잠금';

  @override
  String get unlockDeposit => '예치금 잠금 해제';

  @override
  String get advanced => '고급';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Orchid 계정에 대하여 자세히 알아보기</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return '$efficiency의 효율과 $num 티켓의 가치를 지닌 Orchid 계정을 만들기 위한 예상 비용.';
  }

  @override
  String get chain => '체인';

  @override
  String get token => '토큰';

  @override
  String get minDeposit => '최소 예치금';

  @override
  String get minBalance => '최소 잔고';

  @override
  String get fundFee => '자금 수수료';

  @override
  String get withdrawFee => '인출 수수료';

  @override
  String get tokenValues => '토큰 가치';

  @override
  String get usdPrices => 'USD 가격';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      '경고 예치금 금액을 설정하면 예치금 자금을 인출할 때 24시간 대기 시간이 필요합니다.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      '이 대기 시간 동안 해당 자금은 Orchid 네트워크에서 유효한 예치금으로 사용할 수 없습니다.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      '경고 금액을 줄여서 언제든지 자금을 다시 잠글 수 있습니다.';

  @override
  String get warn => '경고';

  @override
  String get totalWarnedAmount => '총 경고 금액';

  @override
  String get newIdentity => '새로운 ID';

  @override
  String get importIdentity => 'ID 가져오기';

  @override
  String get exportIdentity => 'ID 내보내기';

  @override
  String get deleteIdentity => 'ID 삭제';

  @override
  String get importOrchidIdentity => 'Orchid ID 가져오기';

  @override
  String get funderAddress => '자금 제공자 주소';

  @override
  String get contract => '컨트랙트';

  @override
  String get txFee => '트랜잭션 수수료';

  @override
  String get show => '표시';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => '오류';

  @override
  String get lastHour => '지난 1시간';

  @override
  String get chainSettings => '체인 설정';

  @override
  String get price => '가격';

  @override
  String get failed => '실패';

  @override
  String get fetchGasPrice => '가스비 가져오기';

  @override
  String get fetchLotteryPot => '잔고 가져오기';

  @override
  String get lines => '줄';

  @override
  String get filtered => '필터링됨';

  @override
  String get backUpYourIdentity => '신원 백업';

  @override
  String get accountSetUp => '계정 설정';

  @override
  String get setUpAccount => '계정 설정';

  @override
  String get generateIdentity => 'ID 생성';

  @override
  String get enterAnExistingOrchidIdentity =>
      '기존 <account_link>난초 ID</account_link>입력';

  @override
  String get pasteTheWeb3WalletAddress =>
      '아래에 귀하의 계정에 자금을 입금하는 데 사용할 web3 지갑 주소를 붙여넣습니다.';

  @override
  String get funderWalletAddress => '펀딩자 지갑 주소';

  @override
  String get yourOrchidIdentityPublicAddress => '귀하의 난초 신원 공개 주소';

  @override
  String get continueButton => '잇다';

  @override
  String get yesIHaveSavedACopyOf => '예, 개인 키 사본을 안전한 곳에 저장했습니다.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Orchid ID <bold>개인 키</bold>를 백업하십시오. 이 ID 및 연결된 모든 계정을 공유, 가져오기 또는 복원하려면 이 키가 필요합니다.';

  @override
  String get locked1 => '잠김';

  @override
  String get unlockDeposit1 => '보증금 잠금 해제';

  @override
  String get changeWarnedAmountTo => '경고 금액을 다음으로 변경';

  @override
  String get setWarnedAmountTo => '경고 금액 설정';

  @override
  String get currentWarnedAmount => '현재 경고 금액';

  @override
  String get allWarnedFundsWillBeLockedUntil => '경고된 모든 자금은';

  @override
  String get balanceToDeposit1 => '예치할 잔액';

  @override
  String get depositToBalance1 => '잔액에 예치';

  @override
  String get advanced1 => '많은';

  @override
  String get add1 => '더하다';

  @override
  String get lockUnlock1 => '잠금 / 잠금 해제';

  @override
  String get viewLogs => '로그 보기';

  @override
  String get language => '언어';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get identiconStyle => '아이덴티콘 스타일';

  @override
  String get blockies => '블로키';

  @override
  String get jazzicon => '재즈콘';

  @override
  String get contractVersion => '계약 버전';

  @override
  String get version0 => '버전 0';

  @override
  String get version1 => '버전 1';

  @override
  String get connectedWithMetamask => '메타마스크와 연결';

  @override
  String get blockExplorer => '블록 탐색기';

  @override
  String get tapToMinimize => '탭하여 최소화';

  @override
  String get connectWallet => '지갑 연결';

  @override
  String get checkWallet => '지갑 확인';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      '보류 중인 요청이 있는지 지갑 앱 또는 확장 프로그램을 확인하세요.';

  @override
  String get test => '테스트';

  @override
  String get chainName => '체인 이름';

  @override
  String get rpcUrl => 'RPC URL';

  @override
  String get tokenPrice => '토큰 가격';

  @override
  String get tokenPriceUsd => '토큰 가격 USD';

  @override
  String get addChain => '체인 추가';

  @override
  String get deleteChainQuestion => '체인을 삭제하시겠습니까?';

  @override
  String get deleteUserConfiguredChain => '사용자 구성 체인 삭제';

  @override
  String get fundContractDeployer => '펀드 계약 전개자';

  @override
  String get deploySingletonFactory => '싱글톤 팩토리 배포';

  @override
  String get deployContract => '계약 배포';

  @override
  String get about => '약';

  @override
  String get dappVersion => '디앱 버전';

  @override
  String get viewContractOnEtherscan => 'Etherscan에서 계약 보기';

  @override
  String get viewContractOnGithub => 'Github에서 계약 보기';

  @override
  String get accountChanges => '계정 변경';

  @override
  String get name => '이름';

  @override
  String get step1 =>
      '<bold>1단계.</bold>  <link>충분한 토큰</link> 이 있는 ERC-20 지갑을 연결합니다.';

  @override
  String get step2 =>
      '<bold>2단계.</bold> 계정 관리로 이동한 다음 주소를 탭하여 Orchid 앱에서 Orchid ID를 복사합니다.';

  @override
  String get connectOrCreate => 'Orchid 계정 연결 또는 생성';

  @override
  String get lockDeposit2 => '예치금 잠금';

  @override
  String get unlockDeposit2 => '보증금 잠금 해제';

  @override
  String get enterYourWeb3 => 'web3 지갑 주소를 입력하세요.';

  @override
  String get purchaseComplete => '구매완료';

  @override
  String get generateNewIdentity => '새 ID 생성';

  @override
  String get copyIdentity => '신원 복사';

  @override
  String get yourPurchaseIsComplete =>
      '구매가 완료되었으며 현재 xDai 블록체인에서 처리 중이며 몇 분 정도 소요될 수 있습니다. 이 계정을 사용하여 기본 회로가 생성되었습니다. 홈 화면 또는 계정 관리자에서 사용 가능한 잔액을 모니터링할 수 있습니다.';

  @override
  String get circuitGenerated => '생성된 회로';

  @override
  String get usingYourOrchidAccount =>
      'Orchid 계정을 사용하여 단일 홉 회로가 생성되었습니다. 회로 빌더 화면에서 이를 관리할 수 있습니다.';
}
