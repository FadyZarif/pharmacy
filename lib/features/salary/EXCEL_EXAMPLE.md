# مثال على بيانات ملف Excel للمرتبات

## الصف الأول (العناوين)
employeeUid | pharmacyCode | pharmacyName | acc | nameEnglish | nameArabic | hourlyRate | hoursWorked | basicSalary | incentive | additional | quarterlySalesIncentive | workBonus | administrativeBonus | transportAllowance | employerShare | eideya | hourlyDeduction | penalties | pharmacyCodeDeduction | visaDeduction | advanceDeduction | quarterlyShiftDeficitDeduction | insuranceDeduction | netSalary | remainingAdvance

## مثال على بيانات الصف الثاني (موظف)
ABC123XYZ | PH001 | الصيدلية المركزية | 12345 | Ahmed Mohamed | أحمد محمد | 50 | 180 | 5000 | 500 | 200 | 300 | 400 | 0 | 150 | 250 | 0 | 0 | 0 | 0 | 0 | 500 | 0 | 100 | 6200 | 1000

## مثال على بيانات الصف الثالث (موظف آخر)
DEF456UVW | PH001 | الصيدلية المركزية | 12346 | Sara Ali | سارة علي | 45 | 160 | 4500 | 400 | 150 | 250 | 300 | 0 | 150 | 200 | 0 | 0 | 0 | 0 | 0 | 300 | 0 | 80 | 5570 | 500

---

## شرح الأعمدة:

### البيانات الأساسية
- **employeeUid**: معرف الموظف الفريد (يجب أن يطابق UID في Firebase Authentication)
- **pharmacyCode**: كود الصيدلية
- **pharmacyName**: اسم الصيدلية
- **acc**: رقم الحساب
- **nameEnglish**: اسم الموظف بالإنجليزية
- **nameArabic**: اسم الموظف بالعربية

### نظام العمل بالساعات
- **hourlyRate**: قيمة الساعة الواحدة (بالجنيه)
- **hoursWorked**: عدد الساعات المعمولة في الشهر

### المرتب والحوافز
- **basicSalary**: المرتب الأساسي
- **incentive**: الحافز
- **additional**: مبالغ إضافية
- **quarterlySalesIncentive**: حوافز المبيعات الربع سنوية
- **workBonus**: مكافأة عن العمل
- **administrativeBonus**: المكافآت الإدارية
- **transportAllowance**: بدل المواصلات
- **employerShare**: حصة صاحب العمل
- **eideya**: العيديات

### الخصومات
- **hourlyDeduction**: خصم بالساعات
- **penalties**: الجزاءات
- **pharmacyCodeDeduction**: خصم كود السحب الدوائي
- **visaDeduction**: خصم مصاريف الفيزا
- **advanceDeduction**: خصم السلف
- **quarterlyShiftDeficitDeduction**: خصم عجز الشيفتات
- **insuranceDeduction**: خصم التأمينات

### النتيجة النهائية
- **netSalary**: صافي المرتب المستحق
- **remainingAdvance**: المتبقي من السلف

---

## ملاحظات هامة:
1. يجب أن يكون **employeeUid** موجوداً في قاعدة البيانات
2. جميع القيم المالية يجب أن تكون أرقام موجبة
3. يمكن استخدام 0 للقيم غير المستخدمة
4. تأكد من عدم وجود مسافات زائدة في البيانات
5. احفظ الملف بصيغة `.xlsx` أو `.xls`

