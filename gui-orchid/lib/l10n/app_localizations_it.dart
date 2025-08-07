// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

  @override
  String get orchidHop => 'Hop Orchid';

  @override
  String get orchidDisabled => 'Orchid disabilitata';

  @override
  String get trafficMonitoringOnly => 'Solo monitoraggio del traffico';

  @override
  String get orchidConnecting => 'Orchid si sta connettendo';

  @override
  String get orchidDisconnecting => 'Orchid si sta disconnettendo';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hop configurati',
      two: 'Due hop configurati',
      one: 'Un hop configurato',
      zero: 'Nessun hop configurato',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Hop';

  @override
  String get traffic => 'Traffico';

  @override
  String get curation => 'Cura';

  @override
  String get signerKey => 'Chiave del firmatario';

  @override
  String get copy => 'Copia';

  @override
  String get paste => 'Incolla';

  @override
  String get deposit => 'Deposito';

  @override
  String get curator => 'Curatore';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => 'IMPOSTAZIONI';

  @override
  String get confirmThisAction => 'Conferma questa azione';

  @override
  String get cancelButtonTitle => 'ANNULLA';

  @override
  String get changesWillTakeEffectInstruction =>
      'Le modifiche avranno effetto al riavvio della VPN.';

  @override
  String get saved => 'Salvato';

  @override
  String get configurationSaved => 'Configurazione salvata';

  @override
  String get whoops => 'Ups';

  @override
  String get configurationFailedInstruction =>
      'Impossibile salvare la configurazione. Per favore, controlla la sintassi e riprova.';

  @override
  String get addHop => 'Aggiungi hop';

  @override
  String get scan => 'Scansiona';

  @override
  String get invalidQRCode => 'QR code non valido';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Il QR code scansionato non contiene una configurazione valida dell\'account.';

  @override
  String get invalidCode => 'Codice non valido';

  @override
  String get theCodeYouPastedDoesNot =>
      'Il codice incollato non contiene una configurazione valida dell\'account.';

  @override
  String get openVPNHop => 'Hop OpenVPN';

  @override
  String get username => 'Nome utente';

  @override
  String get password => 'Password';

  @override
  String get config => 'Conﬁg';

  @override
  String get pasteYourOVPN => 'Incolla qui il tuo file OVPN Config';

  @override
  String get enterYourCredentials => 'Inserisci le tue credenziali';

  @override
  String get enterLoginInformationInstruction =>
      'Inserisci sopra i dati di accesso per il tuo provider VPN. Incolla, quindi, il contenuto del file OVPN Config del provider nel campo fornito.';

  @override
  String get save => 'Salva';

  @override
  String get help => 'Aiuto';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get openSourceLicenses => 'Licenze open source';

  @override
  String get settings => 'Impostazioni';

  @override
  String get version => 'Versione';

  @override
  String get noVersion => 'Nessuna versione';

  @override
  String get orchidOverview => 'Panoramica di Orchid';

  @override
  String get defaultCurator => 'Curatore predefinito';

  @override
  String get queryBalances => 'Controlla saldo';

  @override
  String get reset => 'Reimposta';

  @override
  String get manageConfiguration => 'Gestisci configurazione';

  @override
  String get warningThesefeature =>
      'Attenzione: queste funzionalità sono destinate solo agli utenti esperti. Per favore, leggi tutte le istruzioni.';

  @override
  String get exportHopsConfiguration => 'Esporta configurazione hops';

  @override
  String get export => 'Esporta';

  @override
  String get warningExportedConfiguration =>
      'Attenzione: la configurazione esportata include i secrets della chiave privata del firmatario degli hops esportati. Rivelando le chiavi private rischi di perdere tutti i fondi negli account Orchid associati.';

  @override
  String get importHopsConfiguration => 'Importa configurazione hops';

  @override
  String get import => 'Importa';

  @override
  String get warningImportedConfiguration =>
      'Attenzione: la configurazione importata sostituirà tutti gli hops esistenti che hai creato nell\'app. Le chiavi del firmatario precedentemente generate o importate in questo dispositivo verranno mantenute e rimarranno accessibili per la creazione di nuovi hops; tuttavia, tutte le altre configurazioni, inclusa la configurazione dell\'hop OpenVPN, andranno perse.';

  @override
  String get configuration => 'Conﬁgurazione';

  @override
  String get saveButtonTitle => 'SALVA';

  @override
  String get search => 'Cerca';

  @override
  String get newContent => 'Nuovo contenuto';

  @override
  String get clear => 'Cancella';

  @override
  String get connectionDetail => 'Dettaglio connessione';

  @override
  String get host => 'Host';

  @override
  String get time => 'Ora';

  @override
  String get sourcePort => 'Porta di origine';

  @override
  String get destination => 'Destinazione';

  @override
  String get destinationPort => 'Porta di destinazione';

  @override
  String get generateNewKey => 'Genera nuova chiave';

  @override
  String get importKey => 'Importa chiave';

  @override
  String get nothingToDisplayYet =>
      'Ancora nulla da mostrare. Il traffico verrà visualizzato qui quando c\'è qualcosa da mostrare.';

  @override
  String get disconnecting => 'Disconnettendo...';

  @override
  String get connecting => 'Connettendo...';

  @override
  String get pushToConnect => 'Premi per connetterti.';

  @override
  String get orchidIsRunning => 'Orchid è in funzione!';

  @override
  String get pacPurchaseWaiting => 'AUA Acquisto in attesa';

  @override
  String get retry => 'Riprova';

  @override
  String get getHelpResolvingIssue =>
      'Ottieni assistenza per risolvere il problema.';

  @override
  String get copyDebugInfo => 'Copia informazioni di debug';

  @override
  String get contactOrchid => 'Contatta Orchid';

  @override
  String get remove => 'Rimuovi';

  @override
  String get deleteTransaction => 'Elimina transazione';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Cancella questa transazione in corso. Questa operazione non prevede il rimborso dell\'acquisto in-app. Per risolvere il problema, contatta Orchid.';

  @override
  String get preparingPurchase => 'Preparando acquisto';

  @override
  String get retryingPurchasedPAC => 'Riprovando AUA acquistato';

  @override
  String get retryPurchasedPAC => 'Riprova AUA acquistato';

  @override
  String get purchaseError => 'Errore di acquisto';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Errore durante l\'acquisto. Per favore, contatta il supporto di Orchid.';

  @override
  String get importAnOrchidAccount => 'Importa un account Orchid';

  @override
  String get buyCredits => 'Acquista crediti';

  @override
  String get linkAnOrchidAccount => 'Collega account Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Siamo spiacenti, questo acquisto supererebbe il limite di acquisto giornaliero per i crediti di accesso. Per favore, riprova più tardi.';

  @override
  String get marketStats => 'Statistiche di mercato';

  @override
  String get balanceTooLow => 'Saldo troppo basso';

  @override
  String get depositSizeTooSmall => 'Importo del deposito insufficiente';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Il tuo valore massimo di ticket è attualmente limitato dal tuo saldo di';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Il tuo valore massimo di ticket è attualmente limitato dal tuo deposito di';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Si ritiene opportuno aggiungere OXT al saldo del tuo account.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Si ritiene opportuno aggiungere OXT al tuo deposito o di spostare i fondi dal tuo saldo al tuo deposito.';

  @override
  String get prices => 'Prezzi';

  @override
  String get ticketValue => 'Valore del ticket';

  @override
  String get costToRedeem => 'Costo per riscattare:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Consulta la documentazione per assistenza su questo problema.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Ideale per la semplice navigazione e per le attività meno complesse';

  @override
  String get learnMore => 'Ulteriori informazioni.';

  @override
  String get connect => 'Resta in contatto';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get wireguardHop => 'Hop WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Incolla qui il tuo file WireGuard®️ Config';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Incolla le informazioni delle credenziali del tuo provider WireGuard®️ nel campo sopra.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Cancella tutti i dati di registro?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Questo registro di debug non è persistente e viene cancellato quando chiudi l\'app.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Può contenere informazioni segrete o informazioni di identificazione personale.';

  @override
  String get loggingEnabled => 'Registrazione abilitata';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get logging => 'Registrando';

  @override
  String get loading => 'Caricamento...';

  @override
  String get ethPrice => 'Prezzo ETH:';

  @override
  String get oxtPrice => 'Prezzo OXT:';

  @override
  String get gasPrice => 'Prezzo GAS:';

  @override
  String get maxFaceValue => 'Valore nominale massimo:';

  @override
  String get confirmDelete => 'Conferma eliminazione';

  @override
  String get enterOpenvpnConfig => 'Inserisci OpenVPN Config';

  @override
  String get enterWireguardConfig => 'Inserisci WireGuard®️ Config';

  @override
  String get starting => 'Avvio...';

  @override
  String get legal => 'Legale';

  @override
  String get whatsNewInOrchid => 'Novità di Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid è su xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Ora puoi acquistare crediti Orchid su xDai! Inizia ad utilizzare la VPN al costo di un caffè.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Account xDai per acquisti precedenti';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Per tutti gli acquisti in-app effettuati prima di oggi, i fondi xDai sono stati aggiunti alla stessa chiave dell\'account. Offriamo noi la connessione!';

  @override
  String get newInterface => 'Nuova interfaccia';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Gli account sono ora organizzati in base all\'indirizzo Orchid al quale sono associati.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Visualizza il saldo attivo del tuo account e il costo della larghezza di banda sulla schermata iniziale.';

  @override
  String get seeOrchidcomForHelp => 'Per assistenza, visita orchid.com.';

  @override
  String get payPerUseVpnService =>
      'Servizio VPN a consumo, si paga solo l\'effettivo utilizzo';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Nessun abbonamento, i crediti non scadono';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Condividi l\'account con un numero illimitato di dispositivi';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Lo Store di Orchid non è momentaneamente disponibile. Per favore, controlla di nuovo tra qualche minuto.';

  @override
  String get talkingToPacServer =>
      'Comunicando con il server dell\'account Orchid';

  @override
  String get advancedConfiguration => 'Configurazione avanzata';

  @override
  String get newWord => 'Nuovo';

  @override
  String get copied => 'Copiato';

  @override
  String get efficiency => 'Efficienza';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Ticket minimi disponibili: $tickets';
  }

  @override
  String get transactionSentToBlockchain =>
      'Transazione inviata alla blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Il tuo acquisto è stato completato ed è in corso di elaborazione sulla blockchain di xDai, il quale può richiedere fino a un minuto, a volte più a lungo. Trascina verso il basso per aggiornare e il nuovo saldo verrà visualizzato di seguito.';

  @override
  String get copyReceipt => 'Copia ricevuta';

  @override
  String get manageAccounts => 'Gestisci account';

  @override
  String get configurationManagement => 'Gestione configurazione';

  @override
  String get exportThisOrchidKey => 'Esporta questa chiave Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Di seguito sono riportati un QR code e un testo per tutti gli account Orchid associati a questa chiave.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Importa questa chiave in un altro dispositivo per condividere tutti gli account Orchid associati a questa identità Orchid.';

  @override
  String get orchidAccountInUse => 'Account Orchid in uso';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Questo account Orchid è in uso e non può essere eliminato.';

  @override
  String get pullToRefresh => 'Trascina verso il basso per aggiornare.';

  @override
  String get balance => 'Saldo';

  @override
  String get active => 'Attivo';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Incolla una chiave Orchid dagli appunti per importare tutti gli account Orchid associati a tale chiave.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Scansiona o incolla una chiave Orchid dagli appunti per importare tutti gli account Orchid associati a tale chiave.';

  @override
  String get account => 'Account';

  @override
  String get transactions => 'Transazioni';

  @override
  String get weRecommendBackingItUp =>
      'Ti consigliamo di <link>effettuare il backup</link>.';

  @override
  String get copiedOrchidIdentity => 'Identità Orchid copiata';

  @override
  String get thisIsNotAWalletAddress =>
      'Questo non è un indirizzo di portafoglio valido.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Non inviare monete a questo indirizzo.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'La tua Identità Orchid ti riconosce sulla rete in modo univoco.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Ulteriori informazioni sulla tua <link>Identità Orchid</link>.';

  @override
  String get analyzingYourConnections =>
      'Analisi delle tue connessioni in corso';

  @override
  String get analyzeYourConnections => 'Analizza le tue connessioni';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'L\'analisi della rete utilizza le funzioni VPN del tuo dispositivo per acquisire i pacchetti di rete e analizzare il tuo traffico.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'L\'analisi della rete richiede autorizzazioni della VPN ma, da sola, non protegge i tuoi dati o nasconde il tuo indirizzo IP.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Per ottenere i benefici della privacy di rete, è necessario configurare e attivare una connessione VPN dalla schermata iniziale.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Attivando questa funzionalità, l\'applicazione di Orchid avrà un consumo elevato della batteria.';

  @override
  String get useAnOrchidAccount => 'Utilizza un account Orchid';

  @override
  String get pasteAddress => 'Incolla indirizzo';

  @override
  String get chooseAddress => 'Scegli indirizzo';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Scegli un account Orchid da utilizzare con questo hop.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Se non riesci a visualizzare, di seguito, il tuo account, puoi utilizzare il Gestore Account per importare, acquistare o creare un nuovo account.';

  @override
  String get selectAnOrchidAccount => 'Seleziona un account Orchid';

  @override
  String get takeMeToTheAccountManager => 'Vai al Gestore Account';

  @override
  String get funderAccount => 'Account finanziatore';

  @override
  String get orchidRunningAndAnalyzing =>
      'Orchid è in esecuzione e sta effettuando l\'analisi';

  @override
  String get startingVpn => '(Avvio VPN in corso)';

  @override
  String get disconnectingVpn => '(Disconnessione della VPN in corso)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid sta analizzando il traffico';

  @override
  String get vpnConnectedButNotRouting => '(VPN connessa ma senza routing)';

  @override
  String get restarting => 'Riavvio in corso';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Per modificare lo stato di monitoraggio è necessario riavviare la VPN, il che potrebbe interrompere brevemente la protezione della tua privacy.';

  @override
  String get confirmRestart => 'Conferma riavvio';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Il prezzo medio è $price USD per GB';
  }

  @override
  String get myOrchidConfig => 'La mia configurazione di Orchid';

  @override
  String get noAccountSelected => 'Nessun account selezionato';

  @override
  String get inactive => 'Inattivo';

  @override
  String get tickets => 'Ticket';

  @override
  String get accounts => 'Account';

  @override
  String get orchidIdentity => 'Identità Orchid';

  @override
  String get addFunds => 'AGGIUNGI FONDI';

  @override
  String get addFunds2 => 'Aggiungere fondi';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Hop';

  @override
  String get circuit => 'Circuito';

  @override
  String get clearAllAnalysisData =>
      'Vuoi cancellare tutti i dati delle analisi?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Verranno cancellati tutti i dati di connessione al traffico analizzati in precedenza.';

  @override
  String get clearAll => 'CANCELLA TUTTO';

  @override
  String get stopAnalysis => 'INTERROMPI ANALISI';

  @override
  String get startAnalysis => 'AVVIA ANALISI';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Gli account Orchid includono assistenza clienti 24x7, dispositivi illimitati e sono supportati dalla <link2>criptovaluta Dai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Gli account acquistati si connettono esclusivamente ai nostri <link1>provider preferiti</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Politica di rimborso coperta dagli app store.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid non al momento è in grado di visualizzare gli acquisti in-app.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Verifica che il dispositivo supporti e sia configurato per gli acquisti in-app.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Verifica che il dispositivo supporti e sia configurato per gli acquisti in-app o utilizzi il nostro sistema di <link>gestione degli account</link> decentralizzato.';

  @override
  String get buy => 'ACQUISTA';

  @override
  String get gbApproximately12 => '12 GB (circa)';

  @override
  String get gbApproximately60 => '60 GB (circa)';

  @override
  String get gbApproximately240 => '240 GB (circa)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Dimensioni ideali per l\'uso individuale a medio termine che include la navigazione e lo streaming leggero.';

  @override
  String get mostPopular => 'Più popolare!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Account condivisi o utilizzo a lungo termine con larghezza di banda elevata.';

  @override
  String get total => 'Totale';

  @override
  String get pausingAllTraffic => 'Sospendo tutto il traffico...';

  @override
  String get queryingEthereumForARandom =>
      'Eseguo query su Ethereum per un provider casuale...';

  @override
  String get quickFundAnAccount => 'Finanzia rapidamente un account!';

  @override
  String get accountFound => 'Account trovato';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Abbiamo trovato un account associato alle tue identità e creato un singolo circuito Orchid hop per lo stesso. Ora puoi utilizzare la VPN.';

  @override
  String get welcomeToOrchid => 'Ti diamo il benvenuto su Orchid!';

  @override
  String get fundYourAccount => 'Finanzia il tuo account';

  @override
  String get processing => 'Elaboro...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Servizio VPN decentralizzato e open source, senza abbonamento, con pagamento in base al consumo.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'INIZIA A $smallAmount';
  }

  @override
  String get importAccount => 'IMPORTA ACCOUNT';

  @override
  String get illDoThisLater => 'Lo farò dopo';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Collegati automaticamente a uno dei <link1>provider preferiti</link1> della rete acquistando crediti VPN per finanziare il tuo account Orchid condivisibile e ricaricabile.';

  @override
  String get confirmPurchase => 'CONFERMA ACQUISTO';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Gli account Orchid utilizzano crediti VPN supportati dalla <link>criptovaluta xDAI</link>, includono assistenza clienti 24x7, condivisione illimitata dei dispositivi e sono coperti dalle politiche di rimborso dell\'app store.';

  @override
  String get yourPurchaseIsInProgress => 'Il tuo acquisto è in corso.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'L\'elaborazione di questo acquisto richiede più tempo del previsto ed è possibile che si sia verificato un errore.';

  @override
  String get thisMayTakeAMinute =>
      'L\'operazione potrebbe richiedere qualche minuto...';

  @override
  String get vpnCredits => 'Crediti VPN';

  @override
  String get blockchainFee => 'Commissione blockchain';

  @override
  String get promotion => 'Promozione';

  @override
  String get showInAccountManager => 'Mostra in Gestione account';

  @override
  String get deleteThisOrchidIdentity => 'Elimina questa identità Orchid';

  @override
  String get chooseIdentity => 'Scegli identità';

  @override
  String get updatingAccounts => 'Aggiorno gli account';

  @override
  String get trafficAnalysis => 'Analisi del traffico';

  @override
  String get accountManager => 'Gestione account';

  @override
  String get circuitBuilder => 'Generatore di circuiti';

  @override
  String get exitHop => 'Hop di uscita';

  @override
  String get entryHop => 'Hop di entrata';

  @override
  String get addNewHop => 'AGGIUNGI NUOVO HOP';

  @override
  String get newCircuitBuilder => 'Nuovo Generatore di circuiti!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Ora puoi pagare un circuito Orchid multi-hop con xDAI. L\'interfaccia multi-hop supporta gli account xDAI e OXT Orchid e supporta sempre le configurazioni OpenVPN e WireGuard che possono essere combinate in un instradamento a cipolla.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Gestisci la tua connessione dal Generatore di circuiti anziché da Gestione account. Tutte le connessioni ora utilizzano un circuito con zero o più hop. Qualsiasi configurazione esistente è stata migrata al Generatore di circuiti.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Avvio rapido con $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Abbiamo aggiunto un metodo per acquistare un account Orchid e creare un singolo circuito hop dalla schermata iniziale per semplificare il processo di onboarding.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid è un client multi-hop o di instradamento a cipolla esclusivo che supporta più protocolli VPN. Puoi configurare la connessione concatenando gli hop dai seguenti protocolli supportati.\n\nUn hop è come una normale VPN. Tre hop (per utenti avanzati) è la classica scelta di instradamento a cipolla. Zero hop consente l\'analisi del traffico senza tunnel VPN.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'L\'eliminazione degli hop OpenVPN e Wireguard comporterà la cancellazione di tutte le credenziali associate e della configurazione della connessione. Assicurati di eseguire il backup di tutte le informazioni prima di continuare.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Questa operazione è irreversibile. Per salvare questa identità, premi Annulla e usa l\'opzione Esporta';

  @override
  String get unlockTime => 'Durata sblocco';

  @override
  String get chooseChain => 'Scegli catena';

  @override
  String get unlocking => 'sblocco';

  @override
  String get unlocked => 'Sbloccato';

  @override
  String get orchidTransaction => 'Transazione Orchid';

  @override
  String get confirmations => 'Conferme';

  @override
  String get pending => 'In sospeso...';

  @override
  String get txHash => 'Hash Tx:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Tutti i tuoi fondi sono disponibili per il prelievo.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw dei tuoi $totalFunds di fondi combinati sono attualmente disponibili per il prelievo.';
  }

  @override
  String get alsoUnlockRemainingDeposit => 'Sblocca anche il deposito residuo';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Se specifichi un importo inferiore all\'importo totale, i fondi verranno prelevati prima dal tuo saldo.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Per ulteriori opzioni, consulta il pannello AVANZATE.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Se selezioni l\'opzione di sblocco del deposito, con questa transazione preleverai immediatamente l\'importo specificato dal tuo saldo e verrà avviato anche il processo di sblocco del deposito residuo.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'I fondi di deposito sono disponibili per il prelievo 24 ore dopo lo sblocco.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Preleva fondi dal tuo account Orchid al tuo wallet attuale.';

  @override
  String get withdrawAndUnlockFunds => 'PRELEVA E SBLOCCA FONDI';

  @override
  String get withdrawFunds => 'PRELEVA FONDI';

  @override
  String get withdrawFunds2 => 'Prelevare fondi';

  @override
  String get withdraw => 'Preleva';

  @override
  String get submitTransaction => 'INVIA TRANSAZIONE';

  @override
  String get move => 'Sposta';

  @override
  String get now => 'Ora';

  @override
  String get amount => 'Quantità';

  @override
  String get available => 'Disponibile';

  @override
  String get select => 'Seleziona';

  @override
  String get add => 'AGGIUNGI';

  @override
  String get balanceToDeposit => 'DA SALDO A DEPOSITO';

  @override
  String get depositToBalance => 'DA DEPOSITO A SALDO';

  @override
  String get setWarnedAmount => 'Imposta importo limite';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Aggiungi fondi al saldo e/o al deposito del tuo account Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Per indicazioni sul dimensionamento del tuo account, visita <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Preautorizzazione corrente di $tokenType: $amount';
  }

  @override
  String get noWallet => 'Nessun wallet';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Nessun wallet o browser non supportato.';

  @override
  String get error => 'Errore';

  @override
  String get failedToConnectToWalletconnect =>
      'Impossibile connettersi a WalletConnect.';

  @override
  String get unknownChain => 'Catena sconosciuta';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'La gestione account di Orchid non supporta ancora questa catena.';

  @override
  String get orchidIsntOnThisChain => 'Orchid non è presente in questa catena.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Il contratto Orchid non è ancora stato distribuito in questa catena.';

  @override
  String get moveFunds => 'SPOSTA FONDI';

  @override
  String get moveFunds2 => 'Sposta fondi';

  @override
  String get lockUnlock => 'BLOCCA/SBLOCCA';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Il tuo deposito di $amount è sbloccato.';
  }

  @override
  String get locked => 'bloccato';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Il tuo deposito di $amount è $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'I fondi saranno disponibili per il prelievo tra \$$time.';
  }

  @override
  String get lockDeposit => 'BLOCCA DEPOSITO';

  @override
  String get unlockDeposit => 'SBLOCCA DEPOSITO';

  @override
  String get advanced => 'AVANZATE';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Scopri di più sugli account Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Costo stimato per creare un account Orchid con un\'efficienza di $efficiency e $num ticket di valore.';
  }

  @override
  String get chain => 'Catena';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Deposito min';

  @override
  String get minBalance => 'Saldo min';

  @override
  String get fundFee => 'Commissione fondo';

  @override
  String get withdrawFee => 'Commissione prelievo';

  @override
  String get tokenValues => 'VALORI TOKEN';

  @override
  String get usdPrices => 'PREZZI USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'L\'impostazione di un importo di deposito limite avvia il periodo di attesa di 24 ore necessario per prelevare i fondi del deposito.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Durante questo periodo, i fondi non sono disponibili come deposito valido sulla rete Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'I fondi possono essere nuovamente bloccati in qualsiasi momento riducendo l\'importo limite.';

  @override
  String get warn => 'Limite';

  @override
  String get totalWarnedAmount => 'Importo limite totale';

  @override
  String get newIdentity => 'Nuova identità';

  @override
  String get importIdentity => 'Importa identità';

  @override
  String get exportIdentity => 'Esporta identità';

  @override
  String get deleteIdentity => 'Elimina identità';

  @override
  String get importOrchidIdentity => 'Importa identità Orchid';

  @override
  String get funderAddress => 'Indirizzo finanziatore';

  @override
  String get contract => 'Contratto';

  @override
  String get txFee => 'Commiss. transaz.';

  @override
  String get show => 'Mostra';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Errori';

  @override
  String get lastHour => 'Ultima ora';

  @override
  String get chainSettings => 'Impostazioni catena';

  @override
  String get price => 'Prezzo';

  @override
  String get failed => 'Non riusc.';

  @override
  String get fetchGasPrice => 'Recupera prezzo gas';

  @override
  String get fetchLotteryPot => 'Recupera prezzo lotteria';

  @override
  String get lines => 'linee';

  @override
  String get filtered => 'filtrate';

  @override
  String get backUpYourIdentity => 'Fai il backup della tua identità';

  @override
  String get accountSetUp => 'Account impostato';

  @override
  String get setUpAccount => 'Configura account';

  @override
  String get generateIdentity => 'GENERARE IDENTITÀ';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Inserisci un\' <account_link>Identità Orchidea</account_link>esistente';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Incolla di seguito l\'indirizzo del portafoglio web3 che utilizzerai per finanziare il tuo account.';

  @override
  String get funderWalletAddress => 'Indirizzo portafoglio finanziatore';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Il tuo indirizzo pubblico di identità dell\'orchidea';

  @override
  String get continueButton => 'CONTINUA';

  @override
  String get yesIHaveSavedACopyOf =>
      'Sì, ho salvato una copia della mia chiave privata in un posto sicuro.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Esegui il backup della tua chiave privata <bold>Orchid Identity</bold>. Avrai bisogno di questa chiave per condividere, importare o ripristinare questa identità e tutti gli account associati.';

  @override
  String get locked1 => 'bloccato';

  @override
  String get unlockDeposit1 => 'Sblocca il deposito';

  @override
  String get changeWarnedAmountTo => 'Modifica l\'importo dell\'avviso in';

  @override
  String get setWarnedAmountTo => 'Imposta l\'importo dell\'avviso su';

  @override
  String get currentWarnedAmount => 'Importo attuale dell\'avviso';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Tutti i fondi avvertiti saranno bloccati fino a';

  @override
  String get balanceToDeposit1 => 'Saldo da depositare';

  @override
  String get depositToBalance1 => 'Deposito a saldo';

  @override
  String get advanced1 => 'Avanzate';

  @override
  String get add1 => 'Inserisci';

  @override
  String get lockUnlock1 => 'Blocca sblocca';

  @override
  String get viewLogs => 'Visualizza i log';

  @override
  String get language => 'linguaggio';

  @override
  String get systemDefault => 'Default del sistema';

  @override
  String get identiconStyle => 'Stile Identico';

  @override
  String get blockies => 'Blockies';

  @override
  String get jazzicon => 'Jazzicone';

  @override
  String get contractVersion => 'Versione contratto';

  @override
  String get version0 => 'Versione 0';

  @override
  String get version1 => 'Versione 1';

  @override
  String get connectedWithMetamask => 'Collegato con Metamask';

  @override
  String get blockExplorer => 'blocco esploratore';

  @override
  String get tapToMinimize => 'Tocca per ridurre a icona';

  @override
  String get connectWallet => 'Collega il portafoglio';

  @override
  String get checkWallet => 'Controlla Portafoglio';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Controlla la tua app o estensione Wallet per una richiesta in sospeso.';

  @override
  String get test => 'Test';

  @override
  String get chainName => 'Nome della catena';

  @override
  String get rpcUrl => 'URL RPC';

  @override
  String get tokenPrice => 'Prezzo del token';

  @override
  String get tokenPriceUsd => 'Prezzo del token USD';

  @override
  String get addChain => 'Aggiungi catena';

  @override
  String get deleteChainQuestion => 'Elimina catena?';

  @override
  String get deleteUserConfiguredChain =>
      'Elimina la catena configurata dall\'utente';

  @override
  String get fundContractDeployer => 'Gestore del contratto del fondo';

  @override
  String get deploySingletonFactory => 'Distribuire Singleton Factory';

  @override
  String get deployContract => 'Contratto di distribuzione';

  @override
  String get about => 'Di';

  @override
  String get dappVersion => 'Versione Dapp';

  @override
  String get viewContractOnEtherscan => 'Visualizza contratto su Etherscan';

  @override
  String get viewContractOnGithub => 'Visualizza contratto su Github';

  @override
  String get accountChanges => 'Modifiche all\'account';

  @override
  String get name => 'Nome';

  @override
  String get step1 =>
      '<bold>Passaggio 1.</bold> Collega un portafoglio ERC-20 con <link>token sufficienti</link> al suo interno.';

  @override
  String get step2 =>
      '<bold>Passaggio 2.</bold> Copia l\'identità Orchid dall\'app Orchid andando su Gestisci account e toccando l\'indirizzo.';

  @override
  String get connectOrCreate => 'Collega o crea un account Orchid';

  @override
  String get lockDeposit2 => 'Deposito a chiave';

  @override
  String get unlockDeposit2 => 'Sblocca il deposito';

  @override
  String get enterYourWeb3 =>
      'Inserisci l\'indirizzo del tuo portafoglio web3.';

  @override
  String get purchaseComplete => 'Acquisto completato';

  @override
  String get generateNewIdentity => 'Genera una nuova identità';

  @override
  String get copyIdentity => 'Copia identità';

  @override
  String get yourPurchaseIsComplete =>
      'Il tuo acquisto è completo ed è ora in fase di elaborazione da parte della blockchain xDai, operazione che potrebbe richiedere alcuni minuti. È stato generato un circuito predefinito per te utilizzando questo account. Puoi monitorare il saldo disponibile nella schermata principale o nel gestore dell\'account.';

  @override
  String get circuitGenerated => 'Circuito generato';

  @override
  String get usingYourOrchidAccount =>
      'Utilizzando il tuo account Orchid, è stato generato un singolo circuito hop. Puoi gestirlo dalla schermata del costruttore di circuiti.';
}
