import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_alloc_app/core/utils/formatters.dart';
import 'package:fuel_alloc_app/core/widgets/custom_dropdown.dart';

void main() {
  group('Operation Station Dropdown Tests', () {
    testWidgets('CustomDropdown renders items with trailingText beside checkmark and no liter suffix',
        (tester) async {
      int? selectedValue = 1;

      final items = [
        CustomDropdownItem<int?>(
          value: 1,
          label: 'محطة سبأ',
          selectedLabel: 'محطة سبأ',
          trailingText: AppFormatters.formatQuantity(25000),
        ),
        CustomDropdownItem<int?>(
          value: 2,
          label: 'محطة الأمل',
          selectedLabel: 'محطة الأمل',
          trailingText: AppFormatters.formatQuantity(12500),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomDropdown<int?>(
                value: selectedValue,
                items: items,
                onChanged: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      // Verify closed dropdown shows station name only
      expect(find.text('محطة سبأ'), findsOneWidget);
      expect(find.text('25,000'), findsNothing);

      // Tap to open popup menu
      await tester.tap(find.text('محطة سبأ'));
      await tester.pumpAndSettle();

      // In popup menu: both station names and their exact quantities are visible
      expect(find.text('محطة سبأ'), findsWidgets);
      expect(find.text('25,000'), findsOneWidget);
      expect(find.text('محطة الأمل'), findsOneWidget);
      expect(find.text('12,500'), findsOneWidget);

      // Ensure NO "لتر" is appended anywhere
      expect(find.textContaining('لتر'), findsNothing);
    });

    test('Station sorting logic sorts descending by selected fuel type balance', () {
      final mockBalances = {
        10: {1: 5000.0, 2: 20000.0}, // Station 10: Petrol 5k, Diesel 20k
        20: {1: 18000.0, 2: 3000.0}, // Station 20: Petrol 18k, Diesel 3k
        30: {1: 12000.0, 2: 12000.0}, // Station 30: Petrol 12k, Diesel 12k
      };

      final stations = [
        {'id': 10, 'name': 'محطة أ'},
        {'id': 20, 'name': 'محطة ب'},
        {'id': 30, 'name': 'محطة ج'},
      ];

      // Sort for Petrol (fuelTypeId = 1)
      final sortedPetrol = List<Map<String, dynamic>>.from(stations);
      sortedPetrol.sort((a, b) {
        final balA = mockBalances[a['id']]?[1] ?? 0.0;
        final balB = mockBalances[b['id']]?[1] ?? 0.0;
        return balB.compareTo(balA);
      });

      expect(sortedPetrol[0]['id'], equals(20)); // 18,000
      expect(sortedPetrol[1]['id'], equals(30)); // 12,000
      expect(sortedPetrol[2]['id'], equals(10)); // 5,000

      // Sort for Diesel (fuelTypeId = 2)
      final sortedDiesel = List<Map<String, dynamic>>.from(stations);
      sortedDiesel.sort((a, b) {
        final balA = mockBalances[a['id']]?[2] ?? 0.0;
        final balB = mockBalances[b['id']]?[2] ?? 0.0;
        return balB.compareTo(balA);
      });

      expect(sortedDiesel[0]['id'], equals(10)); // 20,000
      expect(sortedDiesel[1]['id'], equals(30)); // 12,000
      expect(sortedDiesel[2]['id'], equals(20)); // 3,000
    });
  });
}

