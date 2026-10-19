import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import 'app_loading_indicator.dart';
import 'app_snackbar.dart';
import 'custom_text_field.dart';
import 'empty_state_widget.dart';

/// ورقة سفلية بنمط One UI لاختيار جهة اتصال وتعبئة الاسم ورقم الهاتف
class ContactPickerSheet extends StatefulWidget {
  const ContactPickerSheet({super.key});

  /// إظهار منتقي جهات الاتصال وإرجاع الزوج (الاسم، الهاتف)
  static Future<({String name, String phone})?> show(
      BuildContext context) async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (context.mounted) {
        AppSnackBar.showError(context, AppStrings.contactsPermissionDenied);
      }
      return null;
    }

    if (!context.mounted) return null;

    return await showModalBottomSheet<({String name, String phone})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ContactPickerSheet(),
    );
  }

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  List<Contact> _allContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts =
          await FlutterContacts.getContacts(withProperties: true);
      if (mounted) {
        setState(() {
          _allContacts = contacts.where((c) => c.phones.isNotEmpty).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.trim().isEmpty) return _allContacts;
    final q = _searchQuery.toLowerCase();
    return _allContacts.where((c) {
      final nameMatches = c.displayName.toLowerCase().contains(q);
      final phoneMatches = c.phones.any((p) => p.number.contains(q));
      return nameMatches || phoneMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // مقبض السحب العلوي
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: AppDimensions.handleWidth,
              height: AppDimensions.handleHeight,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // شريط العنوان
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceS,
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.contacts,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                const Expanded(
                  child: Text(
                    AppStrings.selectContact,
                    style: TextStyle(
                      fontSize: AppTypography.sizeH2,
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.closeRounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // حقل البحث
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceS,
            ),
            child: CustomTextField(
              hint: AppStrings.searchContactsHint,
              prefixIcon: const Icon(AppIcons.search, size: 18),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // قائمة جهات الاتصال
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoadingIndicator())
                : _filteredContacts.isEmpty
                    ? const EmptyStateWidget(
                        icon: AppIcons.contacts,
                        title: AppStrings.contactsEmpty,
                      )
                    : ListView.separated(
                        itemCount: _filteredContacts.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 68,
                          color: AppColors.borderLight,
                        ),
                        itemBuilder: (ctx, index) {
                          final contact = _filteredContacts[index];
                          final displayName = contact.displayName.trim().isEmpty
                              ? AppStrings.notSpecified
                              : contact.displayName;
                          final phone = contact.phones.isNotEmpty
                              ? contact.phones.first.number.trim()
                              : '';

                          final initial = displayName.isNotEmpty
                              ? displayName.substring(0, 1)
                              : '?';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: AppTypography.weightBold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightMedium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              phone,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              AppIcons.phone,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            onTap: () {
                              if (phone.isEmpty) {
                                AppSnackBar.showError(
                                    context, AppStrings.contactHasNoPhone);
                                return;
                              }
                              Navigator.of(context).pop((
                                name: displayName,
                                phone: phone,
                              ));
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
