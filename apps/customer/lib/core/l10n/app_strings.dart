import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppStrings {
  final BuildContext _context;
  const AppStrings(this._context);

  static AppStrings of(BuildContext context) {
    return AppStrings(context);
  }

  bool get isArabic => Localizations.localeOf(_context).languageCode == 'ar';
  String get dontHaveAccount => 'app.dontHaveAccount'.tr(context: _context);

  String get navHome => 'app.navHome'.tr(context: _context);
  String get navOrders => 'app.navOrders'.tr(context: _context);
  String get navChat => 'app.navChat'.tr(context: _context);
  String get navProfile => 'app.navProfile'.tr(context: _context);
  String get navSearch => 'app.navSearch'.tr(context: _context);
  String get deliverTo => 'app.deliverTo'.tr(context: _context);
  String get locationName => 'app.locationName'.tr(context: _context);
  String get searchRestaurant => 'app.searchRestaurant'.tr(context: _context);
  String get restaurants => 'app.restaurants'.tr(context: _context);
  String get pharmacies => 'app.pharmacies'.tr(context: _context);
  String get supermarkets => 'app.supermarkets'.tr(context: _context);
  String get nearbyRestaurants => 'app.nearbyRestaurants'.tr(context: _context);
  String get availablePharm => 'app.availablePharm'.tr(context: _context);
  String get nearbySuper => 'app.nearbySuper'.tr(context: _context);
  String get seeAll => 'app.seeAll'.tr(context: _context);
  String get customDeliveryBannerTitle => 'app.customDeliveryBannerTitle'.tr(context: _context);
  String get customDeliveryBannerSub => 'app.customDeliveryBannerSub'.tr(context: _context);
  String get customDeliveryTitle => 'app.customDeliveryTitle'.tr(context: _context);
  String get pickupLocation => 'app.pickupLocation'.tr(context: _context);
  String get dropoffLocation => 'app.dropoffLocation'.tr(context: _context);
  String get itemDetails => 'app.itemDetails'.tr(context: _context);
  String get enterPickupLocation => 'app.enterPickupLocation'.tr(context: _context);
  String get enterDropoffLocation => 'app.enterDropoffLocation'.tr(context: _context);
  String get enterItemDetails => 'app.enterItemDetails'.tr(context: _context);
  String get vehicleType => 'app.vehicleType'.tr(context: _context);
  String get motorcycle => 'app.motorcycle'.tr(context: _context);
  String get car => 'app.car'.tr(context: _context);
  String get requestCourier => 'app.requestCourier'.tr(context: _context);
  String get trackOrder => 'app.trackOrder'.tr(context: _context);
  String get cartButton => 'app.cartButton'.tr(context: _context);
  String get egp => 'app.egp'.tr(context: _context);
  String get retry => 'app.retry'.tr(context: _context);
  String get maintenanceTitle => 'app.maintenanceTitle'.tr(context: _context);
  String get maintenanceMessage => 'app.maintenanceMessage'.tr(context: _context);
  String get updateRequiredTitle => 'app.updateRequiredTitle'.tr(context: _context);
  String get updateRequiredMessage => 'app.updateRequiredMessage'.tr(context: _context);
  String get updateNow => 'app.updateNow'.tr(context: _context);
  String get updateAvailableTitle => 'app.updateAvailableTitle'.tr(context: _context);
  String get updateAvailableMessage => 'app.updateAvailableMessage'.tr(context: _context);
  String get updateLater => 'app.updateLater'.tr(context: _context);
  String get terms => 'app.terms'.tr(context: _context);
  String get privacy => 'app.privacy'.tr(context: _context);
  String get noResults => 'app.noResults'.tr(context: _context);
  String get orderNow => 'app.orderNow'.tr(context: _context);
  String get chatWithVendor => 'app.chatWithVendor'.tr(context: _context);
  String get chatWithVendorSubtext => 'app.chatWithVendorSubtext'.tr(context: _context);
  String get menu => 'app.menu'.tr(context: _context);
  String get viewCart => 'app.viewCart'.tr(context: _context);
  String get addedToCart => 'app.addedToCart'.tr(context: _context);
  String get cart => 'app.cart'.tr(context: _context);
  String get clearAll => 'app.clearAll'.tr(context: _context);
  String get emptyCart => 'app.emptyCart'.tr(context: _context);
  String get emptyCartSub => 'app.emptyCartSub'.tr(context: _context);
  String get browseNow => 'app.browseNow'.tr(context: _context);
  String get total => 'app.total'.tr(context: _context);
  String get checkout => 'app.checkout'.tr(context: _context);
  String get subtotal => 'app.subtotal'.tr(context: _context);
  String get deliveryFee => 'app.deliveryFee'.tr(context: _context);
  String get free => 'app.free'.tr(context: _context);
  String get orderSummary => 'app.orderSummary'.tr(context: _context);
  String get placeOrder => 'app.placeOrder'.tr(context: _context);
  String get checkoutTitle => 'app.checkoutTitle'.tr(context: _context);
  String get deliveryAddress => 'app.deliveryAddress'.tr(context: _context);
  String get paymentMethod => 'app.paymentMethod'.tr(context: _context);
  String get instapay => 'app.instapay'.tr(context: _context);
  String get mobileWallet => 'app.mobileWallet'.tr(context: _context);
  String get cashOnDelivery => 'app.cashOnDelivery'.tr(context: _context);
  String get orderSuccess => 'app.orderSuccess'.tr(context: _context);
  String get orderSuccessSub => 'app.orderSuccessSub'.tr(context: _context);
  String get goToOrders => 'app.goToOrders'.tr(context: _context);
  String get processing => 'app.processing'.tr(context: _context);
  String get editProfile => 'app.editProfile'.tr(context: _context);
  String get myAddresses => 'app.myAddresses'.tr(context: _context);
  String get helpCenter => 'app.helpCenter'.tr(context: _context);
  String get aboutApp => 'app.aboutApp'.tr(context: _context);
  String get logout => 'app.logout'.tr(context: _context);
  String get language => 'app.language'.tr(context: _context);
  String get notifications => 'app.notifications'.tr(context: _context);
  String get darkMode => 'app.darkMode'.tr(context: _context);
  String get languageName => 'app.languageName'.tr(context: _context);
  String get enabled => 'app.enabled'.tr(context: _context);
  String get disabled => 'app.disabled'.tr(context: _context);
  String get on => 'app.on'.tr(context: _context);
  String get off => 'app.off'.tr(context: _context);
  String get logoutConfirm => 'app.logoutConfirm'.tr(context: _context);
  String get cancel => 'app.cancel'.tr(context: _context);
  String get saveChanges => 'app.saveChanges'.tr(context: _context);
  String get fullName => 'app.fullName'.tr(context: _context);
  String get emailAddress => 'app.emailAddress'.tr(context: _context);
  String get phoneNumber => 'app.phoneNumber'.tr(context: _context);
  String get phoneRequired => 'app.phoneRequired'.tr(context: _context);
  String get completePhoneTitle => 'app.completePhoneTitle'.tr(context: _context);
  String get completePhoneMessage => 'app.completePhoneMessage'.tr(context: _context);
  String get noAddresses => 'app.noAddresses'.tr(context: _context);
  String get addAddressSub => 'app.addAddressSub'.tr(context: _context);
  String get addNewAddress => 'app.addNewAddress'.tr(context: _context);
  String get addressLabel => 'app.addressLabel'.tr(context: _context);
  String get fullAddress => 'app.fullAddress'.tr(context: _context);
  String get addAddress => 'app.addAddress'.tr(context: _context);
  String get addressAdded => 'app.addressAdded'.tr(context: _context);
  String get addressUpdated => 'app.addressUpdated'.tr(context: _context);
  String get addressDeleted => 'app.addressDeleted'.tr(context: _context);
  String get address => 'app.address'.tr(context: _context);
  String get welcomeBack => 'app.welcomeBack'.tr(context: _context);
  String get loginToApp => 'app.loginToApp'.tr(context: _context);
  String get email => 'app.email'.tr(context: _context);
  String get password => 'app.password'.tr(context: _context);
  String get emailRequired => 'app.emailRequired'.tr(context: _context);
  String get passwordMinLen => 'app.passwordMinLen'.tr(context: _context);
  String get forgotPassword => 'app.forgotPassword'.tr(context: _context);
  String get login => 'app.login'.tr(context: _context);
  String get or => 'app.or'.tr(context: _context);
  String get continueWithGoogle => 'app.continueWithGoogle'.tr(context: _context);
  String get signUp => 'app.signUp'.tr(context: _context);
  String get createAccount => 'app.createAccount'.tr(context: _context);
  String get joinApp => 'app.joinApp'.tr(context: _context);
  String get nameRequired => 'app.nameRequired'.tr(context: _context);
  String get phoneNumberOptional => 'app.phoneNumberOptional'.tr(context: _context);
  String get register => 'app.register'.tr(context: _context);
  String get alreadyHaveAccount => 'app.alreadyHaveAccount'.tr(context: _context);
  String get vendor => 'app.vendor'.tr(context: _context);
  String get defaultCity => 'app.defaultCity'.tr(context: _context);
  String get orderNo => 'app.orderNo'.tr(context: _context);
  String get readLess => 'app.readLess'.tr(context: _context);
  String get readMore => 'app.readMore'.tr(context: _context);
  String get customCourierDesc => 'app.customCourierDesc'.tr(context: _context);
  String get rideServiceDesc => 'app.rideServiceDesc'.tr(context: _context);
  String get yourLocation => 'app.yourLocation'.tr(context: _context);
  String get whereAreYou => 'app.whereAreYou'.tr(context: _context);
  String get wherePickUp => 'app.wherePickUp'.tr(context: _context);
  String get destination => 'app.destination'.tr(context: _context);
  String get whereToGo => 'app.whereToGo'.tr(context: _context);
  String get wherePackageGoing => 'app.wherePackageGoing'.tr(context: _context);
  String get required => 'app.required'.tr(context: _context);
  String get delivery => 'app.delivery'.tr(context: _context);
  String get ride => 'app.ride'.tr(context: _context);
  String get findingCaptain => 'app.findingCaptain'.tr(context: _context);
  String get pleaseWaitConnectDriver => 'app.pleaseWaitConnectDriver'.tr(context: _context);
  String get requestConfirmed => 'app.requestConfirmed'.tr(context: _context);
  String get plateNo => 'app.plateNo'.tr(context: _context);
  String get trackRequest => 'app.trackRequest'.tr(context: _context);
  String get backToHome => 'app.backToHome'.tr(context: _context);
  String get products => 'app.products'.tr(context: _context);
  String get noItemsInCategory => 'app.noItemsInCategory'.tr(context: _context);
  String get errorPrefix => 'app.errorPrefix'.tr(context: _context);
  String get catAll => 'app.catAll'.tr(context: _context);
  String get catMedicines => 'app.catMedicines'.tr(context: _context);
  String get catCosmetics => 'app.catCosmetics'.tr(context: _context);
  String get addToCart => 'app.addToCart'.tr(context: _context);
  String get outOfStock => 'app.outOfStock'.tr(context: _context);
  String get done => 'app.done'.tr(context: _context);
  String get allStores => 'app.allStores'.tr(context: _context);
  String get stores => 'app.stores'.tr(context: _context);
  String get allResults => 'app.allResults'.tr(context: _context);
  String get searchResults => 'app.searchResults'.tr(context: _context);
  String get clickToViewMenu => 'app.clickToViewMenu'.tr(context: _context);
  String get searchInStores => 'app.searchInStores'.tr(context: _context);
  String get featuredSuggestions => 'app.featuredSuggestions'.tr(context: _context);
  String get searchErrorPrefix => 'app.searchErrorPrefix'.tr(context: _context);
  String get typeAMessage => 'app.typeAMessage'.tr(context: _context);
  String get onlyImagesAllowed => 'app.onlyImagesAllowed'.tr(context: _context);
  String get orderShort => 'app.orderShort'.tr(context: _context);
  String get proLabel => 'app.proLabel'.tr(context: _context);
  String get nearbyStores => 'app.nearbyStores'.tr(context: _context);
  String get nearbyPrefix => 'app.nearbyPrefix'.tr(context: _context);
  String get nearbySuffix => 'app.nearbySuffix'.tr(context: _context);
  String get appName => 'app.appName'.tr(context: _context);
  String get search => 'app.search'.tr(context: _context);
  String get supportGreeting => 'app.supportGreeting'.tr(context: _context);
  String get vendorGreeting => 'app.vendorGreeting'.tr(context: _context);
  String get edit => 'app.edit'.tr(context: _context);
  String get delete => 'app.delete'.tr(context: _context);
  String get voiceMessage => 'app.voiceMessage'.tr(context: _context);
  String get releaseToSend => 'app.releaseToSend'.tr(context: _context);
  String get uploading => 'app.uploading'.tr(context: _context);
  String get deleteConfirmTitle => 'app.deleteConfirmTitle'.tr(context: _context);
  String get deleteConfirmBody => 'app.deleteConfirmBody'.tr(context: _context);
  String get offerTitle => 'app.offerTitle'.tr(context: _context);
  String get viewOffer => 'app.viewOffer'.tr(context: _context);
  String get confirmOrder => 'app.confirmOrder'.tr(context: _context);
  String get cancelOrder => 'app.cancelOrder'.tr(context: _context);
  String get package => 'app.package'.tr(context: _context);
  String get strip => 'app.strip'.tr(context: _context);
  String get sellingUnit => 'app.sellingUnit'.tr(context: _context);
  String get selectVariant => 'app.selectVariant'.tr(context: _context);
  String get yes => 'app.yes'.tr(context: _context);
  String get confirm => 'app.confirm'.tr(context: _context);
  String get hotDeals => 'app.hotDeals'.tr(context: _context);
  String get offerBadge => 'app.offerBadge'.tr(context: _context);
  String get seeAllOffers => 'app.seeAllOffers'.tr(context: _context);
  String get rememberMe => 'app.rememberMe'.tr(context: _context);
  String get orLoginWithAnother => 'app.orLoginWithAnother'.tr(context: _context);
  String get ticketExists => 'app.ticketExists'.tr(context: _context);
  String get authRequiredTitle => 'app.authRequiredTitle'.tr(context: _context);
  String get authRequiredMessage => 'app.authRequiredMessage'.tr(context: _context);

  String get verifyOtp => 'app.verifyOtp'.tr(context: _context);
  String get checkYourEmail => 'app.checkYourEmail'.tr(context: _context);
  String otpSentToEmail(String email) =>
      'app.otpSentToEmail'.tr(context: _context, namedArgs: {'email': email});
  String get verificationCode => 'app.verificationCode'.tr(context: _context);
  String get enterValidCode => 'app.enterValidCode'.tr(context: _context);
  String get verifyCode => 'app.verifyCode'.tr(context: _context);
  String get accountVerifiedSuccess => 'app.accountVerifiedSuccess'.tr(context: _context);
  String get successLoginNow => 'app.successLoginNow'.tr(context: _context);
  String get newPasswordTitle => 'app.newPasswordTitle'.tr(context: _context);
  String get setNewPassword => 'app.setNewPassword'.tr(context: _context);
  String get newPassword => 'app.newPassword'.tr(context: _context);
  String get confirmPassword => 'app.confirmPassword'.tr(context: _context);
  String get passwordsDoNotMatch => 'app.passwordsDoNotMatch'.tr(context: _context);
  String get resetPassword => 'app.resetPassword'.tr(context: _context);
  String get forgotPasswordTitle => 'app.forgotPasswordTitle'.tr(context: _context);
  String get forgotPasswordHint => 'app.forgotPasswordHint'.tr(context: _context);
  String get sendOtp => 'app.sendOtp'.tr(context: _context);
  String get otpSentIfAccountExists =>
      'app.otpSentIfAccountExists'.tr(context: _context);

  List<List<String>> get promoBanners => [
    ['🔥 50% Off Your First Order!'.tr(context: _context), 'Code: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 Free Delivery This Week'.tr(context: _context), 'On all pizza orders'.tr(context: _context), 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ];

  String translateStatus(String? status) => status ?? '';
  String translateEta(String? eta) => eta ?? '';

  String translateApiError(String error) {
    if (error.contains('out_of_delivery_zones')) {
      return 'customer.error.out_of_delivery_zones'.tr(context: _context);
    }
    if (error.contains('Minimum order amount')) {
      return 'customer.error.minimum_coins_required'.tr(context: _context); // approximation
    }
    return error;
  }
}
