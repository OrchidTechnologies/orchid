// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static m0(num) => "${Intl.plural(num, other: '${num} 个已配置跃点')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "addAccount" : MessageLookupByLibrary.simpleMessage("添加帐户"),
    "addHop" : MessageLookupByLibrary.simpleMessage("添加跃点"),
    "addOrchidAccount" : MessageLookupByLibrary.simpleMessage("添加 Orchid 帐户"),
    "advanced" : MessageLookupByLibrary.simpleMessage("高级"),
    "allowNoHopVPN" : MessageLookupByLibrary.simpleMessage("允许无跃点 VPN"),
    "amount" : MessageLookupByLibrary.simpleMessage("金额"),
    "beta" : MessageLookupByLibrary.simpleMessage("beta"),
    "budget" : MessageLookupByLibrary.simpleMessage("预算"),
    "cancelButtonTitle" : MessageLookupByLibrary.simpleMessage("取消"),
    "changesWillTakeEffectInstruction" : MessageLookupByLibrary.simpleMessage("重新启动 VPN 后，更改将随之生效。"),
    "chooseKey" : MessageLookupByLibrary.simpleMessage("选择密钥"),
    "clear" : MessageLookupByLibrary.simpleMessage("清除"),
    "config" : MessageLookupByLibrary.simpleMessage("配置"),
    "configuration" : MessageLookupByLibrary.simpleMessage("配置"),
    "configurationFailedInstruction" : MessageLookupByLibrary.simpleMessage("无法保存配置，请检查语法并重试。"),
    "configurationSaved" : MessageLookupByLibrary.simpleMessage("配置已保存"),
    "confirmThisAction" : MessageLookupByLibrary.simpleMessage("确认此操作"),
    "connectionDetail" : MessageLookupByLibrary.simpleMessage("连接详情"),
    "copy" : MessageLookupByLibrary.simpleMessage("复制"),
    "createFirstHop" : MessageLookupByLibrary.simpleMessage("创建您的第一个跃点以保护连接。"),
    "createInstruction1" : MessageLookupByLibrary.simpleMessage("要创建 Orchid 跃点，您需要 Orchid 帐户。"),
    "createInstructions2" : MessageLookupByLibrary.simpleMessage("在 Web3 浏览器中打开并遵循后续步骤。在您的下列以太坊地址中粘贴。"),
    "createOrchidAccount" : MessageLookupByLibrary.simpleMessage("创建 Orchid 帐户"),
    "credentials" : MessageLookupByLibrary.simpleMessage("凭据"),
    "curation" : MessageLookupByLibrary.simpleMessage("集展"),
    "curator" : MessageLookupByLibrary.simpleMessage("集展人"),
    "defaultCurator" : MessageLookupByLibrary.simpleMessage("默认集展人"),
    "delete" : MessageLookupByLibrary.simpleMessage("删除"),
    "deleteAllData" : MessageLookupByLibrary.simpleMessage("删除所有数据"),
    "deposit" : MessageLookupByLibrary.simpleMessage("存款"),
    "destination" : MessageLookupByLibrary.simpleMessage("目的地"),
    "destinationPort" : MessageLookupByLibrary.simpleMessage("目的端口"),
    "enterLoginInformationInstruction" : MessageLookupByLibrary.simpleMessage("输入以上 VPN 提供商的登录信息，然后粘贴提供商的 OpenVPN 配置文件内容至所提供的字段中。"),
    "enterYourCredentials" : MessageLookupByLibrary.simpleMessage("输入您的凭据"),
    "ethereumAddress" : MessageLookupByLibrary.simpleMessage("以太坊地址"),
    "export" : MessageLookupByLibrary.simpleMessage("导出"),
    "exportHopsConfiguration" : MessageLookupByLibrary.simpleMessage("导出跃点配置"),
    "generateNewKey" : MessageLookupByLibrary.simpleMessage("生成新密钥"),
    "help" : MessageLookupByLibrary.simpleMessage("帮助"),
    "hops" : MessageLookupByLibrary.simpleMessage("跃点"),
    "host" : MessageLookupByLibrary.simpleMessage("主机"),
    "iHaveAQRCode" : MessageLookupByLibrary.simpleMessage("我有二维码"),
    "iHaveAVPNSubscription" : MessageLookupByLibrary.simpleMessage("我有订购 VPN"),
    "iWantToTryOrchid" : MessageLookupByLibrary.simpleMessage("我想试用 Orchid"),
    "import" : MessageLookupByLibrary.simpleMessage("导入"),
    "importHopsConfiguration" : MessageLookupByLibrary.simpleMessage("导入跃点配置"),
    "importKey" : MessageLookupByLibrary.simpleMessage("导入密钥"),
    "inYourWalletBrowserInstruction" : MessageLookupByLibrary.simpleMessage("在您钱包的浏览器中加载，然后开始。"),
    "invalidCode" : MessageLookupByLibrary.simpleMessage("无效代码"),
    "invalidQRCode" : MessageLookupByLibrary.simpleMessage("无效二维码"),
    "learnMoreButtonTitle" : MessageLookupByLibrary.simpleMessage("了解更多"),
    "loadMsg" : MessageLookupByLibrary.simpleMessage("加载"),
    "log" : MessageLookupByLibrary.simpleMessage("日志"),
    "manageConfiguration" : MessageLookupByLibrary.simpleMessage("管理配置"),
    "myOrchidAccount" : MessageLookupByLibrary.simpleMessage("我的 Orchid 帐户"),
    "needMoreHelp" : MessageLookupByLibrary.simpleMessage("需要更多帮助"),
    "newContent" : MessageLookupByLibrary.simpleMessage("新内容"),
    "newHop" : MessageLookupByLibrary.simpleMessage("新跃点"),
    "noVersion" : MessageLookupByLibrary.simpleMessage("无版本"),
    "nothingToDisplayYet" : MessageLookupByLibrary.simpleMessage("尚无内容可供显示。存在可显示内容时，将于此处显示流量。"),
    "numHopsConfigured" : m0,
    "ok" : MessageLookupByLibrary.simpleMessage("好"),
    "okButtonTitle" : MessageLookupByLibrary.simpleMessage("好"),
    "openSourceLicenses" : MessageLookupByLibrary.simpleMessage("开源许可"),
    "openVPN" : MessageLookupByLibrary.simpleMessage("OpenVPN"),
    "openVPNHop" : MessageLookupByLibrary.simpleMessage("OpenVPN 跃点"),
    "orchid" : MessageLookupByLibrary.simpleMessage("Orchid"),
    "orchidConnecting" : MessageLookupByLibrary.simpleMessage("正在连接 Orchid"),
    "orchidDisabled" : MessageLookupByLibrary.simpleMessage("Orchid 已禁用"),
    "orchidDisconnecting" : MessageLookupByLibrary.simpleMessage("正在断开连接 Orchid"),
    "orchidHop" : MessageLookupByLibrary.simpleMessage("Orchid 跃点"),
    "orchidOverview" : MessageLookupByLibrary.simpleMessage("Orchid 概述"),
    "orchidRequiresAccountInstruction" : MessageLookupByLibrary.simpleMessage("Orchid 需要 Orchid 帐户。扫描或粘贴您现有的下列帐户即可开始体验。"),
    "orchidRequiresOXT" : MessageLookupByLibrary.simpleMessage("Orchid 需要 OXT 币"),
    "oxt" : MessageLookupByLibrary.simpleMessage("OXT 币"),
    "password" : MessageLookupByLibrary.simpleMessage("密码"),
    "paste" : MessageLookupByLibrary.simpleMessage("粘贴"),
    "pasteYourOVPN" : MessageLookupByLibrary.simpleMessage("请在此处粘贴 OVPN 配置"),
    "privacyPolicy" : MessageLookupByLibrary.simpleMessage("隐私政策"),
    "queryBalances" : MessageLookupByLibrary.simpleMessage("查询余额"),
    "rateLimit" : MessageLookupByLibrary.simpleMessage("评价限制"),
    "readTheGuide" : MessageLookupByLibrary.simpleMessage("阅读本指南"),
    "reset" : MessageLookupByLibrary.simpleMessage("重置"),
    "save" : MessageLookupByLibrary.simpleMessage("保存"),
    "saveButtonTitle" : MessageLookupByLibrary.simpleMessage("保存"),
    "saved" : MessageLookupByLibrary.simpleMessage("已保存"),
    "scan" : MessageLookupByLibrary.simpleMessage("扫描"),
    "search" : MessageLookupByLibrary.simpleMessage("搜索"),
    "selectYourHop" : MessageLookupByLibrary.simpleMessage("选择跃点"),
    "settings" : MessageLookupByLibrary.simpleMessage("设置"),
    "settingsButtonTitle" : MessageLookupByLibrary.simpleMessage("设置"),
    "setup" : MessageLookupByLibrary.simpleMessage("设置"),
    "shareOrchidAccount" : MessageLookupByLibrary.simpleMessage("分享 Orchid 帐户"),
    "showInstructions" : MessageLookupByLibrary.simpleMessage("显示说明"),
    "showStatusPage" : MessageLookupByLibrary.simpleMessage("显示状态页面"),
    "signerKey" : MessageLookupByLibrary.simpleMessage("签名者密钥"),
    "sourcePort" : MessageLookupByLibrary.simpleMessage("源端口"),
    "status" : MessageLookupByLibrary.simpleMessage("状态"),
    "theCodeYouPastedDoesNot" : MessageLookupByLibrary.simpleMessage("您粘贴的代码未包含有效帐户配置。"),
    "theQRCodeYouScannedDoesNot" : MessageLookupByLibrary.simpleMessage("您扫描的二维码未包含有效帐户配置。"),
    "thisReleaseVPNInstruction" : MessageLookupByLibrary.simpleMessage("此版本是 Orchid 的高级 VPN 客户端，支持多跃点和本地流量分析。"),
    "thisWillDeleteRecorded" : MessageLookupByLibrary.simpleMessage("此操作将删除应用中所有已记录的流量数据。"),
    "time" : MessageLookupByLibrary.simpleMessage("时间"),
    "toGetStartedInstruction" : MessageLookupByLibrary.simpleMessage("首先，请启用 VPN。"),
    "traffic" : MessageLookupByLibrary.simpleMessage("流量"),
    "trafficListView" : MessageLookupByLibrary.simpleMessage("流量列表视图"),
    "trafficMonitoringOnly" : MessageLookupByLibrary.simpleMessage("仅流量监控"),
    "turnOnToActivate" : MessageLookupByLibrary.simpleMessage("打开 Orchid，激活您的跃点并保护流量"),
    "username" : MessageLookupByLibrary.simpleMessage("用户名"),
    "version" : MessageLookupByLibrary.simpleMessage("版本"),
    "viewOrModifyRateLimit" : MessageLookupByLibrary.simpleMessage("查看或修改评价限制。"),
    "warningExportedConfiguration" : MessageLookupByLibrary.simpleMessage("警告： 导出的配置包括已导出跃点的签名者私钥机密。 泄露私钥可能导致您损失相关 Orchid 帐户中的所有资金。"),
    "warningImportedConfiguration" : MessageLookupByLibrary.simpleMessage("警告： 导入的配置将替换您在应用中创建的任何现有跃点。 以前在此设备上生成或导入的签名者密钥将保留，且仍然可用于创建新跃点，但所有其他配置（包括 OpenVPN 跃点配置）都将丢失。"),
    "warningThesefeature" : MessageLookupByLibrary.simpleMessage("警告： 这些功能仅适用于高级用户。 请阅读所有说明。"),
    "welcomeToOrchid" : MessageLookupByLibrary.simpleMessage("欢迎使用 Orchid"),
    "whoops" : MessageLookupByLibrary.simpleMessage("糟糕"),
    "youNeedEthereumWallet" : MessageLookupByLibrary.simpleMessage("您需要一个以太坊钱包才能创建 Orchid 帐户。")
  };
}
