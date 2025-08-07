// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get orchidHop => 'Hop Orchid';

  @override
  String get orchidDisabled => 'Orchid deshabilitado';

  @override
  String get trafficMonitoringOnly => 'Solo monitoreo de tráfico';

  @override
  String get orchidConnecting => 'Conectando Orchid';

  @override
  String get orchidDisconnecting => 'Desconectando Orchid';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hops configurados',
      two: 'Dos hops configurados',
      one: 'Un hop configurado',
      zero: 'Ningún hop configurado',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Hops';

  @override
  String get traffic => 'Tráfico';

  @override
  String get curation => 'Curación';

  @override
  String get signerKey => 'Clave de firmante';

  @override
  String get copy => 'Copiar';

  @override
  String get paste => 'Pegar';

  @override
  String get deposit => 'Depósito';

  @override
  String get curator => 'Curación';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => 'AJUSTES';

  @override
  String get confirmThisAction => 'Confirmar esta acción';

  @override
  String get cancelButtonTitle => 'CANCELAR';

  @override
  String get changesWillTakeEffectInstruction =>
      'Los cambios tendrán efecto una vez reiniciada la VPN.';

  @override
  String get saved => 'Guardado';

  @override
  String get configurationSaved => 'Configuración guardada';

  @override
  String get whoops => 'Upsss';

  @override
  String get configurationFailedInstruction =>
      'Fallo al guardar la configuración. Compruebe por favor la sintaxis e inténtelo de nuevo.';

  @override
  String get addHop => 'Añadir Hop';

  @override
  String get scan => 'Escanear';

  @override
  String get invalidQRCode => 'Código QR no válido';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'El código QR escaneado no contiene una configuración de cuenta válida.';

  @override
  String get invalidCode => 'Código no válido';

  @override
  String get theCodeYouPastedDoesNot =>
      'El código que pegaste no contiene una configuración de cuenta válida.';

  @override
  String get openVPNHop => 'Hop OpenVPN';

  @override
  String get username => 'Usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get config => 'Configuración';

  @override
  String get pasteYourOVPN => 'Pega tu archivo de configuración OVPN aquí';

  @override
  String get enterYourCredentials => 'Introduce tus credenciales';

  @override
  String get enterLoginInformationInstruction =>
      'Introduce la información de acceso de tu proveedor VPN arriba. Después pega el contenido de la configuración OpenVPN de tu proveedor en el campo previsto.';

  @override
  String get save => 'Guardar';

  @override
  String get help => 'Ayuda';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get settings => 'Ajustes';

  @override
  String get version => 'Versión';

  @override
  String get noVersion => 'Sin versión';

  @override
  String get orchidOverview => 'Descripción general de Orchid';

  @override
  String get defaultCurator => 'Curación predeterminada';

  @override
  String get queryBalances => 'Consultar Saldo';

  @override
  String get reset => 'Restablecer';

  @override
  String get manageConfiguration => 'Administrar Configuración';

  @override
  String get warningThesefeature =>
      'Advertencia: estas funciones están dirigidas a usuarios avanzados. Lea todas las instrucciones.';

  @override
  String get exportHopsConfiguration => 'Exportar Configuración de Hops';

  @override
  String get export => 'Exportar';

  @override
  String get warningExportedConfiguration =>
      'Advertencia: la configuración exportada incluye las claves secretas privadas del firmante para los Hops exportados. Revelar las claves privadas le expone a la pérdida total de los fondos en sus cuentas Orchid asociadas.';

  @override
  String get importHopsConfiguration => 'Importar Configuración de Hops';

  @override
  String get import => 'Importar';

  @override
  String get warningImportedConfiguration =>
      'Advertencia: la configuración importada reemplazará cualquier Hop existente que haya creado en la app. Las claves del firmante generadas o importadas previamente en este dispositivo se conservarán y seguirán accesibles para crear nuevos Hops, sin embargo, se perderá el resto de la configuración, incluida la configuración del Hop OpenVPN.';

  @override
  String get configuration => 'Configuración';

  @override
  String get saveButtonTitle => 'GUARDAR';

  @override
  String get search => 'Buscar';

  @override
  String get newContent => 'Nuevo Contenido';

  @override
  String get clear => 'Borrar';

  @override
  String get connectionDetail => 'Detalles de Conexión';

  @override
  String get host => 'Host';

  @override
  String get time => 'Hora';

  @override
  String get sourcePort => 'Puerto de Origen';

  @override
  String get destination => 'Destino';

  @override
  String get destinationPort => 'Puerto de Destino';

  @override
  String get generateNewKey => 'Generar clave nueva';

  @override
  String get importKey => 'Importar clave';

  @override
  String get nothingToDisplayYet =>
      'Nada que mostrar aún. El tráfico aparecerá aquí cuando haya algo que mostrar.';

  @override
  String get disconnecting => 'Desconectando...';

  @override
  String get connecting => 'Conectando...';

  @override
  String get pushToConnect => 'Pulse para conectar.';

  @override
  String get orchidIsRunning => '¡Orchid está funcionando!';

  @override
  String get pacPurchaseWaiting => 'Esperando compra';

  @override
  String get retry => 'Reintentar';

  @override
  String get getHelpResolvingIssue =>
      'Obtener ayuda para resolver este problema.';

  @override
  String get copyDebugInfo => 'Copiar información de Depuración';

  @override
  String get contactOrchid => 'Contactar con Orchid';

  @override
  String get remove => 'Eliminar';

  @override
  String get deleteTransaction => 'Borrar transacción';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Borrar la transacción en curso. Esto no reembolsará su compra dentro de la aplicación. Contacte con Orchid para resolver el problema.';

  @override
  String get preparingPurchase => 'Preparando Compra';

  @override
  String get retryingPurchasedPAC => 'Reintentando compra';

  @override
  String get retryPurchasedPAC => 'Reintentar compra';

  @override
  String get purchaseError => 'Error de Compra';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Se produjo un error durante el proceso de compra. Contacte con el soporte de Orchid.';

  @override
  String get importAnOrchidAccount => 'Importar una cuenta Orchid';

  @override
  String get buyCredits => 'Comprar Créditos';

  @override
  String get linkAnOrchidAccount => 'Vincular Cuenta Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Lo sentimos, esta compra superaría el límite de compra diario para créditos de acceso. Inténtelo de nuevo más tarde.';

  @override
  String get marketStats => 'Estadísticas de Mercado';

  @override
  String get balanceTooLow => 'Saldo demasiado bajo';

  @override
  String get depositSizeTooSmall => 'Depósito insuficiente';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'El valor máximo del ticket está actualmente limitado por su saldo de';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'El valor máximo del ticket está actualmente limitado por su depósito de';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Considere agregar OXT al balance de su cuenta.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Considere agregar OXT a su depósito o transferir fondos de su saldo a su depósito.';

  @override
  String get prices => 'Precios';

  @override
  String get ticketValue => 'Valor del Ticket';

  @override
  String get costToRedeem => 'Coste de canjear:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Consulte los documentos para obtener ayuda sobre este problema.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Idóneo para navegar y actividad básica en la red';

  @override
  String get learnMore => 'Más información.';

  @override
  String get connect => 'Conéctate';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get wireguardHop => 'Hop WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Pega tu archivo de configuración WireGuard®️ aquí';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Pega la información de las credenciales de tu proveedor WireGuard®️ en el campo anterior.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => '¿Borrar todos los datos de registro?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Este registro de depuración no es permanente y se borrará al salir de la aplicación.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Puede contener información privada o de carácter personal.';

  @override
  String get loggingEnabled => 'Registro activado';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get logging => 'Registrando';

  @override
  String get loading => 'Cargando...';

  @override
  String get ethPrice => 'Precio de ETH:';

  @override
  String get oxtPrice => 'Precio de OXT:';

  @override
  String get gasPrice => 'Precio de GAS:';

  @override
  String get maxFaceValue => 'Valor nominal máximo:';

  @override
  String get confirmDelete => 'Confirmar eliminación';

  @override
  String get enterOpenvpnConfig => 'Introduce la configuración OpenVPN';

  @override
  String get enterWireguardConfig => 'Introduce la configuración WireGuard®️';

  @override
  String get starting => 'Iniciando...';

  @override
  String get legal => 'Legal';

  @override
  String get whatsNewInOrchid => 'Novedades de Orchid';

  @override
  String get orchidIsOnXdai => '¡Orchid disponible en xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      '¡Ahora puedes comprar créditos de Orchid en xDai! Empieza a usar la VPN por tan solo \$1 USD.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'Cuenta xDai para compras anteriores';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Para cualquier compra en la app realizada antes de hoy, los fondos xDai se han agregado a la misma clave de cuenta. ¡Utiliza el ancho de banda con nosotros!';

  @override
  String get newInterface => 'Nueva interfaz';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Las cuentas están organizadas ahora bajo la Dirección Orchid a la que están asociadas.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Consulta el saldo activo de tu cuenta y el coste del ancho de banda en la pantalla de inicio.';

  @override
  String get seeOrchidcomForHelp => 'Consulta orchid.com para obtener ayuda.';

  @override
  String get payPerUseVpnService => 'Servicio VPN de pago por uso';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Sin suscripción, los créditos no caducan';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Comparte la cuenta con dispositivos ilimitados';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'La Tienda Orchid no está disponible temporalmente. Vuelve en unos minutos.';

  @override
  String get talkingToPacServer =>
      'Comunicando con el Servidor de Cuentas Orchid';

  @override
  String get advancedConfiguration => 'Configuración avanzada';

  @override
  String get newWord => 'Nuevo';

  @override
  String get copied => 'Copiado';

  @override
  String get efficiency => 'Eficiencia';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Mínimo de tickets disponibles: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Transacción enviada a Blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Tu compra se ha completado y está siendo procesada por la blockchain de xDai, lo que puede tardar hasta un minuto, puede que más. Desliza hacia abajo para actualizar y que aparezca tu cuenta con el saldo actualizado.';

  @override
  String get copyReceipt => 'Copiar recibo';

  @override
  String get manageAccounts => 'Administrar Cuentas';

  @override
  String get configurationManagement => 'Gestión de la Configuración';

  @override
  String get exportThisOrchidKey => 'Exportar esta Clave Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'A continuación se muestra un código QR y un texto para todas las cuentas Orchid asociadas a esta clave.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Importa esta clave en otro dispositivo para compartir todas las cuentas Orchid asociadas a esta identidad Orchid.';

  @override
  String get orchidAccountInUse => 'Cuenta Orchid en uso';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Esta cuenta Orchid está en uso y no se puede eliminar.';

  @override
  String get pullToRefresh => 'Desliza hacia abajo para actualizar.';

  @override
  String get balance => 'Saldo';

  @override
  String get active => 'Activo';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Pega una clave Orchid del portapapeles para importar todas las cuentas Orchid asociadas a esa clave.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Escanea o pega una clave Orchid del portapapeles para importar todas las cuentas Orchid asociadas a esa clave.';

  @override
  String get account => 'Cuenta';

  @override
  String get transactions => 'Transacciones';

  @override
  String get weRecommendBackingItUp =>
      'Recomendamos <link>copia de seguridad</link>.';

  @override
  String get copiedOrchidIdentity => 'Identidad Orchid copiada';

  @override
  String get thisIsNotAWalletAddress => 'Esta no es una dirección de cartera.';

  @override
  String get doNotSendTokensToThisAddress =>
      'No enviar tokens a esta dirección.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Tu identidad Orchid te identifica de forma única en la red.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Obten más detalles sobre tu <link>Identidad Orchid</link>.';

  @override
  String get analyzingYourConnections => 'Analizando tus conexiones';

  @override
  String get analyzeYourConnections => 'Analiza tus conexiones';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'El análisis de Red utiliza la función VPN de tu dispositivo para capturar paquetes y analizar tu tráfico.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'El análisis de la Red requiere permisos de VPN, pero no protege tus datos ni oculta tu dirección IP por sí solo.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Para obtener los beneficios de la privacidad en la red, debes configurar y activar una conexión VPN desde la pantalla de inicio.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Activar esta función aumentará el uso de la batería de la app Orchid.';

  @override
  String get useAnOrchidAccount => 'Usar una cuenta Orchid';

  @override
  String get pasteAddress => 'Pegar dirección';

  @override
  String get chooseAddress => 'Elegir dirección';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Elige una cuenta Orchid para usar con este hop.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Si no ves tu cuenta abajo, puedes usar el administrador de cuentas para importar, comprar o crear una nueva.';

  @override
  String get selectAnOrchidAccount => 'Selecciona una Cuenta Orchid';

  @override
  String get takeMeToTheAccountManager => 'Ir al Administrador de cuentas';

  @override
  String get funderAccount => 'Cuenta del financiador';

  @override
  String get orchidRunningAndAnalyzing =>
      'Orchid está ejecutándose y analizando';

  @override
  String get startingVpn => '(Iniciando VPN)';

  @override
  String get disconnectingVpn => '(Desconectando VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid está analizando el tráfico';

  @override
  String get vpnConnectedButNotRouting =>
      '(VPN conectada pero sin enrutamiento)';

  @override
  String get restarting => 'Reiniciando';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Para cambiar el estado de monitoreo es necesario reiniciar la VPN, lo que podría interrumpir brevemente la protección de la privacidad.';

  @override
  String get confirmRestart => 'Confirmar reinicio';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'El precio medio es de $price USD por GB';
  }

  @override
  String get myOrchidConfig => 'Mi configuración de Orchid';

  @override
  String get noAccountSelected => 'Ninguna cuenta seleccionada';

  @override
  String get inactive => 'Inactivo';

  @override
  String get tickets => 'Tickets';

  @override
  String get accounts => 'Cuentas';

  @override
  String get orchidIdentity => 'Identidad Orchid';

  @override
  String get addFunds => 'AGREGAR FONDOS';

  @override
  String get addFunds2 => 'Añadir fondos';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Hop';

  @override
  String get circuit => 'Circuito';

  @override
  String get clearAllAnalysisData => '¿Borrar todos los datos de análisis?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Esta acción borrará todos los datos de conexión de tráfico previamente analizados.';

  @override
  String get clearAll => 'BORRAR TODO';

  @override
  String get stopAnalysis => 'DETENER ANÁLISIS';

  @override
  String get startAnalysis => 'INICIAR ANÁLISIS';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Las cuentas Orchid incluyen soporte al cliente 24/7, dispositivos ilimitados y están respaldadas por la <link2>criptomoneda xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Las cuentas compradas se conectan exclusivamente a nuestros <link1>proveedores preferidos</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Política de reembolso cubierta por las tiendas de apps.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid no puede mostrar las compras dentro de la app en este momento.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Por favor confirma que este dispositivo es compatible y está configurado para compras dentro de la app.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Por favor confirma que este dispositivo es compatible y está configurado para compras dentro de la app o la utilización de nuestro sistema de <link>gestión de cuentas</link> descentralizado.';

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
      'Tamaño ideal para uso intermedio o individual que incluye navegación y streaming ligero.';

  @override
  String get mostPopular => '¡Más popular!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Uso intenso del ancho de banda a largo plazo o cuentas compartidas.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'Pausando todo el tráfico...';

  @override
  String get queryingEthereumForARandom =>
      'Consultando Ethereum para un proveedor aleatorio...';

  @override
  String get quickFundAnAccount => '¡Agrega rápidamente fondos a una cuenta!';

  @override
  String get accountFound => 'Cuenta encontrada';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Encontramos una cuenta asociada con tus identidades y creamos un circuito Orchid de un solo hop para ella. Ahora estás listo para usar la VPN.';

  @override
  String get welcomeToOrchid => '¡Bienvenido a Orchid!';

  @override
  String get fundYourAccount => 'Agrega fondos a tu cuenta';

  @override
  String get processing => 'Procesando...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Servicio VPN de código abierto, descentralizado, sin suscripción y de pago por uso.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'COMIENZA POR $smallAmount';
  }

  @override
  String get importAccount => 'IMPORTAR CUENTA';

  @override
  String get illDoThisLater => 'Haré esto más tarde';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Conéctate automáticamente a uno de los <link1>proveedores preferidos</link1> de la red al comprar créditos VPN para agregar fondos a tu cuenta Orchid que es recargable y se puede compartir.';

  @override
  String get confirmPurchase => 'CONFIRMAR COMPRA';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Las cuentas Orchid usan créditos VPN respaldados por la <link>criptomoneda xDAI</link>, incluyen soporte al cliente 24/7, uso compartido ilimitado de dispositivos y están cubiertas por las políticas de reembolso de las tiendas de apps.';

  @override
  String get yourPurchaseIsInProgress => 'Tu compra está en curso.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Esta compra está tardando más de lo esperado en procesarse y es posible que se haya producido un error.';

  @override
  String get thisMayTakeAMinute => 'Esto puede tardar un minuto...';

  @override
  String get vpnCredits => 'Créditos VPN';

  @override
  String get blockchainFee => 'Tarifa de blockchain';

  @override
  String get promotion => 'Promoción';

  @override
  String get showInAccountManager => 'Mostrar en Administrador de cuentas';

  @override
  String get deleteThisOrchidIdentity => 'Eliminar esta identidad Orchid';

  @override
  String get chooseIdentity => 'Elegir identidad';

  @override
  String get updatingAccounts => 'Actualizando cuentas';

  @override
  String get trafficAnalysis => 'Análisis de tráfico';

  @override
  String get accountManager => 'Administrador de cuentas';

  @override
  String get circuitBuilder => 'Generador de circuitos';

  @override
  String get exitHop => 'Hop de salida';

  @override
  String get entryHop => 'Hop de entrada';

  @override
  String get addNewHop => 'AÑADIR NUEVO HOP';

  @override
  String get newCircuitBuilder => '¡Nuevo generador de circuitos!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Ahora puedes pagar un circuito Orchid de múltiples hops con xDAI. La interfaz multi-hops ahora admite cuentas Orchid de xDAI y OXT y aún admite configuraciones de OpenVPN y WireGuard que se pueden unir en una ruta de cebolla.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Administra tu conexión desde el generador de circuitos en lugar del administrador de cuentas. Todas las conexiones ahora usan un circuito con cero o más hops. Cualquier configuración existente se ha migrado al generador de circuitos.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Comienza rápidamente por $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Agregamos un método para comprar una cuenta Orchid y crear un circuito de un solo hop desde la pantalla de inicio para acortar el proceso de integración.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid es único como cliente de enrutamiento de múltiples hops o cebolla que admite varios protocolos VPN. Puedes configurar tu conexión al unir hops de los protocolos compatibles a continuación.\n\nUn hop es como una VPN normal. Tres hops (para usuarios avanzados) es la opción clásica para enrutamiento de cebolla. Cero hops permite el análisis del tráfico sin ningún túnel VPN.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Eliminar los hops de OpenVPN y Wireguard perderá las credenciales asociadas y la configuración de conexión. Asegúrate de hacer una copia de seguridad de la información antes de continuar.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Esto no se puede deshacer. Para guardar esta identidad, toca cancelar y usa la opción Exportar';

  @override
  String get unlockTime => 'Duración de desbloqueo';

  @override
  String get chooseChain => 'Elegir cadena';

  @override
  String get unlocking => 'desbloqueando';

  @override
  String get unlocked => 'Desbloqueado';

  @override
  String get orchidTransaction => 'Transacción Orchid';

  @override
  String get confirmations => 'Confirmaciones';

  @override
  String get pending => 'Pendiente...';

  @override
  String get txHash => 'Hash Tx:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Todos tus fondos están disponibles para retiro.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw de tus $totalFunds fondos combinados están disponibles actualmente para retiro.';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'También desbloquear depósito restante';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Si especificas un monto menor al valor total, los fondos serán retirados primero de tu saldo.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Para opciones adicionales, consulta el panel AVANZADO.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Si seleccionas la opción de desbloquear depósito, esta transacción retirará la cantidad especificada inmediatamente de tu saldo y comenzará el proceso de desbloqueo de tu depósito restante.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Los fondos de depósito están disponibles para retiro 24 horas después del desbloqueo.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Retira fondos de tu cuenta Orchid a tu cartera actual.';

  @override
  String get withdrawAndUnlockFunds => 'RETIRAR Y DESBLOQUEAR FONDOS';

  @override
  String get withdrawFunds => 'RETIRAR FONDOS';

  @override
  String get withdrawFunds2 => 'Retirar Fondos';

  @override
  String get withdraw => 'Retirar';

  @override
  String get submitTransaction => 'ENVIAR TRANSACCIÓN';

  @override
  String get move => 'Mover';

  @override
  String get now => 'Ahora';

  @override
  String get amount => 'Cantidad';

  @override
  String get available => 'Disponible';

  @override
  String get select => 'Seleccionar';

  @override
  String get add => 'AGREGAR';

  @override
  String get balanceToDeposit => 'SALDO A DEPÓSITO';

  @override
  String get depositToBalance => 'DEPÓSITO A SALDO';

  @override
  String get setWarnedAmount => 'Definir cantidad advertida';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Agrega fondos al saldo y/o depósito de tu cuenta Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Para obtener orientación sobre el tamaño de tu cuenta, visita <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Preautorización actual de $tokenType: $amount';
  }

  @override
  String get noWallet => 'Ninguna cartera';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Ninguna cartera o navegador no compatible.';

  @override
  String get error => 'Error';

  @override
  String get failedToConnectToWalletconnect =>
      'No se pudo conectar a WalletConnect.';

  @override
  String get unknownChain => 'Cadena desconocida';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'El administrador de cuentas Orchid aún no es compatible con esta cadena.';

  @override
  String get orchidIsntOnThisChain => 'Orchid no está en esta cadena.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'El contrato Orchid aún no se ha implementado en esta cadena.';

  @override
  String get moveFunds => 'MOVER FONDOS';

  @override
  String get moveFunds2 => 'Mover fondos';

  @override
  String get lockUnlock => 'BLOQUEAR/DESBLOQUEAR';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Tu depósito de $amount está desbloqueado.';
  }

  @override
  String get locked => 'bloqueado';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Tu depósito de $amount está $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Los fondos estarán disponibles para su retiro en \$$time.';
  }

  @override
  String get lockDeposit => 'BLOQUEAR DEPÓSITO';

  @override
  String get unlockDeposit => 'DESBLOQUEAR DEPÓSITO';

  @override
  String get advanced => 'AVANZADO';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Obtener más información sobre las cuentas Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Costo estimado de crear una cuenta Orchid con una eficiencia de $efficiency y $num tickets de valor.';
  }

  @override
  String get chain => 'Cadena';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Depósito mínimo';

  @override
  String get minBalance => 'Saldo mínimo';

  @override
  String get fundFee => 'Tarifa de fondo';

  @override
  String get withdrawFee => 'Tarifa de retiro';

  @override
  String get tokenValues => 'VALORES DE TOKEN';

  @override
  String get usdPrices => 'PRECIOS EN USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'La definición de una cantidad de depósito advertida inicia el periodo de espera de 24 horas requerido para retirar los fondos de depósito.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Durante este periodo, los fondos no están disponibles como un depósito válido en la red Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Los fondos se pueden volver a bloquear en cualquier momento al reducir la cantidad advertida.';

  @override
  String get warn => 'Advertir';

  @override
  String get totalWarnedAmount => 'Cantidad advertida total';

  @override
  String get newIdentity => 'Nueva identidad';

  @override
  String get importIdentity => 'Importar identidad';

  @override
  String get exportIdentity => 'Exportar identidad';

  @override
  String get deleteIdentity => 'Eliminar identidad';

  @override
  String get importOrchidIdentity => 'Importar identidad Orchid';

  @override
  String get funderAddress => 'Dirección del financiador';

  @override
  String get contract => 'Contrato';

  @override
  String get txFee => 'Cuota por Tx';

  @override
  String get show => 'Mostrar';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Errores';

  @override
  String get lastHour => 'Última hora';

  @override
  String get chainSettings => 'Configuración de cadena';

  @override
  String get price => 'Precio';

  @override
  String get failed => 'Error';

  @override
  String get fetchGasPrice => 'Buscar precio de gasolina';

  @override
  String get fetchLotteryPot => 'Buscar premio de lotería';

  @override
  String get lines => 'líneas';

  @override
  String get filtered => 'filtradas';

  @override
  String get backUpYourIdentity => 'Respalda tu Identidad';

  @override
  String get accountSetUp => 'Configuracion de cuenta';

  @override
  String get setUpAccount => 'Configurar la cuenta';

  @override
  String get generateIdentity => 'GENERAR IDENTIDAD';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Ingrese una <account_link>identidad de orquídea</account_link>existente';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Pegue la dirección de la billetera web3 que usará para depositar fondos en su cuenta a continuación.';

  @override
  String get funderWalletAddress => 'Dirección de la billetera del financiador';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Su dirección pública de Orchid Identity';

  @override
  String get continueButton => 'Continuar';

  @override
  String get yesIHaveSavedACopyOf =>
      'Sí, guardé una copia de mi clave privada en un lugar seguro.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Haga una copia de seguridad de su clave privada <bold>de Orchid Identity</bold>. Necesitará esta clave para compartir, importar o restaurar esta identidad y todas las cuentas asociadas.';

  @override
  String get locked1 => 'Bloqueado';

  @override
  String get unlockDeposit1 => 'Desbloquear depósito';

  @override
  String get changeWarnedAmountTo => 'Cambiar cantidad advertida a';

  @override
  String get setWarnedAmountTo => 'Establecer cantidad advertida en';

  @override
  String get currentWarnedAmount => 'Monto advertido actual';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Todos los fondos advertidos serán bloqueados hasta';

  @override
  String get balanceToDeposit1 => 'Saldo a depositar';

  @override
  String get depositToBalance1 => 'Depósito a Saldo';

  @override
  String get advanced1 => 'Avanzado';

  @override
  String get add1 => 'Añadir';

  @override
  String get lockUnlock1 => 'Bloqueo y desbloqueo';

  @override
  String get viewLogs => 'Ver los registros';

  @override
  String get language => 'idioma';

  @override
  String get systemDefault => 'Sistema por defecto';

  @override
  String get identiconStyle => 'Estilo de identificación';

  @override
  String get blockies => 'bloques';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => 'Versión del contrato';

  @override
  String get version0 => 'Versión 0';

  @override
  String get version1 => 'Versión 1';

  @override
  String get connectedWithMetamask => 'Conectado con Metamask';

  @override
  String get blockExplorer => 'Explorador de bloques';

  @override
  String get tapToMinimize => 'Toca para minimizar';

  @override
  String get connectWallet => 'Conectar billetera';

  @override
  String get checkWallet => 'Comprobar billetera';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Verifique su aplicación o extensión de Wallet para ver si hay una solicitud pendiente.';

  @override
  String get test => 'Prueba';

  @override
  String get chainName => 'Nombre de cadena';

  @override
  String get rpcUrl => 'URL de RPC';

  @override
  String get tokenPrice => 'Precio del token';

  @override
  String get tokenPriceUsd => 'Precio del token USD';

  @override
  String get addChain => 'Agregar cadena';

  @override
  String get deleteChainQuestion => '¿Eliminar cadena?';

  @override
  String get deleteUserConfiguredChain =>
      'Eliminar cadena configurada por el usuario';

  @override
  String get fundContractDeployer => 'Implementador de contratos de fondos';

  @override
  String get deploySingletonFactory => 'Implementar fábrica Singleton';

  @override
  String get deployContract => 'Contrato de implementación';

  @override
  String get about => 'Acerca de';

  @override
  String get dappVersion => 'Versión Dapp';

  @override
  String get viewContractOnEtherscan => 'Ver contrato en Etherscan';

  @override
  String get viewContractOnGithub => 'Ver contrato en Github';

  @override
  String get accountChanges => 'Cambios de cuenta';

  @override
  String get name => 'Nombre';

  @override
  String get step1 =>
      '<bold>Paso 1.</bold> Conecte una billetera ERC-20 con <link>tokens suficientes</link> en ella.';

  @override
  String get step2 =>
      '<bold>Paso 2.</bold> Copie la identidad de Orchid desde la aplicación Orchid yendo a Administrar cuentas y luego tocando la dirección.';

  @override
  String get connectOrCreate => 'Conectar o crear Cuenta Orquídea';

  @override
  String get lockDeposit2 => 'Depósito de bloqueo';

  @override
  String get unlockDeposit2 => 'Desbloquear depósito';

  @override
  String get enterYourWeb3 => 'Ingrese la dirección de su billetera web3.';

  @override
  String get purchaseComplete => 'Compra completada';

  @override
  String get generateNewIdentity => 'Generar una nueva Identidad';

  @override
  String get copyIdentity => 'Copiar identidad';

  @override
  String get yourPurchaseIsComplete =>
      'Su compra está completa y ahora está siendo procesada por la cadena de bloques xDai, lo que podría demorar unos minutos. Se ha generado un circuito predeterminado para usted utilizando esta cuenta. Puede monitorear el saldo disponible en la pantalla de inicio o en el administrador de cuenta.';

  @override
  String get circuitGenerated => 'circuito generado';

  @override
  String get usingYourOrchidAccount =>
      'Con su cuenta Orchid, se ha generado un circuito de un solo salto. Puede administrar esto desde la pantalla del generador de circuitos.';
}
