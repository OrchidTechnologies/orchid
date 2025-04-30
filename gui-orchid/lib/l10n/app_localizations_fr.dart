// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get orchidHop => 'Bond Orchid';

  @override
  String get orchidDisabled => 'Orchid désactivé';

  @override
  String get trafficMonitoringOnly => 'Surveillance du trafic uniquement';

  @override
  String get orchidConnecting => 'Connexion à Orchid';

  @override
  String get orchidDisconnecting => 'Déconnexion d\'Orchid';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num bonds configurés',
      two: 'Deux bons configurés',
      one: 'Un bond configuré',
      zero: 'Aucun bond configuré',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Bonds';

  @override
  String get traffic => 'Trafic';

  @override
  String get curation => 'Sélection';

  @override
  String get signerKey => 'Clé de signature';

  @override
  String get copy => 'Copier';

  @override
  String get paste => 'Coller';

  @override
  String get deposit => 'Dépôt';

  @override
  String get curator => 'Curateur';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => 'PARAMÈTRES';

  @override
  String get confirmThisAction => 'Confirmer cette action';

  @override
  String get cancelButtonTitle => 'ANNULER';

  @override
  String get changesWillTakeEffectInstruction =>
      'Les modifications prendront effet lorsque le VPN aura redémarré.';

  @override
  String get saved => 'Enregistré';

  @override
  String get configurationSaved => 'Configuration enregistrée';

  @override
  String get whoops => 'Oups';

  @override
  String get configurationFailedInstruction =>
      'Échec de l\'enregistrement de la configuration. Veuillez vérifier la syntaxe et réessayez.';

  @override
  String get addHop => 'Ajouter un bond';

  @override
  String get scan => 'Scanner';

  @override
  String get invalidQRCode => 'Code QR non valide';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Le code QR que vous avez scanné ne contient pas de configuration de compte valide.';

  @override
  String get invalidCode => 'Code non valide';

  @override
  String get theCodeYouPastedDoesNot =>
      'Le code que vous avez collé ne contient pas de configuration de compte valide.';

  @override
  String get openVPNHop => 'Bond OpenVPN';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get config => 'Configuration';

  @override
  String get pasteYourOVPN => 'Collez votre fichier de configuration OVPN ici';

  @override
  String get enterYourCredentials => 'Saisissez vos identifiants';

  @override
  String get enterLoginInformationInstruction =>
      'Saisissez les informations de connexion de votre fournisseur VPN ci-dessus. Collez ensuite le contenu du fichier de configuration OpenVPN de votre fournisseur dans le champ fourni.';

  @override
  String get save => 'Enregistrer';

  @override
  String get help => 'Aide';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get openSourceLicenses => 'Licences Open source';

  @override
  String get settings => 'Paramètres';

  @override
  String get version => 'Version';

  @override
  String get noVersion => 'Aucune version';

  @override
  String get orchidOverview => 'Vue d\'ensemble d\'Orchid';

  @override
  String get defaultCurator => 'Curateur par défaut';

  @override
  String get queryBalances => 'Consulter les soldes';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get manageConfiguration => 'Gérer la configuration';

  @override
  String get warningThesefeature =>
      'Avertissement : Ces fonctionnalités sont destinées aux utilisateurs avancés uniquement.  Veuillez lire toutes les instructions.';

  @override
  String get exportHopsConfiguration => 'Exporter la configuration des bonds';

  @override
  String get export => 'Exporter';

  @override
  String get warningExportedConfiguration =>
      'Avertissement : La configuration exportée inclut les secrets de clé privée du signataire pour les bonds exportés.  La révélation des clés privées vous expose à la perte de tous les fonds des comptes Orchid associés.';

  @override
  String get importHopsConfiguration => 'Importer la configuration des bonds';

  @override
  String get import => 'Importer';

  @override
  String get warningImportedConfiguration =>
      'Avertissement : La configuration importée remplacera tous les bonds existants que vous avez créés dans l\'application. Les clés de signature précédemment générées ou importées sur cet appareil seront conservées et resteront accessibles pour créer de nouveaux bonds, mais toutes les autres configurations, y compris la configuration du bond OpenVPN, seront perdues.';

  @override
  String get configuration => 'Configuration';

  @override
  String get saveButtonTitle => 'ENREGISTRER';

  @override
  String get search => 'Recherche';

  @override
  String get newContent => 'Nouveau contenu';

  @override
  String get clear => 'Effacer';

  @override
  String get connectionDetail => 'Détails de la connexion';

  @override
  String get host => 'Hôte';

  @override
  String get time => 'Heure';

  @override
  String get sourcePort => 'Port de la source';

  @override
  String get destination => 'Destination';

  @override
  String get destinationPort => 'Port de la destination';

  @override
  String get generateNewKey => 'Générer une nouvelle clé';

  @override
  String get importKey => 'Importer une clé';

  @override
  String get nothingToDisplayYet =>
      'Rien à afficher pour l\'instant. Le trafic apparaîtra ici lorsqu\'il y aura quelque chose à afficher.';

  @override
  String get disconnecting => 'Déconnexion...';

  @override
  String get connecting => 'Connexion...';

  @override
  String get pushToConnect => 'Appuyez pour vous connecter.';

  @override
  String get orchidIsRunning => 'Orchid est en cours d’exécution !';

  @override
  String get pacPurchaseWaiting => 'Achat en attente';

  @override
  String get retry => 'Réessayer';

  @override
  String get getHelpResolvingIssue =>
      'Obtenez de l’aide pour résoudre ce problème.';

  @override
  String get copyDebugInfo => 'Copier les infos de débogage';

  @override
  String get contactOrchid => 'Contacter Orchid';

  @override
  String get remove => 'Supprimer';

  @override
  String get deleteTransaction => 'Supprimer la transaction';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Effacez cette transaction en cours. Cela ne remboursera pas votre achat intégré à l\'application. Vous devez contacter Orchid pour résoudre le problème.';

  @override
  String get preparingPurchase => 'Préparation de l’achat';

  @override
  String get retryingPurchasedPAC => 'Nouvelle tentative d\'achat';

  @override
  String get retryPurchasedPAC => 'Réessayer l\'achat';

  @override
  String get purchaseError => 'L\'achat n\'a pas abouti';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Une erreur s\'est produite lors de l\'achat. Veuillez contacter l\'assistance Orchid.';

  @override
  String get importAnOrchidAccount => 'Importer un compte Orchid';

  @override
  String get buyCredits => 'Acheter des crédits';

  @override
  String get linkAnOrchidAccount => 'Lier le compte Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Malheureusement, cet achat dépasserait la limite d\'achat quotidienne des crédits d\'accès. Veuillez réessayer plus tard.';

  @override
  String get marketStats => 'Statistiques du marché';

  @override
  String get balanceTooLow => 'Solde trop bas';

  @override
  String get depositSizeTooSmall => 'Taille du dépôt trop faible';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'La valeur maximale de votre billet est actuellement limitée par votre solde de';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'La valeur maximale de votre billet est actuellement limitée par votre dépôt de';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Envisagez d’ajouter des OXT au solde de votre compte.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Envisagez d\'ajouter des OXT à votre dépôt ou transférez-en depuis votre solde vers votre dépôt.';

  @override
  String get prices => 'Prix';

  @override
  String get ticketValue => 'Valeur du billet';

  @override
  String get costToRedeem => 'Coût pour échanger :';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Consultez la documentation pour obtenir de l’aide sur ce problème.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Idéal pour surfer sur Internet';

  @override
  String get learnMore => 'En savoir plus.';

  @override
  String get connect => 'Connexion';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get wireguardHop => 'Bond WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Collez votre fichier de configuration WireGuard®️ ici';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Collez les informations d\'identification de votre fournisseur WireGuard® dans le champ ci-dessus.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Effacer toutes les données du journal ?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Ce journal de débogage n\'est pas persistant et sera effacé lorsque vous quitterez l\'application.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Peut contenir des informations sensibles et/ou personnelles.';

  @override
  String get loggingEnabled => 'Journalisation activée';

  @override
  String get cancel => 'ANNULER';

  @override
  String get logging => 'Journalisation';

  @override
  String get loading => 'Chargement...';

  @override
  String get ethPrice => 'Prix de l’ETH :';

  @override
  String get oxtPrice => 'Prix de l\'OTX :';

  @override
  String get gasPrice => 'Prix du gaz :';

  @override
  String get maxFaceValue => 'Valeur nominale maximale :';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get enterOpenvpnConfig => 'Entrez la configuration OpenVPN';

  @override
  String get enterWireguardConfig => 'Entrez la configuration WireGuard®️';

  @override
  String get starting => 'Démarrage...';

  @override
  String get legal => 'Mentions légales';

  @override
  String get whatsNewInOrchid => 'Nouveautés d\'Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid est sur xDai !';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Vous pouvez maintenant acheter des crédits Orchid avec xDai ! Commencez à utiliser le VPN pour seulement 1 €.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Comptes xDai pour les achats passés';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Pour tout achat intégré effectué avant aujourd\'hui, les fonds xDai ont été ajoutés à la même clé de compte. C\'est nous qui offrons la bande passante !';

  @override
  String get newInterface => 'Nouvelle interface';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Les comptes sont désormais organisés sous l\'adresse Orchid à laquelle ils sont associés.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Consultez le solde de votre compte actif et le coût de la bande passante sur l\'écran d\'accueil.';

  @override
  String get seeOrchidcomForHelp =>
      'Consultez orchid.com pour obtenir de l’aide.';

  @override
  String get payPerUseVpnService => 'Service VPN payant à l\'utilisation';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Aucun abonnement, les crédits n’expirent pas';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Partagez un compte avec un nombre illimité d\'appareils';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'La Boutique Orchid est temporairement indisponible. Merci de revenir dans quelques minutes.';

  @override
  String get talkingToPacServer =>
      'Communication avec le serveur de compte Orchid';

  @override
  String get advancedConfiguration => 'Configuration avancée';

  @override
  String get newWord => 'Nouveau';

  @override
  String get copied => 'Copié';

  @override
  String get efficiency => 'Efficacité';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Billets min disponibles : $tickets';
  }

  @override
  String get transactionSentToBlockchain =>
      'Transaction envoyée à la blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Votre achat est terminé et est maintenant traité par la blockchain xDai, ce qui peut prendre jusqu\'à une minute, parfois un peu plus. Tirez vers le bas pour afficher le solde de votre compte ci-dessous.';

  @override
  String get copyReceipt => 'Copier le reçu';

  @override
  String get manageAccounts => 'Gérer les comptes';

  @override
  String get configurationManagement => 'Gestion de la configuration';

  @override
  String get exportThisOrchidKey => 'Exporter cette clé Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Vous trouverez ci-dessous un code QR et un texte pour tous les comptes Orchid associés à cette clé.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Importez cette clé sur un autre appareil pour partager tous les comptes Orchid associés à cette identité Orchid.';

  @override
  String get orchidAccountInUse => 'Compte Orchid en cours d’utilisation';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Ce compte Orchid est en cours d’utilisation et ne peut pas être supprimé.';

  @override
  String get pullToRefresh => 'Glissez vers le bas pour actualiser.';

  @override
  String get balance => 'Solde';

  @override
  String get active => 'Actif';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Collez une clé Orchid depuis le presse-papiers pour importer tous les comptes Orchid associés à cette clé.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Scannez ou collez une clé Orchid depuis le presse-papiers pour importer tous les comptes Orchid associés à cette clé.';

  @override
  String get account => 'Compte';

  @override
  String get transactions => 'Transactions';

  @override
  String get weRecommendBackingItUp =>
      'Nous vous recommandons de <link>la sauvegarder</link>.';

  @override
  String get copiedOrchidIdentity => 'Identité Orchid copiée';

  @override
  String get thisIsNotAWalletAddress =>
      'Il ne s’agit pas d’une adresse de portefeuille.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Ne pas envoyer de jetons à cette adresse.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Votre identité Orchid vous identifie de manière unique sur le réseau.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'En savoir plus à propos de votre <link>identité Orchid</link>.';

  @override
  String get analyzingYourConnections => 'Analyse de vos connexions';

  @override
  String get analyzeYourConnections => 'Analysez vos connexions';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'L\'analyse réseau utilise la fonction VPN de votre appareil pour capturer des paquets et analyser votre trafic.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'L\'analyse du réseau nécessite des autorisations VPN, mais ne permet pas en soi de protéger vos données ou de masquer votre adresse IP.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Pour bénéficier des avantages de la confidentialité du réseau, vous devez configurer et activer une connexion VPN depuis l’écran d’accueil.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Activer cette fonctionnalité augmentera l’utilisation de la batterie de l’application Orchid.';

  @override
  String get useAnOrchidAccount => 'Utiliser un compte Orchid';

  @override
  String get pasteAddress => 'Coller l\'adresse';

  @override
  String get chooseAddress => 'Choisir l\'adresse';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Choisissez un compte Orchid à utiliser avec ce bond.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Si vous ne voyez pas votre compte ci-dessous, vous pouvez utiliser le gestionnaire de compte pour importer, acheter ou créer un nouveau compte.';

  @override
  String get selectAnOrchidAccount => 'Sélectionner un compte Orchid';

  @override
  String get takeMeToTheAccountManager =>
      'Aller vers le gestionnaire de compte';

  @override
  String get funderAccount => 'Compte du financeur';

  @override
  String get orchidRunningAndAnalyzing =>
      'Orchid en cours d’exécution et d’analyse';

  @override
  String get startingVpn => '(Démarrage du VPN)';

  @override
  String get disconnectingVpn => '(Déconnexion du VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Analyse du trafic par Orchid';

  @override
  String get vpnConnectedButNotRouting => '(VPN connecté mais pas de routage)';

  @override
  String get restarting => 'Redémarrage';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Le changement de l\'état de la surveillance requiert un redémarrage du VPN, ce qui peut interrompre brièvement la protection de la vie privée.';

  @override
  String get confirmRestart => 'Confirmer le redémarrage';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Le prix moyen est de $price USD par Go';
  }

  @override
  String get myOrchidConfig => 'Ma configuration Orchid';

  @override
  String get noAccountSelected => 'Aucun compte sélectionné';

  @override
  String get inactive => 'Inactif';

  @override
  String get tickets => 'Billets';

  @override
  String get accounts => 'Comptes';

  @override
  String get orchidIdentity => 'Identité Orchid';

  @override
  String get addFunds => 'AJOUTER DES FONDS';

  @override
  String get addFunds2 => 'Ajouter des fonds';

  @override
  String get gb => 'Go';

  @override
  String get usdgb => 'USD/Go';

  @override
  String get hop => 'Bond';

  @override
  String get circuit => 'Circuit';

  @override
  String get clearAllAnalysisData => 'Effacer toutes les données d\'analyse ?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Cette action effacera toutes les données de connexion de trafic précédemment analysées.';

  @override
  String get clearAll => 'TOUT EFFACER';

  @override
  String get stopAnalysis => 'ARRÊTER L\'ANALYSE';

  @override
  String get startAnalysis => 'COMMENCER L\'ANALYSE';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Les comptes Orchid comprennent une assistance client 24h/24 et 7j/7, un nombre illimité d\'appareils et sont soutenus par la <link2>crypto-monnaie xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Les comptes achetés se connectent exclusivement à nos <link1>fournisseurs préférés</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Politique de remboursement couverte par les app stores.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid n\'est pas en mesure d\'afficher les achats intégrés pour le moment.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Veuillez confirmer que cet appareil prend en charge et est configuré pour les achats intégrés.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Veuillez confirmer que cet appareil prend en charge et est configuré pour les achats intégrés ou utilisez notre système de <link>gestion de compte</link> décentralisé.';

  @override
  String get buy => 'ACHETER';

  @override
  String get gbApproximately12 => '12 Go (environ)';

  @override
  String get gbApproximately60 => '60 Go (environ)';

  @override
  String get gbApproximately240 => '240 Go (environ)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Taille idéale pour une utilisation individuelle à moyen terme, y compris la navigation et le streaming léger.';

  @override
  String get mostPopular => 'Le plus populaire !';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Bande passante importante, utilisation à long terme ou comptes partagés.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'Suspendre tout le trafic...';

  @override
  String get queryingEthereumForARandom =>
      'Interrogation d\'Ethereum pour un fournisseur aléatoire...';

  @override
  String get quickFundAnAccount => 'Financez rapidement un compte !';

  @override
  String get accountFound => 'Compte trouvé';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Nous avons trouvé un compte associé à vos identités et créé un circuit Orchid à bond unique pour celui-ci. Vous êtes maintenant prêt à utiliser le VPN.';

  @override
  String get welcomeToOrchid => 'Bienvenue sur Orchid !';

  @override
  String get fundYourAccount => 'Financez votre compte';

  @override
  String get processing => 'Traitement...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Service VPN sans abonnement, paiement au fur et à mesure, décentralisé, open source.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'COMMENCER POUR $smallAmount';
  }

  @override
  String get importAccount => 'IMPORTER UN COMPTE';

  @override
  String get illDoThisLater => 'Je le ferai plus tard';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Connectez-vous automatiquement à l\'un des <link1>fournisseurs préférés</link1> du réseau en achetant des crédits VPN pour financer votre compte Orchid partageable et rechargeable.';

  @override
  String get confirmPurchase => 'CONFIRMER L\'ACHAT';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Les comptes Orchid utilisent des crédits VPN adossés à la <link>cryptomonnaie xDAI</link>, ils incluent un support client 24 heures sur 24, 7 jours sur 7, un partage illimité d\'appareils et sont couverts par les politiques de remboursement de l\'App Store.';

  @override
  String get yourPurchaseIsInProgress => 'Votre achat est en cours.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Cet achat prend plus de temps que prévu et a peut-être rencontré une erreur.';

  @override
  String get thisMayTakeAMinute => 'Cela peut prendre une minute...';

  @override
  String get vpnCredits => 'Crédits VPN';

  @override
  String get blockchainFee => 'Frais de blockchain';

  @override
  String get promotion => 'Promotion';

  @override
  String get showInAccountManager => 'Afficher dans le gestionnaire de compte';

  @override
  String get deleteThisOrchidIdentity => 'Supprimer cette identité Orchid';

  @override
  String get chooseIdentity => 'Choisissez une identité';

  @override
  String get updatingAccounts => 'Mise à jour des comptes';

  @override
  String get trafficAnalysis => 'Analyse du trafic';

  @override
  String get accountManager => 'Gestionnaire de compte';

  @override
  String get circuitBuilder => 'Créateur de circuits';

  @override
  String get exitHop => 'Bond de sortie';

  @override
  String get entryHop => 'Bond d\'entrée';

  @override
  String get addNewHop => 'AJOUTER UN NOUVEAU BOND';

  @override
  String get newCircuitBuilder => 'Nouveau créateur de circuits !';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Vous pouvez désormais payer pour un circuit Orchid multi-bonds avec xDAI. L\'interface multi-bonds prend désormais en charge les comptes Orchid xDAi et OXT et prend toujours en charge les configurations OpenVPN et WireGuard qui peuvent être reliées ensemble dans une route onion.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Gérez votre connexion depuis le créateur de circuits plutôt que depuis le gestionnaire de compte. Toutes les connexions utilisent désormais un circuit avec zéro bond ou plus. Toute configuration existante a été migrée vers le créateur de circuits.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Commencez rapidement pour $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Nous avons ajouté une méthode pour acheter un compte Orchid et créer un circuit à bond unique à partir de l\'écran d\'accueil pour raccourcir le processus d\'intégration.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid est unique en tant que client de routage multi-bonds ou onion prenant en charge plusieurs protocoles VPN. Vous pouvez configurer votre connexion en enchaînant les bonds avec les protocoles pris en charge ci-dessous.\n\nUn seul bond, c\'est comme un VPN classique. Trois bonds (pour les utilisateurs expérimentés) constituent le choix classique de routage onion. Le zéro bond permet d\'analyser le trafic sans tunnel VPN.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'La suppression des bonds OpenVPN et Wireguard fera perdre les identifiants et la configuration de connexion associées. Assurez-vous de sauvegarder toutes les informations avant de continuer.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Cette action est irréversible. Pour enregistrer cette identité, appuyez sur Annuler et utilisez l\'option Exporter';

  @override
  String get unlockTime => 'Durée du déverrouillage';

  @override
  String get chooseChain => 'Choisir la chaîne';

  @override
  String get unlocking => 'déblocage';

  @override
  String get unlocked => 'Débloqué';

  @override
  String get orchidTransaction => 'Transaction Orchid';

  @override
  String get confirmations => 'Confirmations';

  @override
  String get pending => 'En attente...';

  @override
  String get txHash => 'Tx Hash :';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Tous vos fonds sont disponibles au retrait.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw sur vos $totalFunds de fonds combinés sont actuellement disponibles au retrait.';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'Débloquer également le dépôt restant';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Si vous spécifiez un montant inférieur au montant total, les fonds seront prélevés sur votre solde en premier.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Pour plus d\'options, consultez le panneau AVANCÉ.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Si vous sélectionnez l\'option de déverrouillage du dépôt, cette transaction retirera immédiatement le montant spécifié de votre solde et lancera également le processus de déverrouillage de votre dépôt restant.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Les fonds de dépôt sont disponibles au retrait 24 heures après le déverrouillage.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Retirez des fonds de votre compte Orchid vers votre portefeuille actuel.';

  @override
  String get withdrawAndUnlockFunds => 'RETIRER ET DÉBLOQUER LES FONDS';

  @override
  String get withdrawFunds => 'RETIRER LES FONDS';

  @override
  String get withdrawFunds2 => 'Retirer des fonds';

  @override
  String get withdraw => 'Retirer';

  @override
  String get submitTransaction => 'SOUMETTRE LA TRANSACTION';

  @override
  String get move => 'Déplacer';

  @override
  String get now => 'Maintenant';

  @override
  String get amount => 'Quantité';

  @override
  String get available => 'Disponible';

  @override
  String get select => 'Sélectionner';

  @override
  String get add => 'AJOUTER';

  @override
  String get balanceToDeposit => 'SOLDE VERS DÉPÔT';

  @override
  String get depositToBalance => 'DÉPÔT VERS SOLDE';

  @override
  String get setWarnedAmount => 'Définir un montant d\'avertissement';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Ajoutez des fonds au solde et/ou au dépôt de votre compte Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Pour obtenir des conseils sur la taille de votre compte, consultez <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Préautorisation actuelle de $tokenType : $amount';
  }

  @override
  String get noWallet => 'Aucun portefeuille';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Aucun portefeuille ou navigateur non pris en charge.';

  @override
  String get error => 'Erreur';

  @override
  String get failedToConnectToWalletconnect =>
      'Échec de la connexion au WalletConnect.';

  @override
  String get unknownChain => 'Chaîne inconnue';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Le gestionnaire de compte Orchid ne prend pas encore en charge cette chaîne.';

  @override
  String get orchidIsntOnThisChain => 'Orchid n\'est pas sur cette chaîne.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Le contrat Orchid n\'a pas encore été déployé sur cette chaîne.';

  @override
  String get moveFunds => 'DÉPLACER LES FONDS';

  @override
  String get moveFunds2 => 'Déplacer des fonds';

  @override
  String get lockUnlock => 'VERROUILLER / DÉVERROUILLER';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Voter dépôt de $amount est déverrouillé.';
  }

  @override
  String get locked => 'verrouillé';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Votre dépôt de $amount est $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Les fonds seront disponibles au retraut dans \$$time.';
  }

  @override
  String get lockDeposit => 'VERROUILLER LE DÉPÔT';

  @override
  String get unlockDeposit => 'DÉVERROUILLER LE DÉPÔT';

  @override
  String get advanced => 'AVANCÉ';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>En savoir plus sur les comptes Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Coût estimé pour créer un compte Orchid avec une efficacité de $efficiency et $num tickets de valeur.';
  }

  @override
  String get chain => 'Chaîne';

  @override
  String get token => 'Jeton';

  @override
  String get minDeposit => 'Dépôt min';

  @override
  String get minBalance => 'Solde min';

  @override
  String get fundFee => 'Frais de fonds';

  @override
  String get withdrawFee => 'Frais de retrait';

  @override
  String get tokenValues => 'VALEURS DU JETON';

  @override
  String get usdPrices => 'PRIX EN USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'La définition d\'un montant de dépôt d\'avertissement fait commencer la période d\'attente de 24 heures requise pour retirer les fonds de dépôt.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Pendant cette période, les fonds ne sont pas disponibles en tant que dépôt valide sur le réseau Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Les fonds peuvent être rebloqués à tout moment en réduisant le montant d\'avertissement.';

  @override
  String get warn => 'Avertir';

  @override
  String get totalWarnedAmount => 'Montant total d\'avertissement';

  @override
  String get newIdentity => 'Nouvelle identité';

  @override
  String get importIdentity => 'Importer l\'indentité';

  @override
  String get exportIdentity => 'Exporter l\'identité';

  @override
  String get deleteIdentity => 'Supprimer l\'indentité';

  @override
  String get importOrchidIdentity => 'Importer l\'indentité Orchid';

  @override
  String get funderAddress => 'Adresse du financeur';

  @override
  String get contract => 'Contrat';

  @override
  String get txFee => 'Frais de transaction';

  @override
  String get show => 'Afficher';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Erreurs';

  @override
  String get lastHour => 'Dernière heure';

  @override
  String get chainSettings => 'Paramètres de la chaîne';

  @override
  String get price => 'Prix';

  @override
  String get failed => 'Échec';

  @override
  String get fetchGasPrice => 'Récupérer le prix du gaz';

  @override
  String get fetchLotteryPot => 'Récupérer le prix de la loterie';

  @override
  String get lines => 'lignes';

  @override
  String get filtered => 'filtré';

  @override
  String get backUpYourIdentity => 'Sauvegardez votre identité';

  @override
  String get accountSetUp => 'Configuration du compte';

  @override
  String get setUpAccount => 'Mettre en place compte';

  @override
  String get generateIdentity => 'GÉNÉRER UNE IDENTITÉ';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Saisissez une <account_link>identité d\'orchidée</account_link>existante';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Collez ci-dessous l\'adresse du portefeuille Web3 que vous utiliserez pour approvisionner votre compte.';

  @override
  String get funderWalletAddress =>
      'Adresse du portefeuille du bailleur de fonds';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Votre adresse publique Orchid Identity';

  @override
  String get continueButton => 'Continuer';

  @override
  String get yesIHaveSavedACopyOf =>
      'Oui, j\'ai enregistré une copie de ma clé privée dans un endroit sûr.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Sauvegardez votre clé privée <bold>Orchid Identity</bold>. Vous aurez besoin de cette clé pour partager, importer ou restaurer cette identité et tous les comptes associés.';

  @override
  String get locked1 => 'Fermé à clef';

  @override
  String get unlockDeposit1 => 'Débloquer le dépôt';

  @override
  String get changeWarnedAmountTo => 'Remplacer le montant averti par';

  @override
  String get setWarnedAmountTo => 'Définir le montant averti sur';

  @override
  String get currentWarnedAmount => 'Montant averti actuel';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Tous les fonds avertis seront bloqués jusqu\'à';

  @override
  String get balanceToDeposit1 => 'Solde à déposer';

  @override
  String get depositToBalance1 => 'Dépôt au solde';

  @override
  String get advanced1 => 'Avancée';

  @override
  String get add1 => 'Ajouter';

  @override
  String get lockUnlock1 => 'Verrouiller / Déverrouiller';

  @override
  String get viewLogs => 'Regardes les connexions';

  @override
  String get language => 'La langue';

  @override
  String get systemDefault => 'Défaut du système';

  @override
  String get identiconStyle => 'Style d\'icône d\'identification';

  @override
  String get blockies => 'blocs';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => 'Version du contrat';

  @override
  String get version0 => 'Variante 0';

  @override
  String get version1 => 'Version 1';

  @override
  String get connectedWithMetamask => 'Connecté avec Metamask';

  @override
  String get blockExplorer => 'explorateur de blocs';

  @override
  String get tapToMinimize => 'Appuyez pour réduire';

  @override
  String get connectWallet => 'Connecter le portefeuille';

  @override
  String get checkWallet => 'Chèque Portefeuille';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Vérifiez votre application Wallet ou votre extension pour une demande en attente.';

  @override
  String get test => 'tester';

  @override
  String get chainName => 'Nom de la chaîne';

  @override
  String get rpcUrl => 'URL RPC';

  @override
  String get tokenPrice => 'Prix du jeton';

  @override
  String get tokenPriceUsd => 'Prix du jeton USD';

  @override
  String get addChain => 'Ajouter une chaîne';

  @override
  String get deleteChainQuestion => 'Supprimer la chaîne ?';

  @override
  String get deleteUserConfiguredChain =>
      'Supprimer la chaîne configurée par l\'utilisateur';

  @override
  String get fundContractDeployer => 'Déployeur de contrat de fonds';

  @override
  String get deploySingletonFactory => 'Déployer la fabrique de singletons';

  @override
  String get deployContract => 'Déployer le contrat';

  @override
  String get about => 'sur';

  @override
  String get dappVersion => 'Version dapp';

  @override
  String get viewContractOnEtherscan => 'Voir le contrat sur Etherscan';

  @override
  String get viewContractOnGithub => 'Voir le contrat sur Github';

  @override
  String get accountChanges => 'Changements de compte';

  @override
  String get name => 'Prénom';

  @override
  String get step1 =>
      '<bold> Étape 1.</bold> Connectez un portefeuille ERC-20 contenant <link>suffisamment de jetons</link> .';

  @override
  String get step2 =>
      '<bold>Étape 2.</bold> Copiez l\'identité d\'Orchid à partir de l\'application Orchid en accédant à Gérer les comptes, puis en appuyant sur l\'adresse.';

  @override
  String get connectOrCreate => 'Connectez-vous ou créez un compte Orchid';

  @override
  String get lockDeposit2 => 'Verrouiller le dépôt';

  @override
  String get unlockDeposit2 => 'Débloquer le dépôt';

  @override
  String get enterYourWeb3 => 'Entrez votre adresse de portefeuille Web3.';

  @override
  String get purchaseComplete => 'Achat terminé';

  @override
  String get generateNewIdentity => 'Générer une nouvelle identité';

  @override
  String get copyIdentity => 'Copier l\'identité';

  @override
  String get yourPurchaseIsComplete =>
      'Votre achat est terminé et est maintenant traité par la blockchain xDai, ce qui peut prendre quelques minutes. Un circuit par défaut a été généré pour vous en utilisant ce compte. Vous pouvez surveiller le solde disponible sur l\'écran d\'accueil ou dans le gestionnaire de compte.';

  @override
  String get circuitGenerated => 'Circuit généré';

  @override
  String get usingYourOrchidAccount =>
      'À l\'aide de votre compte Orchid, un circuit à saut unique a été généré. Vous pouvez gérer cela à partir de l\'écran du générateur de circuits.';
}
