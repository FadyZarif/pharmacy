# ميزة المستخدمين غير النشطين (Inactive Users)

## نظرة عامة
تم تنفيذ ميزة كاملة لإدارة حالة نشاط المستخدمين في النظام. عند تحويل مستخدم إلى حالة غير نشط (Inactive)، يتم تطبيق القيود التالية:

---

## 1️⃣ منع تسجيل الدخول

### التغييرات في `lib/core/helpers/constants.dart`:
- تم تعديل دالة `checkIsLogged()` لفحص حالة `isActive`
- إذا كان المستخدم غير نشط، يتم:
  - تسجيل خروج تلقائي من Firebase Auth
  - إرجاع `false` لمنع الوصول
  - تحديث `isLogged = false`

```dart
// Check if user is active
if (!currentUser.isActive) {
  // Sign out inactive user
  await FirebaseAuth.instance.signOut();
  isLogged = false;
  return false;
}
```

### التغييرات في `lib/features/login/logic/login_cubit.dart`:
- تم إضافة فحص بعد نجاح المصادقة
- إذا كان المستخدم غير نشط، يتم:
  - تسجيل خروج فوري
  - عرض رسالة خطأ واضحة: "Your account has been deactivated. Please contact your administrator."
  - منع الوصول للتطبيق

```dart
// Check if user is logged and active
bool userIsActive = await checkIsLogged();

if (!userIsActive || !isLogged) {
  // User is inactive, sign them out and show error
  await FirebaseAuth.instance.signOut();
  btnController.error();
  emit(LoginErrorState('Your account has been deactivated. Please contact your administrator.'));
  return;
}
```

---

## 2️⃣ مؤشرات بصرية واضحة في الواجهة

### التغييرات في `lib/features/user/ui/users_management_screen.dart`:

#### أ) تحسينات بصرية على بطاقة المستخدم:
1. **Opacity (الشفافية)**: المستخدمون غير النشطين يظهرون بشفافية 60%
2. **Background Color**: خلفية رمادية للمستخدمين غير النشطين
3. **Border**: حدود حمراء حول البطاقة
4. **Profile Picture**: أيقونة "Block" على الصورة الشخصية
5. **Name Strikethrough**: خط يتوسط اسم المستخدم غير النشط
6. **INACTIVE Badge**: شارة حمراء واضحة بجانب الاسم تقول "INACTIVE"
7. **Status Indicator**: أيقونة حمراء مع علامة X

#### ب) فلتر حالة النشاط:
تم إضافة فلتر جديد يسمح بتصفية المستخدمين حسب حالة النشاط:
- **All Status**: عرض جميع المستخدمين (نشطين وغير نشطين)
- **Active Only**: عرض المستخدمين النشطين فقط ✅
- **Inactive Only**: عرض المستخدمين غير النشطين فقط ❌

```dart
// Active/Inactive Filter
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _buildActiveFilterChip('All Status', null),
      _buildActiveFilterChip('Active Only', true),
      _buildActiveFilterChip('Inactive Only', false),
    ],
  ),
)
```

### التغييرات في `lib/features/user/logic/users_cubit.dart`:
- تم إضافة معامل `isActive` لدالة `filterUsers()`
- يسمح بتصفية المستخدمين حسب حالتهم

```dart
List<UserModel> filterUsers({
  required String searchQuery,
  Role? selectedRole,
  bool? isActive, // جديد
}) {
  return allUsers.where((user) {
    final matchesActive = isActive == null || user.isActive == isActive;
    return matchesSearch && matchesRole && matchesActive;
  }).toList();
}
```

---

## 3️⃣ سيناريوهات الاستخدام

### متى تستخدم Inactive؟
1. **الإجازات الطويلة**: موظف في إجازة لمدة شهر أو أكثر
2. **الإيقاف المؤقت**: إيقاف الحساب لأسباب إدارية
3. **ترك العمل**: الموظف ترك العمل لكن نريد الاحتفاظ ببياناته
4. **الفصل المؤقت**: معلق عن العمل لفترة محددة

### الفرق بين Inactive و Delete:
- **Inactive**: الحساب موجود لكن غير قابل للاستخدام، البيانات محفوظة
- **Delete**: حذف الحساب نهائياً من Firebase Auth و Firestore

---

## 4️⃣ التأثيرات على النظام

### ✅ ما يحدث للمستخدم غير النشط:
- ❌ لا يستطيع تسجيل الدخول
- ❌ يتم تسجيل خروجه تلقائياً إذا كان مسجلاً
- ✅ بياناته محفوظة في Firestore
- ✅ سجله التاريخي محفوظ (الطلبات، الحضور، الغياب، إلخ)
- ✅ يظهر في قائمة المستخدمين مع مؤشرات واضحة
- ✅ يمكن إعادة تفعيله في أي وقت

### ✅ ما يراه الإداري:
- مؤشرات بصرية واضحة جداً
- إمكانية فلترة المستخدمين غير النشطين
- إمكانية إعادة تفعيل المستخدم من شاشة Edit User

---

## 5️⃣ كيفية التفعيل/التعطيل

### من شاشة Edit User:
```dart
// Active Status Switch
Switch(
  value: _isActive,
  onChanged: (value) {
    setState(() {
      _isActive = value;
    });
  },
)
```

عند الضغط على "Update User"، يتم تحديث حالة `isActive` في Firestore.

---

## 6️⃣ الملفات المعدلة

1. ✅ `lib/core/helpers/constants.dart` - منع تسجيل الدخول
2. ✅ `lib/features/login/logic/login_cubit.dart` - فحص عند Login
3. ✅ `lib/features/user/ui/users_management_screen.dart` - المؤشرات البصرية والفلتر
4. ✅ `lib/features/user/logic/users_cubit.dart` - منطق الفلترة
5. ✅ `lib/features/user/ui/edit_user_screen.dart` - تعديل رصيد الإجازات (ميزة إضافية)
6. ✅ `lib/features/user/ui/edit_profile_screen.dart` - دعم vocationBalanceMinutes

---

## 7️⃣ الاختبار

### للاختبار:
1. افتح شاشة Users Management
2. اختر أي مستخدم واضغط Edit
3. قم بإيقاف تشغيل "Active Status"
4. احفظ التغييرات
5. حاول تسجيل الدخول بحساب المستخدم المعطل
6. يجب أن تظهر رسالة: "Your account has been deactivated. Please contact your administrator."
7. ارجع لشاشة Users Management - ستلاحظ المؤشرات البصرية الواضحة
8. استخدم فلتر "Inactive Only" لعرض المستخدمين غير النشطين فقط

---

## 8️⃣ ملاحظات مهمة

⚠️ **انتبه**: 
- المستخدم غير النشط لا يمكنه الوصول لأي شيء في التطبيق
- حتى لو كان لديه Token صالح، سيتم تسجيل خروجه تلقائياً
- البيانات التاريخية تبقى محفوظة ولا تتأثر

✅ **المميزات**:
- حماية كاملة من الوصول غير المصرح به
- مؤشرات بصرية واضحة جداً
- سهولة التفعيل/التعطيل
- الاحتفاظ بالبيانات التاريخية

---

## تم التنفيذ بتاريخ: 25 يناير 2026
