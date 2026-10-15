# وثيقة المعمارية والتصميم الفني (Technical Architecture Document)
## نظام إدارة ومحاسبة مخصصات المحروقات (Fuel Allocation App)

---

### 1. مقدمة ومعايير المعمارية (Architectural Principles)
تهدف هذه الوثيقة إلى تحديد المعمارية البرمجية الدقيقة للمشروع لضمان كتابة كود نظيف، معياري، وقابل للصيانة، بالاعتماد على:
* **إطار العمل:** Flutter.
* **النمط المعماري:** **MVC (Model - View - Controller)**.
* **إدارة الحالة (State Management):** حزمة **Provider**.
* **نظام التصميم المركزي (Centralized Design System):** مكونات مشتركة وموحدة لكامل التطبيق.
* **الجاهزية للتزامن المستقبلي (Sync-Ready Architecture):** فصل طبقة التخزين عبر مستودعات (Repositories) لتمكين المزامنة السحابية مستقبلاً دون المساس بالواجهات.

---

### 2. هيكل المجلدات المعتمد (Folder Structure)

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # الألوان المركزية للمشروع كاملاً
│   │   ├── app_text_styles.dart    # أحجام وأوزان الخطوط الموحدة
│   │   ├── app_strings.dart        # ثوابت النصوص (منع النصوص السحرية)
│   │   └── app_dimens.dart         # المسافات والهوامش ونصف القطر الموحد
│   ├── theme/
│   │   └── app_theme.dart          # الثيم العام للتطبيق
│   ├── utils/
│   │   ├── formatters.dart         # تنسيق الأرقام والكميات والتواريخ
│   │   └── unit_converter.dart     # دوال التحويل بين اللتر، الدبة، والبرميل
│   └── widgets/                    # المكونات المشتركة (Design System)
│       ├── custom_button.dart      # الزر الموحد للتطبيق
│       ├── custom_text_field.dart  # حقل الإدخال الموحد
│       ├── custom_dialog.dart      # النوافذ المنبثقة الموحدة
│       ├── custom_bottom_sheet.dart# القوائم السفلية الموحدة
│       ├── custom_card.dart        # البطاقة الموحدة لعرض البيانات
│       └── custom_app_bar.dart     # شريط العنوان الموحد
│
├── data/
│   ├── local/
│   │   ├── database_helper.dart    # مدير قاعدة بيانات SQLite المحلية
│   │   └── tables/                 # تعريف وإنشاء الجداول الـ 5
│   └── repositories/               # طبقة المستودعات (عزل التخزين المحلي لدعم التزامن لاحقاً)
│       ├── account_repository.dart
│       ├── station_repository.dart
│       ├── unit_repository.dart
│       └── transaction_repository.dart
│
├── models/                         # نماذج البيانات (Entities & Models)
│   ├── account_model.dart          # نموذج الحساب (مورد / عميل)
│   ├── station_model.dart          # نموذج المحطة
│   ├── unit_model.dart             # نموذج الوحدة (لتر، دبة، برميل)
│   ├── transaction_type_model.dart # أنواع العمليات
│   └── transaction_model.dart      # نموذج القيد والعملية المحاسبية
│
├── controllers/                    # المتحكمات ومنطق العمل (MVC Controllers with Provider)
│   ├── accounts_controller.dart    # إدارة الحسابات والعملاء
│   ├── stations_controller.dart    # إدارة المحطات
│   ├── transactions_controller.dart# إدارة القيود (التوريد، الصرف، عمولة التهوية)
│   └── balance_controller.dart     # حساب الأرصدة والمطابقات اللحظية
│
├── views/                          # واجهات وشاشات المستخدم (UI)
│   ├── home/                       # الشاشة الرئيسية ومؤشرات الأرصدة
│   ├── accounts/                   # شاشات إدارة الحسابات وكشوفاتها
│   ├── stations/                   # شاشات إدارة المحطات وكشوفات أرصدتها
│   ├── transactions/               # شاشات إدخال العمليات (أوامر الصرف والتوريد)
│   └── reports/                    # شاشات التقارير والطباعة والرسائل
│
└── main.dart                       # نقطة البداية وتهيئة الـ Providers والمسارات
```

---

### 3. تدفق البيانات والطبقات (Data Flow in MVC + Provider)

```mermaid
flowchart LR
    subgraph View_Layer [1. Views]
        V[واجهات المستخدم]
    end

    subgraph Controller_Layer [2. Controllers (ChangeNotifier)]
        C[المتحكمات - منطق العمل والأرصدة]
    end

    subgraph Repository_Layer [3. Repositories]
        R[مستودع البيانات الموحد]
    end

    subgraph Storage_Layer [4. Data Sources]
        DB[(قاعدة بيانات SQLite المحلية)]
        Sync[(خادم التزامن السحابي - مستقبلاً)]
    end

    V -->|استدعاء أحداث| C
    C -->|تحديث الحالة عبر notifyListeners| V
    C -->|طلب وحفظ البيانات| R
    R -->|تخزين وقراءة محلياً| DB
    R -.->|مزامنة مستقبلية دون تعديل الـ Controllers| Sync
```

---

### 4. قواعد التصميم والمكونات المشتركة (Centralized Components Rules)

#### أ. الزر الموحد (`CustomButton`):
* لا يتم استخدام أزرار Flutter الافتراضية بشكل مباشر داخل الشاشات (`ElevatedButton` عشوائي).
* يتم استدعاء مكون واحد فقط `CustomButton` يدعم أنماط محددة:
  * أساسي (`primary`): للعمليات الإيجابية والحفظ.
  * ثانوي (`secondary`): للإلغاء والعودة.
  * خطر (`danger`): للحذف والتراجع.
* يحوي حالات التحميل (`isLoading`) والتعطيل (`isDisabled`) بشكل موحد.

#### ب. حقل الإدخال الموحد (`CustomTextField`):
* حقل موحد ومخصص يدعم:
  * التصميم المتناسق (نفس الحواف، التباعد، والخطوط).
  * حقول الأرقام والكميات مع لوحة مفاتيح رقمية افتراضية واختيار الوحدة.
  * معالجة رسائل التحقق (Validation) بدون نصوص عشوائية.

#### ج. النوافذ المنبثقة ورسائل التأكيد (`CustomDialog` & `CustomBottomSheet`):
* لا يُستخدم `showDialog` بنصوص وتنسيقات حرة.
* يتم استدعاء دالة موحدة مثل:
  * `CustomDialog.showConfirm(...)` لتأكيد العمليات المهمة (مثل تأكيد أمر الصرف).
  * `CustomDialog.showError(...)` لعرض الأخطاء مثل عدم كفاية الرصيد.
  * `CustomBottomSheet.show(...)` لقوائم الاختيار السريعة (اختيار محطة، اختيار مستفيد).

#### د. الألوان والخطوط المركزية (`AppColors` & `AppTextStyles`):
* **منع الألوان الصلبة (Hardcoded Colors):** يمنع كتابة `Colors.blue` أو أي كود لوني داخل شاشات الـ View.
* جميع الألوان يتم سحبها حصراً من `AppColors`.
* جميع أحجام الخطوط تُسحب من `AppTextStyles`.

---

### 5. قاعدة منع النصوص السحرية والشروحات (No Magic Strings & Clean UI)
1. **ثوابت النصوص (`AppStrings`):**
   * تجمع كافة العناوين، أسماء الأزرار، والرسائل في ملف واحد.
   * سهولة التعديل أو دعم لغات إضافية لاحقاً.
2. **واجهات نظيفة ومباشرة (Minimalist & Clutter-Free):**
   * الابتعاد التام عن وضع فقرات شروحات مطولة داخل الشاشات.
   * استخدام أيقونات معبرة، بطاقات واضحة، وحقول بيانات واضحة المعنى بدون رغي أو تعقيد.

---

### 6. الجاهزية للتزامن المستقبلي (Future Cloud-Sync Readiness)
* تم تصميم جداول قاعدة البيانات المحلية لتشمل حقولاً قياسية تدعم المزامنة عند تفعيلها مستقبلاً:
  * `created_at` (تاريخ الإنشاء).
  * `updated_at` (تاريخ آخر تعديل).
  * `sync_status` (حالة المزامنة: `PENDING` / `SYNCED`).
* معمارية المستودعات (`Repositories`) تفصل تماماً بين طريقة جلب البيانات وبين واجهات المستخدم؛ فعند الرغبة في ربط خادم سحابي في مرحلة لاحقة، يتم فقط إضافة محرك المزامنة (`SyncEngine`) في طبقة البيانات دون تعديل سطر واحد في الواجهات أو المتحكمات.
