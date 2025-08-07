// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get orchidHop => 'Salto Orchid';

  @override
  String get orchidDisabled => 'Orchid desativado';

  @override
  String get trafficMonitoringOnly => 'Apenas monitorização de tráfego';

  @override
  String get orchidConnecting => 'Orchid a estabelecer ligação';

  @override
  String get orchidDisconnecting => 'Orchid a terminar ligação';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hops configurados',
      two: 'Dois hops configurados',
      one: 'Um hop configurado',
      zero: 'Sem hops configurados',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Remover';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Saltos';

  @override
  String get traffic => 'Tráfego';

  @override
  String get curation => 'Curadoria';

  @override
  String get signerKey => 'Chave do signatário';

  @override
  String get copy => 'Copiar';

  @override
  String get paste => 'Colar';

  @override
  String get deposit => 'Depósito';

  @override
  String get curator => 'Curador(a)';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => 'CONFIGURAÇÕES';

  @override
  String get confirmThisAction => 'Confirmar esta ação';

  @override
  String get cancelButtonTitle => 'CANCELAR';

  @override
  String get changesWillTakeEffectInstruction =>
      'As suas alterações serão aplicadas assim que a VPN seja reiniciada.';

  @override
  String get saved => 'Guardado';

  @override
  String get configurationSaved => 'Configuração Guardada';

  @override
  String get whoops => 'Ups';

  @override
  String get configurationFailedInstruction =>
      'Falha ao salvar a configuração. Verifique a sintaxe e tente novamente.';

  @override
  String get addHop => 'Adicionar Hop';

  @override
  String get scan => 'Digitalizar';

  @override
  String get invalidQRCode => 'Código QR inválido';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'O código QR que você digitalizou não contém uma configuração de conta válida.';

  @override
  String get invalidCode => 'Código inválido';

  @override
  String get theCodeYouPastedDoesNot =>
      'O código que você colou não contém uma configuração de conta válida.';

  @override
  String get openVPNHop => 'Hop OpenVPN';

  @override
  String get username => 'Nome do Utilizador';

  @override
  String get password => 'Palavra Passe';

  @override
  String get config => 'Configuração';

  @override
  String get pasteYourOVPN => 'Cole seu ficheiro de configuração OVPN aqui';

  @override
  String get enterYourCredentials => 'Insira as suas credenciais';

  @override
  String get enterLoginInformationInstruction =>
      'Insira as suas credenciais do seu fornecedor de  VPN abaixo. Depois cole o conteúdo do ficheiro de configuração da OpenVPN do seu fornecedor no campo fornecido.';

  @override
  String get save => 'Guardar';

  @override
  String get help => 'Ajuda';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get openSourceLicenses => 'Licenças Open Source';

  @override
  String get settings => 'Configurações';

  @override
  String get version => 'Versão';

  @override
  String get noVersion => 'Sem versão';

  @override
  String get orchidOverview => 'Visão geral da Orchid';

  @override
  String get defaultCurator => 'Curador padrão';

  @override
  String get queryBalances => 'Consultar Saldos';

  @override
  String get reset => 'Redefinir';

  @override
  String get manageConfiguration => 'Gerir Configuração';

  @override
  String get warningThesefeature =>
      'Aviso: esses recursos são direcionados somente a usuários avançados. Leia todas as instruções.';

  @override
  String get exportHopsConfiguration => 'Exportar configurações de hop';

  @override
  String get export => 'Exportar';

  @override
  String get warningExportedConfiguration =>
      'Aviso: a configuração exportada inclui os segredos de chave privada do signatário para os hops exportados. Revelar chaves privadas expõe-o à perda de todos os seus fundos nas contas Orchid relacionadas.';

  @override
  String get importHopsConfiguration => 'Importar configurações do Hop';

  @override
  String get import => 'Importar';

  @override
  String get warningImportedConfiguration =>
      'Aviso: a configuração importada substitui os Hops  que criou na aplicação. As chaves de signatário geradas anteriormente ou importadas nesse dispositivo serão retidas e irão permanecer disponíveis para a criação de novos hops, no entanto todas as outras configurações, incluindo a configuração de hop OpenVPN serão perdidas.';

  @override
  String get configuration => 'Configuração';

  @override
  String get saveButtonTitle => 'GUARDAR';

  @override
  String get search => 'Pesquisa';

  @override
  String get newContent => 'Novo conteúdo';

  @override
  String get clear => 'Limpar';

  @override
  String get connectionDetail => 'Detalhes da Ligação';

  @override
  String get host => 'Anfitrião';

  @override
  String get time => 'Hora';

  @override
  String get sourcePort => 'Porta de origem';

  @override
  String get destination => 'Destino';

  @override
  String get destinationPort => 'Porta de destino';

  @override
  String get generateNewKey => 'Gerar nova chave';

  @override
  String get importKey => 'Importar chave';

  @override
  String get nothingToDisplayYet =>
      'Nada a mostrar para já. O tráfego irá aparecer aqui quando houver algo a mostrar.';

  @override
  String get disconnecting => 'A Desligar...';

  @override
  String get connecting => 'A Ligar...';

  @override
  String get pushToConnect => 'Pressione para conectar.';

  @override
  String get orchidIsRunning => 'Orchid em execução!';

  @override
  String get pacPurchaseWaiting => 'Aguardando compra';

  @override
  String get retry => 'Tente de novo';

  @override
  String get getHelpResolvingIssue =>
      'Obter ajuda para solucionar este problema.';

  @override
  String get copyDebugInfo => 'Copiar informações de depuração';

  @override
  String get contactOrchid => 'Contactar Orchid';

  @override
  String get remove => 'Remover';

  @override
  String get deleteTransaction => 'Apagar transação';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Limpar esta transação. Não haverá reembolso da sua compra na aplicação. Terá de entrar em contato com a Orchid para solucionar o problema.';

  @override
  String get preparingPurchase => 'Preparando compra';

  @override
  String get retryingPurchasedPAC => 'Tentando compra novamente';

  @override
  String get retryPurchasedPAC => 'Tentar compra de novo';

  @override
  String get purchaseError => 'Erro na compra';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Houve um erro na compra. Entre em contato com o suporte Orchid.';

  @override
  String get importAnOrchidAccount => 'Importar uma conta da Orchid';

  @override
  String get buyCredits => 'Compre créditos';

  @override
  String get linkAnOrchidAccount => 'Conectar conta Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Infelizmente a sua compra excede o limite de compra diário para créditos de acesso. Tente novamente mais tarde.';

  @override
  String get marketStats => 'Estatísticas de mercado';

  @override
  String get balanceTooLow => 'Saldo muito baixo';

  @override
  String get depositSizeTooSmall => 'Montante do depósito é muito pequeno';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'O valor máximo do seu ticket atualmente é limitado pelo seu saldo de';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'O valor máximo do seu ticket atualmente é limitado pelo seu depósito de';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Considere adicionar OXT ao saldo da sua conta.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Considere adicionar OXT ao seu depósito ou mover fundos do seu saldo para o seu depósito.';

  @override
  String get prices => 'Preços';

  @override
  String get ticketValue => 'Valor do ticket';

  @override
  String get costToRedeem => 'Custo do resgate:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Consulte a documentação para obter ajuda.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Bom para navegação e atividade leve';

  @override
  String get learnMore => 'Saiba mais.';

  @override
  String get connect => 'Ligar';

  @override
  String get disconnect => 'Desligar';

  @override
  String get wireguardHop => 'Hop WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Cole sua configuração WireGuard® aqui';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Cole as suas credenciais do seu fornecedor WireGuard® no campo acima.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Limpar todos os dados de registro?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Esse registro de depuração não é persistente e é limpo quando fechar a aplicação.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Ele poderá conter informações secretas ou de identificação pessoal.';

  @override
  String get loggingEnabled => 'Registro ativado';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get logging => 'Registro';

  @override
  String get loading => 'Carregando...';

  @override
  String get ethPrice => 'Preço do ETH:';

  @override
  String get oxtPrice => 'Preço do OXT:';

  @override
  String get gasPrice => 'Preço da gasolina:';

  @override
  String get maxFaceValue => 'Valor de face máximo:';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String get enterOpenvpnConfig => 'Insira a configuração OpenVPN';

  @override
  String get enterWireguardConfig => 'Insira a configuração WireGuard®️';

  @override
  String get starting => 'A Iniciar...';

  @override
  String get legal => 'Jurídico';

  @override
  String get whatsNewInOrchid => 'Novidades da Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid no xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Agora pode comprar créditos Orchid no xDai! Podes começar pelo preço de uma imperial.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Contas xDai para compras passadas';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Para qualquer compra dentro da aplicação feita antes de hoje, os fundos xDai foram adicionados à mesma chave de conta. Use a largura de banda por nossa conta!';

  @override
  String get newInterface => 'Novo interface';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'As contas agora ficam organizadas no endereço Orchid com a qual estão associadas.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Veja o saldo da sua conta ativa e o custo da largura de banda na vista inicial.';

  @override
  String get seeOrchidcomForHelp => 'Consulte orchid.com para obter ajuda.';

  @override
  String get payPerUseVpnService => 'Serviço de VPN pago por uso';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Sem subscrição, créditos que não vencem';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Partilhe a sua conta com dispositivos ilimitados';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'A loja Orchid está temporariamente indisponível. Volte dentro de alguns minutos.';

  @override
  String get talkingToPacServer => 'Falando com o Servidor de Conta Orchid';

  @override
  String get advancedConfiguration => 'Configuração avançada';

  @override
  String get newWord => 'Nova';

  @override
  String get copied => 'Copiada';

  @override
  String get efficiency => 'Eficiência';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Mín de tickets disponíveis: $tickets';
  }

  @override
  String get transactionSentToBlockchain =>
      'Transação enviada para a blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'A sua compra foi concluída encontra-se agora a ser processada pela blockchain xDai, o que pode levar até um minuto, algumas vezes mais. Puxe para baixo para atualizar, sua conta com o saldo atualizado será exibida abaixo.';

  @override
  String get copyReceipt => 'Copiar recibo';

  @override
  String get manageAccounts => 'Gerir Contas';

  @override
  String get configurationManagement => 'Gerir Configuração';

  @override
  String get exportThisOrchidKey => 'Exportar essa chave Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Um código QR e o texto de todas as contas Orchid associadas com esta chave estão abaixo.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Importar essa chave em outro dispositivo para partilhar todas as contas Orchid associadas com essa identidade Orchid.';

  @override
  String get orchidAccountInUse => 'Conta Orchid em uso';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Essa conta Orchid está em uso e não pode ser eliminada.';

  @override
  String get pullToRefresh => 'Puxe para atualizar.';

  @override
  String get balance => 'Saldo';

  @override
  String get active => 'Ativo';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Cole uma chave Orchid da área de transferência para importar todas as contas Orchid associadas com essa chave.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Digitalize ou cole uma chave Orchid da área de transferência para importar todas as contas Orchid associadas a essa chave.';

  @override
  String get account => 'Conta';

  @override
  String get transactions => 'Transações';

  @override
  String get weRecommendBackingItUp =>
      'Recomendamos <link>fazer backup</link>.';

  @override
  String get copiedOrchidIdentity => 'Identidade Orchid copiada';

  @override
  String get thisIsNotAWalletAddress => 'Este não é um endereço de carteira.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Não enviar tokens para este endereço.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'A Sua identidade Orchid identifica-o com exclusividade na rede.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Saiba mais sobre a sua <link>Identidade orchid</link>.';

  @override
  String get analyzingYourConnections => 'Analisando suas ligações';

  @override
  String get analyzeYourConnections => 'Analisar suas Ligações';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'A análise de rede utiliza as capacidades de VPN do seu dispositivo para capturar pacotes e analisar seu tráfego.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'A análise de rede requer permissões de VPN mas não protege por si só os seus dados nem esconde seu endereço de IP.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Para obter os benefícios da privacidade de rede, necessita configurar e ativar uma ligação VPN a partir da vista inicial.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Ligar esta funcionalidade aumenta o uso da bateria por parte da aplicação Orchid.';

  @override
  String get useAnOrchidAccount => 'Usar uma conta Orchid';

  @override
  String get pasteAddress => 'Colar endereço';

  @override
  String get chooseAddress => 'Escolher endereço';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Escolha uma conta Orchid para usar com este hop.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Caso não veja sua conta abaixo, pode usar o gestor de conta para importar, comprar ou criar uma nova.';

  @override
  String get selectAnOrchidAccount => 'Selecione uma conta Orchid';

  @override
  String get takeMeToTheAccountManager => 'Leve-me para o Gestor de Conta';

  @override
  String get funderAccount => 'Conta Financiadora';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid a correr e a analisar';

  @override
  String get startingVpn => '(A Iniciar VPN)';

  @override
  String get disconnectingVpn => '(Desligando a VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid a analisar tráfego';

  @override
  String get vpnConnectedButNotRouting => '(VPN conectado, mas sem roteamento)';

  @override
  String get restarting => 'Reiniciando';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'A alteração do status de monitoração exige o reinício da VPN, que pode interromper por momentos a proteção de privacidade.';

  @override
  String get confirmRestart => 'Confirmar reinício';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'O preço médio é de $price USD por GB';
  }

  @override
  String get myOrchidConfig => 'A Minha Configuração do Orchid';

  @override
  String get noAccountSelected => 'Nenhuma conta selecionada';

  @override
  String get inactive => 'Inativo';

  @override
  String get tickets => 'Bilhetes';

  @override
  String get accounts => 'Contas';

  @override
  String get orchidIdentity => 'Identidade do Orchid';

  @override
  String get addFunds => 'ADICIONAR FUNDOS';

  @override
  String get addFunds2 => 'Adicionar Fundos';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Salto';

  @override
  String get circuit => 'Circuito';

  @override
  String get clearAllAnalysisData => 'Limpar todos os dados de análise?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Esta ação limpa todos os dados de ligação de tráfego anteriormente analisados.';

  @override
  String get clearAll => 'LIMPAR TUDO';

  @override
  String get stopAnalysis => 'PARAR ANÁLISE';

  @override
  String get startAnalysis => 'INICIAR ANÁLISE';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'As contas do Orchid incluem apoio técnico 24h, dispositivos ilimitados e são apoiados pela <link2>criptografia xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'As contas adquiriras ligam-se exclusivamente aos nossos <link1>fornecedores preferidos</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'A política de reembolso é coberta pelas lojas de aplicações.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'O Orchid não consegue exibir as compras dentro da aplicação no momento.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Confirme que este dispositivo suporta e está configurado para compras na aplicação.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Confirme que este dispositivo suporta e está configurado para compras na aplicação ou utilize o nosso sistema descentralizado de <link>gestão de contas</link>.';

  @override
  String get buy => 'COMPRAR';

  @override
  String get gbApproximately12 => '12GB (aproximadamente)';

  @override
  String get gbApproximately60 => '60GB (aproximadamente)';

  @override
  String get gbApproximately240 => '240GB (aproximadamente)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Tamanho ideal para uma utilização individual a médio-prazo que inclui navegação e streaming leve.';

  @override
  String get mostPopular => 'Mais Popular!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Utilização a longo prazo com largura de banda intensa ou contas partilhadas.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'A colocar todo o tráfego em pausa...';

  @override
  String get queryingEthereumForARandom =>
      'A consultar Ethereum para um fornecedor aleatório...';

  @override
  String get quickFundAnAccount => 'Coloque rapidamente fundos numa conta!';

  @override
  String get accountFound => 'Conta encontrada';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Encontrámos uma conta associada às suas identidades e criámos um circuito do Orchid de hop única para ela. Agora pode utilizar a VPN.';

  @override
  String get welcomeToOrchid => 'Seja bem-vindo(a) ao Orchid!';

  @override
  String get fundYourAccount => 'Adicione Fundos à sua Conta';

  @override
  String get processing => 'A processar...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Serviço VPN em código aberto, descentralizado, sem subscrições, pague conforme o uso.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'COMEÇAR POR $smallAmount';
  }

  @override
  String get importAccount => 'IMPORTAR CONTA';

  @override
  String get illDoThisLater => 'Faço isto mais tarde';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Ligue-se automaticamente a um dos <link1>fornecedores favoritos</link1> da rede ao adquirir créditos de VPN para adicionar saldo à sua conta partilhável e recarregável do Orchid.';

  @override
  String get confirmPurchase => 'CONFIRMAR COMPRA';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'As contas do Orchid utilizam créditos de VPN suportadas pela <link>criptomoeda xDAI</link>, inclui apoio ao cliente 24h, partilha ilimitada de dispositivos e são cobertas pelas políticas de reembolso das lojas de aplicações.';

  @override
  String get yourPurchaseIsInProgress => 'A sua compra está em curso.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'O processamento desta compra está a demorar mais que o esperado, pode ter sido encontrado um erro.';

  @override
  String get thisMayTakeAMinute => 'Isto pode demorar um minuto...';

  @override
  String get vpnCredits => 'Créditos de VPN';

  @override
  String get blockchainFee => 'Taxa de blockchain';

  @override
  String get promotion => 'Promoção';

  @override
  String get showInAccountManager => 'Mostrar no Gestor de Contas';

  @override
  String get deleteThisOrchidIdentity => 'Eliminar esta Identidade do Orchid';

  @override
  String get chooseIdentity => 'Escolher Identidade';

  @override
  String get updatingAccounts => 'A atualizar Contas';

  @override
  String get trafficAnalysis => 'Análise de Tráfego';

  @override
  String get accountManager => 'Gestor de Conta';

  @override
  String get circuitBuilder => 'Criador de Circuitos';

  @override
  String get exitHop => 'Hop de Saída';

  @override
  String get entryHop => 'Hop de Entrada';

  @override
  String get addNewHop => 'ADICIONAR NOVO HOP';

  @override
  String get newCircuitBuilder => 'Novo criador de circuitos!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Agora pode pagar por um circuito do Orchi com vários hops com xDAI. A interface multihop agora suporta contas do Orchid xDAI e OXT. Ainda é compatível com configurações OpenVPN e WireGuard que podem ser agrupadas num percurso onion.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Faça a gestão da sua ligação a partir do criador de circuitos em vez do gestor de contas. Todas as ligações utilizam agora um circuito com zero ou mais hops. Qualquer configuração existente foi migrada para o criador de circuitos.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Começar rapidamente por $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Adicionamos uma forma de comprar uma conta do Orchid e criar um circuito de único hop a partir do ecrã inicial para criar um atalho para o processo de integração.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'O Orchid é único enquanto cliente de encaminhamento multi-hop ou onion que suporta vários protocolos de VPN. Pode configurar a sua ligação ao encadear hops a partir dos protocolos compatíveis abaixo.\n\nUm hop é como um VPN normal. Três hops (para utilizadores avançados) é a opção de encaminhamento onion clássica. Zero hops permitem a análise de tráfego sem qualquer túnel de VPN.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Eliminar os hops do OpenVPN e do Wireguard faz perder quaisquer credenciais associadas e configurações de ligação. Certifique-se de que salvaguarda quaisquer informações antes de continuar.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Esta ação não pode ser desfeita. Para guardar esta identidade, toque em Cancelar e utilize a opção de Exportar';

  @override
  String get unlockTime => 'Hora de Desbloqueio';

  @override
  String get chooseChain => 'Escolher Cadeia';

  @override
  String get unlocking => 'A desbloquear';

  @override
  String get unlocked => 'Desbloqueado';

  @override
  String get orchidTransaction => 'Transação do Orchid';

  @override
  String get confirmations => 'Confirmações';

  @override
  String get pending => 'Pendente...';

  @override
  String get txHash => 'Hash Tx:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Todos os seus fundos estão disponíveis para levantamento.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw dos seus $totalFunds fundos juntos estão atualmente disponíveis para levantamento.';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'Desbloquear também o depósito restante';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Se especificar menos que a quantidade inteira de fundos, estes vão ser retirados primeiro do seu saldo.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Para opções adicionais, consulte o painel AVANÇADO.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Se selecionar a opção de desbloquear depósito, esta transação levanta imediatamente a quantidade especificada do seu saldo e começa também o processo de desbloqueio do seu depósito restante.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Os fundos de depósito estão disponíveis para levantar após 24 horas do desbloqueio.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Levantar fundos da sua Conta Orchid para a sua carteira atual.';

  @override
  String get withdrawAndUnlockFunds => 'LEVANTAR E DESBLOQUEAR FUNDOS';

  @override
  String get withdrawFunds => 'LEVANTAR FUNDOS';

  @override
  String get withdrawFunds2 => 'Retirar Fundos';

  @override
  String get withdraw => 'Levantar';

  @override
  String get submitTransaction => 'ENVIAR TRANSAÇÃO';

  @override
  String get move => 'Mover';

  @override
  String get now => 'Agora';

  @override
  String get amount => 'Quantidade';

  @override
  String get available => 'Disponível';

  @override
  String get select => 'Selecionar';

  @override
  String get add => 'ADICIONAR';

  @override
  String get balanceToDeposit => 'SALDO PARA DEPOSITAR';

  @override
  String get depositToBalance => 'DEPOSITAR PARA O SALDO';

  @override
  String get setWarnedAmount => 'Definir Quantia com Aviso';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Adicionar fundos no saldo da sua Conta Orchid e/ou depositar.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Para obter apoio sobre como dimensionar a sua conta, consulte <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Pré-autorização atual de $tokenType: $amount';
  }

  @override
  String get noWallet => 'Sem Carteira';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Sem Carteira ou Browser não compatíveis.';

  @override
  String get error => 'Erro';

  @override
  String get failedToConnectToWalletconnect =>
      'Falha ao ligar ao WalletConnect.';

  @override
  String get unknownChain => 'Cadeia Desconhecida';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'O Gestor de Conta Orchid ainda não é compatível com esta cadeia.';

  @override
  String get orchidIsntOnThisChain => 'O Orchid não está nesta cadeia.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'O contrato do Orchid ainda não foi implementado nesta cadeia.';

  @override
  String get moveFunds => 'MOVER FUNDOS';

  @override
  String get moveFunds2 => 'Mover fundos';

  @override
  String get lockUnlock => 'BLOQUEAR / DESBLOQUEAR';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'O seu depósito de $amount foi desbloqueado.';
  }

  @override
  String get locked => 'bloqueado';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'O seu depósito de $amount está $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Os fundos vão estar disponíveis para levantamento a $time.';
  }

  @override
  String get lockDeposit => 'BLOQUEAR DEPÓSITO';

  @override
  String get unlockDeposit => 'DESBLOQUEAR DEPÓSITO';

  @override
  String get advanced => 'AVANÇADO';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Leia mais sobre as Contas do Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Custo estimado para criar uma Conta do Orchid com uma eficiência de $efficiency e $num bilhetes de valor.';
  }

  @override
  String get chain => 'Cadeia';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Depósito Mínimo';

  @override
  String get minBalance => 'Saldo Mínimo';

  @override
  String get fundFee => 'Taxa de Financiamento';

  @override
  String get withdrawFee => 'Taxa de Levantamento';

  @override
  String get tokenValues => 'VALORES DO TOKEN';

  @override
  String get usdPrices => 'PREÇOS EM USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Definir uma quantia de depósito com aviso inicia o período de espera de 24 horas necessárias para levantar fundos depositados.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Durante este período, os fundos não estão disponíveis enquanto depósito válido na rede do Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Os fundos podem voltar a ser bloqueados a qualquer momento ao reduzir a quantia com aviso.';

  @override
  String get warn => 'Aviso';

  @override
  String get totalWarnedAmount => 'Quantia Total com Aviso';

  @override
  String get newIdentity => 'Nova Identidade';

  @override
  String get importIdentity => 'Importar Identidade';

  @override
  String get exportIdentity => 'Exportar Identidade';

  @override
  String get deleteIdentity => 'Eliminar Identidade';

  @override
  String get importOrchidIdentity => 'Importar Identidade do Orchid';

  @override
  String get funderAddress => 'Morada do Financiador';

  @override
  String get contract => 'Contrato';

  @override
  String get txFee => 'Taxa de Transação';

  @override
  String get show => 'Mostrar';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Erros';

  @override
  String get lastHour => 'Última Hora';

  @override
  String get chainSettings => 'Definições de Corrente';

  @override
  String get price => 'Preço';

  @override
  String get failed => 'Falha';

  @override
  String get fetchGasPrice => 'Obter preço de Gas';

  @override
  String get fetchLotteryPot => 'Obter pote da lotaria';

  @override
  String get lines => 'linhas';

  @override
  String get filtered => 'filtro';

  @override
  String get backUpYourIdentity => 'Faça backup de sua identidade';

  @override
  String get accountSetUp => 'Configuração da conta';

  @override
  String get setUpAccount => 'Configurar conta';

  @override
  String get generateIdentity => 'GERAR IDENTIDADE';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Insira uma <account_link>identidade de orquídea</account_link>existente';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Cole o endereço da carteira web3 que você usará para financiar sua conta abaixo.';

  @override
  String get funderWalletAddress => 'Endereço da carteira do financiador';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Seu endereço público de identidade de orquídea';

  @override
  String get continueButton => 'Continuar';

  @override
  String get yesIHaveSavedACopyOf =>
      'Sim, salvei uma cópia da minha chave privada em algum lugar seguro.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Faça backup de sua chave privada <bold>de identidade de orquídea</bold>. Você precisará dessa chave para compartilhar, importar ou restaurar essa identidade e todas as contas associadas.';

  @override
  String get locked1 => 'Bloqueado';

  @override
  String get unlockDeposit1 => 'Desbloquear depósito';

  @override
  String get changeWarnedAmountTo => 'Alterar valor avisado para';

  @override
  String get setWarnedAmountTo => 'Definir valor avisado para';

  @override
  String get currentWarnedAmount => 'Valor atual da advertência';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Todos os fundos avisados serão bloqueados até';

  @override
  String get balanceToDeposit1 => 'Saldo para Depósito';

  @override
  String get depositToBalance1 => 'Depósito para saldo';

  @override
  String get advanced1 => 'Avançado';

  @override
  String get add1 => 'Adicionar';

  @override
  String get lockUnlock1 => 'Bloquear desbloquear';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String get language => 'Língua';

  @override
  String get systemDefault => 'Sistema padrão';

  @override
  String get identiconStyle => 'Estilo do Identificador';

  @override
  String get blockies => 'Blocos';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => 'Versão do contrato';

  @override
  String get version0 => 'Versão 0';

  @override
  String get version1 => 'Versão 1';

  @override
  String get connectedWithMetamask => 'Conectado com Metamask';

  @override
  String get blockExplorer => 'explorador de bloco';

  @override
  String get tapToMinimize => 'Toque para minimizar';

  @override
  String get connectWallet => 'Carteira conectada';

  @override
  String get checkWallet => 'Verificar carteira';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Verifique se há uma solicitação pendente no aplicativo ou extensão da Google Wallet.';

  @override
  String get test => 'Teste';

  @override
  String get chainName => 'Nome da cadeia';

  @override
  String get rpcUrl => 'URL de RPC';

  @override
  String get tokenPrice => 'Preço do token';

  @override
  String get tokenPriceUsd => 'Preço do token USD';

  @override
  String get addChain => 'Adicionar cadeia';

  @override
  String get deleteChainQuestion => 'Excluir cadeia?';

  @override
  String get deleteUserConfiguredChain =>
      'Excluir cadeia configurada pelo usuário';

  @override
  String get fundContractDeployer => 'Implantador de Contrato de Fundo';

  @override
  String get deploySingletonFactory => 'Implantar Fábrica Singleton';

  @override
  String get deployContract => 'Implantar contrato';

  @override
  String get about => 'Sobre';

  @override
  String get dappVersion => 'Versão do Dapp';

  @override
  String get viewContractOnEtherscan => 'Ver contrato no Etherscan';

  @override
  String get viewContractOnGithub => 'Ver contrato no Github';

  @override
  String get accountChanges => 'Alterações de conta';

  @override
  String get name => 'Nome';

  @override
  String get step1 =>
      '<bold>Etapa 1.</bold> Conecte uma carteira ERC-20 com <link>tokens suficientes</link> nela.';

  @override
  String get step2 =>
      '<bold>Etapa 2.</bold> Copie a identidade da orquídea do aplicativo Orchid acessando Gerenciar contas e tocando no endereço.';

  @override
  String get connectOrCreate => 'Conecte ou crie uma conta Orchid';

  @override
  String get lockDeposit2 => 'Depósito de bloqueio';

  @override
  String get unlockDeposit2 => 'Desbloquear depósito';

  @override
  String get enterYourWeb3 => 'Digite o endereço da sua carteira web3.';

  @override
  String get purchaseComplete => 'Compra completa';

  @override
  String get generateNewIdentity => 'Gerar uma nova Identidade';

  @override
  String get copyIdentity => 'Copiar Identidade';

  @override
  String get yourPurchaseIsComplete =>
      'Sua compra está concluída e agora está sendo processada pelo blockchain xDai, o que pode levar alguns minutos. Um circuito padrão foi gerado para você usando esta conta. Você pode acompanhar o saldo disponível na tela inicial ou no gerenciador de contas.';

  @override
  String get circuitGenerated => 'Circuito Gerado';

  @override
  String get usingYourOrchidAccount =>
      'Usando sua conta Orchid, um circuito de salto único foi gerado. Você pode gerenciar isso na tela do construtor de circuitos.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class SPtBr extends SPt {
  SPtBr() : super('pt_BR');

  @override
  String get orchidHop => 'Hop Orchid';

  @override
  String get orchidDisabled => 'Orchid desativado.';

  @override
  String get trafficMonitoringOnly => 'Monitoração do tráfego';

  @override
  String get orchidConnecting => 'Orchid está estabelecendo conexão';

  @override
  String get orchidDisconnecting => 'Orchid desconectando';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hops configurados',
      two: 'Dois hops configurados',
      one: 'Um hop configurado',
      zero: 'Nenhum hop configurado',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Excluir';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Hops';

  @override
  String get traffic => 'Tráfego.';

  @override
  String get curation => 'Curadororia';

  @override
  String get signerKey => 'Signer Key';

  @override
  String get copy => 'Copiar.';

  @override
  String get paste => 'Colar.';

  @override
  String get deposit => 'Depósito';

  @override
  String get curator => 'Curador';

  @override
  String get ok => 'Ok';

  @override
  String get settingsButtonTitle => 'CONFIGURAÇÕES.';

  @override
  String get confirmThisAction => 'Confirmar esta ação.';

  @override
  String get cancelButtonTitle => 'CANCELAR.';

  @override
  String get changesWillTakeEffectInstruction =>
      'As suas alterações serão aplicadas assim que a VPN reiniciar';

  @override
  String get saved => 'Guardado.';

  @override
  String get configurationSaved => 'Configuração Guardada.';

  @override
  String get whoops => 'Whoops';

  @override
  String get configurationFailedInstruction =>
      'Falha ao salvar a configuração. Verifique a sintaxe e tente novamente';

  @override
  String get addHop => 'Adicionar Hop.';

  @override
  String get scan => 'Digitalizar.';

  @override
  String get invalidQRCode => 'Código QR inválido.';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'O código QR que você digitalizou não contém uma configuração de conta válida';

  @override
  String get invalidCode => 'Código inválido.';

  @override
  String get theCodeYouPastedDoesNot =>
      'O código que você colou não contém uma configuração de conta válida';

  @override
  String get openVPNHop => 'Hop OpenVPN.';

  @override
  String get username => 'Nome do Utilizador.';

  @override
  String get password => 'Senha.';

  @override
  String get config => 'Configuração.';

  @override
  String get pasteYourOVPN => 'Cole seu ficheiro de configuração OVPN aqui.';

  @override
  String get enterYourCredentials => 'Insira as suas credenciais.';

  @override
  String get enterLoginInformationInstruction =>
      'Insira as suas credenciais do seu fornecedor de  VPN abaixo. Depois cole o conteúdo do ficheiro de configuração da OpenVPN do seu fornecedor no campo fornecido';

  @override
  String get save => 'Guardar.';

  @override
  String get help => 'Ajuda';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get openSourceLicenses => 'Licenças Open Source.';

  @override
  String get settings => 'Configurações.';

  @override
  String get version => 'Versão.';

  @override
  String get noVersion => 'Sem versão.';

  @override
  String get orchidOverview => 'Visão geral de Orchid';

  @override
  String get defaultCurator => 'Curador padrão.';

  @override
  String get queryBalances => 'Consultar Saldos.';

  @override
  String get reset => 'Redefinir.';

  @override
  String get manageConfiguration => 'Gerir Configuração.';

  @override
  String get warningThesefeature =>
      'Aviso: esses recursos são direcionados somente a usuários avançados. Leia todas as instruções';

  @override
  String get exportHopsConfiguration => 'Exportar configurações de hop.';

  @override
  String get export => 'Exportar.';

  @override
  String get warningExportedConfiguration =>
      'Aviso: a configuração exportada inclui os segredos de chave privada do signatário para os hops exportados. Revelar chaves privadas expõe-o à perda de todos os seus fundos nas contas Orchid relacionadas';

  @override
  String get importHopsConfiguration => 'Importar configurações do Hop.';

  @override
  String get import => 'Importar.';

  @override
  String get warningImportedConfiguration =>
      'Aviso: a configuração importada substitui os Hops  que criou na aplicação. As chaves de signatário geradas anteriormente ou importadas nesse dispositivo serão retidas e irão permanecer disponíveis para a criação de novos hops, no entanto todas as outras configurações, incluindo a configuração de hop OpenVPN serão perdidas';

  @override
  String get configuration => 'Configuração.';

  @override
  String get saveButtonTitle => 'GUARDAR.';

  @override
  String get search => 'Pesquisar';

  @override
  String get newContent => 'Novo conteúdo.';

  @override
  String get clear => 'Limpar';

  @override
  String get connectionDetail => 'Detalhe de conexão';

  @override
  String get host => 'Host.';

  @override
  String get time => 'Hora.';

  @override
  String get sourcePort => 'Porta de origem.';

  @override
  String get destination => 'Destino.';

  @override
  String get destinationPort => 'Porta de destino.';

  @override
  String get generateNewKey => 'Gerar nova chave.';

  @override
  String get importKey => 'Importar Chave';

  @override
  String get nothingToDisplayYet =>
      'Nada para mostrar. O tráfego irá aparecer aqui quando houver algo para mostrar';

  @override
  String get disconnecting => 'Desconectando...';

  @override
  String get connecting => 'Conectando...';

  @override
  String get pushToConnect => 'Pressione para conectar';

  @override
  String get orchidIsRunning => 'Orchid em execução';

  @override
  String get pacPurchaseWaiting => 'Aguardando compra.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get getHelpResolvingIssue => 'Obter ajuda para solucionar problema.';

  @override
  String get copyDebugInfo => 'Copiar informações de depuração.';

  @override
  String get contactOrchid => 'Contactar Orchid.';

  @override
  String get remove => 'Remover.';

  @override
  String get deleteTransaction => 'Apagar transação.';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Limpar esta transação. Não haverá reembolso da sua compra na aplicação. Entre em contato com a Orchid para solucionar o problema.';

  @override
  String get preparingPurchase => 'Preparando compra.';

  @override
  String get retryingPurchasedPAC => 'Tentando compra novamente.';

  @override
  String get retryPurchasedPAC => 'Tentar compra de novo.';

  @override
  String get purchaseError => 'Erro na compra.';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Houve um erro na compra. Entre em contato com o suporte Orchid';

  @override
  String get importAnOrchidAccount => 'Importar uma conta da Orchid.';

  @override
  String get buyCredits => 'Compre créditos';

  @override
  String get linkAnOrchidAccount => 'Conectar conta Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Infelizmente a sua compra excede o limite de compra diário para créditos de acesso. Tente novamente mais tarde.';

  @override
  String get marketStats => 'Estatísticas de mercado';

  @override
  String get balanceTooLow => 'Saldo muito baixo';

  @override
  String get depositSizeTooSmall => 'Montante do depósito é muito pequeno';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'O valor máximo do seu ticket atualmente é limitado pelo seu saldo de';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'O valor máximo do seu ticket atualmente é limitado pelo seu depósito de';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Considere adicionar OXT ao saldo da sua conta.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Considere adicionar OXT ao seu depósito ou mover fundos do seu saldo para o seu depósito.';

  @override
  String get prices => 'Preços';

  @override
  String get ticketValue => 'Valor do ticket';

  @override
  String get costToRedeem => 'Custo do resgate:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Consulte a documentação para obter ajuda.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Bom para navegação e atividade leve';

  @override
  String get learnMore => 'Saiba mais.';

  @override
  String get connect => 'Conecte-se';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get wireguardHop => 'Hop WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Cole sua configuração WireGuard® aqui';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Cole as suas credenciais do seu fornecedor WireGuard® no campo acima.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Limpar todos os dados de registro?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Esse registro de depuração não é persistente e é limpo quando fechar a aplicação.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Ele poderá conter informações secretas ou de identificação pessoal.';

  @override
  String get loggingEnabled => 'Registro ativado';

  @override
  String get cancel => 'CANCELAR.';

  @override
  String get logging => 'Registro';

  @override
  String get loading => 'Carregando...';

  @override
  String get ethPrice => 'Preço do ETH:';

  @override
  String get oxtPrice => 'Preço do OXT:';

  @override
  String get gasPrice => 'Preço da taxa:';

  @override
  String get maxFaceValue => 'Valor de face máximo:';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String get enterOpenvpnConfig => 'Insira a configuração OpenVPN';

  @override
  String get enterWireguardConfig => 'Insira a configuração WireGuard®️';

  @override
  String get starting => 'A Iniciar...';

  @override
  String get legal => 'Jurídico';

  @override
  String get whatsNewInOrchid => 'Novidades do Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid no xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Agora você pode comprar créditos Orchid no xDai! Comece a usar o VPN por a partir de US\$1.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Contas xDai para compras passadas';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Para qualquer compra dentro do aplicativo feita antes de hoje, os fundos xDai foram adicionados à mesma chave de conta. Use a largura de banda por nossa conta!';

  @override
  String get newInterface => 'Nova interface';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'As contas agora ficam organizadas no endereço Orchid com a qual elas estavam associadas.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Veja seu saldo de conta ativo e o custo de largura de banda na tela inicial.';

  @override
  String get seeOrchidcomForHelp => 'Consulte orchid.com para obter ajuda.';

  @override
  String get payPerUseVpnService => 'Serviço de VPN pague quando usar';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Sem assinatura, créditos que não vencem';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Compartilhe sua conta com dispositivos ilimitados';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'A loja Orchid está temporariamente indisponível. Volte em alguns minutos.';

  @override
  String get talkingToPacServer => 'Conectando com o servidor de conta Orchid';

  @override
  String get advancedConfiguration => 'Configuração avançada';

  @override
  String get newWord => 'Nova';

  @override
  String get copied => 'Copiada';

  @override
  String get efficiency => 'Eficiência';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Mín de tickets disponíveis: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Transação enviada para blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Sua compra foi concluída e agora está sendo processada pelo blockchain xDai, o que pode levar até um minuto, algumas vezes mais. Puxe para baixo para atualizar e sua conta com o saldo atualizado será exibida abaixo.';

  @override
  String get copyReceipt => 'Copiar recibo';

  @override
  String get manageAccounts => 'Gerenciar contas';

  @override
  String get configurationManagement => 'Gerenciamento de configuração';

  @override
  String get exportThisOrchidKey => 'Exportar essa chave Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Um código QR e o texto de todas as contas Orchid associadas com essa chave estão abaixo.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Importar essa chave em outro dispositivo para compartilhar todas as contas Orchid associadas com essa identidade Orchid.';

  @override
  String get orchidAccountInUse => 'Conta Orchid em uso';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Essa conta Orchid está em uso e não pode ser apagada.';

  @override
  String get pullToRefresh => 'Puxe para atualizar.';

  @override
  String get balance => 'Saldo';

  @override
  String get active => 'Ativo';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Cole uma chave Orchid da área de transferência para importar todas as contas Orchid associadas com essa chave.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Escaneie ou cole uma chave Orchid da área de transferência para importar todas as contas Orchid associadas a essa chave.';

  @override
  String get account => 'Conta';

  @override
  String get transactions => 'Transações';

  @override
  String get weRecommendBackingItUp =>
      'Recomendamos <link>fazer backup</link>.';

  @override
  String get copiedOrchidIdentity => 'Identidade Orchid copiada';

  @override
  String get thisIsNotAWalletAddress => 'Esse não é um endereço de carteira.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Não enviar tokens para este endereço.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Sua identidade Orchid tem sua identificação exclusiva na rede.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Aprender mais sobre sua <link>Identidade orchid</link>.';

  @override
  String get analyzingYourConnections => 'Analisando suas conexões';

  @override
  String get analyzeYourConnections => 'Analise suas conexões';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'A análise de rede usa a facilidade de VPN do seu dispositivo para capturar pacotes e analisar seu tráfego.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'A análise de rede requer permissões de VPN mas não protege sozinha seus dados nem oculta seu endereço de IP.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Para obter os benefícios da privacidade de rede, você precisa configurar e ativar uma conexão VPN a partir da tela inicial.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Ligar este recurso aumenta o uso de bateria do aplicativo Orchid.';

  @override
  String get useAnOrchidAccount => 'Usar uma conta Orchid';

  @override
  String get pasteAddress => 'Colar endereço';

  @override
  String get chooseAddress => 'Escolher endereço';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Escolha uma conta Orchid para usar com esse hop.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Caso você não veja sua conta abaixo, você pode usar o gerente de conta para importar, comprar ou criar uma nova.';

  @override
  String get selectAnOrchidAccount => 'Selecione uma conta Orchid';

  @override
  String get takeMeToTheAccountManager => 'Ir para o gerente de contas';

  @override
  String get funderAccount => 'Conta de financiador';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid em execução e analisando';

  @override
  String get startingVpn => '(Iniciando VPN)';

  @override
  String get disconnectingVpn => '(Desconectando VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid analisando tráfego';

  @override
  String get vpnConnectedButNotRouting => '(VPN conectado, mas sem roteamento)';

  @override
  String get restarting => 'Reiniciando';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'A alteração do status de monitoramento exige o reinício do VPN, que pode interromper temporariamente a proteção de privacidade.';

  @override
  String get confirmRestart => 'Confirmar reinício';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'O preço médio é $price USD por GB';
  }

  @override
  String get myOrchidConfig => 'Minha configuração Orchid';

  @override
  String get noAccountSelected => 'Nenhuma conta selecionada';

  @override
  String get inactive => 'Inativo';

  @override
  String get tickets => 'Tickets';

  @override
  String get accounts => 'Contas';

  @override
  String get orchidIdentity => 'Identidade Orchid';

  @override
  String get addFunds => 'ADICIONAR FUNDOS';

  @override
  String get addFunds2 => 'Adicionar Fundos';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Hop';

  @override
  String get circuit => 'Circuito';

  @override
  String get clearAllAnalysisData => 'Limpar todos os dados de análise?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Essa ação limpará todos os dados analisados anteriormente de conexão de tráfego.';

  @override
  String get clearAll => 'LIMPAR TUDO';

  @override
  String get stopAnalysis => 'PARAR ANÁLISE';

  @override
  String get startAnalysis => 'COMEÇAR ANÁLISE';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'As contas Orchid incluem suporte ao cliente 24/7, dispositivos ilimitados e são baseados na <link2>criptomoeda xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Contas compradas conectam-se exclusivamente aos nossos <link1>provedores preferenciais</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Política de reembolso coberta pelas lojas de aplicativos.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'O Orchid não consegue exibir as compras dentro do aplicativo no momento.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Confirme se esse dispositivo é compatível e está configurado para compras no aplicativo.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Confirme que esse dispositivo é compatível com compras no aplicativo e está configurado corretamente para fazê-las ou use nosso sistema de <link>gerenciamento de contas</link> descentralizado.';

  @override
  String get buy => 'COMPRAR';

  @override
  String get gbApproximately12 => '12GB (aproximadamente)';

  @override
  String get gbApproximately60 => '60GB (aproximadamente)';

  @override
  String get gbApproximately240 => '240GB (aproximadamente)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'O tamanho ideal para uso individual de médio prazo que inclui navegação e streaming leve.';

  @override
  String get mostPopular => 'Mais popular!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Uso pesado de largura de banda de longo prazo ou contas compartilhadas.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'Pausando todo o tráfego...';

  @override
  String get queryingEthereumForARandom =>
      'Consultando Ethereum por um provedor aleatório...';

  @override
  String get quickFundAnAccount => 'Financiar uma conta rapidamente!';

  @override
  String get accountFound => 'Conta encontrada';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Encontramos uma conta associada com suas identidades e criamos um circuito de hop único Orchid para ela. Agora você já pode usar o VPN.';

  @override
  String get welcomeToOrchid => 'Boas vindas ao Orchid!';

  @override
  String get fundYourAccount => 'Financie sua conta';

  @override
  String get processing => 'Processando...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Serviço de VPN sem assinatura, pague quanto usar, descentralizado, código aberto.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'COMECE COM $smallAmount';
  }

  @override
  String get importAccount => 'IMPORTAR CONTA';

  @override
  String get illDoThisLater => 'Farei isso depois';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Conecte-se automaticamente a um dos <link1>provedores preferenciais</link1> da rede comprando créditos de VPN para financiar sua conta Orchid compartilhável e recarregável.';

  @override
  String get confirmPurchase => 'CONFIRMAR COMPRA';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Contas Orchid usam créditos de VPN sustentados pela <link>criptomoeda xDAI</link>, incluem suporte ao cliente 24/7, compartilhamento de dispositivos ilimitado e são cobertos pelas políticas de restituição das lojas de aplicativo.';

  @override
  String get yourPurchaseIsInProgress => 'Sua compra está em andamento.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Essa compra está demorando mais que o esperado para ser processada e pode ter encontrado um erro.';

  @override
  String get thisMayTakeAMinute => 'Isso pode levar um minuto...';

  @override
  String get vpnCredits => 'Créditos de VPN';

  @override
  String get blockchainFee => 'Taxa de blockchain';

  @override
  String get promotion => 'Promoção';

  @override
  String get showInAccountManager => 'Mostrar no gerenciador de conta';

  @override
  String get deleteThisOrchidIdentity => 'Apagar essa identidade Orchid';

  @override
  String get chooseIdentity => 'Escolher identidade';

  @override
  String get updatingAccounts => 'Atualizando contas';

  @override
  String get trafficAnalysis => 'Análise de tráfego';

  @override
  String get accountManager => 'Gerenciador de conta';

  @override
  String get circuitBuilder => 'Construtor de circuito';

  @override
  String get exitHop => 'Sair do hop';

  @override
  String get entryHop => 'Hop de entrada';

  @override
  String get addNewHop => 'ADICIONAR NOVO HOP';

  @override
  String get newCircuitBuilder => 'Novo construtor de circuito!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Agora você pode pagar por um circuito Orchid multi-hop com xDAI. A interface de multihop agora é compatível com contas xDAI e OXT da Orchid e ainda são compatíveis com as configurações OpenVPN e WireGuard que podem ser encadeadas em uma rota onion.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Gerencie sua conexão com o construtor de circuito em vez de com o gerenciador de conta. Todas as conexões agora usam um circuito com zero ou mais hops. Qualquer configuração existente foi migrada para o construtor de circuito.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Início rápido por $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Adicionamos um método de comprar uma conta Orchid e criar um circuito de hop único a partir da tela inicial para encurtar o processo de integração.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'O Orchid é exclusivo como cliente de multi-hop ou roteamento onion com suporte a vários protocolos de VPN. Você pode configurar suas conexões encadeando hops a partir dos protocolos compatíveis abaixo.\n\nUm hop é como um VPN normal. Três hops (para usuários avançados) é a opção clássica de roteamento onion. Zero hops permitem a análise de tráfego sem nenhum túnel VPN.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'A exclusão dos hops OpenVPN e Wireguard perderá as credenciais e a configuração de conexão associadas a elas. Certifique-se de fazer backup de qualquer informação antes de continuar.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Isso não pode ser desfeito. Para salvar essa identidade cancele e use a opção de Exportar';

  @override
  String get unlockTime => 'Horário de desbloqueio';

  @override
  String get chooseChain => 'Escolha a cadeia';

  @override
  String get unlocking => 'desbloqueando';

  @override
  String get unlocked => 'Desbloqueado';

  @override
  String get orchidTransaction => 'Transação Orchid';

  @override
  String get confirmations => 'Confirmações';

  @override
  String get pending => 'Pendente...';

  @override
  String get txHash => 'Hash Tx:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Todos os seus fundos estão disponíveis para retirada.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw de $totalFunds fundos combinados estão disponíveis atualmente para retirada.';
  }

  @override
  String get alsoUnlockRemainingDeposit => 'Liberar depósito restante também';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Se você especificar um valor menor que o valor total, os fundos serão retirados primeiro do seu saldo.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Para opções adicionais veja o painel AVANÇADO.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Caso você selecione a opção de liberar depósito, essa transação retirará imediatamente o valor especificado do seu saldo e também começará o processo de desbloqueio do restante do seu depósito.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Fundos de depósito estão disponíveis para retirada 24 horas depois do desbloqueio.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Retirar fundos da sua conta Orchid para sua carteira atual.';

  @override
  String get withdrawAndUnlockFunds => 'RETIRAR E LIBERAR TODOS OS FUNDOS';

  @override
  String get withdrawFunds => 'RETIRAR FUNDOS';

  @override
  String get withdrawFunds2 => 'Retirar Fundos';

  @override
  String get withdraw => 'Retirar';

  @override
  String get submitTransaction => 'ENVIAR TRANSAÇÃO';

  @override
  String get move => 'Mover';

  @override
  String get now => 'Agora';

  @override
  String get amount => 'Quantia';

  @override
  String get available => 'Disponível';

  @override
  String get select => 'Selecionar';

  @override
  String get add => 'ADICIONAR';

  @override
  String get balanceToDeposit => 'SALDO PARA DEPÓSITO';

  @override
  String get depositToBalance => 'DEPÓSITO PARA SALDO';

  @override
  String get setWarnedAmount => 'Definir valor de aviso';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Adicione fundos ao saldo e/ou depósito da sua conta Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Para orientações sobre o dimensionamento da sua conta, consulte <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return '$tokenType atual de pré-autorização: $amount';
  }

  @override
  String get noWallet => 'Nenhuma carteira';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Nenhuma carteira ou navegador não compatível.';

  @override
  String get error => 'Erro';

  @override
  String get failedToConnectToWalletconnect =>
      'Falha ao conectar-se ao WalletConnect.';

  @override
  String get unknownChain => 'Cadeia desconhecida';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'O Gerenciador de conta Orchid não é compatível com essa cadeia ainda.';

  @override
  String get orchidIsntOnThisChain => 'Orchid não está nessa cadeia.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'O contrato Orchid ainda não foi implementado nessa cadeia.';

  @override
  String get moveFunds => 'MOVER FUNDOS';

  @override
  String get moveFunds2 => 'Mover fundos';

  @override
  String get lockUnlock => 'BLOQUEAR/DESBLOQUEAR';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Seu depósito de $amount foi desbloqueado.';
  }

  @override
  String get locked => 'bloqueado';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Seu depósito de $amount está $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Os fundos estarão disponíveis para retirada em \$$time.';
  }

  @override
  String get lockDeposit => 'BLOQUEAR DEPÓSITO';

  @override
  String get unlockDeposit => 'DESBLOQUEAR DEPÓSITO';

  @override
  String get advanced => 'AVANÇADO';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Aprender mais sobre contas Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Custo estimado para criar uma conta Orchid com uma eficiência de $efficiency e $num bilhetes de valor.';
  }

  @override
  String get chain => 'Cadeia';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Depósito mínimo';

  @override
  String get minBalance => 'Saldo mínimo';

  @override
  String get fundFee => 'Taxa de fundo';

  @override
  String get withdrawFee => 'Taxa de retirada';

  @override
  String get tokenValues => 'VALORES DE TOKEN';

  @override
  String get usdPrices => 'PREÇOS EM USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'A definição de um valor de depósito de aviso inicia o período de espera de 24 horas necessário para a retirada dos fundos depositados.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Durante este período os fundos não estão disponíveis como um depósito válido na rede Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Os fundos podem ser bloqueados novamente a qualquer momento reduzindo-se o valor de aviso.';

  @override
  String get warn => 'Aviso';

  @override
  String get totalWarnedAmount => 'Valor total de aviso';

  @override
  String get newIdentity => 'Nova identidade';

  @override
  String get importIdentity => 'Importar identidade';

  @override
  String get exportIdentity => 'Exportar identidade';

  @override
  String get deleteIdentity => 'Excluir identidade';

  @override
  String get importOrchidIdentity => 'Importar identidade do Orchid';

  @override
  String get funderAddress => 'Endereço do financiador';

  @override
  String get contract => 'Contrato';

  @override
  String get txFee => 'Taxa de transação';

  @override
  String get show => 'Mostrar';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Erros';

  @override
  String get lastHour => 'Última hora';

  @override
  String get chainSettings => 'Configurações de cadeia';

  @override
  String get price => 'Preço';

  @override
  String get failed => 'Falha';

  @override
  String get fetchGasPrice => 'Buscar preço do gás';

  @override
  String get fetchLotteryPot => 'Buscar prêmio de loteria';

  @override
  String get lines => 'linhas';

  @override
  String get filtered => 'filtradas';

  @override
  String get backUpYourIdentity => 'Faça backup de sua identidade';

  @override
  String get accountSetUp => 'Configuração da conta';

  @override
  String get setUpAccount => 'Configurar conta';

  @override
  String get generateIdentity => 'GERAR IDENTIDADE';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Insira uma <account_link>identidade de orquídea</account_link>existente';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Cole o endereço da carteira web3 que você usará para financiar sua conta abaixo.';

  @override
  String get funderWalletAddress => 'Endereço da carteira do financiador';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Seu endereço público de identidade de orquídea';

  @override
  String get continueButton => 'Continuar';

  @override
  String get yesIHaveSavedACopyOf =>
      'Sim, salvei uma cópia da minha chave privada em algum lugar seguro.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Faça backup de sua chave privada <bold>de identidade de orquídea</bold>. Você precisará dessa chave para compartilhar, importar ou restaurar essa identidade e todas as contas associadas.';

  @override
  String get locked1 => 'Bloqueado';

  @override
  String get unlockDeposit1 => 'Desbloquear depósito';

  @override
  String get changeWarnedAmountTo => 'Alterar valor avisado para';

  @override
  String get setWarnedAmountTo => 'Definir valor avisado para';

  @override
  String get currentWarnedAmount => 'Valor atual da advertência';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Todos os fundos avisados serão bloqueados até';

  @override
  String get balanceToDeposit1 => 'Saldo para Depósito';

  @override
  String get depositToBalance1 => 'Depósito para saldo';

  @override
  String get advanced1 => 'Avançado';

  @override
  String get add1 => 'Adicionar';

  @override
  String get lockUnlock1 => 'Bloquear desbloquear';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String get language => 'Língua';

  @override
  String get systemDefault => 'Sistema padrão';

  @override
  String get identiconStyle => 'Estilo do Identificador';

  @override
  String get blockies => 'Blocos';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => 'Versão do contrato';

  @override
  String get version0 => 'Versão 0';

  @override
  String get version1 => 'Versão 1';

  @override
  String get connectedWithMetamask => 'Conectado com Metamask';

  @override
  String get blockExplorer => 'explorador de bloco';

  @override
  String get tapToMinimize => 'Toque para minimizar';

  @override
  String get connectWallet => 'Carteira conectada';

  @override
  String get checkWallet => 'Verificar carteira';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Verifique se há uma solicitação pendente no aplicativo ou extensão da Google Wallet.';

  @override
  String get test => 'Teste';

  @override
  String get chainName => 'Nome da cadeia';

  @override
  String get rpcUrl => 'URL de RPC';

  @override
  String get tokenPrice => 'Preço do token';

  @override
  String get tokenPriceUsd => 'Preço do token USD';

  @override
  String get addChain => 'Adicionar cadeia';

  @override
  String get deleteChainQuestion => 'Excluir cadeia?';

  @override
  String get deleteUserConfiguredChain =>
      'Excluir cadeia configurada pelo usuário';

  @override
  String get fundContractDeployer => 'Implantador de Contrato de Fundo';

  @override
  String get deploySingletonFactory => 'Implantar Fábrica Singleton';

  @override
  String get deployContract => 'Implantar contrato';

  @override
  String get about => 'Sobre';

  @override
  String get dappVersion => 'Versão do Dapp';

  @override
  String get viewContractOnEtherscan => 'Ver contrato no Etherscan';

  @override
  String get viewContractOnGithub => 'Ver contrato no Github';

  @override
  String get accountChanges => 'Alterações de conta';

  @override
  String get name => 'Nome';

  @override
  String get step1 =>
      '<bold>Etapa 1.</bold> Conecte uma carteira ERC-20 com <link>tokens suficientes</link> nela.';

  @override
  String get step2 =>
      '<bold>Etapa 2.</bold> Copie a identidade da orquídea do aplicativo Orchid acessando Gerenciar contas e tocando no endereço.';

  @override
  String get connectOrCreate => 'Conecte ou crie uma conta Orchid';

  @override
  String get lockDeposit2 => 'Depósito de bloqueio';

  @override
  String get unlockDeposit2 => 'Desbloquear depósito';

  @override
  String get enterYourWeb3 => 'Digite o endereço da sua carteira web3.';

  @override
  String get purchaseComplete => 'Compra completa';

  @override
  String get generateNewIdentity => 'Gerar uma nova Identidade';

  @override
  String get copyIdentity => 'Copiar Identidade';

  @override
  String get yourPurchaseIsComplete =>
      'Sua compra está concluída e agora está sendo processada pelo blockchain xDai, o que pode levar alguns minutos. Um circuito padrão foi gerado para você usando esta conta. Você pode acompanhar o saldo disponível na tela inicial ou no gerenciador de contas.';

  @override
  String get circuitGenerated => 'Circuito Gerado';

  @override
  String get usingYourOrchidAccount =>
      'Usando sua conta Orchid, um circuito de salto único foi gerado. Você pode gerenciar isso na tela do construtor de circuitos.';
}
