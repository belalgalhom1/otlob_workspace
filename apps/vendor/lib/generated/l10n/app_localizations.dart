import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Otlob Admin'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appCustomization.
  ///
  /// In en, this message translates to:
  /// **'App Customization'**
  String get appCustomization;

  /// No description provided for @homeCover.
  ///
  /// In en, this message translates to:
  /// **'Home Cover Image'**
  String get homeCover;

  /// No description provided for @motorcycleIcon.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle Icon'**
  String get motorcycleIcon;

  /// No description provided for @carIcon.
  ///
  /// In en, this message translates to:
  /// **'Car Icon'**
  String get carIcon;

  /// No description provided for @bicycleIcon.
  ///
  /// In en, this message translates to:
  /// **'Bicycle Icon'**
  String get bicycleIcon;

  /// No description provided for @motorTricycleIcon.
  ///
  /// In en, this message translates to:
  /// **'Motor Tricycle Icon'**
  String get motorTricycleIcon;

  /// No description provided for @vanIcon.
  ///
  /// In en, this message translates to:
  /// **'Van Icon'**
  String get vanIcon;

  /// No description provided for @truckIcon.
  ///
  /// In en, this message translates to:
  /// **'Truck Icon'**
  String get truckIcon;

  /// No description provided for @deliveryBannerIcon.
  ///
  /// In en, this message translates to:
  /// **'Delivery Banner Icon'**
  String get deliveryBannerIcon;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get uploadSuccess;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get uploadError;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @storeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Store Appearance'**
  String get storeAppearance;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'admin@otlob.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @orLoginWithAnother.
  ///
  /// In en, this message translates to:
  /// **'Or login with another account'**
  String get orLoginWithAnother;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @businessTypes.
  ///
  /// In en, this message translates to:
  /// **'Business Types'**
  String get businessTypes;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @zones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get tickets;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @vendorPanel.
  ///
  /// In en, this message translates to:
  /// **'Vendor Panel'**
  String get vendorPanel;

  /// No description provided for @vendorMember.
  ///
  /// In en, this message translates to:
  /// **'Vendor Member'**
  String get vendorMember;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @variants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get variants;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @addVariant.
  ///
  /// In en, this message translates to:
  /// **'Add Variant'**
  String get addVariant;

  /// No description provided for @addOptionGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Option Group'**
  String get addOptionGroup;

  /// No description provided for @noVariantsYet.
  ///
  /// In en, this message translates to:
  /// **'No variants added yet'**
  String get noVariantsYet;

  /// No description provided for @noOptionGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No option groups added yet'**
  String get noOptionGroupsYet;

  /// No description provided for @editVariant.
  ///
  /// In en, this message translates to:
  /// **'Edit Variant'**
  String get editVariant;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (EN)'**
  String get nameEn;

  /// No description provided for @nameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (AR)'**
  String get nameAr;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save;

  /// No description provided for @deleteVariant.
  ///
  /// In en, this message translates to:
  /// **'Delete Variant'**
  String get deleteVariant;

  /// No description provided for @deleteConfirmVariant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this variant?'**
  String get deleteConfirmVariant;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editOptionGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Option Group'**
  String get editOptionGroup;

  /// No description provided for @groupNameEn.
  ///
  /// In en, this message translates to:
  /// **'Group Name (EN)'**
  String get groupNameEn;

  /// No description provided for @groupNameAr.
  ///
  /// In en, this message translates to:
  /// **'Group Name (AR)'**
  String get groupNameAr;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **'Is Required'**
  String get isRequired;

  /// No description provided for @deleteOptionGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Option Group'**
  String get deleteOptionGroup;

  /// No description provided for @deleteConfirmOptionGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group and all its options?'**
  String get deleteConfirmOptionGroup;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @editOption.
  ///
  /// In en, this message translates to:
  /// **'Edit Option'**
  String get editOption;

  /// No description provided for @optionNameEn.
  ///
  /// In en, this message translates to:
  /// **'Option Name (EN)'**
  String get optionNameEn;

  /// No description provided for @optionNameAr.
  ///
  /// In en, this message translates to:
  /// **'Option Name (AR)'**
  String get optionNameAr;

  /// No description provided for @additionalPrice.
  ///
  /// In en, this message translates to:
  /// **'Additional Price'**
  String get additionalPrice;

  /// No description provided for @deleteOption.
  ///
  /// In en, this message translates to:
  /// **'Delete Option'**
  String get deleteOption;

  /// No description provided for @deleteConfirmOption.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this option?'**
  String get deleteConfirmOption;

  /// No description provided for @variantAdded.
  ///
  /// In en, this message translates to:
  /// **'Variant added successfully'**
  String get variantAdded;

  /// No description provided for @variantUpdated.
  ///
  /// In en, this message translates to:
  /// **'Variant updated successfully'**
  String get variantUpdated;

  /// No description provided for @variantDeleted.
  ///
  /// In en, this message translates to:
  /// **'Variant deleted successfully'**
  String get variantDeleted;

  /// No description provided for @variantActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save variant'**
  String get variantActionFailed;

  /// No description provided for @optionGroupAdded.
  ///
  /// In en, this message translates to:
  /// **'Option group added successfully'**
  String get optionGroupAdded;

  /// No description provided for @optionGroupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Option group updated successfully'**
  String get optionGroupUpdated;

  /// No description provided for @optionGroupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Option group deleted successfully'**
  String get optionGroupDeleted;

  /// No description provided for @optionGroupActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save option group'**
  String get optionGroupActionFailed;

  /// No description provided for @optionAdded.
  ///
  /// In en, this message translates to:
  /// **'Option added successfully'**
  String get optionAdded;

  /// No description provided for @optionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Option updated successfully'**
  String get optionUpdated;

  /// No description provided for @optionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Option deleted successfully'**
  String get optionDeleted;

  /// No description provided for @optionActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save option'**
  String get optionActionFailed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Page Coming Soon'**
  String get comingSoon;

  /// No description provided for @totalVendors.
  ///
  /// In en, this message translates to:
  /// **'Total Vendors'**
  String get totalVendors;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @systemUsers.
  ///
  /// In en, this message translates to:
  /// **'System Users'**
  String get systemUsers;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @liveOrders.
  ///
  /// In en, this message translates to:
  /// **'Live Orders'**
  String get liveOrders;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get systemLogs;

  /// No description provided for @ordersApiNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Orders API not implemented'**
  String get ordersApiNotImplemented;

  /// No description provided for @auditLogsApiNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Audit logs API not implemented'**
  String get auditLogsApiNotImplemented;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @addVendor.
  ///
  /// In en, this message translates to:
  /// **'Add Vendor'**
  String get addVendor;

  /// No description provided for @noVendorsFound.
  ///
  /// In en, this message translates to:
  /// **'No vendors found'**
  String get noVendorsFound;

  /// No description provided for @unnamedStore.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Store'**
  String get unnamedStore;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @menuCategories.
  ///
  /// In en, this message translates to:
  /// **'Menu Categories'**
  String get menuCategories;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @editVendor.
  ///
  /// In en, this message translates to:
  /// **'Edit Vendor'**
  String get editVendor;

  /// No description provided for @deleteVendor.
  ///
  /// In en, this message translates to:
  /// **'Delete Vendor'**
  String get deleteVendor;

  /// No description provided for @addNewVendor.
  ///
  /// In en, this message translates to:
  /// **'Add New Vendor'**
  String get addNewVendor;

  /// No description provided for @updateVendorDetails.
  ///
  /// In en, this message translates to:
  /// **'Update vendor details'**
  String get updateVendorDetails;

  /// No description provided for @registerNewStore.
  ///
  /// In en, this message translates to:
  /// **'Register a new store on the platform'**
  String get registerNewStore;

  /// No description provided for @generalInformation.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInformation;

  /// No description provided for @storeNameEn.
  ///
  /// In en, this message translates to:
  /// **'Store Name (EN)'**
  String get storeNameEn;

  /// No description provided for @storeNameAr.
  ///
  /// In en, this message translates to:
  /// **'Store Name (AR)'**
  String get storeNameAr;

  /// No description provided for @descriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (EN)'**
  String get descriptionEn;

  /// No description provided for @descriptionAr.
  ///
  /// In en, this message translates to:
  /// **'Description (AR)'**
  String get descriptionAr;

  /// No description provided for @taxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxId;

  /// No description provided for @commissionPercent.
  ///
  /// In en, this message translates to:
  /// **'Commission (%)'**
  String get commissionPercent;

  /// No description provided for @updateVendor.
  ///
  /// In en, this message translates to:
  /// **'Update Vendor'**
  String get updateVendor;

  /// No description provided for @registerStore.
  ///
  /// In en, this message translates to:
  /// **'Register Store'**
  String get registerStore;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @pleaseFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillRequiredFields;

  /// No description provided for @businessCategory.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get businessCategory;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @financials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @pleaseSelectBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Please select a business type'**
  String get pleaseSelectBusinessType;

  /// No description provided for @menuCategory.
  ///
  /// In en, this message translates to:
  /// **'Menu Category'**
  String get menuCategory;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @selectMenuCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Menu Category'**
  String get selectMenuCategory;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get productImage;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @productNameEn.
  ///
  /// In en, this message translates to:
  /// **'Product Name (EN)'**
  String get productNameEn;

  /// No description provided for @productNameAr.
  ///
  /// In en, this message translates to:
  /// **'Product Name (AR)'**
  String get productNameAr;

  /// No description provided for @pricingInventory.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Inventory'**
  String get pricingInventory;

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePrice;

  /// No description provided for @comparePrice.
  ///
  /// In en, this message translates to:
  /// **'Compare Price'**
  String get comparePrice;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Initial Stock'**
  String get initialStock;

  /// No description provided for @productActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get productActiveStatus;

  /// No description provided for @productVisibleToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Product will be visible to customers'**
  String get productVisibleToCustomers;

  /// No description provided for @featuredProduct.
  ///
  /// In en, this message translates to:
  /// **'Featured Product'**
  String get featuredProduct;

  /// No description provided for @showAtTopOfMenu.
  ///
  /// In en, this message translates to:
  /// **'Show at the top of the menu'**
  String get showAtTopOfMenu;

  /// No description provided for @trackStock.
  ///
  /// In en, this message translates to:
  /// **'Track Stock'**
  String get trackStock;

  /// No description provided for @trackStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show as out of stock when quantity reaches zero'**
  String get trackStockSubtitle;

  /// No description provided for @notTracked.
  ///
  /// In en, this message translates to:
  /// **'Not tracked'**
  String get notTracked;

  /// No description provided for @uploadProductImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Product Image'**
  String get uploadProductImage;

  /// No description provided for @imageFormatSupport.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 5MB'**
  String get imageFormatSupport;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor: {name}'**
  String vendor(String name);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Vendor'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteConfirmContent(String name);

  /// No description provided for @zoneInUseDeleteError.
  ///
  /// In en, this message translates to:
  /// **'This zone is in use. Reassign or remove its branches, orders, and shifts before deleting it.'**
  String get zoneInUseDeleteError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ban.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get ban;

  /// No description provided for @unban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get unban;

  /// No description provided for @changeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Select New Status'**
  String get changeStatusTitle;

  /// No description provided for @deliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @newOrders.
  ///
  /// In en, this message translates to:
  /// **'New Orders'**
  String get newOrders;

  /// No description provided for @inDelivery.
  ///
  /// In en, this message translates to:
  /// **'In Delivery'**
  String get inDelivery;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @ordersApiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The Orders API is currently not connected.'**
  String get ordersApiNotConnected;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @noProductsDescription.
  ///
  /// In en, this message translates to:
  /// **'This vendor doesn\'t have any products yet.'**
  String get noProductsDescription;

  /// No description provided for @unnamedProduct.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Product'**
  String get unnamedProduct;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdated;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get productAdded;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product?'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String deleteProductConfirm(String name);

  /// No description provided for @storeBranches.
  ///
  /// In en, this message translates to:
  /// **'Store Branches'**
  String get storeBranches;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add Branch'**
  String get addBranch;

  /// No description provided for @noBranchesFound.
  ///
  /// In en, this message translates to:
  /// **'No Branches Found'**
  String get noBranchesFound;

  /// No description provided for @noBranchesDescription.
  ///
  /// In en, this message translates to:
  /// **'This vendor doesn\'t have any branches registered yet.'**
  String get noBranchesDescription;

  /// No description provided for @unnamedBranch.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Branch'**
  String get unnamedBranch;

  /// No description provided for @noAddressProvided.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddressProvided;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit Branch'**
  String get editBranch;

  /// No description provided for @newBranch.
  ///
  /// In en, this message translates to:
  /// **'New Branch'**
  String get newBranch;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchName;

  /// No description provided for @branchNameAr.
  ///
  /// In en, this message translates to:
  /// **'Branch Name (AR)'**
  String get branchNameAr;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @manageVerticalsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage vertical categories for vendors'**
  String get manageVerticalsDescription;

  /// No description provided for @addBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Add Business Type'**
  String get addBusinessType;

  /// No description provided for @editBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Edit Business Type'**
  String get editBusinessType;

  /// No description provided for @noBusinessTypesFound.
  ///
  /// In en, this message translates to:
  /// **'No business types found'**
  String get noBusinessTypesFound;

  /// No description provided for @deleteBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Delete Business Type'**
  String get deleteBusinessType;

  /// No description provided for @deleteBusinessTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteBusinessTypeConfirm(String name);

  /// No description provided for @menuCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Start by adding a new menu category for this vendor.'**
  String get menuCategoriesDescription;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No Categories Found'**
  String get noCategoriesFound;

  /// No description provided for @unnamedCategory.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Category'**
  String get unnamedCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get categoryIcon;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @iconUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Icon URL (Optional)'**
  String get iconUrlOptional;

  /// No description provided for @businessTypeIcon.
  ///
  /// In en, this message translates to:
  /// **'Business Type Icon'**
  String get businessTypeIcon;

  /// No description provided for @uploadIcon.
  ///
  /// In en, this message translates to:
  /// **'Upload Icon'**
  String get uploadIcon;

  /// No description provided for @uploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover'**
  String get uploadCover;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @visibilityForVendors.
  ///
  /// In en, this message translates to:
  /// **'Visibility for vendors'**
  String get visibilityForVendors;

  /// No description provided for @deleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete Branch?'**
  String get deleteBranch;

  /// No description provided for @deleteBranchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteBranchConfirm(String name);

  /// No description provided for @totalDrivers.
  ///
  /// In en, this message translates to:
  /// **'Total Drivers'**
  String get totalDrivers;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active Now'**
  String get activeNow;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @driverTrackingOffline.
  ///
  /// In en, this message translates to:
  /// **'Driver Tracking Offline'**
  String get driverTrackingOffline;

  /// No description provided for @waitBackendDriverGps.
  ///
  /// In en, this message translates to:
  /// **'Wait for backend implementation of Driver GPS.'**
  String get waitBackendDriverGps;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @activeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Active This Month'**
  String get activeThisMonth;

  /// No description provided for @banned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get banned;

  /// No description provided for @customerDirectory.
  ///
  /// In en, this message translates to:
  /// **'Customer Directory'**
  String get customerDirectory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @emailPhone.
  ///
  /// In en, this message translates to:
  /// **'Email/Phone'**
  String get emailPhone;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get openTickets;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @noSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'No Support Tickets'**
  String get noSupportTickets;

  /// No description provided for @allInquiriesResolved.
  ///
  /// In en, this message translates to:
  /// **'All customer inquiries have been resolved.'**
  String get allInquiriesResolved;

  /// No description provided for @platformAdmins.
  ///
  /// In en, this message translates to:
  /// **'Platform Admins'**
  String get platformAdmins;

  /// No description provided for @activeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Active Accounts'**
  String get activeAccounts;

  /// No description provided for @platformUsers.
  ///
  /// In en, this message translates to:
  /// **'Platform Users'**
  String get platformUsers;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @pageXofY.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageXofY(int page, int total);

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found in the system.'**
  String get noUsersFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @bannedStatus.
  ///
  /// In en, this message translates to:
  /// **'BANNED'**
  String get bannedStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeStatus;

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUser;

  /// No description provided for @editUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit User Profile'**
  String get editUserProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Account Role'**
  String get accountRole;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @cannotBanSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot ban yourself!'**
  String get cannotBanSelf;

  /// No description provided for @banUser.
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get banUser;

  /// No description provided for @banUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to ban this user? They will not be able to log in.'**
  String get banUserConfirm;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (Optional)'**
  String get reasonOptional;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your own account!'**
  String get cannotDeleteSelf;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This action cannot be undone.'**
  String deleteUserConfirm(String name);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @activeZones.
  ///
  /// In en, this message translates to:
  /// **'Active Zones'**
  String get activeZones;

  /// No description provided for @busyZones.
  ///
  /// In en, this message translates to:
  /// **'Busy Zones'**
  String get busyZones;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @addZone.
  ///
  /// In en, this message translates to:
  /// **'Add Zone'**
  String get addZone;

  /// No description provided for @noZonesDefined.
  ///
  /// In en, this message translates to:
  /// **'No zones defined yet.'**
  String get noZonesDefined;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactiveStatus;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @manageBannersAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage Banners and Offers'**
  String get manageBannersAndOffers;

  /// No description provided for @addPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add Promotion'**
  String get addPromotion;

  /// No description provided for @editPromotion.
  ///
  /// In en, this message translates to:
  /// **'Edit Promotion'**
  String get editPromotion;

  /// No description provided for @deletePromotion.
  ///
  /// In en, this message translates to:
  /// **'Delete Promotion'**
  String get deletePromotion;

  /// No description provided for @noPromotionsFound.
  ///
  /// In en, this message translates to:
  /// **'No promotions found'**
  String get noPromotionsFound;

  /// No description provided for @startCreatingBanners.
  ///
  /// In en, this message translates to:
  /// **'Start creating banners to engage your customers'**
  String get startCreatingBanners;

  /// No description provided for @deletePromotionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePromotionConfirm(String name);

  /// No description provided for @promotionType.
  ///
  /// In en, this message translates to:
  /// **'Promotion Type'**
  String get promotionType;

  /// No description provided for @bannerType.
  ///
  /// In en, this message translates to:
  /// **'Simple Banner'**
  String get bannerType;

  /// No description provided for @vendorType.
  ///
  /// In en, this message translates to:
  /// **'Link to Vendor'**
  String get vendorType;

  /// No description provided for @productType.
  ///
  /// In en, this message translates to:
  /// **'Link to Product'**
  String get productType;

  /// No description provided for @linkType.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get linkType;

  /// No description provided for @popupType.
  ///
  /// In en, this message translates to:
  /// **'Popup'**
  String get popupType;

  /// No description provided for @notificationType.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationType;

  /// No description provided for @externalUrl.
  ///
  /// In en, this message translates to:
  /// **'External URL'**
  String get externalUrl;

  /// No description provided for @selectVendor.
  ///
  /// In en, this message translates to:
  /// **'Select Vendor'**
  String get selectVendor;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @uploadBannerImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Banner Image'**
  String get uploadBannerImage;

  /// No description provided for @titleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (EN)'**
  String get titleEn;

  /// No description provided for @titleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (AR)'**
  String get titleAr;

  /// No description provided for @common_error_validation.
  ///
  /// In en, this message translates to:
  /// **'Validation Error: Please check your input.'**
  String get common_error_validation;

  /// No description provided for @common_error_server_error.
  ///
  /// In en, this message translates to:
  /// **'Server Error: Please try again later.'**
  String get common_error_server_error;

  /// No description provided for @common_error_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get common_error_unknown;

  /// No description provided for @common_error_forbidden.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: You do not have permission.'**
  String get common_error_forbidden;

  /// No description provided for @common_error_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized: Please log in again.'**
  String get common_error_unauthorized;

  /// No description provided for @common_error_too_many_requests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please slow down.'**
  String get common_error_too_many_requests;

  /// No description provided for @common_success_operation.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully.'**
  String get common_success_operation;

  /// No description provided for @common_success_resource_created.
  ///
  /// In en, this message translates to:
  /// **'Created successfully.'**
  String get common_success_resource_created;

  /// No description provided for @common_success_resource_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully.'**
  String get common_success_resource_updated;

  /// No description provided for @common_success_resource_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully.'**
  String get common_success_resource_deleted;

  /// No description provided for @auth_error_user_exists.
  ///
  /// In en, this message translates to:
  /// **'User already exists with this email or phone.'**
  String get auth_error_user_exists;

  /// No description provided for @auth_error_invalid_credentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get auth_error_invalid_credentials;

  /// No description provided for @auth_error_unverified.
  ///
  /// In en, this message translates to:
  /// **'Account not verified.'**
  String get auth_error_unverified;

  /// No description provided for @auth_error_banned.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned.'**
  String get auth_error_banned;

  /// No description provided for @auth_error_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get auth_error_user_not_found;

  /// No description provided for @auth_error_otp_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code.'**
  String get auth_error_otp_invalid;

  /// No description provided for @auth_error_otp_expired.
  ///
  /// In en, this message translates to:
  /// **'OTP code has expired.'**
  String get auth_error_otp_expired;

  /// No description provided for @auth_error_session_expired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get auth_error_session_expired;

  /// No description provided for @user_error_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get user_error_user_not_found;

  /// No description provided for @user_error_profile_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get user_error_profile_update_failed;

  /// No description provided for @user_error_avatar_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar.'**
  String get user_error_avatar_upload_failed;

  /// No description provided for @user_error_invalid_password.
  ///
  /// In en, this message translates to:
  /// **'The current password you entered is incorrect.'**
  String get user_error_invalid_password;

  /// No description provided for @user_error_password_same_as_old.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be the same as the old one.'**
  String get user_error_password_same_as_old;

  /// No description provided for @user_error_only_drivers_allowed.
  ///
  /// In en, this message translates to:
  /// **'You only have permission to access driver users.'**
  String get user_error_only_drivers_allowed;

  /// No description provided for @user_error_only_driver_creation_allowed.
  ///
  /// In en, this message translates to:
  /// **'You only have permission to create driver users.'**
  String get user_error_only_driver_creation_allowed;

  /// No description provided for @user_error_only_driver_role_allowed.
  ///
  /// In en, this message translates to:
  /// **'You only have permission to assign DRIVER role.'**
  String get user_error_only_driver_role_allowed;

  /// No description provided for @vendor_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Vendor not found.'**
  String get vendor_error_not_found;

  /// No description provided for @vendor_error_slug_taken.
  ///
  /// In en, this message translates to:
  /// **'This store name or slug is already taken.'**
  String get vendor_error_slug_taken;

  /// No description provided for @vendor_branch_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Branch not found.'**
  String get vendor_branch_error_not_found;

  /// No description provided for @menu_category_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Category not found.'**
  String get menu_category_error_not_found;

  /// No description provided for @product_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get product_error_not_found;

  /// No description provided for @product_error_sku_taken.
  ///
  /// In en, this message translates to:
  /// **'SKU already exists.'**
  String get product_error_sku_taken;

  /// No description provided for @vendor_vertical_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Business type not found.'**
  String get vendor_vertical_error_not_found;

  /// No description provided for @zone_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Zone not found.'**
  String get zone_error_not_found;

  /// No description provided for @zone_error_invalid_boundary_polygon.
  ///
  /// In en, this message translates to:
  /// **'Invalid boundary polygon.'**
  String get zone_error_invalid_boundary_polygon;

  /// No description provided for @zone_error_invalid_location_for_zone.
  ///
  /// In en, this message translates to:
  /// **'The selected location is outside delivery zones. Please pick a location inside an active delivery zone.'**
  String get zone_error_invalid_location_for_zone;

  /// No description provided for @zone_error_zone_has_branches.
  ///
  /// In en, this message translates to:
  /// **'This delivery zone has stores assigned to it. Move or remove them first.'**
  String get zone_error_zone_has_branches;

  /// No description provided for @autoDetectZone.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect from location'**
  String get autoDetectZone;

  /// No description provided for @outsideDeliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Outside delivery zones'**
  String get outsideDeliveryZones;

  /// No description provided for @insideZone.
  ///
  /// In en, this message translates to:
  /// **'Zone: {zoneName}'**
  String insideZone(String zoneName);

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// No description provided for @imageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an image'**
  String get imageRequired;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @scheduleOptional.
  ///
  /// In en, this message translates to:
  /// **'Schedule (Optional)'**
  String get scheduleOptional;

  /// No description provided for @assignToVendor.
  ///
  /// In en, this message translates to:
  /// **'Assign to Vendor'**
  String get assignToVendor;

  /// No description provided for @vendorRole.
  ///
  /// In en, this message translates to:
  /// **'Vendor Role'**
  String get vendorRole;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @myVendor.
  ///
  /// In en, this message translates to:
  /// **'My Vendor'**
  String get myVendor;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @tier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get tier;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @enterNewText.
  ///
  /// In en, this message translates to:
  /// **'Enter new text'**
  String get enterNewText;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @onlyImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only images are allowed.'**
  String get onlyImagesAllowed;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice Message'**
  String get voiceMessage;

  /// No description provided for @releaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Release to send'**
  String get releaseToSend;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @pushToMenu.
  ///
  /// In en, this message translates to:
  /// **'Push to Menu List'**
  String get pushToMenu;

  /// No description provided for @pushToMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make this product available permanently in your menu'**
  String get pushToMenuSubtitle;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @createOrderOffer.
  ///
  /// In en, this message translates to:
  /// **'Create Order Offer'**
  String get createOrderOffer;

  /// No description provided for @sellByStrip.
  ///
  /// In en, this message translates to:
  /// **'Sell by Strip'**
  String get sellByStrip;

  /// No description provided for @stripsPerPackage.
  ///
  /// In en, this message translates to:
  /// **'Strips per Package'**
  String get stripsPerPackage;

  /// No description provided for @stripPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per Strip'**
  String get stripPrice;

  /// No description provided for @sellingOptions.
  ///
  /// In en, this message translates to:
  /// **'Selling Options'**
  String get sellingOptions;

  /// No description provided for @addOffer.
  ///
  /// In en, this message translates to:
  /// **'Add offer'**
  String get addOffer;

  /// No description provided for @editOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit offer'**
  String get editOffer;

  /// No description provided for @deleteOffer.
  ///
  /// In en, this message translates to:
  /// **'Delete offer'**
  String get deleteOffer;

  /// No description provided for @offerPrice.
  ///
  /// In en, this message translates to:
  /// **'Offer Price'**
  String get offerPrice;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original Price'**
  String get originalPrice;

  /// No description provided for @deleteOfferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer?'**
  String get deleteOfferConfirm;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get noExpiry;

  /// No description provided for @offerCreated.
  ///
  /// In en, this message translates to:
  /// **'Offer created successfully'**
  String get offerCreated;

  /// No description provided for @offerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Offer updated successfully'**
  String get offerUpdated;

  /// No description provided for @offerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Offer deleted successfully'**
  String get offerDeleted;

  /// No description provided for @escalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get escalated;

  /// No description provided for @waitingOnUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting on User'**
  String get waitingOnUser;

  /// No description provided for @ticketCategoryDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery Issue'**
  String get ticketCategoryDelivery;

  /// No description provided for @ticketCategoryVendor.
  ///
  /// In en, this message translates to:
  /// **'Store/Restaurant Issue'**
  String get ticketCategoryVendor;

  /// No description provided for @ticketCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get ticketCategoryPayment;

  /// No description provided for @ticketCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Issue'**
  String get ticketCategoryAccount;

  /// No description provided for @ticketCategoryReturn.
  ///
  /// In en, this message translates to:
  /// **'Return/Complaint'**
  String get ticketCategoryReturn;

  /// No description provided for @ticketCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ticketCategoryOther;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'Ticket No.'**
  String get ticketNumber;

  /// No description provided for @createPendingOrderImmediately.
  ///
  /// In en, this message translates to:
  /// **'Create Pending Order Immediately'**
  String get createPendingOrderImmediately;

  /// No description provided for @createPendingOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This offer will immediately be an open order'**
  String get createPendingOrderSubtitle;

  /// No description provided for @searchExistingProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Existing Product (Optional)'**
  String get searchExistingProduct;

  /// No description provided for @searchVendorCatalog.
  ///
  /// In en, this message translates to:
  /// **'Search vendor catalog...'**
  String get searchVendorCatalog;

  /// No description provided for @escalateComplaint.
  ///
  /// In en, this message translates to:
  /// **'Escalate Complaint'**
  String get escalateComplaint;

  /// No description provided for @escalateComplaintConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to escalate this complaint to Senior Management?'**
  String get escalateComplaintConfirm;

  /// No description provided for @vendorIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vendor ID not found for this conversation'**
  String get vendorIdNotFound;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// No description provided for @transactionProcessed.
  ///
  /// In en, this message translates to:
  /// **'Transaction processed successfully!'**
  String get transactionProcessed;

  /// No description provided for @walletAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wallet added successfully!'**
  String get walletAddedSuccessfully;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @noUsersFoundSystem.
  ///
  /// In en, this message translates to:
  /// **'No users found in the system.'**
  String get noUsersFoundSystem;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No drivers found.'**
  String get noDriversFound;

  /// No description provided for @confirmBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Confirm Broadcast'**
  String get confirmBroadcast;

  /// No description provided for @broadcastNow.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Now'**
  String get broadcastNow;

  /// No description provided for @announcementSuccess.
  ///
  /// In en, this message translates to:
  /// **'Announcement successfully broadcasted!'**
  String get announcementSuccess;

  /// No description provided for @allUsersGlobal.
  ///
  /// In en, this message translates to:
  /// **'All Users (Global)'**
  String get allUsersGlobal;

  /// No description provided for @customersOnly.
  ///
  /// In en, this message translates to:
  /// **'Customers Only'**
  String get customersOnly;

  /// No description provided for @driversOnly.
  ///
  /// In en, this message translates to:
  /// **'Drivers Only'**
  String get driversOnly;

  /// No description provided for @vendorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Vendors Only'**
  String get vendorsOnly;

  /// No description provided for @driverAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned successfully!'**
  String get driverAssignedSuccess;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusOnBreak.
  ///
  /// In en, this message translates to:
  /// **'On Break'**
  String get statusOnBreak;

  /// No description provided for @statusOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'On Delivery'**
  String get statusOnDelivery;

  /// No description provided for @locationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied.'**
  String get locationPermissionsDenied;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Location'**
  String get pickLocation;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @noAuditLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found'**
  String get noAuditLogsFound;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders'**
  String get errorLoadingOrders;

  /// No description provided for @noSystemLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No system logs found'**
  String get noSystemLogsFound;

  /// No description provided for @errorLoadingLogs.
  ///
  /// In en, this message translates to:
  /// **'Error loading logs'**
  String get errorLoadingLogs;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @processAction.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get processAction;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @reviewTopUp.
  ///
  /// In en, this message translates to:
  /// **'Review Top-Up'**
  String get reviewTopUp;

  /// No description provided for @addPlatformWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Platform Wallet'**
  String get addPlatformWallet;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @assignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignAction;

  /// No description provided for @filterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterAction;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @detailedProductDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed product description...'**
  String get detailedProductDescription;

  /// No description provided for @descriptionArPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Detailed product description in Arabic...'**
  String get descriptionArPlaceholder;

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @stockUnit.
  ///
  /// In en, this message translates to:
  /// **'Stock unit'**
  String get stockUnit;

  /// No description provided for @optionalForChatOffers.
  ///
  /// In en, this message translates to:
  /// **'Optional for chat offers'**
  String get optionalForChatOffers;

  /// No description provided for @pendingTopUps.
  ///
  /// In en, this message translates to:
  /// **'Pending Top-Ups'**
  String get pendingTopUps;

  /// No description provided for @platformWallets.
  ///
  /// In en, this message translates to:
  /// **'Platform Wallets'**
  String get platformWallets;

  /// No description provided for @walletAndFinancials.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Financials'**
  String get walletAndFinancials;

  /// No description provided for @financialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage driver top-up requests and platform payment wallets'**
  String get financialsSubtitle;

  /// No description provided for @pendingTopUpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and approve driver wallet funding requests'**
  String get pendingTopUpsSubtitle;

  /// No description provided for @platformWalletsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure payment receiving accounts for the platform'**
  String get platformWalletsSubtitle;

  /// No description provided for @noPendingTopUps.
  ///
  /// In en, this message translates to:
  /// **'No pending top-up requests'**
  String get noPendingTopUps;

  /// No description provided for @noPlatformWallets.
  ///
  /// In en, this message translates to:
  /// **'No platform wallets configured'**
  String get noPlatformWallets;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid whole number amount'**
  String get invalidAmount;

  /// No description provided for @driverId.
  ///
  /// In en, this message translates to:
  /// **'Driver ID'**
  String get driverId;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional Notes'**
  String get optionalNotes;

  /// No description provided for @topUpApproved.
  ///
  /// In en, this message translates to:
  /// **'Top-up approved successfully'**
  String get topUpApproved;

  /// No description provided for @topUpRejected.
  ///
  /// In en, this message translates to:
  /// **'Top-up rejected'**
  String get topUpRejected;

  /// No description provided for @topUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get topUpFailed;

  /// No description provided for @viewScreenshot.
  ///
  /// In en, this message translates to:
  /// **'View Screenshot'**
  String get viewScreenshot;

  /// No description provided for @walletProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get walletProvider;

  /// No description provided for @walletNumber.
  ///
  /// In en, this message translates to:
  /// **'Wallet Number'**
  String get walletNumber;

  /// No description provided for @walletActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletActive;

  /// No description provided for @walletInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get walletInactive;

  /// No description provided for @providerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MOBILE_WALLET'**
  String get providerHint;

  /// No description provided for @walletNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 01XXXXXXXXX'**
  String get walletNumberHint;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @walletFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save wallet'**
  String get walletFailed;

  /// No description provided for @auditLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track all admin actions and system changes'**
  String get auditLogsSubtitle;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get actionCreate;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get actionUpdate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get actionDelete;

  /// No description provided for @actionLogin.
  ///
  /// In en, this message translates to:
  /// **'Logged In'**
  String get actionLogin;

  /// No description provided for @actionLogout.
  ///
  /// In en, this message translates to:
  /// **'Logged Out'**
  String get actionLogout;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get by;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// No description provided for @announcementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast push notifications to your users'**
  String get announcementsSubtitle;

  /// No description provided for @newAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get newAnnouncementTitle;

  /// No description provided for @targetAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudience;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic (Optional)'**
  String get arabic;

  /// No description provided for @messageBodyEn.
  ///
  /// In en, this message translates to:
  /// **'Message Body (EN)'**
  String get messageBodyEn;

  /// No description provided for @messageBodyAr.
  ///
  /// In en, this message translates to:
  /// **'Message Body (AR)'**
  String get messageBodyAr;

  /// No description provided for @broadcastAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Announcement'**
  String get broadcastAnnouncement;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @confirmBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to broadcast to {audience}? This cannot be undone.'**
  String confirmBroadcastBody(String audience);

  /// No description provided for @tabAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get tabAssets;

  /// No description provided for @tabFinancials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get tabFinancials;

  /// No description provided for @tabDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get tabDelivery;

  /// No description provided for @tabLoyalty.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get tabLoyalty;

  /// No description provided for @tabDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get tabDrivers;

  /// No description provided for @tabAppLegal.
  ///
  /// In en, this message translates to:
  /// **'App & Legal'**
  String get tabAppLegal;

  /// No description provided for @tabDataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get tabDataRetention;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @defaultCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Default Commission Rate (%)'**
  String get defaultCommissionRate;

  /// No description provided for @deliveryCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Commission Rate (%)'**
  String get deliveryCommissionRate;

  /// No description provided for @customOrderPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Custom Order Platform Fee'**
  String get customOrderPlatformFee;

  /// No description provided for @defaultTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Default Tax Rate (%)'**
  String get defaultTaxRate;

  /// No description provided for @minOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Amount'**
  String get minOrderAmount;

  /// No description provided for @highValueOrderThreshold.
  ///
  /// In en, this message translates to:
  /// **'High Value Order Threshold'**
  String get highValueOrderThreshold;

  /// No description provided for @highValueUpfrontRate.
  ///
  /// In en, this message translates to:
  /// **'High Value Upfront Rate (%)'**
  String get highValueUpfrontRate;

  /// No description provided for @baseDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Base Delivery Fee'**
  String get baseDeliveryFee;

  /// No description provided for @pricePerKm.
  ///
  /// In en, this message translates to:
  /// **'Price Per Km'**
  String get pricePerKm;

  /// No description provided for @pricePerKmBicycle.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Bicycle)'**
  String get pricePerKmBicycle;

  /// No description provided for @pricePerKmMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Motorcycle)'**
  String get pricePerKmMotorcycle;

  /// No description provided for @pricePerKmCar.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Car)'**
  String get pricePerKmCar;

  /// No description provided for @pricePerKmVan.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Van)'**
  String get pricePerKmVan;

  /// No description provided for @pricePerKmTruck.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Truck)'**
  String get pricePerKmTruck;

  /// No description provided for @pricePerKmMotorTricycle.
  ///
  /// In en, this message translates to:
  /// **'Price per Km (Motor Tricycle)'**
  String get pricePerKmMotorTricycle;

  /// No description provided for @minDeliveryFeeBicycle.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Bicycle)'**
  String get minDeliveryFeeBicycle;

  /// No description provided for @maxDeliveryFeeBicycle.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Bicycle)'**
  String get maxDeliveryFeeBicycle;

  /// No description provided for @minDeliveryFeeMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Motorcycle)'**
  String get minDeliveryFeeMotorcycle;

  /// No description provided for @maxDeliveryFeeMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Motorcycle)'**
  String get maxDeliveryFeeMotorcycle;

  /// No description provided for @minDeliveryFeeCar.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Car)'**
  String get minDeliveryFeeCar;

  /// No description provided for @maxDeliveryFeeCar.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Car)'**
  String get maxDeliveryFeeCar;

  /// No description provided for @minDeliveryFeeVan.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Van)'**
  String get minDeliveryFeeVan;

  /// No description provided for @maxDeliveryFeeVan.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Van)'**
  String get maxDeliveryFeeVan;

  /// No description provided for @minDeliveryFeeTruck.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Truck)'**
  String get minDeliveryFeeTruck;

  /// No description provided for @maxDeliveryFeeTruck.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Truck)'**
  String get maxDeliveryFeeTruck;

  /// No description provided for @minDeliveryFeeMotorTricycle.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Fee (Motor Tricycle)'**
  String get minDeliveryFeeMotorTricycle;

  /// No description provided for @maxDeliveryFeeMotorTricycle.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee (Motor Tricycle)'**
  String get maxDeliveryFeeMotorTricycle;

  /// No description provided for @vehicleDeliveryPricing.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Delivery Pricing'**
  String get vehicleDeliveryPricing;

  /// No description provided for @maxDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Fee'**
  String get maxDeliveryFee;

  /// No description provided for @minOrderKm.
  ///
  /// In en, this message translates to:
  /// **'Min Order Km'**
  String get minOrderKm;

  /// No description provided for @minDistanceFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Distance Fixed Price'**
  String get minDistanceFixedPrice;

  /// No description provided for @autoCancelPendingMins.
  ///
  /// In en, this message translates to:
  /// **'Auto Cancel Pending (Mins)'**
  String get autoCancelPendingMins;

  /// No description provided for @maxDeliveryRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Radius (Km)'**
  String get maxDeliveryRadiusKm;

  /// No description provided for @driverSearchRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'Driver Search Radius (Km)'**
  String get driverSearchRadiusKm;

  /// No description provided for @driverSearchRadiusStepKm.
  ///
  /// In en, this message translates to:
  /// **'Driver Search Radius Step (Km)'**
  String get driverSearchRadiusStepKm;

  /// No description provided for @driverSearchRadiusMaxKm.
  ///
  /// In en, this message translates to:
  /// **'Driver Search Radius Max (Km)'**
  String get driverSearchRadiusMaxKm;

  /// No description provided for @driverSearchMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Driver Search Max Attempts'**
  String get driverSearchMaxAttempts;

  /// No description provided for @fallbackOrderDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'Fallback Order Distance (Km)'**
  String get fallbackOrderDistanceKm;

  /// No description provided for @driverAcceptTimeoutSecs.
  ///
  /// In en, this message translates to:
  /// **'Driver Accept Timeout (Secs)'**
  String get driverAcceptTimeoutSecs;

  /// No description provided for @maxDispatchBatchSize.
  ///
  /// In en, this message translates to:
  /// **'Max Dispatch Batch Size'**
  String get maxDispatchBatchSize;

  /// No description provided for @maxKmForBicycle.
  ///
  /// In en, this message translates to:
  /// **'Max Km For Bicycle'**
  String get maxKmForBicycle;

  /// No description provided for @coinValue.
  ///
  /// In en, this message translates to:
  /// **'Coin Value'**
  String get coinValue;

  /// No description provided for @amountSpentPerCoin.
  ///
  /// In en, this message translates to:
  /// **'Amount Spent Per Coin'**
  String get amountSpentPerCoin;

  /// No description provided for @minCoinsToUse.
  ///
  /// In en, this message translates to:
  /// **'Minimum Coins To Use'**
  String get minCoinsToUse;

  /// No description provided for @driverShiftsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Driver Shifts'**
  String get driverShiftsEnabled;

  /// No description provided for @driverBonusActive.
  ///
  /// In en, this message translates to:
  /// **'Driver Bonus Active'**
  String get driverBonusActive;

  /// No description provided for @driverBonusPaidByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Driver Bonus Paid By Customer'**
  String get driverBonusPaidByCustomer;

  /// No description provided for @driverBonusAmount.
  ///
  /// In en, this message translates to:
  /// **'Driver Bonus Amount'**
  String get driverBonusAmount;

  /// No description provided for @bronzeTierBonusPerKm.
  ///
  /// In en, this message translates to:
  /// **'Bronze Tier Bonus Per Km'**
  String get bronzeTierBonusPerKm;

  /// No description provided for @silverTierBonusPerKm.
  ///
  /// In en, this message translates to:
  /// **'Silver Tier Bonus Per Km'**
  String get silverTierBonusPerKm;

  /// No description provided for @goldTierBonusPerKm.
  ///
  /// In en, this message translates to:
  /// **'Gold Tier Bonus Per Km'**
  String get goldTierBonusPerKm;

  /// No description provided for @driverSettlementOrderThreshold.
  ///
  /// In en, this message translates to:
  /// **'Orders Until Driver Settlement'**
  String get driverSettlementOrderThreshold;

  /// No description provided for @isMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get isMaintenanceMode;

  /// No description provided for @androidMinVersion.
  ///
  /// In en, this message translates to:
  /// **'Android Min Version'**
  String get androidMinVersion;

  /// No description provided for @androidLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Android Latest Version'**
  String get androidLatestVersion;

  /// No description provided for @androidForceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Android Force Update'**
  String get androidForceUpdate;

  /// No description provided for @androidStoreUrl.
  ///
  /// In en, this message translates to:
  /// **'Android Store URL'**
  String get androidStoreUrl;

  /// No description provided for @iosMinVersion.
  ///
  /// In en, this message translates to:
  /// **'iOS Min Version'**
  String get iosMinVersion;

  /// No description provided for @iosLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'iOS Latest Version'**
  String get iosLatestVersion;

  /// No description provided for @iosForceUpdate.
  ///
  /// In en, this message translates to:
  /// **'iOS Force Update'**
  String get iosForceUpdate;

  /// No description provided for @iosStoreUrl.
  ///
  /// In en, this message translates to:
  /// **'iOS Store URL'**
  String get iosStoreUrl;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get supportEmail;

  /// No description provided for @supportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support Phone'**
  String get supportPhone;

  /// No description provided for @supportWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Support WhatsApp'**
  String get supportWhatsapp;

  /// No description provided for @termsUrl.
  ///
  /// In en, this message translates to:
  /// **'Terms URL'**
  String get termsUrl;

  /// No description provided for @privacyUrl.
  ///
  /// In en, this message translates to:
  /// **'Privacy URL'**
  String get privacyUrl;

  /// No description provided for @retentionOrdersDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Orders (Days)'**
  String get retentionOrdersDays;

  /// No description provided for @retentionArchivedChatsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Archived Chats (Days)'**
  String get retentionArchivedChatsDays;

  /// No description provided for @retentionNotificationsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Notifications (Days)'**
  String get retentionNotificationsDays;

  /// No description provided for @retentionExpiredSessionsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Expired Sessions (Days)'**
  String get retentionExpiredSessionsDays;

  /// No description provided for @retentionAuditLogsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Audit Logs (Days)'**
  String get retentionAuditLogsDays;

  /// No description provided for @retentionAbandonedCartsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Abandoned Carts (Days)'**
  String get retentionAbandonedCartsDays;

  /// No description provided for @retentionWalletTransactionsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Wallet Transactions (Days)'**
  String get retentionWalletTransactionsDays;

  /// No description provided for @retentionStatisticsDays.
  ///
  /// In en, this message translates to:
  /// **'Retention Statistics (Days)'**
  String get retentionStatisticsDays;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSavedSuccessfully;

  /// No description provided for @adjustWalletVendor.
  ///
  /// In en, this message translates to:
  /// **'Adjust Wallet (Vendor)'**
  String get adjustWalletVendor;

  /// No description provided for @adjustWalletDriver.
  ///
  /// In en, this message translates to:
  /// **'Adjust Wallet (Driver)'**
  String get adjustWalletDriver;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @payout.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get payout;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get topUp;

  /// No description provided for @penalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get penalty;

  /// No description provided for @cashCollection.
  ///
  /// In en, this message translates to:
  /// **'Cash Collection'**
  String get cashCollection;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @adjustWallet.
  ///
  /// In en, this message translates to:
  /// **'Adjust Wallet'**
  String get adjustWallet;

  /// No description provided for @failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithError(String error);

  /// No description provided for @searchDrivers.
  ///
  /// In en, this message translates to:
  /// **'Search Drivers'**
  String get searchDrivers;

  /// No description provided for @assignOrder.
  ///
  /// In en, this message translates to:
  /// **'Assign Order'**
  String get assignOrder;

  /// No description provided for @assignOrderToDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Order to {driverName}'**
  String assignOrderToDriver(String driverName);

  /// No description provided for @orderIdUuid.
  ///
  /// In en, this message translates to:
  /// **'Order ID (UUID)'**
  String get orderIdUuid;

  /// No description provided for @fileExceedsMaxSize.
  ///
  /// In en, this message translates to:
  /// **'File exceeds maximum size of {size}MB'**
  String fileExceedsMaxSize(String size);

  /// No description provided for @noVendorMembershipsFound.
  ///
  /// In en, this message translates to:
  /// **'No vendor memberships found.'**
  String get noVendorMembershipsFound;

  /// No description provided for @vendorIdParam.
  ///
  /// In en, this message translates to:
  /// **'Vendor ID: {id}'**
  String vendorIdParam(String id);

  /// No description provided for @roleParam.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleParam(String role);

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String errorSavingSettings(String error);

  /// No description provided for @mobileWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get mobileWallet;

  /// No description provided for @orangeCash.
  ///
  /// In en, this message translates to:
  /// **'Orange Cash'**
  String get orangeCash;

  /// No description provided for @wePay.
  ///
  /// In en, this message translates to:
  /// **'WE Pay'**
  String get wePay;

  /// No description provided for @etisalatCash.
  ///
  /// In en, this message translates to:
  /// **'Etisalat Cash'**
  String get etisalatCash;

  /// No description provided for @instaPay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get instaPay;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @enterOrderIdToAssign.
  ///
  /// In en, this message translates to:
  /// **'Select the order you want to manually assign to this driver.'**
  String get enterOrderIdToAssign;

  /// No description provided for @editZone.
  ///
  /// In en, this message translates to:
  /// **'Edit Zone'**
  String get editZone;

  /// No description provided for @defineDeliveryArea.
  ///
  /// In en, this message translates to:
  /// **'Define delivery area parameters'**
  String get defineDeliveryArea;

  /// No description provided for @boundary.
  ///
  /// In en, this message translates to:
  /// **'Boundary'**
  String get boundary;

  /// No description provided for @noBoundarySet.
  ///
  /// In en, this message translates to:
  /// **'No Boundary Set'**
  String get noBoundarySet;

  /// No description provided for @boundaryDefined.
  ///
  /// In en, this message translates to:
  /// **'Boundary Defined'**
  String get boundaryDefined;

  /// No description provided for @tapToDrawMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to draw on map'**
  String get tapToDrawMap;

  /// No description provided for @pointsDefined.
  ///
  /// In en, this message translates to:
  /// **'{count} points defined'**
  String pointsDefined(String count);

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @overridesOptional.
  ///
  /// In en, this message translates to:
  /// **'Overrides (Optional)'**
  String get overridesOptional;

  /// No description provided for @baseFeeOverride.
  ///
  /// In en, this message translates to:
  /// **'Base Fee Override'**
  String get baseFeeOverride;

  /// No description provided for @minOrderOverride.
  ///
  /// In en, this message translates to:
  /// **'Min Order Override'**
  String get minOrderOverride;

  /// No description provided for @updateZone.
  ///
  /// In en, this message translates to:
  /// **'Update Zone'**
  String get updateZone;

  /// No description provided for @createZone.
  ///
  /// In en, this message translates to:
  /// **'Create Zone'**
  String get createZone;

  /// No description provided for @drawZoneBoundary.
  ///
  /// In en, this message translates to:
  /// **'Draw Zone Boundary'**
  String get drawZoneBoundary;

  /// No description provided for @confirmBoundary.
  ///
  /// In en, this message translates to:
  /// **'Confirm Boundary'**
  String get confirmBoundary;

  /// No description provided for @tapMapToDrawMinimum.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to draw the delivery zone polygon. Minimum 3 points required.'**
  String get tapMapToDrawMinimum;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in settings.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionsDeniedPermanent.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied, please enable them in app settings.'**
  String get locationPermissionsDeniedPermanent;

  /// No description provided for @pleaseDrawValidBoundary.
  ///
  /// In en, this message translates to:
  /// **'Please draw a valid boundary on the map'**
  String get pleaseDrawValidBoundary;

  /// No description provided for @errorSavingZone.
  ///
  /// In en, this message translates to:
  /// **'Error saving zone: {error}'**
  String errorSavingZone(String error);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re improving the app right now. Please try again in a bit.'**
  String get maintenanceMessage;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update the app to the latest version to continue.'**
  String get updateRequiredMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New Version Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version of the app is available.'**
  String get updateAvailableMessage;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @perm_manage_orders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get perm_manage_orders;

  /// No description provided for @perm_manage_products.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get perm_manage_products;

  /// No description provided for @perm_manage_vendors.
  ///
  /// In en, this message translates to:
  /// **'Manage Vendors'**
  String get perm_manage_vendors;

  /// No description provided for @perm_manage_drivers.
  ///
  /// In en, this message translates to:
  /// **'Manage Drivers'**
  String get perm_manage_drivers;

  /// No description provided for @perm_manage_customers.
  ///
  /// In en, this message translates to:
  /// **'Manage Customers'**
  String get perm_manage_customers;

  /// No description provided for @perm_manage_tickets.
  ///
  /// In en, this message translates to:
  /// **'Manage Tickets'**
  String get perm_manage_tickets;

  /// No description provided for @perm_manage_conversations.
  ///
  /// In en, this message translates to:
  /// **'Manage Conversations'**
  String get perm_manage_conversations;

  /// No description provided for @perm_view_statistics.
  ///
  /// In en, this message translates to:
  /// **'View Statistics'**
  String get perm_view_statistics;

  /// No description provided for @perm_manage_settings.
  ///
  /// In en, this message translates to:
  /// **'Manage Settings'**
  String get perm_manage_settings;

  /// No description provided for @perm_manage_users.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get perm_manage_users;

  /// No description provided for @perm_view_financials.
  ///
  /// In en, this message translates to:
  /// **'View Financials'**
  String get perm_view_financials;

  /// No description provided for @perm_manage_finance.
  ///
  /// In en, this message translates to:
  /// **'Manage Finance'**
  String get perm_manage_finance;

  /// No description provided for @perm_manage_promotions.
  ///
  /// In en, this message translates to:
  /// **'Manage Promotions'**
  String get perm_manage_promotions;

  /// No description provided for @perm_manage_announcements.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get perm_manage_announcements;

  /// No description provided for @perm_view_audit_logs.
  ///
  /// In en, this message translates to:
  /// **'View Audit Logs'**
  String get perm_view_audit_logs;

  /// No description provided for @driverShifts.
  ///
  /// In en, this message translates to:
  /// **'Driver Shifts'**
  String get driverShifts;

  /// No description provided for @shiftManagement.
  ///
  /// In en, this message translates to:
  /// **'Shift Management'**
  String get shiftManagement;

  /// No description provided for @shiftPools.
  ///
  /// In en, this message translates to:
  /// **'Shift Pools'**
  String get shiftPools;

  /// No description provided for @generateShifts.
  ///
  /// In en, this message translates to:
  /// **'Generate Shifts'**
  String get generateShifts;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriver;

  /// No description provided for @shiftDate.
  ///
  /// In en, this message translates to:
  /// **'Shift Date'**
  String get shiftDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @maxDrivers.
  ///
  /// In en, this message translates to:
  /// **'Max Drivers'**
  String get maxDrivers;

  /// No description provided for @assignedDrivers.
  ///
  /// In en, this message translates to:
  /// **'Assigned Drivers'**
  String get assignedDrivers;

  /// No description provided for @shiftGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shifts generated successfully'**
  String get shiftGeneratedSuccessfully;

  /// No description provided for @shiftGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate shifts'**
  String get shiftGenerationFailed;

  /// No description provided for @shiftDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shift pool deleted successfully'**
  String get shiftDeletedSuccessfully;

  /// No description provided for @shiftPoolDisabledDueToHistory.
  ///
  /// In en, this message translates to:
  /// **'This shift pool has past completed shifts, so it can\'t be deleted. It was disabled instead.'**
  String get shiftPoolDisabledDueToHistory;

  /// No description provided for @driverAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned successfully'**
  String get driverAssignedSuccessfully;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @selectZone.
  ///
  /// In en, this message translates to:
  /// **'Select Zone'**
  String get selectZone;

  /// No description provided for @allZones.
  ///
  /// In en, this message translates to:
  /// **'All Zones'**
  String get allZones;

  /// No description provided for @searchDriver.
  ///
  /// In en, this message translates to:
  /// **'Search Driver...'**
  String get searchDriver;

  /// No description provided for @noShiftsFound.
  ///
  /// In en, this message translates to:
  /// **'No shifts found'**
  String get noShiftsFound;

  /// No description provided for @deleteShiftPool.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift Pool'**
  String get deleteShiftPool;

  /// No description provided for @deleteShiftPoolConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shift pool? This action cannot be undone.'**
  String get deleteShiftPoolConfirm;

  /// No description provided for @deleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift'**
  String get deleteShift;

  /// No description provided for @deleteShiftConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this shift?'**
  String get deleteShiftConfirmTitle;

  /// No description provided for @deleteShiftConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This shift will be permanently removed. The driver will lose it immediately.'**
  String get deleteShiftConfirmMessage;

  /// No description provided for @shiftRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shift removed successfully'**
  String get shiftRemovedSuccessfully;

  /// No description provided for @deleteShiftPoolHasDrivers.
  ///
  /// In en, this message translates to:
  /// **'This shift pool has assigned drivers. Remove the drivers first before deleting it.'**
  String get deleteShiftPoolHasDrivers;

  /// No description provided for @removeDriver.
  ///
  /// In en, this message translates to:
  /// **'Remove Driver'**
  String get removeDriver;

  /// No description provided for @removeDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this driver from the shift?'**
  String get removeDriverConfirm;

  /// No description provided for @removeDriverSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver removed from shift'**
  String get removeDriverSuccess;

  /// No description provided for @removeAllDrivers.
  ///
  /// In en, this message translates to:
  /// **'Remove All Drivers'**
  String get removeAllDrivers;

  /// No description provided for @removeAllDriversConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all drivers from this pool? The pool itself will be kept.'**
  String get removeAllDriversConfirm;

  /// No description provided for @removeAllDriversSuccess.
  ///
  /// In en, this message translates to:
  /// **'All drivers removed from pool'**
  String get removeAllDriversSuccess;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @roleUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdatedSuccessfully;

  /// No description provided for @staffMembership.
  ///
  /// In en, this message translates to:
  /// **'Staffs'**
  String get staffMembership;

  /// No description provided for @noStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No staff members found.'**
  String get noStaffFound;

  /// No description provided for @accessControl.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get accessControl;

  /// No description provided for @failedToLoadShifts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shifts'**
  String get failedToLoadShifts;

  /// No description provided for @driverNoScheduledShifts.
  ///
  /// In en, this message translates to:
  /// **'This driver has no scheduled shifts.'**
  String get driverNoScheduledShifts;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @driverBalance.
  ///
  /// In en, this message translates to:
  /// **'Bal'**
  String get driverBalance;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate'**
  String get vehiclePlate;

  /// No description provided for @vehicleTypeBicycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get vehicleTypeBicycle;

  /// No description provided for @vehicleTypeMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get vehicleTypeMotorcycle;

  /// No description provided for @vehicleTypeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehicleTypeCar;

  /// No description provided for @vehicleTypeVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleTypeVan;

  /// No description provided for @vehicleTypeTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get vehicleTypeTruck;

  /// No description provided for @vehicleTypeMotorTricycle.
  ///
  /// In en, this message translates to:
  /// **'Motor Tricycle'**
  String get vehicleTypeMotorTricycle;

  /// No description provided for @vehicleVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleVan;

  /// No description provided for @vehicleTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get vehicleTruck;

  /// No description provided for @vehicleMotorTricycle.
  ///
  /// In en, this message translates to:
  /// **'Motor Tricycle'**
  String get vehicleMotorTricycle;

  /// No description provided for @mostOrderedProduct.
  ///
  /// In en, this message translates to:
  /// **'Most ordered'**
  String get mostOrderedProduct;

  /// No description provided for @noMostOrderedProduct.
  ///
  /// In en, this message translates to:
  /// **'No most ordered yet'**
  String get noMostOrderedProduct;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get ordersCount;

  /// No description provided for @driverApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Approved'**
  String get driverApprovedTitle;

  /// No description provided for @driverApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow driver to log in and go online'**
  String get driverApprovedSubtitle;

  /// No description provided for @actionWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get actionWallet;

  /// No description provided for @actionAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get actionAssign;

  /// No description provided for @actionShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get actionShifts;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get actionSuspend;

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actionApprove;

  /// No description provided for @actionLocation.
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get actionLocation;

  /// No description provided for @driverLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live location'**
  String get driverLiveLocation;

  /// No description provided for @driverLastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Last known location'**
  String get driverLastKnownLocation;

  /// No description provided for @driverNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location available'**
  String get driverNoLocation;

  /// No description provided for @driverStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get driverStatusApproved;

  /// No description provided for @driverStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get driverStatusPending;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID (UUID)'**
  String get orderIdLabel;

  /// No description provided for @actionUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend'**
  String get actionUnsuspend;

  /// No description provided for @driverStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get driverStatusSuspended;

  /// No description provided for @drawSelectionArea.
  ///
  /// In en, this message translates to:
  /// **'Draw Selection Area'**
  String get drawSelectionArea;

  /// No description provided for @audienceSelection.
  ///
  /// In en, this message translates to:
  /// **'Audience Selection'**
  String get audienceSelection;

  /// No description provided for @customersFound.
  ///
  /// In en, this message translates to:
  /// **'Customers Found: {count}'**
  String customersFound(String count);

  /// No description provided for @polygonInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to draw a polygon. Tap the first point to close it.'**
  String get polygonInstructions;

  /// No description provided for @resetPolygon.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetPolygon;

  /// No description provided for @undoPoint.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoPoint;

  /// No description provided for @findCustomers.
  ///
  /// In en, this message translates to:
  /// **'Find Customers'**
  String get findCustomers;

  /// No description provided for @customerResults.
  ///
  /// In en, this message translates to:
  /// **'Customer Results'**
  String get customerResults;

  /// No description provided for @registrationDate.
  ///
  /// In en, this message translates to:
  /// **'Registration Date: {date}'**
  String registrationDate(String date);

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @topDrivers.
  ///
  /// In en, this message translates to:
  /// **'Top Drivers'**
  String get topDrivers;

  /// No description provided for @topCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get topCustomers;

  /// No description provided for @topVendors.
  ///
  /// In en, this message translates to:
  /// **'Top Vendors'**
  String get topVendors;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @topProduct.
  ///
  /// In en, this message translates to:
  /// **'Top Product'**
  String get topProduct;

  /// No description provided for @analyticsTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get analyticsTrips;

  /// No description provided for @analyticsBal.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get analyticsBal;

  /// No description provided for @analyticsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get analyticsRevenue;

  /// No description provided for @analyticsTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get analyticsTotalSpent;

  /// No description provided for @analyticsCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get analyticsCoins;

  /// No description provided for @noActiveOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No active orders found'**
  String get noActiveOrdersFound;

  /// No description provided for @pickupPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pickup photo'**
  String get pickupPhoto;

  /// No description provided for @viewPickupPhoto.
  ///
  /// In en, this message translates to:
  /// **'View pickup photo'**
  String get viewPickupPhoto;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
