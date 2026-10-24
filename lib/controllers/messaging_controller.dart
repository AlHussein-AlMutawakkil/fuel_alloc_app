import 'package:flutter/foundation.dart';
import '../data/local/database_helper.dart';
import '../models/account_model.dart';
import '../models/message_template_model.dart';
import '../models/transaction_model.dart';
import '../services/messaging_service.dart';

/// كائن يحمل نصوص وبيانات الرسائل المجهزة لعملية معينة
class TransactionPreparedMessages {
  final String? beneficiaryMessage;
  final String? beneficiaryPhone;
  final bool shouldSendToBeneficiary;

  final String? stationMessage;
  final String? stationPhone;
  final bool shouldSendToStation;

  const TransactionPreparedMessages({
    this.beneficiaryMessage,
    this.beneficiaryPhone,
    this.shouldSendToBeneficiary = false,
    this.stationMessage,
    this.stationPhone,
    this.shouldSendToStation = false,
  });

  bool get hasAnyMessageToSend =>
      (shouldSendToBeneficiary && beneficiaryMessage != null && beneficiaryMessage!.isNotEmpty) ||
      (shouldSendToStation && stationMessage != null && stationMessage!.isNotEmpty);
}

/// متحكم إدارة نظام الرسائل النصية والقوالب والإعدادات
class MessagingController extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final MessagingService _messagingService = MessagingService.instance;

  List<MessageTemplateModel> _templates = [];
  bool _isMessagingEnabled = true;
  String _defaultChannel = 'sms'; // 'sms' | 'whatsapp'
  bool _autoPreviewEnabled = true;
  bool _notifyStationDefault = true;
  bool _notifyAccountDefault = true;
  bool _isLoading = false;

  List<MessageTemplateModel> get templates => _templates;
  bool get isMessagingEnabled => _isMessagingEnabled;
  String get defaultChannel => _defaultChannel;
  bool get autoPreviewEnabled => _autoPreviewEnabled;
  bool get notifyStationDefault => _notifyStationDefault;
  bool get notifyAccountDefault => _notifyAccountDefault;
  bool get isLoading => _isLoading;

  MessagingController() {
    loadSettingsAndTemplates();
  }

  /// تحميل كافة القوالب والإعدادات من قاعدة البيانات
  Future<void> loadSettingsAndTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _dbHelper.getMessageTemplates();

      final enabledStr = await _dbHelper.getSetting('messaging_enabled');
      _isMessagingEnabled = enabledStr != 'false';

      final channelStr = await _dbHelper.getSetting('messaging_default_channel');
      _defaultChannel = (channelStr == 'whatsapp') ? 'whatsapp' : 'sms';

      final autoPreviewStr = await _dbHelper.getSetting('messaging_auto_preview');
      _autoPreviewEnabled = autoPreviewStr != 'false';

      final notifyStationStr = await _dbHelper.getSetting('messaging_notify_station_default');
      _notifyStationDefault = notifyStationStr != 'false';

      final notifyAccStr = await _dbHelper.getSetting('messaging_notify_account_default');
      _notifyAccountDefault = notifyAccStr != 'false';
    } catch (e) {
      debugPrint('Error loading messaging settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تفعيل أو تعطيل نظام الرسائل بالكامل
  Future<void> setMessagingEnabled(bool value) async {
    _isMessagingEnabled = value;
    notifyListeners();
    await _dbHelper.setSetting('messaging_enabled', value ? 'true' : 'false');
  }

  /// تعيين القناة الافتراضية المفضلة (sms أو whatsapp)
  Future<void> setDefaultChannel(String channel) async {
    _defaultChannel = channel;
    notifyListeners();
    await _dbHelper.setSetting('messaging_default_channel', channel);
  }

  /// تفعيل أو تعطيل نافذة المعاينة التلقائية بعد كل عملية
  Future<void> setAutoPreviewEnabled(bool value) async {
    _autoPreviewEnabled = value;
    notifyListeners();
    await _dbHelper.setSetting('messaging_auto_preview', value ? 'true' : 'false');
  }

  /// تعيين الخيار الافتراضي لإشعار المحطة
  Future<void> setNotifyStationDefault(bool value) async {
    _notifyStationDefault = value;
    notifyListeners();
    await _dbHelper.setSetting('messaging_notify_station_default', value ? 'true' : 'false');
  }

  /// تعيين الخيار الافتراضي لإشعار العميل / المستفيد
  Future<void> setNotifyAccountDefault(bool value) async {
    _notifyAccountDefault = value;
    notifyListeners();
    await _dbHelper.setSetting('messaging_notify_account_default', value ? 'true' : 'false');
  }

  /// تحديث نص قالب محدد
  Future<bool> updateTemplate(String key, String newContent) async {
    try {
      await _dbHelper.updateMessageTemplate(key, newContent);
      final index = _templates.indexWhere((t) => t.key == key);
      if (index != -1) {
        _templates[index] = _templates[index].copyWith(
          content: newContent,
          updatedAt: DateTime.now().toIso8601String(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating template $key: $e');
      return false;
    }
  }

  /// استعادة جميع القوالب للوضع الافتراضي
  Future<bool> resetTemplatesToDefault() async {
    try {
      await _dbHelper.resetMessageTemplatesToDefault();
      _templates = await _dbHelper.getMessageTemplates();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resetting templates: $e');
      return false;
    }
  }

  /// تجهيز نصوص وبيانات الرسائل لعملية محددة بناءً على نوعها والحسابات المرتبطة بها
  TransactionPreparedMessages prepareMessagesForTransaction({
    required TransactionModel transaction,
    AccountModel? account,
    AccountModel? station,
    double? remainingBalance,
  }) {
    if (!_isMessagingEnabled) {
      return const TransactionPreparedMessages();
    }

    // 1. تجهيز رسالة المستفيد / العميل
    String? beneficiaryMsg;
    String? beneficiaryPhone = account?.effectivePhone ?? transaction.accountPhone;
    bool shouldSendBeneficiary = false;

    if (account == null || account.isMessagingEnabled) {
      if (beneficiaryPhone != null && beneficiaryPhone.trim().isNotEmpty) {
        shouldSendBeneficiary = _notifyAccountDefault;

        // التحقق إن كان للحساب قالب مخصص
        if (account?.customSmsTemplate != null &&
            account!.customSmsTemplate!.trim().isNotEmpty) {
          beneficiaryMsg = _messagingService.populateTemplate(
            templateContent: account.customSmsTemplate!,
            transaction: transaction,
            account: account,
            station: station,
            remainingBalance: remainingBalance,
          );
        } else {
          // استخدام القالب العام بحسب نوع العملية
          String templateKey = 'beneficiary_dispense';
          if (transaction.typeId == 1 || transaction.typeId == 2) {
            templateKey = 'supplier_supply';
          } else if (transaction.typeId == 6 || transaction.typeId == 7) {
            templateKey = 'transfer';
          }

          final tpl = _templates.firstWhere(
            (t) => t.key == templateKey,
            orElse: () => const MessageTemplateModel(
              key: 'default',
              title: 'افتراضي',
              targetType: 'BENEFICIARY',
              operationType: 'DISPENSE',
              content: MessageTemplateModel.defaultBeneficiaryDispense,
            ),
          );

          beneficiaryMsg = _messagingService.populateTemplate(
            templateContent: tpl.content,
            transaction: transaction,
            account: account,
            station: station,
            remainingBalance: remainingBalance,
          );
        }
      }
    }

    // 2. تجهيز رسالة المحطة (أمر الصرف أو إشعار التوريد)
    String? stationMsg;
    String? stationPhone = station?.effectivePhone;
    bool shouldSendStation = false;

    if (station != null && station.isMessagingEnabled) {
      if (stationPhone != null && stationPhone.trim().isNotEmpty) {
        shouldSendStation = _notifyStationDefault;

        if (station.customSmsTemplate != null &&
            station.customSmsTemplate!.trim().isNotEmpty) {
          stationMsg = _messagingService.populateTemplate(
            templateContent: station.customSmsTemplate!,
            transaction: transaction,
            account: account,
            station: station,
            remainingBalance: remainingBalance,
          );
        } else {
          final tpl = _templates.firstWhere(
            (t) => t.key == 'station_dispense',
            orElse: () => const MessageTemplateModel(
              key: 'station_dispense',
              title: 'أمر صرف',
              targetType: 'STATION',
              operationType: 'DISPENSE',
              content: MessageTemplateModel.defaultStationDispense,
            ),
          );

          stationMsg = _messagingService.populateTemplate(
            templateContent: tpl.content,
            transaction: transaction,
            account: account,
            station: station,
            remainingBalance: remainingBalance,
          );
        }
      }
    }

    return TransactionPreparedMessages(
      beneficiaryMessage: beneficiaryMsg,
      beneficiaryPhone: beneficiaryPhone,
      shouldSendToBeneficiary: shouldSendBeneficiary,
      stationMessage: stationMsg,
      stationPhone: stationPhone,
      shouldSendToStation: shouldSendStation,
    );
  }

  /// إرسال عبر SMS
  Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    return await _messagingService.sendSms(
      phoneNumber: phone,
      message: message,
    );
  }

  /// إرسال عبر WhatsApp
  Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    return await _messagingService.sendWhatsApp(
      phoneNumber: phone,
      message: message,
    );
  }
}
