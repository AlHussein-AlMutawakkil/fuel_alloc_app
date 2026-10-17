import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// نظام النوافذ المنبثقة الموحد المطابق للتصميم المعتمد
class CustomDialog {
  CustomDialog._();

  /// نافذة تأكيد عملية (مطابقة بنسبة 100% لصورة التأكيد المعتمدة)
  static Future<bool> showConfirmation({
    required BuildContext context,
    String title = 'تأكيد!',
    required String message,
    String confirmText = 'حسناً',
    String cancelText = 'إلغاء',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // العنوان في المنتصف
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // نص الرسالة في المنتصف
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // الفاصل الأفقي السفلي
              const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),
              // أزرار التأكيد والإلغاء مقسومة بخط رأسي (في RTL الأول يظهر يميناً والثاني يساراً)
              IntrinsicHeight(
                child: Row(
                  children: [
                    // زر التأكيد على اليمين (حسناً)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(true),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDanger
                                  ? AppColors.dispenseRed
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                        width: 1, color: Color(0xFFF1F5F9), thickness: 1),
                    // زر الإلغاء على اليسار (إلغاء)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(false),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Text(
                            cancelText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
