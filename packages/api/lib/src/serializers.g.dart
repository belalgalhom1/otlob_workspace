// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add($ApiResponseDto.serializer)
          ..add(AddCartItemDto.serializer)
          ..add(AddCartItemDtoSelectedUnitEnum.serializer)
          ..add(AddVendorMemberDto.serializer)
          ..add(AddVendorMemberDtoRoleEnum.serializer)
          ..add(AdminAssignDriverDto.serializer)
          ..add(AdminAssignShiftDto.serializer)
          ..add(AdminBookWeeklyShiftsDto.serializer)
          ..add(AdminCreateDriverDto.serializer)
          ..add(AdminCreateDriverDtoStatusEnum.serializer)
          ..add(AdminCreateDriverDtoVehicleTypeEnum.serializer)
          ..add(AdminUpdateDriverDto.serializer)
          ..add(AdminUpdateDriverDtoStatusEnum.serializer)
          ..add(AdminUpdateDriverDtoVehicleTypeEnum.serializer)
          ..add(AdminUpdateUserDto.serializer)
          ..add(AdminUpdateUserDtoLanguageEnum.serializer)
          ..add(AdminUpdateUserDtoPermissionsEnum.serializer)
          ..add(AdminUpdateUserDtoRoleEnum.serializer)
          ..add(AdminUpdateUserDtoVendorRoleEnum.serializer)
          ..add(ApiControllerRoot200Response.serializer)
          ..add(AppVersionCheckDto.serializer)
          ..add(AppVersionCheckDtoPlatformEnum.serializer)
          ..add(AssignAssistDriverDto.serializer)
          ..add(AssignDriversToManagerDto.serializer)
          ..add(AuditActionType.serializer)
          ..add(AuditLogResponseDto.serializer)
          ..add(AuditLogsControllerFindAll200Response.serializer)
          ..add(BanUserDto.serializer)
          ..add(BookOvertimeShiftDto.serializer)
          ..add(BookWeeklyShiftsDto.serializer)
          ..add(CartItem.serializer)
          ..add(CartItemOption.serializer)
          ..add(ChangeEmailDto.serializer)
          ..add(ChangePasswordDto.serializer)
          ..add(CheckLocationDto.serializer)
          ..add(ConfirmPaymentDto.serializer)
          ..add(CreateAddressDto.serializer)
          ..add(CreateDirectConversationDto.serializer)
          ..add(CreateDriverShiftDto.serializer)
          ..add(CreateMenuCategoryDto.serializer)
          ..add(CreateMenuCategoryDtoBranchAvailabilityModeEnum.serializer)
          ..add(CreateMobileWalletDto.serializer)
          ..add(CreateMobileWalletDtoTypeEnum.serializer)
          ..add(CreateOfferDto.serializer)
          ..add(CreateOptionGroupDto.serializer)
          ..add(CreateOrderConversationDto.serializer)
          ..add(CreateProductDto.serializer)
          ..add(CreateProductDtoBranchAvailabilityModeEnum.serializer)
          ..add(CreateProductOptionDto.serializer)
          ..add(CreateProductVariantDto.serializer)
          ..add(CreateReviewDto.serializer)
          ..add(CreateSupportConversationDto.serializer)
          ..add(CreateTicketDto.serializer)
          ..add(CreateTicketDtoCategoryEnum.serializer)
          ..add(CreateTicketDtoPriorityEnum.serializer)
          ..add(CreateVendorBranchDto.serializer)
          ..add(CreateVendorConversationDto.serializer)
          ..add(CreateVendorDto.serializer)
          ..add(CreateVendorVerticalDto.serializer)
          ..add(CreateWalletTopUpDto.serializer)
          ..add(CreateZoneDto.serializer)
          ..add(Customer.serializer)
          ..add(DecideAssistRequestDto.serializer)
          ..add(DecideAssistRequestDtoStatusEnum.serializer)
          ..add(DeliveryGroupStatus.serializer)
          ..add(DispatchAnnouncementDto.serializer)
          ..add(DispatchAnnouncementDtoAudienceEnum.serializer)
          ..add(DispatchAnnouncementDtoTypeEnum.serializer)
          ..add(DispatchStatus.serializer)
          ..add(Driver.serializer)
          ..add(DriverBreak.serializer)
          ..add(DriverBreakReason.serializer)
          ..add(DriverBreakStatus.serializer)
          ..add(DriverShift.serializer)
          ..add(DriverShiftStatus.serializer)
          ..add(DriverStatus.serializer)
          ..add(DriverTier.serializer)
          ..add(DriverWalletTransaction.serializer)
          ..add(DriverWalletTransactionResponseDto.serializer)
          ..add(DriversControllerGetMyBreaks200Response.serializer)
          ..add(DriversControllerMyAssistRequests200Response.serializer)
          ..add(DriversControllerStartBreak200Response.serializer)
          ..add(FavoriteProduct.serializer)
          ..add(ForgotPasswordDto.serializer)
          ..add(GenerateShiftPoolsDto.serializer)
          ..add(JoinWaitlistDto.serializer)
          ..add(Language.serializer)
          ..add(LoginDto.serializer)
          ..add(LogoutDto.serializer)
          ..add(MarkNotificationsReadDto.serializer)
          ..add(MarkReadDto.serializer)
          ..add(MenuCategory.serializer)
          ..add(MenuCategoryBranchAvailabilityModeEnum.serializer)
          ..add(MobileWallet.serializer)
          ..add(MobileWalletResponseDto.serializer)
          ..add(Offer.serializer)
          ..add(Order.serializer)
          ..add(OrderDeliveryGroup.serializer)
          ..add(OrderDispatch.serializer)
          ..add(OrderFeeEstimateDto.serializer)
          ..add(OrderItem.serializer)
          ..add(OrderItemOption.serializer)
          ..add(OrderResponseDto.serializer)
          ..add(OrderStatus.serializer)
          ..add(OrderStatusEvent.serializer)
          ..add(OrderType.serializer)
          ..add(OrderVendorFulfillment.serializer)
          ..add(OrderVendorFulfillmentStatus.serializer)
          ..add(OrdersControllerEstimateCustomOrder200Response.serializer)
          ..add(OrdersControllerPlaceOrder200Response.serializer)
          ..add(PaginatedReviewsResponseDto.serializer)
          ..add(PaginationMetaDto.serializer)
          ..add(PaymentMethod.serializer)
          ..add(PaymentStatus.serializer)
          ..add(Permission.serializer)
          ..add(PlaceCustomOrderDto.serializer)
          ..add(PlaceCustomOrderDtoPaymentMethodEnum.serializer)
          ..add(PlaceCustomOrderDtoTypeEnum.serializer)
          ..add(PlaceCustomOrderDtoVehicleTypeEnum.serializer)
          ..add(PlaceDirectOrderDto.serializer)
          ..add(PlaceDirectOrderDtoPaymentMethodEnum.serializer)
          ..add(PlaceMultiVendorOrderDto.serializer)
          ..add(PlaceMultiVendorOrderDtoPaymentMethodEnum.serializer)
          ..add(PlaceOrderDto.serializer)
          ..add(PlaceOrderDtoPaymentMethodEnum.serializer)
          ..add(ProcessManualTransactionDto.serializer)
          ..add(Product.serializer)
          ..add(ProductBranchAvailability.serializer)
          ..add(ProductBranchAvailabilityModeEnum.serializer)
          ..add(ProductOption.serializer)
          ..add(ProductOptionGroup.serializer)
          ..add(ProductOptionGroupResponseDto.serializer)
          ..add(ProductOptionResponseDto.serializer)
          ..add(ProductResponseDto.serializer)
          ..add(ProductResponseDtoBranchAvailabilityModeEnum.serializer)
          ..add(ProductVariant.serializer)
          ..add(ProductVariantResponseDto.serializer)
          ..add(ProductsControllerCreate200Response.serializer)
          ..add(ProductsControllerUpdateOption200Response.serializer)
          ..add(ProductsControllerUpdateOptionGroup200Response.serializer)
          ..add(ProductsControllerUpdateVariant200Response.serializer)
          ..add(Promotion.serializer)
          ..add(PromotionType.serializer)
          ..add(RegisterDeviceDto.serializer)
          ..add(RegisterDeviceDtoPlatformEnum.serializer)
          ..add(RegisterDriverDto.serializer)
          ..add(RegisterDriverDtoVehicleTypeEnum.serializer)
          ..add(RegisterDto.serializer)
          ..add(RegisterDtoRoleEnum.serializer)
          ..add(RegisterDtoVendorRoleEnum.serializer)
          ..add(RejectVendorFulfillmentDto.serializer)
          ..add(RejectVendorFulfillmentDtoCodeEnum.serializer)
          ..add(ReorderCategoriesDto.serializer)
          ..add(RequestAssistDriverDto.serializer)
          ..add(RequestAssistDriverDtoReasonEnum.serializer)
          ..add(ResetPasswordDto.serializer)
          ..add(RespondToDispatchDto.serializer)
          ..add(RespondToDispatchDtoResponseEnum.serializer)
          ..add(ReviewCustomerDto.serializer)
          ..add(ReviewCustomerUserDto.serializer)
          ..add(ReviewDto.serializer)
          ..add(ReviewWalletTopUpDto.serializer)
          ..add(ReviewsControllerGetVendorReviews200Response.serializer)
          ..add(Role.serializer)
          ..add(SearchCustomersInPolygonDto.serializer)
          ..add(SendMessageDto.serializer)
          ..add(SendMessageDtoTypeEnum.serializer)
          ..add(SendOtpDto.serializer)
          ..add(SendOtpDtoMethodEnum.serializer)
          ..add(Session.serializer)
          ..add(SetPasswordDto.serializer)
          ..add(SocialLoginDto.serializer)
          ..add(SocialLoginDtoAppEnum.serializer)
          ..add(SocialLoginDtoProviderEnum.serializer)
          ..add(StartBreakDto.serializer)
          ..add(StartBreakDtoReasonEnum.serializer)
          ..add(SupportTicket.serializer)
          ..add(TicketCategory.serializer)
          ..add(TicketPriority.serializer)
          ..add(TicketStatus.serializer)
          ..add(TopUpStatus.serializer)
          ..add(UnassignDriversFromManagerDto.serializer)
          ..add(UpdateAddressDto.serializer)
          ..add(UpdateCartItemDto.serializer)
          ..add(UpdateCartItemDtoSelectedUnitEnum.serializer)
          ..add(UpdateDriverProfileDto.serializer)
          ..add(UpdateDriverStatusDto.serializer)
          ..add(UpdateDriverStatusDtoStatusEnum.serializer)
          ..add(UpdateMenuCategoryDto.serializer)
          ..add(UpdateMenuCategoryDtoBranchAvailabilityModeEnum.serializer)
          ..add(UpdateNotificationSettingsDto.serializer)
          ..add(UpdateOfferDto.serializer)
          ..add(UpdateOptionGroupDto.serializer)
          ..add(UpdateOrderStatusDto.serializer)
          ..add(UpdateOrderStatusDtoStatusEnum.serializer)
          ..add(UpdatePlatformSettingsDto.serializer)
          ..add(UpdateProductDto.serializer)
          ..add(UpdateProductDtoBranchAvailabilityModeEnum.serializer)
          ..add(UpdateProductOptionDto.serializer)
          ..add(UpdateProductVariantDto.serializer)
          ..add(UpdatePromotionDto.serializer)
          ..add(UpdatePromotionDtoTypeEnum.serializer)
          ..add(UpdateTicketDto.serializer)
          ..add(UpdateTicketDtoCategoryEnum.serializer)
          ..add(UpdateTicketDtoPriorityEnum.serializer)
          ..add(UpdateTicketDtoStatusEnum.serializer)
          ..add(UpdateUserDto.serializer)
          ..add(UpdateUserDtoLanguageEnum.serializer)
          ..add(UpdateVendorBranchDto.serializer)
          ..add(UpdateVendorDto.serializer)
          ..add(UpdateVendorMemberRoleDto.serializer)
          ..add(UpdateVendorMemberRoleDtoRoleEnum.serializer)
          ..add(UpdateVendorStatusDto.serializer)
          ..add(UpdateVendorStatusDtoStatusEnum.serializer)
          ..add(UpdateVendorVerticalDto.serializer)
          ..add(UpdateZoneDto.serializer)
          ..add(User.serializer)
          ..add(VehicleType.serializer)
          ..add(Vendor.serializer)
          ..add(VendorBranch.serializer)
          ..add(VendorStatus.serializer)
          ..add(VendorTransactionType.serializer)
          ..add(VendorWalletTransaction.serializer)
          ..add(VendorWalletTransactionResponseDto.serializer)
          ..add(VerifyOtpDto.serializer)
          ..add(VerifyOtpDtoPurposeEnum.serializer)
          ..add(WalletControllerGetActivePlatformWallets200Response.serializer)
          ..add(WalletControllerGetPendingTopUps200Response.serializer)
          ..add(WalletControllerProcessDriverTransaction200Response.serializer)
          ..add(WalletControllerProcessVendorTransaction200Response.serializer)
          ..add(WalletTopUpRequest.serializer)
          ..add(WalletTopUpRequestResponseDto.serializer)
          ..add(WalletTransactionType.serializer)
          ..add(WalletType.serializer)
          ..add(Zone.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(AdminUpdateUserDtoPermissionsEnum),
            ]),
            () => ListBuilder<AdminUpdateUserDtoPermissionsEnum>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(CartItem)]),
            () => ListBuilder<CartItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(FavoriteProduct)]),
            () => ListBuilder<FavoriteProduct>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderItem)]),
            () => ListBuilder<OrderItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ProductOptionGroup),
            ]),
            () => ListBuilder<ProductOptionGroup>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ProductVariant)]),
            () => ListBuilder<ProductVariant>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Promotion)]),
            () => ListBuilder<Promotion>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Offer)]),
            () => ListBuilder<Offer>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ProductBranchAvailability),
            ]),
            () => ListBuilder<ProductBranchAvailability>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(CartItem)]),
            () => ListBuilder<CartItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderItem)]),
            () => ListBuilder<OrderItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ProductOptionGroup),
            ]),
            () => ListBuilder<ProductOptionGroup>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Offer)]),
            () => ListBuilder<Offer>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(CartItemOption)]),
            () => ListBuilder<CartItemOption>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderItemOption)]),
            () => ListBuilder<OrderItemOption>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(CreateOptionGroupDto),
            ]),
            () => ListBuilder<CreateOptionGroupDto>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(CreateProductOptionDto),
            ]),
            () => ListBuilder<CreateProductOptionDto>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(DriverWalletTransaction),
            ]),
            () => ListBuilder<DriverWalletTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderDispatch)]),
            () => ListBuilder<OrderDispatch>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderItem)]),
            () => ListBuilder<OrderItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderStatusEvent)]),
            () => ListBuilder<OrderStatusEvent>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(SupportTicket)]),
            () => ListBuilder<SupportTicket>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(VendorWalletTransaction),
            ]),
            () => ListBuilder<VendorWalletTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(OrderVendorFulfillment),
            ]),
            () => ListBuilder<OrderVendorFulfillment>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(OrderDeliveryGroup),
            ]),
            () => ListBuilder<OrderDeliveryGroup>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(OrderItem)]),
            () => ListBuilder<OrderItem>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Permission)]),
            () => ListBuilder<Permission>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ProductOption)]),
            () => ListBuilder<ProductOption>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ReviewDto)]),
            () => ListBuilder<ReviewDto>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(CreateOptionGroupDto),
            ]),
            () => ListBuilder<CreateOptionGroupDto>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(CreateProductVariantDto),
            ]),
            () => ListBuilder<CreateProductVariantDto>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(WalletTopUpRequest),
            ]),
            () => ListBuilder<WalletTopUpRequest>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(num)]),
            () => ListBuilder<num>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltList, const [const FullType(String)]),
            ]),
            () => MapBuilder<String, BuiltList<String>>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
