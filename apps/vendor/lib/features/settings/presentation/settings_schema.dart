import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The kind of editor used to render a settings field.
enum SettingsFieldKind { text, number, toggle, image }

/// A single editable platform setting.
///
/// `labelAr`/`labelEn` and `helpAr`/`helpEn` are intentionally self-contained
/// (rather than going through the ARB catalog) so the whole platform-settings
/// catalogue can be described in one place — including the plain-language
/// explanation shown in the "شرح" sheet.
class SettingsField {
  final String key;
  final SettingsFieldKind kind;
  final String labelAr;
  final String labelEn;
  final String helpAr;
  final String helpEn;

  /// Optional sub-group header shown above the field inside a section.
  final String? groupAr;
  final String? groupEn;

  /// For [SettingsFieldKind.image]: the upload type understood by the backend.
  final String? imageType;

  /// For wide image uploads (covers / banners).
  final bool wide;

  /// Optional suffix shown inside numeric inputs (e.g. `%`).
  final String? suffix;

  const SettingsField({
    required this.key,
    required this.kind,
    required this.labelAr,
    required this.labelEn,
    required this.helpAr,
    required this.helpEn,
    this.groupAr,
    this.groupEn,
    this.imageType,
    this.wide = false,
    this.suffix,
  });

  String label(bool isAr) => isAr ? labelAr : labelEn;
  String help(bool isAr) => isAr ? helpAr : helpEn;
  String? group(bool isAr) => isAr ? groupAr : groupEn;
}

/// A logical group of settings shown as a card on the Settings home screen.
class SettingsSection {
  final String id;
  final IconData icon;
  final Color color;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  final String explainAr;
  final String explainEn;
  final List<SettingsField> fields;

  const SettingsSection({
    required this.id,
    required this.icon,
    required this.color,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.explainAr,
    required this.explainEn,
    required this.fields,
  });

  String title(bool isAr) => isAr ? titleAr : titleEn;
  String desc(bool isAr) => isAr ? descAr : descEn;
  String explain(bool isAr) => isAr ? explainAr : explainEn;
}

const Color _moneyColor = Color(0xFF10B981);
const Color _deliveryColor = Color(0xFF3B82F6);
const Color _vehiclesColor = Color(0xFF8B5CF6);
const Color _dispatchColor = Color(0xFF06B6D4);
const Color _loyaltyColor = Color(0xFFF59E0B);
const Color _driversColor = Color(0xFFEF4444);
const Color _breaksColor = Color(0xFF14B8A6);
const Color _appColor = Color(0xFF6366F1);
const Color _customerColor = Color(0xFFEC4899);
const Color _assetsColor = Color(0xFFF97316);
const Color _supportColor = Color(0xFF0EA5E9);
const Color _retentionColor = Color(0xFF64748B);

const List<SettingsSection> platformSettingsSections = [
  // ───────────────────────────────────────────────────────────── 1) Money
  SettingsSection(
    id: 'money',
    icon: LucideIcons.wallet,
    color: _moneyColor,
    titleAr: 'الأموال والعمولات',
    titleEn: 'Money & Commissions',
    descAr: 'العمولات، الضريبة، والعملة',
    descEn: 'Commissions, tax and currency',
    explainAr:
        'هنا بتحدد المنصة بتاخد كام من كل عملية، والضريبة كام، وأقل قيمة للطلب. '
        'العمولة بتتخصم من البائع، وعمولة التوصيل بتتخصم من المندوب.',
    explainEn:
        'Control how much the platform earns per operation, the tax rate and the '
        'minimum order value. Vendor commission is taken from the vendor, and the '
        'delivery commission from the driver.',
    fields: [
      SettingsField(
        key: 'currency',
        kind: SettingsFieldKind.text,
        labelAr: 'العملة',
        labelEn: 'Currency',
        helpAr: 'رمز عملة التطبيق، مثال: EGP.',
        helpEn: 'The app currency symbol, e.g. EGP.',
      ),
      SettingsField(
        key: 'defaultCommissionRate',
        kind: SettingsFieldKind.number,
        suffix: '%',
        labelAr: 'عمولة المنصة من الطلب',
        labelEn: 'Order Commission',
        helpAr:
            'نسبة بتتخصم من البائع على قيمة الطلب. لو البائع مش متعاقد، العميل '
            'هو اللي بيدفعها كرسوم خدمة.',
        helpEn:
            'Percentage taken from the vendor on the order value. If the vendor '
            'is not contracted, the customer pays it as a service fee.',
      ),
      SettingsField(
        key: 'deliveryCommissionRate',
        kind: SettingsFieldKind.number,
        suffix: '%',
        labelAr: 'عمولة المنصة من التوصيل',
        labelEn: 'Delivery Commission',
        helpAr:
            'نسبة بتتخصم من المندوب على كل توصيل. المندوب بياخد الباقي '
            '(مثال: 20% يعني المندوب ياخد 80% من رسوم التوصيل).',
        helpEn:
            'Percentage taken from the driver on every delivery. The driver keeps '
            'the rest (e.g. 20% means the driver gets 80% of the delivery fee).',
      ),
      SettingsField(
        key: 'driverManagerCommissionRate',
        kind: SettingsFieldKind.number,
        suffix: '%',
        labelAr: 'نسبة مدير المناديب من التوصيل',
        labelEn: 'Driver Manager Cut',
        helpAr:
            'نسبة عمولة مدير المناديب من رسوم التوصيل لكل طلب في منطقته (مثال: 10%).',
        helpEn:
            'Percentage of the delivery fee credited to the driver manager for each order in their zone (e.g. 10%).',
      ),
      SettingsField(
        key: 'customOrderPlatformFee',
        kind: SettingsFieldKind.number,
        labelAr: 'رسوم خدمات التوصيل المخصص',
        labelEn: 'Custom Delivery Service Fee',
        helpAr: 'مبلغ ثابت بيدفعه العميل في الطلبات/الرحلات المخصصة.',
        helpEn: 'Fixed amount paid by the customer on custom orders/rides.',
      ),
      SettingsField(
        key: 'defaultTaxRate',
        kind: SettingsFieldKind.number,
        suffix: '%',
        labelAr: 'الضريبة',
        labelEn: 'Tax Rate',
        helpAr: 'نسبة الضريبة المضافة على الفاتورة.',
        helpEn: 'Tax percentage added to the invoice.',
      ),
      SettingsField(
        key: 'minOrderAmount',
        kind: SettingsFieldKind.number,
        labelAr: 'أقل قيمة للطلب',
        labelEn: 'Minimum Order Amount',
        helpAr:
            'أقل قيمة لمنتجات الطلب (بدون توصيل/ضريبة). 0 يعني بدون حد أدنى.',
        helpEn:
            'Minimum product subtotal to place an order (excludes delivery/tax). '
            '0 disables the minimum.',
      ),
      SettingsField(
        key: 'highValueOrderThreshold',
        kind: SettingsFieldKind.number,
        labelAr: 'حد الطلب الكاش الكبير',
        labelEn: 'High-Value Cash Threshold',
        helpAr:
            'لو إجمالي الطلب الكاش أكبر من الرقم ده، بيتطلب دفع مقدم. 0 يعني '
            'معطّل.',
        helpEn:
            'If a cash order total exceeds this value, an upfront payment is '
            'required. 0 disables it.',
      ),
      SettingsField(
        key: 'highValueUpfrontRate',
        kind: SettingsFieldKind.number,
        suffix: '%',
        labelAr: 'نسبة المقدم للطلب الكاش الكبير',
        labelEn: 'High-Value Upfront Rate',
        helpAr:
            'نسبة المقدم المطلوب من إجمالي الطلب الكاش الكبير (مثال: 20% من '
            '1000 = 200).',
        helpEn:
            'Upfront percentage of a high-value cash order total (e.g. 20% of '
            '1000 = 200).',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────── 2) Delivery fee
  SettingsSection(
    id: 'delivery',
    icon: LucideIcons.truck,
    color: _deliveryColor,
    titleAr: 'أجرة التوصيل',
    titleEn: 'Delivery Fee',
    descAr: 'أجرة الفتح وسعر الكيلو',
    descEn: 'Base fare and price per km',
    explainAr:
        'هنا بتحدد سعر المشوار. المعادلة: «أجرة الفتح + (المسافة × سعر الكيلو)»، '
        'إلا لو المشوار قصير يبقى سعر ثابت. مثال: 15 + (10كم × 3) = 45 ج.',
    explainEn:
        'Control how a trip is priced: base fare + (distance × price per km), '
        'except short trips which use a flat price. Example: 15 + (10km × 3) = 45.',
    fields: [
      SettingsField(
        key: 'baseDeliveryFee',
        kind: SettingsFieldKind.number,
        labelAr: 'أجرة فتح المشوار',
        labelEn: 'Base Delivery Fee',
        helpAr: 'مبلغ ثابت في بداية كل مشوار قبل حساب الكيلوات.',
        helpEn: 'Fixed amount at the start of every delivery, before the kms.',
      ),
      SettingsField(
        key: 'extraVendorDeliveryFee',
        kind: SettingsFieldKind.number,
        labelAr: 'أجرة كل متجر إضافي في نفس المشوار',
        labelEn: 'Extra Vendor Delivery Fee',
        helpAr: 'مبلغ ثابت يُضاف للتوصيل لكل متجر إضافي في طلبات المتاجر المتعددة.',
        helpEn: 'Fixed delivery fee added for each additional vendor in multi-vendor orders.',
      ),
      SettingsField(
        key: 'pricePerKm',
        kind: SettingsFieldKind.number,
        labelAr: 'سعر الكيلو',
        labelEn: 'Price Per Km',
        helpAr: 'على كل كيلو بيزيد كام على الأجرة.',
        helpEn: 'How much is added per kilometre.',
      ),
      SettingsField(
        key: 'minOrderKm',
        kind: SettingsFieldKind.number,
        labelAr: 'مسافة المشوار القصير',
        labelEn: 'Short-Trip Distance',
        helpAr:
            'لحد كام كيلو يعتبر المشوار قصير وياخد السعر الثابت. 0 يعني معطّل.',
        helpEn:
            'Below this distance a trip counts as short and uses the flat price. '
            '0 disables it.',
      ),
      SettingsField(
        key: 'minDistanceFixedPrice',
        kind: SettingsFieldKind.number,
        labelAr: 'أجرة المشوار القصير',
        labelEn: 'Short-Trip Flat Price',
        helpAr: 'السعر الثابت لأي مشوار أقل من «مسافة المشوار القصير».',
        helpEn: 'Flat price for any trip shorter than the short-trip distance.',
      ),
      SettingsField(
        key: 'maxDeliveryFee',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى أجرة توصيل',
        labelEn: 'Max Delivery Fee',
        helpAr: 'سقف لرسوم التوصيل. 0 يعني بدون حد أقصى.',
        helpEn: 'Upper cap on the delivery fee. 0 means no cap.',
      ),
      SettingsField(
        key: 'maxDeliveryRadiusKm',
        kind: SettingsFieldKind.number,
        labelAr: 'أبعد مسافة للتوصيل',
        labelEn: 'Max Delivery Radius (km)',
        helpAr: 'أي عميل أبعد من المسافة دي ميتقبلش الأوردر.',
        helpEn: 'Orders beyond this distance are rejected.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────── 3) Vehicles
  SettingsSection(
    id: 'vehicles',
    icon: LucideIcons.car,
    color: _vehiclesColor,
    titleAr: 'المركبات',
    titleEn: 'Vehicles',
    descAr: 'السماح والأسعار لكل نوع مركبة',
    descEn: 'Allowance and pricing per vehicle',
    explainAr:
        'لكل نوع مركبة بتحدد: مسموح ولا لأ، سعر الكيلو، وأقل/أقصى أجرة. '
        'الأسعار دي بتُستخدم في الطلبات والرحلات المخصصة.',
    explainEn:
        'For each vehicle type set whether it is allowed, its price per km and '
        'its min/max fare. These apply to custom orders and rides.',
    fields: [
      SettingsField(
        key: 'allowBicycle',
        kind: SettingsFieldKind.toggle,
        groupAr: 'دراجة هوائية',
        groupEn: 'Bicycle',
        labelAr: 'السماح بالدراجة',
        labelEn: 'Allow Bicycle',
        helpAr: 'تشغيل/إيقاف استقبال الطلبات بالدراجات.',
        helpEn: 'Enable/disable bicycle deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmBicycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة هوائية',
        groupEn: 'Bicycle',
        labelAr: 'سعر الكيلو (دراجة)',
        labelEn: 'Price per Km (Bicycle)',
        helpAr: 'سعر الكيلو للدراجة.',
        helpEn: 'Per-km price for bicycles.',
      ),
      SettingsField(
        key: 'minDeliveryFeeBicycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة هوائية',
        groupEn: 'Bicycle',
        labelAr: 'أقل أجرة (دراجة)',
        labelEn: 'Min Fare (Bicycle)',
        helpAr: 'أقل رسوم توصيل للدراجة.',
        helpEn: 'Minimum delivery fee for bicycles.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeBicycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة هوائية',
        groupEn: 'Bicycle',
        labelAr: 'أقصى أجرة (دراجة)',
        labelEn: 'Max Fare (Bicycle)',
        helpAr: 'أقصى رسوم توصيل للدراجة. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for bicycles. 0 means no cap.',
      ),
      SettingsField(
        key: 'maxKmForBicycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة هوائية',
        groupEn: 'Bicycle',
        labelAr: 'أبعد مسافة للدراجة',
        labelEn: 'Max Distance (Bicycle)',
        helpAr: 'أبعد مسافة يُسمح بيها لطلبات الدراجة.',
        helpEn: 'Maximum distance allowed for bicycle deliveries.',
      ),
      SettingsField(
        key: 'allowMotorcycle',
        kind: SettingsFieldKind.toggle,
        groupAr: 'دراجة نارية',
        groupEn: 'Motorcycle',
        labelAr: 'السماح بالدراجة النارية',
        labelEn: 'Allow Motorcycle',
        helpAr: 'تشغيل/إيقاف الطلبات بالدراجات النارية.',
        helpEn: 'Enable/disable motorcycle deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmMotorcycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة نارية',
        groupEn: 'Motorcycle',
        labelAr: 'سعر الكيلو (دراجة نارية)',
        labelEn: 'Price per Km (Motorcycle)',
        helpAr: 'سعر الكيلو للدراجة النارية.',
        helpEn: 'Per-km price for motorcycles.',
      ),
      SettingsField(
        key: 'minDeliveryFeeMotorcycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة نارية',
        groupEn: 'Motorcycle',
        labelAr: 'أقل أجرة (دراجة نارية)',
        labelEn: 'Min Fare (Motorcycle)',
        helpAr: 'أقل رسوم توصيل للدراجة النارية.',
        helpEn: 'Minimum delivery fee for motorcycles.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeMotorcycle',
        kind: SettingsFieldKind.number,
        groupAr: 'دراجة نارية',
        groupEn: 'Motorcycle',
        labelAr: 'أقصى أجرة (دراجة نارية)',
        labelEn: 'Max Fare (Motorcycle)',
        helpAr: 'أقصى رسوم توصيل للدراجة النارية. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for motorcycles. 0 means no cap.',
      ),
      SettingsField(
        key: 'allowMotorTricycle',
        kind: SettingsFieldKind.toggle,
        groupAr: 'تروسيكل',
        groupEn: 'Motor Tricycle',
        labelAr: 'السماح بالتروسيكل',
        labelEn: 'Allow Motor Tricycle',
        helpAr: 'تشغيل/إيقاف الطلبات بالتروسيكل.',
        helpEn: 'Enable/disable motor-tricycle deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmMotorTricycle',
        kind: SettingsFieldKind.number,
        groupAr: 'تروسيكل',
        groupEn: 'Motor Tricycle',
        labelAr: 'سعر الكيلو (تروسيكل)',
        labelEn: 'Price per Km (Motor Tricycle)',
        helpAr: 'سعر الكيلو للتروسيكل.',
        helpEn: 'Per-km price for motor tricycles.',
      ),
      SettingsField(
        key: 'minDeliveryFeeMotorTricycle',
        kind: SettingsFieldKind.number,
        groupAr: 'تروسيكل',
        groupEn: 'Motor Tricycle',
        labelAr: 'أقل أجرة (تروسيكل)',
        labelEn: 'Min Fare (Motor Tricycle)',
        helpAr: 'أقل رسوم توصيل للتروسيكل.',
        helpEn: 'Minimum delivery fee for motor tricycles.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeMotorTricycle',
        kind: SettingsFieldKind.number,
        groupAr: 'تروسيكل',
        groupEn: 'Motor Tricycle',
        labelAr: 'أقصى أجرة (تروسيكل)',
        labelEn: 'Max Fare (Motor Tricycle)',
        helpAr: 'أقصى رسوم توصيل للتروسيكل. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for motor tricycles. 0 means no cap.',
      ),
      SettingsField(
        key: 'allowCar',
        kind: SettingsFieldKind.toggle,
        groupAr: 'سيارة',
        groupEn: 'Car',
        labelAr: 'السماح بالسيارة',
        labelEn: 'Allow Car',
        helpAr: 'تشغيل/إيقاف الطلبات بالسيارات.',
        helpEn: 'Enable/disable car deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmCar',
        kind: SettingsFieldKind.number,
        groupAr: 'سيارة',
        groupEn: 'Car',
        labelAr: 'سعر الكيلو (سيارة)',
        labelEn: 'Price per Km (Car)',
        helpAr: 'سعر الكيلو للسيارة.',
        helpEn: 'Per-km price for cars.',
      ),
      SettingsField(
        key: 'minDeliveryFeeCar',
        kind: SettingsFieldKind.number,
        groupAr: 'سيارة',
        groupEn: 'Car',
        labelAr: 'أقل أجرة (سيارة)',
        labelEn: 'Min Fare (Car)',
        helpAr: 'أقل رسوم توصيل للسيارة.',
        helpEn: 'Minimum delivery fee for cars.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeCar',
        kind: SettingsFieldKind.number,
        groupAr: 'سيارة',
        groupEn: 'Car',
        labelAr: 'أقصى أجرة (سيارة)',
        labelEn: 'Max Fare (Car)',
        helpAr: 'أقصى رسوم توصيل للسيارة. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for cars. 0 means no cap.',
      ),
      SettingsField(
        key: 'allowVan',
        kind: SettingsFieldKind.toggle,
        groupAr: 'نص نقل',
        groupEn: 'Van',
        labelAr: 'السماح بالفان',
        labelEn: 'Allow Van',
        helpAr: 'تشغيل/إيقاف الطلبات بالفان.',
        helpEn: 'Enable/disable van deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmVan',
        kind: SettingsFieldKind.number,
        groupAr: 'نص نقل',
        groupEn: 'Van',
        labelAr: 'سعر الكيلو (فان)',
        labelEn: 'Price per Km (Van)',
        helpAr: 'سعر الكيلو للفان.',
        helpEn: 'Per-km price for vans.',
      ),
      SettingsField(
        key: 'minDeliveryFeeVan',
        kind: SettingsFieldKind.number,
        groupAr: 'نص نقل',
        groupEn: 'Van',
        labelAr: 'أقل أجرة (فان)',
        labelEn: 'Min Fare (Van)',
        helpAr: 'أقل رسوم توصيل للفان.',
        helpEn: 'Minimum delivery fee for vans.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeVan',
        kind: SettingsFieldKind.number,
        groupAr: 'نص نقل',
        groupEn: 'Van',
        labelAr: 'أقصى أجرة (فان)',
        labelEn: 'Max Fare (Van)',
        helpAr: 'أقصى رسوم توصيل للفان. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for vans. 0 means no cap.',
      ),
      SettingsField(
        key: 'allowTruck',
        kind: SettingsFieldKind.toggle,
        groupAr: 'شاحنة',
        groupEn: 'Truck',
        labelAr: 'السماح بالشاحنة',
        labelEn: 'Allow Truck',
        helpAr: 'تشغيل/إيقاف الطلبات بالشاحنات.',
        helpEn: 'Enable/disable truck deliveries.',
      ),
      SettingsField(
        key: 'pricePerKmTruck',
        kind: SettingsFieldKind.number,
        groupAr: 'شاحنة',
        groupEn: 'Truck',
        labelAr: 'سعر الكيلو (شاحنة)',
        labelEn: 'Price per Km (Truck)',
        helpAr: 'سعر الكيلو للشاحنة.',
        helpEn: 'Per-km price for trucks.',
      ),
      SettingsField(
        key: 'minDeliveryFeeTruck',
        kind: SettingsFieldKind.number,
        groupAr: 'شاحنة',
        groupEn: 'Truck',
        labelAr: 'أقل أجرة (شاحنة)',
        labelEn: 'Min Fare (Truck)',
        helpAr: 'أقل رسوم توصيل للشاحنة.',
        helpEn: 'Minimum delivery fee for trucks.',
      ),
      SettingsField(
        key: 'maxDeliveryFeeTruck',
        kind: SettingsFieldKind.number,
        groupAr: 'شاحنة',
        groupEn: 'Truck',
        labelAr: 'أقصى أجرة (شاحنة)',
        labelEn: 'Max Fare (Truck)',
        helpAr: 'أقصى رسوم توصيل للشاحنة. 0 يعني بدون حد.',
        helpEn: 'Maximum delivery fee for trucks. 0 means no cap.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────── 4) Dispatch
  SettingsSection(
    id: 'dispatch',
    icon: LucideIcons.navigation,
    color: _dispatchColor,
    titleAr: 'توزيع الطلبات',
    titleEn: 'Dispatch',
    descAr: 'البحث عن مندوب ومهل القبول',
    descEn: 'Driver search and timeouts',
    explainAr:
        'هنا بتحدد إزاي التطبيق يدوّر على مندوب: نطاق البحث، وكل محاولة بيوسّع '
        'كام، ومهلة القبول، وإمتى الطلب يتلغي تلقائيًا.',
    explainEn:
        'Control how the app finds a driver: search radius, how much it widens '
        'per attempt, the accept timeout, and when pending orders auto-cancel.',
    fields: [
      SettingsField(
        key: 'driverSearchRadiusKm',
        kind: SettingsFieldKind.number,
        labelAr: 'نطاق البحث عن مندوب',
        labelEn: 'Driver Search Radius',
        helpAr: 'بداية نطاق البحث عن مندوب (بالكيلو).',
        helpEn: 'Initial driver search radius (km).',
      ),
      SettingsField(
        key: 'driverSearchRadiusStepKm',
        kind: SettingsFieldKind.number,
        labelAr: 'زيادة النطاق كل محاولة',
        labelEn: 'Search Radius Step',
        helpAr: 'كل محاولة فاشلة بيوسّع النطاق بكام كيلو.',
        helpEn: 'How much the radius widens after each failed attempt.',
      ),
      SettingsField(
        key: 'driverSearchRadiusMaxKm',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى نطاق بحث',
        labelEn: 'Max Search Radius',
        helpAr: 'أقصى مسافة للبحث عن مندوب.',
        helpEn: 'Maximum radius to search for a driver.',
      ),
      SettingsField(
        key: 'driverSearchMaxAttempts',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى عدد محاولات بحث',
        labelEn: 'Max Search Attempts',
        helpAr: 'أقصى عدد مرات محاولة إيجاد مندوب.',
        helpEn: 'Maximum number of driver-search attempts.',
      ),
      SettingsField(
        key: 'driverAcceptTimeoutSecs',
        kind: SettingsFieldKind.number,
        labelAr: 'مهلة قبول المندوب (ثواني)',
        labelEn: 'Driver Accept Timeout (sec)',
        helpAr: 'قد إيه المندوب عنده وقت عشان يقبل الطلب.',
        helpEn: 'How long the driver has to accept the order.',
      ),
      SettingsField(
        key: 'autoCancelPendingMins',
        kind: SettingsFieldKind.number,
        labelAr: 'إلغاء تلقائي للطلب المعلّق',
        labelEn: 'Auto-cancel Pending (min)',
        helpAr: 'بعد كام دقيقة يتلغي الطلب المعلّق تلقائيًا.',
        helpEn: 'Minutes before a pending order is auto-cancelled.',
      ),
      SettingsField(
        key: 'mobileWalletTimeoutMins',
        kind: SettingsFieldKind.number,
        labelAr: 'مهلة دفع المحفظة',
        labelEn: 'Mobile Wallet Timeout (min)',
        helpAr: 'بعد كام دقيقة تنتهي مهلة الدفع بالمحفظة.',
        helpEn: 'Minutes before a mobile-wallet payment times out.',
      ),
      SettingsField(
        key: 'maxDispatchBatchSize',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى عدد مندوبين في الدفعة',
        labelEn: 'Max Dispatch Batch Size',
        helpAr: 'أقصى عدد مندوبين بيتم عرض الطلب عليهم في المرة الواحدة.',
        helpEn: 'Maximum number of drivers the order is offered to at once.',
      ),
      SettingsField(
        key: 'maxActiveOrdersPerDriver',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى عدد طلبات نشطة للمندوب',
        labelEn: 'Max Active Orders Per Driver',
        helpAr: 'أقصى عدد طلبات يقدر المندوب الواحد يوصلها في نفس الوقت (1 - 10).',
        helpEn: 'Maximum concurrent active orders a single driver can carry at once (1 - 10).',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────────── 5) Loyalty
  SettingsSection(
    id: 'loyalty',
    icon: LucideIcons.coins,
    color: _loyaltyColor,
    titleAr: 'الكوينز والولاء',
    titleEn: 'Coins & Loyalty',
    descAr: 'قيمة الكوين وكسبه واستخدامه',
    descEn: 'Coin value, earning and usage',
    explainAr:
        'نظام النقاط: الكوين بيساوي كام جنيه، بتصرف كام عشان تكسب كوين، '
        'وأقل عدد كوينز مسموح باستخدامها.',
    explainEn:
        'The points system: how much a coin is worth, how much you must spend to '
        'earn one, and the minimum coins allowed per redemption.',
    fields: [
      SettingsField(
        key: 'coinValue',
        kind: SettingsFieldKind.number,
        labelAr: 'قيمة الكوين',
        labelEn: 'Coin Value',
        helpAr: 'الكوين الواحد بيساوي كام من العملة (مثال: 1 = 1 ج).',
        helpEn: 'How much one coin is worth (e.g. 1 = 1 EGP).',
      ),
      SettingsField(
        key: 'amountSpentPerCoin',
        kind: SettingsFieldKind.number,
        labelAr: 'المبلغ لكسب كوين',
        labelEn: 'Spend Per Coin',
        helpAr: 'لازم تصرف كام عشان تكسب كوين واحد (مثال: 10 = كل 10 ج كوين).',
        helpEn: 'How much must be spent to earn one coin (e.g. 10 = 1 coin/10).',
      ),
      SettingsField(
        key: 'minCoinsToUse',
        kind: SettingsFieldKind.number,
        labelAr: 'أقل عدد كوينز للاستخدام',
        labelEn: 'Min Coins To Use',
        helpAr: 'أقل عدد كوينز مسموح يستخدمها العميل في الطلب.',
        helpEn: 'Minimum coins a customer may redeem per order.',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────────── 6) Drivers
  SettingsSection(
    id: 'drivers',
    icon: LucideIcons.userCog,
    color: _driversColor,
    titleAr: 'المندوبين والحوافز',
    titleEn: 'Drivers & Bonuses',
    descAr: 'الورديات والبونص ومستويات السائقين',
    descEn: 'Shifts, bonus and driver tiers',
    explainAr:
        'هنا بتظبط نظام الورديات، وبونص المندوب (مبلغ وتاريخ ومن يدفعه)، '
        'وبونص المستويات لكل كيلو، وحد التسوية.',
    explainEn:
        'Configure the shifts system, the driver bonus (amount, period and who '
        'pays it), per-km tier bonuses, and the settlement threshold.',
    fields: [
      SettingsField(
        key: 'driverShiftsEnabled',
        kind: SettingsFieldKind.toggle,
        labelAr: 'تشغيل نظام الورديات',
        labelEn: 'Enable Driver Shifts',
        helpAr: 'تشغيل/إيقاف نظام ورديات المندوبين.',
        helpEn: 'Enable/disable the driver shifts system.',
      ),
      SettingsField(
        key: 'driverBonusActive',
        kind: SettingsFieldKind.toggle,
        labelAr: 'تفعيل بونص المندوب',
        labelEn: 'Enable Driver Bonus',
        helpAr: 'المفتاح الرئيسي لبونص المندوب.',
        helpEn: 'Master switch for the driver bonus.',
      ),
      SettingsField(
        key: 'driverBonusAmount',
        kind: SettingsFieldKind.number,
        labelAr: 'قيمة بونص المندوب',
        labelEn: 'Driver Bonus Amount',
        helpAr: 'قيمة البونص المضافة للمندوب (مبلغ ثابت).',
        helpEn: 'Bonus amount added for the driver (fixed amount).',
      ),
      SettingsField(
        key: 'driverBonusStartDate',
        kind: SettingsFieldKind.text,
        labelAr: 'بداية فترة البونص',
        labelEn: 'Bonus Start Date',
        helpAr: 'تاريخ بداية البونص (صيغة: YYYY-MM-DD).',
        helpEn: 'Bonus start date (format: YYYY-MM-DD).',
      ),
      SettingsField(
        key: 'driverBonusEndDate',
        kind: SettingsFieldKind.text,
        labelAr: 'نهاية فترة البونص',
        labelEn: 'Bonus End Date',
        helpAr: 'تاريخ نهاية البونص (صيغة: YYYY-MM-DD).',
        helpEn: 'Bonus end date (format: YYYY-MM-DD).',
      ),
      SettingsField(
        key: 'driverBonusPaidByCustomer',
        kind: SettingsFieldKind.toggle,
        labelAr: 'البونص على العميل؟',
        labelEn: 'Bonus Paid By Customer',
        helpAr:
            'لو مفعّل، العميل بيدفع البونص كرسوم. لو مقفول، المنصة هي اللي '
            'بتدفعه.',
        helpEn:
            'If on, the customer pays the bonus as a fee; otherwise the platform '
            'pays it.',
      ),
      SettingsField(
        key: 'bronzeTierBonusPerKm',
        kind: SettingsFieldKind.number,
        labelAr: 'بونص الكيلو (برونزي)',
        labelEn: 'Bronze Tier Bonus/Km',
        helpAr: 'بونص لكل كيلو لمندوبي المستوى البرونزي.',
        helpEn: 'Per-km bonus for Bronze-tier drivers.',
      ),
      SettingsField(
        key: 'silverTierBonusPerKm',
        kind: SettingsFieldKind.number,
        labelAr: 'بونص الكيلو (فضي)',
        labelEn: 'Silver Tier Bonus/Km',
        helpAr: 'بونص لكل كيلو لمندوبي المستوى الفضي.',
        helpEn: 'Per-km bonus for Silver-tier drivers.',
      ),
      SettingsField(
        key: 'goldTierBonusPerKm',
        kind: SettingsFieldKind.number,
        labelAr: 'بونص الكيلو (ذهبي)',
        labelEn: 'Gold Tier Bonus/Km',
        helpAr: 'بونص لكل كيلو لمندوبي المستوى الذهبي (يُستخدم في الحساب).',
        helpEn: 'Per-km bonus for Gold-tier drivers (used at checkout).',
      ),
      SettingsField(
        key: 'driverSettlementOrderThreshold',
        kind: SettingsFieldKind.number,
        labelAr: 'عدد الطلبات قبل التسوية',
        labelEn: 'Settlement Order Threshold',
        helpAr:
            'بعد كام طلب، المندوب اللي عليه فلوس لازم يسوّي قبل ما يستلم طلبات '
            'جديدة. 0 يعني معطّل.',
        helpEn:
            'After this many orders, a driver who owes money must settle before '
            'receiving new orders. 0 disables it.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 7) Breaks
  SettingsSection(
    id: 'breaks',
    icon: LucideIcons.coffee,
    color: _breaksColor,
    titleAr: 'الاستراحات',
    titleEn: 'Breaks',
    descAr: 'استراحات المندوبين وحدودها',
    descEn: 'Driver breaks and limits',
    explainAr:
        'هنا بتظبط استراحات المندوب: مسموحة ولا لأ، ومدة أقصى إجمالية، وعددها، '
        'وأقصى مدة استراحة واحدة، ومهلة الموافقة.',
    explainEn:
        'Configure driver breaks: whether allowed, total duration cap, count '
        'cap, max single-break length and the approval expiry.',
    fields: [
      SettingsField(
        key: 'breaksEnabled',
        kind: SettingsFieldKind.toggle,
        labelAr: 'تشغيل الاستراحات',
        labelEn: 'Enable Breaks',
        helpAr:
            'لو مقفول، المندوب ميقدرش يطلب استراحة. (إيقاف استراحة شغّالة '
            'ممكن دايمًا).',
        helpEn:
            'If off, drivers cannot request breaks. (An active break can always '
            'be ended.)',
      ),
      SettingsField(
        key: 'maxBreakMinutesPerShift',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى دقايق استراحة في الوردية',
        labelEn: 'Max Break Minutes/Shift',
        helpAr: 'أقصى إجمالي دقايق استراحة في الوردية الواحدة.',
        helpEn: 'Maximum total break minutes per shift.',
      ),
      SettingsField(
        key: 'maxBreaksPerShift',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى عدد استراحات في الوردية',
        labelEn: 'Max Breaks/Shift',
        helpAr: 'أقصى عدد مرات الاستراحة في الوردية الواحدة.',
        helpEn: 'Maximum number of breaks per shift.',
      ),
      SettingsField(
        key: 'maxSingleBreakMinutes',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى مدة استراحة واحدة',
        labelEn: 'Max Single Break Minutes',
        helpAr: 'بعدها النظام بيقفل الاستراحة تلقائيًا.',
        helpEn: 'After this the system auto-ends the break.',
      ),
      SettingsField(
        key: 'pendingBreakExpiryMins',
        kind: SettingsFieldKind.number,
        labelAr: 'انتهاء صلاحية طلب الاستراحة',
        labelEn: 'Pending Break Expiry (min)',
        helpAr: 'بعد كام دقيقة طلب الاستراحة المعلّق يتم رفضه تلقائيًا.',
        helpEn: 'Minutes before a pending break request auto-rejects.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 8) App
  SettingsSection(
    id: 'app',
    icon: LucideIcons.smartphone,
    color: _appColor,
    titleAr: 'التطبيق والتحديث',
    titleEn: 'App & Updates',
    descAr: 'وضع الصيانة والإصدارات',
    descEn: 'Maintenance mode and versions',
    explainAr:
        'هنا بتظبط وضع الصيانة، وأقل إصدار مسموح وأحدث إصدار لكل نظام، والتحديث '
        'الإجباري، ورابط المتجر.',
    explainEn:
        'Configure maintenance mode, the minimum and latest version per platform, '
        'forced updates, and the store links.',
    fields: [
      SettingsField(
        key: 'isMaintenanceMode',
        kind: SettingsFieldKind.toggle,
        labelAr: 'وضع الصيانة',
        labelEn: 'Maintenance Mode',
        helpAr: 'لو مفعّل، التطبيق بيتقفل للصيانة على كل المستخدمين.',
        helpEn: 'If on, the app is closed for maintenance for all users.',
      ),
      SettingsField(
        key: 'androidMinVersion',
        kind: SettingsFieldKind.text,
        groupAr: 'أندرويد',
        groupEn: 'Android',
        labelAr: 'أقل إصدار أندرويد مسموح',
        labelEn: 'Android Min Version',
        helpAr: 'أقل إصدار مسموح؛ الأقدم منه يُطلب منه التحديث.',
        helpEn: 'Minimum allowed version; older ones are asked to update.',
      ),
      SettingsField(
        key: 'androidLatestVersion',
        kind: SettingsFieldKind.text,
        groupAr: 'أندرويد',
        groupEn: 'Android',
        labelAr: 'أحدث إصدار أندرويد',
        labelEn: 'Android Latest Version',
        helpAr: 'أحدث إصدار متاح لأندرويد.',
        helpEn: 'Latest available Android version.',
      ),
      SettingsField(
        key: 'androidForceUpdate',
        kind: SettingsFieldKind.toggle,
        groupAr: 'أندرويد',
        groupEn: 'Android',
        labelAr: 'تحديث إجباري (أندرويد)',
        labelEn: 'Android Force Update',
        helpAr: 'لو مفعّل، الإصدار الأقدم من الحد الأدنى يتحدّث إجباريًا.',
        helpEn: 'If on, versions below the minimum are force-updated.',
      ),
      SettingsField(
        key: 'androidStoreUrl',
        kind: SettingsFieldKind.text,
        groupAr: 'أندرويد',
        groupEn: 'Android',
        labelAr: 'رابط متجر أندرويد',
        labelEn: 'Android Store URL',
        helpAr: 'رابط صفحة التطبيق على جوجل بلاي.',
        helpEn: 'The app link on Google Play.',
      ),
      SettingsField(
        key: 'iosMinVersion',
        kind: SettingsFieldKind.text,
        groupAr: 'iOS',
        groupEn: 'iOS',
        labelAr: 'أقل إصدار iOS مسموح',
        labelEn: 'iOS Min Version',
        helpAr: 'أقل إصدار مسموح لـ iOS.',
        helpEn: 'Minimum allowed iOS version.',
      ),
      SettingsField(
        key: 'iosLatestVersion',
        kind: SettingsFieldKind.text,
        groupAr: 'iOS',
        groupEn: 'iOS',
        labelAr: 'أحدث إصدار iOS',
        labelEn: 'iOS Latest Version',
        helpAr: 'أحدث إصدار متاح لـ iOS.',
        helpEn: 'Latest available iOS version.',
      ),
      SettingsField(
        key: 'iosForceUpdate',
        kind: SettingsFieldKind.toggle,
        groupAr: 'iOS',
        groupEn: 'iOS',
        labelAr: 'تحديث إجباري (iOS)',
        labelEn: 'iOS Force Update',
        helpAr: 'لو مفعّل، الإصدار الأقدم من الحد الأدنى يتحدّث إجباريًا.',
        helpEn: 'If on, versions below the minimum are force-updated.',
      ),
      SettingsField(
        key: 'iosStoreUrl',
        kind: SettingsFieldKind.text,
        groupAr: 'iOS',
        groupEn: 'iOS',
        labelAr: 'رابط متجر iOS',
        labelEn: 'iOS Store URL',
        helpAr: 'رابط صفحة التطبيق على App Store.',
        helpEn: 'The app link on the App Store.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────── 9) Customer
  SettingsSection(
    id: 'customer',
    icon: LucideIcons.user,
    color: _customerColor,
    titleAr: 'سياسات العميل',
    titleEn: 'Customer Policies',
    descAr: 'حدود الطلبات وتأكيد OTP',
    descEn: 'Order limits and OTP',
    explainAr:
        'هنا بتحدد أقصى عدد طلبات نشطة للعميل، وهل لازم توصيل سابق قبل تعدد '
        'الطلبات، وإعدادات كود التحقق (OTP).',
    explainEn:
        'Set the maximum active orders per customer, whether a prior delivery is '
        'required before multiple orders, and the OTP settings.',
    fields: [
      SettingsField(
        key: 'maxActiveOrdersPerCustomer',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى عدد طلبات نشطة للعميل',
        labelEn: 'Max Active Orders',
        helpAr: 'أقصى عدد طلبات نشطة مسموح للعميل في نفس الوقت.',
        helpEn: 'Maximum active orders allowed per customer at once.',
      ),
      SettingsField(
        key: 'requirePriorDeliveryForMultipleOrders',
        kind: SettingsFieldKind.toggle,
        labelAr: 'اشتراط توصيل سابق لتعدد الطلبات',
        labelEn: 'Require Prior Delivery',
        helpAr: 'لو مفعّل، العميل لازم يكون عنده توصيل مُسلّم قبل تعدد الطلبات.',
        helpEn:
            'If on, a customer must have a delivered order before placing '
            'multiple orders.',
      ),
      SettingsField(
        key: 'maxOtpAttempts',
        kind: SettingsFieldKind.number,
        labelAr: 'أقصى محاولات كود التحقق',
        labelEn: 'Max OTP Attempts',
        helpAr: 'أقصى عدد محاولات قبل حظر مؤقت.',
        helpEn: 'Maximum attempts before a temporary block.',
      ),
      SettingsField(
        key: 'otpExpirySeconds',
        kind: SettingsFieldKind.number,
        labelAr: 'صلاحية كود التحقق (ثواني)',
        labelEn: 'OTP Expiry (sec)',
        helpAr: 'قد إيه كود التحقق فاضل صالح.',
        helpEn: 'How long the OTP stays valid.',
      ),
    ],
  ),

  // ──────────────────────────────────────────────────────────── 10) Assets
  SettingsSection(
    id: 'assets',
    icon: LucideIcons.image,
    color: _assetsColor,
    titleAr: 'الصور والأيقونات',
    titleEn: 'Images & Icons',
    descAr: 'الغلاف وبانر التوصيل وأيقونات المركبات',
    descEn: 'Cover, banner and vehicle icons',
    explainAr:
        'هنا بترفع الصور اللي بتظهر في تطبيق العميل: الغلاف الرئيسي، بانر '
        'التوصيل، وأيقونة كل نوع مركبة.',
    explainEn:
        'Upload the images shown in the customer app: the home cover, the '
        'delivery banner and each vehicle icon.',
    fields: [
      SettingsField(
        key: 'homeCoverUrl',
        kind: SettingsFieldKind.image,
        imageType: 'home-cover',
        wide: true,
        labelAr: 'صورة الغلاف الرئيسية',
        labelEn: 'Home Cover',
        helpAr: 'الصورة الكبيرة أعلى الصفحة الرئيسية.',
        helpEn: 'The large image at the top of the home screen.',
      ),
      SettingsField(
        key: 'bicycleIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'bicycle',
        labelAr: 'أيقونة دراجة',
        labelEn: 'Bicycle Icon',
        helpAr: 'أيقونة الدراجة الهوائية.',
        helpEn: 'The bicycle icon.',
      ),
      SettingsField(
        key: 'motorcycleIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'motorcycle',
        labelAr: 'أيقونة دراجة نارية',
        labelEn: 'Motorcycle Icon',
        helpAr: 'أيقونة الدراجة النارية.',
        helpEn: 'The motorcycle icon.',
      ),
      SettingsField(
        key: 'motorTricycleIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'motor_tricycle',
        labelAr: 'أيقونة تروسيكل',
        labelEn: 'Motor Tricycle Icon',
        helpAr: 'أيقونة التروسيكل.',
        helpEn: 'The motor-tricycle icon.',
      ),
      SettingsField(
        key: 'carIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'car',
        labelAr: 'أيقونة سيارة',
        labelEn: 'Car Icon',
        helpAr: 'أيقونة السيارة.',
        helpEn: 'The car icon.',
      ),
      SettingsField(
        key: 'vanIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'van',
        labelAr: 'أيقونة فان',
        labelEn: 'Van Icon',
        helpAr: 'أيقونة الفان.',
        helpEn: 'The van icon.',
      ),
      SettingsField(
        key: 'truckIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'truck',
        labelAr: 'أيقونة شاحنة',
        labelEn: 'Truck Icon',
        helpAr: 'أيقونة الشاحنة.',
        helpEn: 'The truck icon.',
      ),
      SettingsField(
        key: 'deliveryBannerIconUrl',
        kind: SettingsFieldKind.image,
        imageType: 'delivery-banner',
        wide: true,
        labelAr: 'بانر التوصيل',
        labelEn: 'Delivery Banner',
        helpAr: 'بانر قسم التوصيل.',
        helpEn: 'The delivery section banner.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────── 11) Support
  SettingsSection(
    id: 'support',
    icon: LucideIcons.helpCircle,
    color: _supportColor,
    titleAr: 'الدعم والقوانين',
    titleEn: 'Support & Legal',
    descAr: 'بيانات التواصل والروابط القانونية',
    descEn: 'Contact details and legal links',
    explainAr:
        'بيانات التواصل مع الدعم (إيميل/تليفون/واتساب) وروابط الشروط وسياسة '
        'الخصوصية.',
    explainEn:
        'Support contact details (email/phone/WhatsApp) and the terms & privacy '
        'links.',
    fields: [
      SettingsField(
        key: 'supportEmail',
        kind: SettingsFieldKind.text,
        labelAr: 'إيميل الدعم',
        labelEn: 'Support Email',
        helpAr: 'البريد الإلكتروني للدعم.',
        helpEn: 'The support email address.',
      ),
      SettingsField(
        key: 'supportPhone',
        kind: SettingsFieldKind.text,
        labelAr: 'تليفون الدعم',
        labelEn: 'Support Phone',
        helpAr: 'رقم تليفون الدعم.',
        helpEn: 'The support phone number.',
      ),
      SettingsField(
        key: 'supportWhatsapp',
        kind: SettingsFieldKind.text,
        labelAr: 'واتساب الدعم',
        labelEn: 'Support WhatsApp',
        helpAr: 'رقم واتساب الدعم.',
        helpEn: 'The support WhatsApp number.',
      ),
      SettingsField(
        key: 'termsUrl',
        kind: SettingsFieldKind.text,
        labelAr: 'رابط الشروط والأحكام',
        labelEn: 'Terms URL',
        helpAr: 'رابط صفحة الشروط والأحكام.',
        helpEn: 'The terms & conditions page link.',
      ),
      SettingsField(
        key: 'privacyUrl',
        kind: SettingsFieldKind.text,
        labelAr: 'رابط سياسة الخصوصية',
        labelEn: 'Privacy URL',
        helpAr: 'رابط صفحة سياسة الخصوصية.',
        helpEn: 'The privacy policy page link.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────── 12) Retention
  SettingsSection(
    id: 'retention',
    icon: LucideIcons.database,
    color: _retentionColor,
    titleAr: 'الاحتفاظ بالبيانات',
    titleEn: 'Data Retention',
    descAr: 'مدة الاحتفاظ بالبيانات بالأيام',
    descEn: 'How long data is kept (days)',
    explainAr:
        'هنا بتحدد مدة الاحتفاظ بكل نوع بيانات بالأيام، وبعدها بيتم حذفها '
        'تلقائيًا.',
    explainEn:
        'Set how many days each kind of data is kept before it is deleted '
        'automatically.',
    fields: [
      SettingsField(
        key: 'retentionOrdersDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ الطلبات',
        labelEn: 'Orders Retention (days)',
        helpAr: 'بعد كام يوم تتشال الطلبات القديمة.',
        helpEn: 'Days before old orders are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionArchivedChatsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ الشاتات',
        labelEn: 'Archived Chats Retention (days)',
        helpAr: 'بعد كام يوم تتشال المحادثات المؤرشفة.',
        helpEn: 'Days before archived chats are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionNotificationsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ الإشعارات',
        labelEn: 'Notifications Retention (days)',
        helpAr: 'بعد كام يوم تتشال الإشعارات القديمة.',
        helpEn: 'Days before old notifications are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionExpiredSessionsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ الجلسات المنتهية',
        labelEn: 'Sessions Retention (days)',
        helpAr: 'بعد انتهاء الجلسة بكام يوم تتشال.',
        helpEn: 'Days after expiry before sessions are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionAuditLogsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ سجل التغييرات',
        labelEn: 'Audit Logs Retention (days)',
        helpAr: 'بعد كام يوم تتشال سجلات التغييرات.',
        helpEn: 'Days before audit logs are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionAbandonedCartsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ السلات المتروكة',
        labelEn: 'Abandoned Carts Retention (days)',
        helpAr: 'بعد كام يوم تتشال السلات المتروكة.',
        helpEn: 'Days before abandoned carts are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionWalletTransactionsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ حركات المحفظة',
        labelEn: 'Wallet Transactions Retention (days)',
        helpAr: 'بعد كام يوم تتشال حركات المحفظة.',
        helpEn: 'Days before wallet transactions are hard-deleted.',
      ),
      SettingsField(
        key: 'retentionStatisticsDays',
        kind: SettingsFieldKind.number,
        labelAr: 'مدة حفظ الإحصائيات',
        labelEn: 'Statistics Retention (days)',
        helpAr: 'بعد كام يوم تتشال الإحصائيات.',
        helpEn: 'Days before statistics are hard-deleted.',
      ),
    ],
  ),
];
