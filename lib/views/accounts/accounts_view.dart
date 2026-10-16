import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/account_model.dart';
import 'account_transactions_view.dart';

/// واجهة إدارة الحسابات
class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsController>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({AccountModel? account}) {
    final nameController = TextEditingController(text: account?.name ?? '');
    final phoneController = TextEditingController(text: account?.phoneNumber ?? '');
    AccountType selectedType = account?.accountType ?? AccountType.beneficiary;

    CustomModalSheet.show(
      context: context,
      title: account == null ? AppStrings.addAccount : AppStrings.editAccount,
      contentBuilder: (ctx, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomModalSheet.buildTextField(
              label: AppStrings.accountName,
              controller: nameController,
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildLabel(AppStrings.accountType),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CustomModalSheet.fieldBorderColor, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountType>(
                  isExpanded: true,
                  value: selectedType,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                  items: const [
                    DropdownMenuItem(
                      value: AccountType.beneficiary,
                      child: Text(AppStrings.typeBeneficiary, style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                    ),
                    DropdownMenuItem(
                      value: AccountType.supplier,
                      child: Text(AppStrings.typeSupplier, style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedType = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomModalSheet.buildTextField(
              label: AppStrings.phoneNumber,
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        );
      },
      onSave: (ctx) async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;

        final navigator = Navigator.of(ctx);
        final controller = context.read<AccountsController>();
        if (account == null) {
          await controller.addAccount(name, selectedType, phoneController.text);
        } else {
          await controller.updateAccount(
            account.copyWith(
              name: name,
              accountType: selectedType,
              phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
            ),
          );
        }
        navigator.pop();
      },
    );
  }

  void _deleteAccount(AccountModel account) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'تأكيد!',
      message: 'هل تريد حذف هذا الحساب؟',
      confirmText: 'حسناً',
      cancelText: 'إلغاء',
      isDanger: true,
    );

    if (confirm && account.id != null && mounted) {
      await context.read<AccountsController>().deleteAccount(account.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط البحث وزر الإضافة
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,
                        hint: AppStrings.searchAccountHint,
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        onChanged: (val) => controller.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: 'إضافة',
                      icon: Icons.add,
                      variant: ButtonVariant.primary,
                      onPressed: () => _showAddEditDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // تبويبات الفلترة الموحدة
                Row(
                  children: [
                    _buildFilterChip(
                      label: AppStrings.allAccounts,
                      isSelected: controller.selectedTypeFilter == null,
                      onTap: () => controller.setTypeFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: AppStrings.beneficiaries,
                      isSelected: controller.selectedTypeFilter == AccountType.beneficiary,
                      onTap: () => controller.setTypeFilter(AccountType.beneficiary),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: AppStrings.suppliers,
                      isSelected: controller.selectedTypeFilter == AccountType.supplier,
                      onTap: () => controller.setTypeFilter(AccountType.supplier),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // قائمة الحسابات
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : controller.accounts.isEmpty
                          ? const Center(
                              child: Text(
                                AppStrings.noAccountsFound,
                                style: AppTextStyles.bodySecondary,
                              ),
                            )
                          : ListView.separated(
                              itemCount: controller.accounts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final account = controller.accounts[index];
                                return _buildAccountCard(account);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _navigateToTransactions(AccountModel account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountTransactionsView(account: account),
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account) {
    final isSupplier = account.accountType == AccountType.supplier;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _navigateToTransactions(account),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // شارة النوع الرسمية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSupplier ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSupplier ? const Color(0xFFBFDBFE) : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isSupplier ? 'مورد' : 'عميل',
                  style: AppTextStyles.caption.copyWith(
                    color: isSupplier ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // الاسم ورقم الهاتف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTextStyles.heading3),
                    if (account.phoneNumber != null && account.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.phoneNumber!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),

              // مؤشر للانتقال لكشف الحساب
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),

              // أيقونة الخيارات الثلاث نقاط (⋮)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                onSelected: (action) {
                  if (action == 'transactions') {
                    _navigateToTransactions(account);
                  } else if (action == 'edit') {
                    _showAddEditDialog(account: account);
                  } else if (action == 'delete') {
                    _deleteAccount(account);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'transactions',
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(AppStrings.viewTransactions, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.edit, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.dispenseRed),
                        SizedBox(width: 8),
                        Text(AppStrings.delete, style: TextStyle(color: AppColors.dispenseRed, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
