import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fuel_alloc_app/controllers/messaging_controller.dart';
import 'package:fuel_alloc_app/core/constants/app_icons.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/core/widgets/operation_message_preview_dialog.dart';
import 'package:fuel_alloc_app/models/account_model.dart';
import 'package:fuel_alloc_app/models/message_template_model.dart';
import 'package:fuel_alloc_app/models/transaction_model.dart';
import 'package:fuel_alloc_app/services/messaging_service.dart';

void main() {
  group('Messaging System Unit & Integration Tests', () {
    test('1. Phone sanitization and WhatsApp formatting tests', () {
      expect(MessagingService.sanitizePhoneNumber('050 123-4567'), equals('0501234567'));
      expect(MessagingService.sanitizePhoneNumber('+967 (77) 123-456'), equals('+96777123456'));
      expect(MessagingService.sanitizePhoneNumber(null), isEmpty);

      // WhatsApp format with default country code (+967 for Yemen)
      expect(MessagingService.formatPhoneForWhatsApp('771234567'), equals('967771234567'));
      expect(MessagingService.formatPhoneForWhatsApp('+967771234567'), equals('967771234567'));
      expect(MessagingService.formatPhoneForWhatsApp('00967771234567'), equals('967771234567'));
      expect(MessagingService.formatPhoneForWhatsApp('0771234567'), equals('967771234567'));
    });

    test('2. Dynamic template placeholders replacement tests', () {
      final tx = TransactionModel(
        id: 101,
        transactionNumber: 'TX-9901',
        transactionDate: '2026-10-24T15:30:00',
        typeId: 4,
        typeName: 'صرف اعتماد',
        accountId: 5,
        accountName: 'مؤسسة الأمل',
        stationId: 2,
        stationName: 'محطة السلام',
        unitId: 1,
        unitName: 'لتر',
        fuelTypeId: 1,
        fuelTypeName: 'بترول',
        enteredQuantity: 350.0,
        baseQuantityLiters: 350.0,
        referenceNumber: 'REF-772',
        recipientName: 'سالم أحمد',
        notes: 'سيارة هايلوكس',
      );

      final account = AccountModel(
        id: 5,
        name: 'مؤسسة الأمل',
        accountType: AccountType.beneficiary,
        phoneNumber: '770112233',
      );

      final station = AccountModel(
        id: 2,
        name: 'محطة السلام',
        accountType: AccountType.station,
        phoneNumber: '779988776',
      );

      const template =
          'أمر صرف:\n'
          'إلى {اسم_المحطة}، يرجى صرف {الكمية} {الوحدة} {نوع_الوقود} للعميل {اسم_العميل} '
          '(المستلم: {اسم_المستلم}). مرجع: {رقم_المرجع}، عملية: {رقم_العملية}. رصيد: {الرصيد_المتبقي}.';

      final populated = MessagingService.instance.populateTemplate(
        templateContent: template,
        transaction: tx,
        account: account,
        station: station,
        remainingBalance: 1250.0,
      );

      expect(populated, contains('محطة السلام'));
      expect(populated, contains('350'));
      expect(populated, contains('لتر'));
      expect(populated, contains('بترول'));
      expect(populated, contains('مؤسسة الأمل'));
      expect(populated, contains('سالم أحمد'));
      expect(populated, contains('REF-772'));
      expect(populated, contains('TX-9901'));
      expect(populated, contains('1,250'));
    });

    test('3. English and Arabic placeholders are both supported', () {
      final tx = TransactionModel(
        transactionNumber: 'TX-1',
        transactionDate: '2026-10-24',
        typeId: 4,
        typeName: 'صرف',
        accountName: 'Ali',
        stationName: 'Shell',
        unitId: 1,
        unitName: 'L',
        fuelTypeName: 'Gas',
        enteredQuantity: 50.0,
        baseQuantityLiters: 50.0,
      );

      const templateEng = '{account_name} at {station_name}: {quantity} {unit} of {fuel_type}. Ref: {transaction_no}';
      final populatedEng = MessagingService.instance.populateTemplate(
        templateContent: templateEng,
        transaction: tx,
      );

      expect(populatedEng, equals('Ali at Shell: 50 L of Gas. Ref: TX-1'));
    });

    test('4. MessageTemplateModel toMap and fromMap serialization', () {
      const tpl = MessageTemplateModel(
        id: 1,
        key: 'station_dispense',
        title: 'أمر صرف',
        targetType: 'STATION',
        operationType: 'DISPENSE',
        content: 'نص القالب التجريبي',
        isActive: true,
      );

      final map = tpl.toMap();
      expect(map['template_key'], equals('station_dispense'));
      expect(map['title'], equals('أمر صرف'));
      expect(map['target_type'], equals('STATION'));

      final restored = MessageTemplateModel.fromMap(map);
      expect(restored.key, equals('station_dispense'));
      expect(restored.title, equals('أمر صرف'));
      expect(restored.content, equals('نص القالب التجريبي'));
      expect(restored.isActive, isTrue);
    });

    test('5. AccountModel messaging fields and effectivePhone getter', () {
      final acc1 = AccountModel(
        id: 10,
        name: 'عميل 1',
        accountType: AccountType.beneficiary,
        phoneNumber: '771122334',
        isMessagingEnabled: true,
      );
      expect(acc1.isMessagingEnabled, isTrue);
      expect(acc1.effectivePhone, equals('771122334'));

      final acc2 = AccountModel(
        id: 11,
        name: 'عميل 2',
        accountType: AccountType.beneficiary,
        phoneNumber: '771122334',
        notificationPhone: '775566778',
        customSmsTemplate: 'قالب خاص بالعميل 2',
        isMessagingEnabled: false,
      );
      expect(acc2.isMessagingEnabled, isFalse);
      expect(acc2.effectivePhone, equals('775566778'));
      expect(acc2.customSmsTemplate, equals('قالب خاص بالعميل 2'));

      final map = acc2.toMap();
      expect(map['is_messaging_enabled'], equals(0));
      expect(map['custom_sms_template'], equals('قالب خاص بالعميل 2'));
      expect(map['notification_phone'], equals('775566778'));

      final fromMapAcc = AccountModel.fromMap(map);
      expect(fromMapAcc.isMessagingEnabled, isFalse);
      expect(fromMapAcc.effectivePhone, equals('775566778'));
      expect(fromMapAcc.customSmsTemplate, equals('قالب خاص بالعميل 2'));
    });

    test('6. Centralized Messaging Design Tokens in AppStrings and AppIcons', () {
      expect(AppStrings.messageSettingsTitle.isNotEmpty, isTrue);
      expect(AppStrings.enableMessagingTitle.isNotEmpty, isTrue);
      expect(AppStrings.preferredChannelTitle.isNotEmpty, isTrue);
      expect(AppStrings.channelSms.isNotEmpty, isTrue);
      expect(AppStrings.channelWhatsApp.isNotEmpty, isTrue);
      expect(AppStrings.autoPreviewTitle.isNotEmpty, isTrue);
      expect(AppStrings.messageTemplatesSection.isNotEmpty, isTrue);
      expect(AppStrings.sendSmsButton.isNotEmpty, isTrue);
      expect(AppStrings.sendWhatsAppButton.isNotEmpty, isTrue);
      expect(AppStrings.operationMessagesTitle.isNotEmpty, isTrue);

      expect(AppIcons.message, isNotNull);
      expect(AppIcons.sms, isNotNull);
      expect(AppIcons.whatsapp, isNotNull);
      expect(AppIcons.template, isNotNull);
      expect(AppIcons.send, isNotNull);
      expect(AppIcons.preview, isNotNull);
    });

    testWidgets('7. OperationMessagePreviewDialog renders with editable fields and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final tx = TransactionModel(
        transactionNumber: 'TX-100',
        transactionDate: '2026-10-24',
        typeId: 4,
        typeName: 'صرف اعتماد',
        accountName: 'شركة النور',
        stationName: 'محطة الفهد',
        unitId: 1,
        unitName: 'لتر',
        enteredQuantity: 200,
        baseQuantityLiters: 200,
      );

      const prepared = TransactionPreparedMessages(
        beneficiaryMessage: 'عزيزي شركة النور تم صرف 200 لتر',
        beneficiaryPhone: '770001111',
        shouldSendToBeneficiary: true,
        stationMessage: 'أمر صرف إلى محطة الفهد 200 لتر',
        stationPhone: '772223333',
        shouldSendToStation: true,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MessagingController(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    OperationMessagePreviewDialog.show(
                      context: ctx,
                      preparedMessages: prepared,
                      transaction: tx,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('صرف اعتماد'), findsOneWidget);
      expect(find.text(AppStrings.beneficiaryNotice), findsOneWidget);
      expect(find.text(AppStrings.stationOrder), findsOneWidget);
      expect(find.text('770001111'), findsOneWidget);
      expect(find.text('772223333'), findsOneWidget);

      // Verify Execute and Cancel buttons, and close icon are rendered
      expect(find.text(AppStrings.execute), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
      expect(find.byIcon(AppIcons.closeRounded), findsOneWidget);
    });

    test('8. SMS URI encoding uses %20 for spaces and never plus signs', () {
      const message = 'عزيزي خالد عبدالله، تم بنجاح صرف 50 لتر';
      final encodedBody = Uri.encodeComponent(message);

      // Verify percent-encoded spaces
      expect(encodedBody, contains('%20'));
      expect(encodedBody, isNot(contains('+')));

      final uri = Uri.parse('sms:771234567?body=$encodedBody');
      expect(uri.scheme, equals('sms'));
      expect(uri.path, equals('771234567'));
      expect(uri.toString(), contains('%20'));
      expect(uri.toString(), isNot(contains('+')));
    });

    test('9. populateTemplate handles transactions with null metadata via fallback IDs', () {
      // Transaction with only IDs and no pre-joined text names
      final rawTx = TransactionModel(
        id: 77,
        transactionDate: '2026-10-24',
        typeId: 4, // صرف اعتماد
        accountId: 10,
        stationId: 5,
        unitId: 1, // لتر
        fuelTypeId: 2, // ديزل
        enteredQuantity: 50.0,
        baseQuantityLiters: 50.0,
      );

      final account = AccountModel(
        id: 10,
        name: 'خالد عبدالله',
        accountType: AccountType.beneficiary,
        phoneNumber: '771234567',
      );

      final station = AccountModel(
        id: 5,
        name: 'محطة الخير',
        accountType: AccountType.station,
      );

      final populated = MessagingService.instance.populateTemplate(
        templateContent: MessageTemplateModel.defaultBeneficiaryDispense,
        transaction: rawTx,
        account: account,
        station: station,
        remainingBalance: 0.0,
      );

      // Verify that NO placeholder remained empty or unreplaced
      expect(populated, contains('خالد عبدالله'));
      expect(populated, contains('صرف اعتماد'));
      expect(populated, contains('50'));
      expect(populated, contains('لتر'));
      expect(populated, contains('ديزل'));
      expect(populated, contains('محطة الخير'));
      expect(populated, contains('رقم العملية: TX-77'));
      expect(populated, contains('رصيدك المتبقي: 0 لتر'));
      expect(populated, isNot(contains('{')));
      expect(populated, isNot(contains('}')));
      expect(populated, isNot(contains('()'))); // Fuel type was resolved!
    });
  });
}

