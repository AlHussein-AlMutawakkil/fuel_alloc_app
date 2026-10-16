import 'package:flutter/material.dart';

/// المكون المشترك الموحد لكافة النوافذ المنبثقة في التطبيق
/// (تسجيل قيد، إضافة حساب، إضافة محطة، إضافة صنف، إضافة وحدة)
/// موحد في العرض والارتفاع والألوان والحواف والأزرار بنسبة 100%
class CustomModalSheet {
  CustomModalSheet._();

  // لون حدود الحقول الموحد الواضح والصريح
  static const Color fieldBorderColor = Color(0xFF64748B);

  /// فتح نافذة منبثقة موحدة في كافة شاشات التطبيق
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext ctx, StateSetter setState) contentBuilder,
    required Future<void> Function(BuildContext ctx) onSave,
    String saveText = 'حفظ',
    String cancelText = 'إلغاء',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. الشريط العلوي الموحد (العنوان في المنتصف و زر X على اليسار في RTL)
                          Row(
                            children: [
                              const SizedBox(width: 32), // لموازنة العنوان
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Color(0xFF475569), size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. محتوى الحقول
                          contentBuilder(dialogCtx, setModalState),
                          const SizedBox(height: 16),

                          // 3. شريط الأزرار السفلي الموحد (حفظ الأخضر يميناً flex: 5 وإلغاء الأبيض يساراً flex: 3 في RTL)
                          Row(
                            children: [
                              // زر الحفظ الأخضر على اليمين
                              Expanded(
                                flex: 5,
                                child: InkWell(
                                  onTap: () => onSave(dialogCtx),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF15803D),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      saveText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // زر الإلغاء الأبيض على اليسار
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogCtx).pop(),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: fieldBorderColor, width: 1.2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cancelText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
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
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
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
          height: maxLines == 1 ? 46 : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: fieldBorderColor, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
