import 'package:flutter/material.dart';

/// المكون المشترك الموحد لكافة النوافذ المنبثقة في التطبيق
/// (إضافة حساب، إضافة محطة، إضافة صنف)
/// بتصميم One UI العصري الموحد
class CustomModalSheet {
  CustomModalSheet._();

  // لون حدود الحقول الموحد الناعم
  static const Color fieldBorderColor = Color(0xFFE2E8F0);

  /// فتح نافذة منبثقة موحدة في كافة شاشات التطبيق
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext ctx, StateSetter setState)
        contentBuilder,
    required Future<void> Function(BuildContext ctx) onSave,
    String saveText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. الشريط العلوي: العنوان وزر الإغلاق
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 2. محتوى الحقول
                          contentBuilder(dialogCtx, setModalState),
                          const SizedBox(height: 24),

                          // 3. شريط الأزرار السفلي (إلغاء رمادي يميناً، وتأكيد أسود يساراً في RTL)
                          Row(
                            children: [
                              // زر الإلغاء على اليمين
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogCtx).pop(),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFf8f8f8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cancelText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // زر التأكيد الأسود على اليسار
                              Expanded(
                                child: InkWell(
                                  onTap: () => onSave(dialogCtx),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      saveText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// بناء عنوان الحقل الموحد
  static Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  /// بناء حقل إدخال نصي موحد بنسبة 100%
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        Container(
          height: maxLines == 1 ? 48 : null,
          decoration: BoxDecoration(
            color: const Color(0xFFf8f8f8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fieldBorderColor, width: 1.0),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: maxLines == 1
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

