import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppStrings {
  final BuildContext _context;
  const AppStrings(this._context);

  static AppStrings of(BuildContext context) {
    return AppStrings(context);
  }

  bool get isArabic => Localizations.localeOf(_context).languageCode == 'ar';
  String get dontHaveAccount => 'app.dontHaveAccount'.tr();

  String get navHome => 'app.navHome'.tr();
  String get navOrders => 'app.navOrders'.tr();
  String get navChat => 'app.navChat'.tr();
  String get navProfile => 'app.navProfile'.tr();
  String get navSearch => 'app.navSearch'.tr();
  String get deliverTo => 'app.deliverTo'.tr();
  String get locationName => 'app.locationName'.tr();
  String get searchRestaurant => 'app.searchRestaurant'.tr();
  String get restaurants => 'app.restaurants'.tr();
  String get pharmacies => 'app.pharmacies'.tr();
  String get supermarkets => 'app.supermarkets'.tr();
  String get nearbyRestaurants => 'app.nearbyRestaurants'.tr();
  String get availablePharm => 'app.availablePharm'.tr();
  String get nearbySuper => 'app.nearbySuper'.tr();
  String get seeAll => 'app.seeAll'.tr();
  String get customDeliveryBannerTitle => 'app.customDeliveryBannerTitle'.tr();
  String get customDeliveryBannerSub => 'app.customDeliveryBannerSub'.tr();
  String get customDeliveryTitle => 'app.customDeliveryTitle'.tr();
  String get pickupLocation => 'app.pickupLocation'.tr();
  String get dropoffLocation => 'app.dropoffLocation'.tr();
  String get itemDetails => 'app.itemDetails'.tr();
  String get enterPickupLocation => 'app.enterPickupLocation'.tr();
  String get enterDropoffLocation => 'app.enterDropoffLocation'.tr();
  String get enterItemDetails => 'app.enterItemDetails'.tr();
  String get vehicleType => 'app.vehicleType'.tr();
  String get motorcycle => 'app.motorcycle'.tr();
  String get car => 'app.car'.tr();
  String get requestCourier => 'app.requestCourier'.tr();
  String get trackOrder => 'app.trackOrder'.tr();
  String get cartButton => 'app.cartButton'.tr();
  String get egp => 'app.egp'.tr();
  String get retry => 'app.retry'.tr();
  String get noResults => 'app.noResults'.tr();
  String get orderNow => 'app.orderNow'.tr();
  String get chatWithVendor => 'app.chatWithVendor'.tr();
  String get chatWithVendorSubtext => 'app.chatWithVendorSubtext'.tr();
  String get menu => 'app.menu'.tr();
  String get viewCart => 'app.viewCart'.tr();
  String get addedToCart => 'app.addedToCart'.tr();
  String get cart => 'app.cart'.tr();
  String get clearAll => 'app.clearAll'.tr();
  String get emptyCart => 'app.emptyCart'.tr();
  String get emptyCartSub => 'app.emptyCartSub'.tr();
  String get browseNow => 'app.browseNow'.tr();
  String get total => 'app.total'.tr();
  String get checkout => 'app.checkout'.tr();
  String get subtotal => 'app.subtotal'.tr();
  String get deliveryFee => 'app.deliveryFee'.tr();
  String get free => 'app.free'.tr();
  String get orderSummary => 'app.orderSummary'.tr();
  String get placeOrder => 'app.placeOrder'.tr();
  String get checkoutTitle => 'app.checkoutTitle'.tr();
  String get deliveryAddress => 'app.deliveryAddress'.tr();
  String get paymentMethod => 'app.paymentMethod'.tr();
  String get instapay => 'app.instapay'.tr();
  String get mobileWallet => 'app.mobileWallet'.tr();
  String get cashOnDelivery => 'app.cashOnDelivery'.tr();
  String get orderSuccess => 'app.orderSuccess'.tr();
  String get orderSuccessSub => 'app.orderSuccessSub'.tr();
  String get goToOrders => 'app.goToOrders'.tr();
  String get processing => 'app.processing'.tr();
  String get editProfile => 'app.editProfile'.tr();
  String get myAddresses => 'app.myAddresses'.tr();
  String get helpCenter => 'app.helpCenter'.tr();
  String get aboutApp => 'app.aboutApp'.tr();
  String get logout => 'app.logout'.tr();
  String get language => 'app.language'.tr();
  String get notifications => 'app.notifications'.tr();
  String get darkMode => 'app.darkMode'.tr();
  String get languageName => 'app.languageName'.tr();
  String get enabled => 'app.enabled'.tr();
  String get disabled => 'app.disabled'.tr();
  String get on => 'app.on'.tr();
  String get off => 'app.off'.tr();
  String get logoutConfirm => 'app.logoutConfirm'.tr();
  String get cancel => 'app.cancel'.tr();
  String get saveChanges => 'app.saveChanges'.tr();
  String get fullName => 'app.fullName'.tr();
  String get emailAddress => 'app.emailAddress'.tr();
  String get phoneNumber => 'app.phoneNumber'.tr();
  String get noAddresses => 'app.noAddresses'.tr();
  String get addAddressSub => 'app.addAddressSub'.tr();
  String get addNewAddress => 'app.addNewAddress'.tr();
  String get addressLabel => 'app.addressLabel'.tr();
  String get fullAddress => 'app.fullAddress'.tr();
  String get addAddress => 'app.addAddress'.tr();
  String get addressAdded => 'app.addressAdded'.tr();
  String get addressUpdated => 'app.addressUpdated'.tr();
  String get addressDeleted => 'app.addressDeleted'.tr();
  String get address => 'app.address'.tr();
  String get welcomeBack => 'app.welcomeBack'.tr();
  String get loginToApp => 'app.loginToApp'.tr();
  String get email => 'app.email'.tr();
  String get password => 'app.password'.tr();
  String get emailRequired => 'app.emailRequired'.tr();
  String get passwordMinLen => 'app.passwordMinLen'.tr();
  String get forgotPassword => 'app.forgotPassword'.tr();
  String get login => 'app.login'.tr();
  String get signUp => 'app.signUp'.tr();
  String get createAccount => 'app.createAccount'.tr();
  String get joinApp => 'app.joinApp'.tr();
  String get nameRequired => 'app.nameRequired'.tr();
  String get phoneNumberOptional => 'app.phoneNumberOptional'.tr();
  String get register => 'app.register'.tr();
  String get alreadyHaveAccount => 'app.alreadyHaveAccount'.tr();
  String get vendor => 'app.vendor'.tr();
  String get defaultCity => 'app.defaultCity'.tr();
  String get orderNo => 'app.orderNo'.tr();
  String get readLess => 'app.readLess'.tr();
  String get readMore => 'app.readMore'.tr();
  String get customCourierDesc => 'app.customCourierDesc'.tr();
  String get rideServiceDesc => 'app.rideServiceDesc'.tr();
  String get yourLocation => 'app.yourLocation'.tr();
  String get whereAreYou => 'app.whereAreYou'.tr();
  String get wherePickUp => 'app.wherePickUp'.tr();
  String get destination => 'app.destination'.tr();
  String get whereToGo => 'app.whereToGo'.tr();
  String get wherePackageGoing => 'app.wherePackageGoing'.tr();
  String get required => 'app.required'.tr();
  String get delivery => 'app.delivery'.tr();
  String get ride => 'app.ride'.tr();
  String get findingCaptain => 'app.findingCaptain'.tr();
  String get pleaseWaitConnectDriver => 'app.pleaseWaitConnectDriver'.tr();
  String get requestConfirmed => 'app.requestConfirmed'.tr();
  String get plateNo => 'app.plateNo'.tr();
  String get trackRequest => 'app.trackRequest'.tr();
  String get backToHome => 'app.backToHome'.tr();
  String get products => 'app.products'.tr();
  String get noItemsInCategory => 'app.noItemsInCategory'.tr();
  String get errorPrefix => 'app.errorPrefix'.tr();
  String get catAll => 'app.catAll'.tr();
  String get catMedicines => 'app.catMedicines'.tr();
  String get catCosmetics => 'app.catCosmetics'.tr();
  String get addToCart => 'app.addToCart'.tr();
  String get done => 'app.done'.tr();
  String get allStores => 'app.allStores'.tr();
  String get stores => 'app.stores'.tr();
  String get allResults => 'app.allResults'.tr();
  String get searchResults => 'app.searchResults'.tr();
  String get clickToViewMenu => 'app.clickToViewMenu'.tr();
  String get searchInStores => 'app.searchInStores'.tr();
  String get featuredSuggestions => 'app.featuredSuggestions'.tr();
  String get searchErrorPrefix => 'app.searchErrorPrefix'.tr();
  String get typeAMessage => 'app.typeAMessage'.tr();
  String get onlyImagesAllowed => 'app.onlyImagesAllowed'.tr();
  String get orderShort => 'app.orderShort'.tr();
  String get proLabel => 'app.proLabel'.tr();
  String get nearbyStores => 'app.nearbyStores'.tr();
  String get nearbyPrefix => 'app.nearbyPrefix'.tr();
  String get nearbySuffix => 'app.nearbySuffix'.tr();
  String get appName => 'app.appName'.tr();
  String get search => 'app.search'.tr();
  String get supportGreeting => 'app.supportGreeting'.tr();
  String get vendorGreeting => 'app.vendorGreeting'.tr();
  String get edit => 'app.edit'.tr();
  String get delete => 'app.delete'.tr();
  String get voiceMessage => 'app.voiceMessage'.tr();
  String get releaseToSend => 'app.releaseToSend'.tr();
  String get uploading => 'app.uploading'.tr();
  String get deleteConfirmTitle => 'app.deleteConfirmTitle'.tr();
  String get deleteConfirmBody => 'app.deleteConfirmBody'.tr();
  String get offerTitle => 'app.offerTitle'.tr();
  String get viewOffer => 'app.viewOffer'.tr();
  String get confirmOrder => 'app.confirmOrder'.tr();
  String get cancelOrder => 'app.cancelOrder'.tr();
  String get package => 'app.package'.tr();
  String get strip => 'app.strip'.tr();
  String get sellingUnit => 'app.sellingUnit'.tr();
  String get selectVariant => 'app.selectVariant'.tr();
  String get yes => 'app.yes'.tr();
  String get confirm => 'app.confirm'.tr();
  String get hotDeals => 'app.hotDeals'.tr();
  String get offerBadge => 'app.offerBadge'.tr();
  String get seeAllOffers => 'app.seeAllOffers'.tr();
  String get rememberMe => 'app.rememberMe'.tr();
  String get orLoginWithAnother => 'app.orLoginWithAnother'.tr();
  String get ticketExists => 'app.ticketExists'.tr();
  String get authRequiredTitle => 'app.authRequiredTitle'.tr();
  String get authRequiredMessage => 'app.authRequiredMessage'.tr();

  List<List<String>> get promoBanners => [
    ['🔥 50% Off Your First Order!'.tr(), 'Code: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 Free Delivery This Week'.tr(), 'On all pizza orders'.tr(), 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ];

  String translateStatus(String? status) => status ?? '';
  String translateEta(String? eta) => eta ?? '';

  String translateApiError(String error) {
    if (error.contains('out_of_delivery_zones')) {
      return 'customer.error.out_of_delivery_zones'.tr();
    }
    if (error.contains('Minimum order amount')) {
      return 'customer.error.minimum_coins_required'.tr(); // approximation
    }
    return error;
  }
}
