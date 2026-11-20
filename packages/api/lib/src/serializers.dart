//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:api/src/date_serializer.dart';
import 'package:api/src/model/date.dart';

import 'package:api/src/model/accept_legal_document_dto.dart';
import 'package:api/src/model/add_cart_item_dto.dart';
import 'package:api/src/model/add_vendor_member_dto.dart';
import 'package:api/src/model/admin_assign_driver_dto.dart';
import 'package:api/src/model/admin_assign_shift_dto.dart';
import 'package:api/src/model/admin_book_weekly_shifts_dto.dart';
import 'package:api/src/model/admin_bulk_assign_shifts_dto.dart';
import 'package:api/src/model/admin_bulk_remove_shifts_dto.dart';
import 'package:api/src/model/admin_create_driver_dto.dart';
import 'package:api/src/model/admin_update_driver_dto.dart';
import 'package:api/src/model/admin_update_user_dto.dart';
import 'package:api/src/model/api_controller_root200_response.dart';
import 'package:api/src/model/api_response_dto.dart';
import 'package:api/src/model/app_version_check_dto.dart';
import 'package:api/src/model/assign_assist_driver_dto.dart';
import 'package:api/src/model/assign_drivers_to_manager_dto.dart';
import 'package:api/src/model/audit_action_type.dart';
import 'package:api/src/model/audit_log_response_dto.dart';
import 'package:api/src/model/audit_logs_controller_find_all200_response.dart';
import 'package:api/src/model/ban_user_dto.dart';
import 'package:api/src/model/book_overtime_shift_dto.dart';
import 'package:api/src/model/book_weekly_shifts_dto.dart';
import 'package:api/src/model/cancel_order_dto.dart';
import 'package:api/src/model/cart_item.dart';
import 'package:api/src/model/cart_item_option.dart';
import 'package:api/src/model/change_email_dto.dart';
import 'package:api/src/model/change_password_dto.dart';
import 'package:api/src/model/check_location_dto.dart';
import 'package:api/src/model/confirm_payment_dto.dart';
import 'package:api/src/model/create_address_dto.dart';
import 'package:api/src/model/create_direct_conversation_dto.dart';
import 'package:api/src/model/create_driver_shift_dto.dart';
import 'package:api/src/model/create_legal_document_dto.dart';
import 'package:api/src/model/create_menu_category_dto.dart';
import 'package:api/src/model/create_mobile_wallet_dto.dart';
import 'package:api/src/model/create_offer_dto.dart';
import 'package:api/src/model/create_option_group_dto.dart';
import 'package:api/src/model/create_order_conversation_dto.dart';
import 'package:api/src/model/create_product_dto.dart';
import 'package:api/src/model/create_product_option_dto.dart';
import 'package:api/src/model/create_product_variant_dto.dart';
import 'package:api/src/model/create_review_dto.dart';
import 'package:api/src/model/create_support_conversation_dto.dart';
import 'package:api/src/model/create_ticket_dto.dart';
import 'package:api/src/model/create_vendor_branch_dto.dart';
import 'package:api/src/model/create_vendor_conversation_dto.dart';
import 'package:api/src/model/create_vendor_dto.dart';
import 'package:api/src/model/create_vendor_vertical_dto.dart';
import 'package:api/src/model/create_wallet_top_up_dto.dart';
import 'package:api/src/model/create_zone_dto.dart';
import 'package:api/src/model/customer.dart';
import 'package:api/src/model/customer_decide_assist_dto.dart';
import 'package:api/src/model/customer_user_summary_dto.dart';
import 'package:api/src/model/decide_assist_request_dto.dart';
import 'package:api/src/model/delivery_group_rating_input_dto.dart';
import 'package:api/src/model/delivery_group_status.dart';
import 'package:api/src/model/delivery_incident_responsibility.dart';
import 'package:api/src/model/delivery_incident_type.dart';
import 'package:api/src/model/dispatch_announcement_dto.dart';
import 'package:api/src/model/dispatch_status.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/driver_break.dart';
import 'package:api/src/model/driver_break_reason.dart';
import 'package:api/src/model/driver_break_status.dart';
import 'package:api/src/model/driver_delivery_incident_dto.dart';
import 'package:api/src/model/driver_metrics_snapshot_dto.dart';
import 'package:api/src/model/driver_my_rank_summary_response_dto.dart';
import 'package:api/src/model/driver_rank_change_reason.dart';
import 'package:api/src/model/driver_rank_history_entry_dto.dart';
import 'package:api/src/model/driver_ranking_controller_get_driver_history200_response.dart';
import 'package:api/src/model/driver_ranking_controller_get_my_rank_summary200_response.dart';
import 'package:api/src/model/driver_ranking_controller_get_run_details200_response.dart';
import 'package:api/src/model/driver_ranking_controller_get_schedule_status200_response.dart';
import 'package:api/src/model/driver_ranking_controller_list_incidents200_response.dart';
import 'package:api/src/model/driver_ranking_controller_list_runs200_response.dart';
import 'package:api/src/model/driver_ranking_controller_override_driver_tier200_response.dart';
import 'package:api/src/model/driver_ranking_controller_preview_evaluation200_response.dart';
import 'package:api/src/model/driver_ranking_controller_review_incident200_response.dart';
import 'package:api/src/model/driver_ranking_controller_run_evaluation_now200_response.dart';
import 'package:api/src/model/driver_ranking_evaluation_run_dto.dart';
import 'package:api/src/model/driver_ranking_outcome.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:api/src/model/driver_ranking_preview_item_dto.dart';
import 'package:api/src/model/driver_ranking_preview_response_dto.dart';
import 'package:api/src/model/driver_ranking_run_details_response_dto.dart';
import 'package:api/src/model/driver_ranking_run_status.dart';
import 'package:api/src/model/driver_ranking_schedule_status_dto.dart';
import 'package:api/src/model/driver_ranking_trigger_source.dart';
import 'package:api/src/model/driver_shift.dart';
import 'package:api/src/model/driver_shift_response_dto.dart';
import 'package:api/src/model/driver_shift_status.dart';
import 'package:api/src/model/driver_shifts_controller_excuse_shift200_response.dart';
import 'package:api/src/model/driver_status.dart';
import 'package:api/src/model/driver_tier.dart';
import 'package:api/src/model/driver_wallet_balance_response_dto.dart';
import 'package:api/src/model/driver_wallet_transaction.dart';
import 'package:api/src/model/driver_wallet_transaction_response_dto.dart';
import 'package:api/src/model/driver_wallet_transactions_response_dto.dart';
import 'package:api/src/model/drivers_controller_get_my_breaks200_response.dart';
import 'package:api/src/model/drivers_controller_get_wallet_balance200_response.dart';
import 'package:api/src/model/drivers_controller_get_wallet_transactions200_response.dart';
import 'package:api/src/model/drivers_controller_my_assist_requests200_response.dart';
import 'package:api/src/model/drivers_controller_start_break200_response.dart';
import 'package:api/src/model/excluded_incidents_summary_dto.dart';
import 'package:api/src/model/excuse_driver_shift_dto.dart';
import 'package:api/src/model/favorite_product.dart';
import 'package:api/src/model/forgot_password_dto.dart';
import 'package:api/src/model/fulfillment_rating_input_dto.dart';
import 'package:api/src/model/generate_shift_pools_dto.dart';
import 'package:api/src/model/join_waitlist_dto.dart';
import 'package:api/src/model/language.dart';
import 'package:api/src/model/login_dto.dart';
import 'package:api/src/model/logout_dto.dart';
import 'package:api/src/model/mark_notifications_read_dto.dart';
import 'package:api/src/model/mark_read_dto.dart';
import 'package:api/src/model/menu_category.dart';
import 'package:api/src/model/mobile_wallet.dart';
import 'package:api/src/model/mobile_wallet_response_dto.dart';
import 'package:api/src/model/offer.dart';
import 'package:api/src/model/order.dart';
import 'package:api/src/model/order_actor_summary_dto.dart';
import 'package:api/src/model/order_cancelled_by_dto.dart';
import 'package:api/src/model/order_delivery_group.dart';
import 'package:api/src/model/order_delivery_group_item.dart';
import 'package:api/src/model/order_dispatch.dart';
import 'package:api/src/model/order_fee_estimate_dto.dart';
import 'package:api/src/model/order_item.dart';
import 'package:api/src/model/order_item_option.dart';
import 'package:api/src/model/order_response_dto.dart';
import 'package:api/src/model/order_review.dart';
import 'package:api/src/model/order_status.dart';
import 'package:api/src/model/order_status_event.dart';
import 'package:api/src/model/order_type.dart';
import 'package:api/src/model/order_vendor_fulfillment.dart';
import 'package:api/src/model/order_vendor_fulfillment_status.dart';
import 'package:api/src/model/orders_controller_estimate_custom_order200_response.dart';
import 'package:api/src/model/orders_controller_place_order200_response.dart';
import 'package:api/src/model/override_driver_rank_dto.dart';
import 'package:api/src/model/paginated_delivery_incidents_response_dto.dart';
import 'package:api/src/model/paginated_driver_rank_history_response_dto.dart';
import 'package:api/src/model/paginated_ranking_runs_response_dto.dart';
import 'package:api/src/model/paginated_reviews_response_dto.dart';
import 'package:api/src/model/pagination_meta_dto.dart';
import 'package:api/src/model/payment_method.dart';
import 'package:api/src/model/payment_status.dart';
import 'package:api/src/model/permission.dart';
import 'package:api/src/model/place_custom_order_dto.dart';
import 'package:api/src/model/place_direct_order_dto.dart';
import 'package:api/src/model/place_multi_vendor_order_dto.dart';
import 'package:api/src/model/place_order_dto.dart';
import 'package:api/src/model/process_manual_transaction_dto.dart';
import 'package:api/src/model/product.dart';
import 'package:api/src/model/product_branch_availability.dart';
import 'package:api/src/model/product_option.dart';
import 'package:api/src/model/product_option_group.dart';
import 'package:api/src/model/product_option_group_response_dto.dart';
import 'package:api/src/model/product_option_response_dto.dart';
import 'package:api/src/model/product_response_dto.dart';
import 'package:api/src/model/product_variant.dart';
import 'package:api/src/model/product_variant_response_dto.dart';
import 'package:api/src/model/products_controller_create200_response.dart';
import 'package:api/src/model/products_controller_update_option200_response.dart';
import 'package:api/src/model/products_controller_update_option_group200_response.dart';
import 'package:api/src/model/products_controller_update_variant200_response.dart';
import 'package:api/src/model/promotion.dart';
import 'package:api/src/model/promotion_type.dart';
import 'package:api/src/model/ranking_week_window_dto.dart';
import 'package:api/src/model/register_device_dto.dart';
import 'package:api/src/model/register_driver_dto.dart';
import 'package:api/src/model/register_dto.dart';
import 'package:api/src/model/reject_vendor_fulfillment_dto.dart';
import 'package:api/src/model/reorder_categories_dto.dart';
import 'package:api/src/model/request_assist_driver_dto.dart';
import 'package:api/src/model/reset_password_dto.dart';
import 'package:api/src/model/respond_assist_offer_dto.dart';
import 'package:api/src/model/respond_to_dispatch_dto.dart';
import 'package:api/src/model/review_customer_dto.dart';
import 'package:api/src/model/review_customer_user_dto.dart';
import 'package:api/src/model/review_dto.dart';
import 'package:api/src/model/review_target_type.dart';
import 'package:api/src/model/review_wallet_top_up_dto.dart';
import 'package:api/src/model/reviews_controller_get_vendor_reviews200_response.dart';
import 'package:api/src/model/role.dart';
import 'package:api/src/model/search_customers_in_polygon_dto.dart';
import 'package:api/src/model/send_message_dto.dart';
import 'package:api/src/model/send_otp_dto.dart';
import 'package:api/src/model/session.dart';
import 'package:api/src/model/set_password_dto.dart';
import 'package:api/src/model/shift_pool.dart';
import 'package:api/src/model/shift_swap_request.dart';
import 'package:api/src/model/social_login_dto.dart';
import 'package:api/src/model/start_break_dto.dart';
import 'package:api/src/model/support_ticket.dart';
import 'package:api/src/model/swap_request_status.dart';
import 'package:api/src/model/ticket_category.dart';
import 'package:api/src/model/ticket_priority.dart';
import 'package:api/src/model/ticket_status.dart';
import 'package:api/src/model/top_up_status.dart';
import 'package:api/src/model/unassign_drivers_from_manager_dto.dart';
import 'package:api/src/model/update_address_dto.dart';
import 'package:api/src/model/update_cart_item_dto.dart';
import 'package:api/src/model/update_delivery_incident_dto.dart';
import 'package:api/src/model/update_driver_profile_dto.dart';
import 'package:api/src/model/update_driver_status_dto.dart';
import 'package:api/src/model/update_legal_document_dto.dart';
import 'package:api/src/model/update_menu_category_dto.dart';
import 'package:api/src/model/update_notification_settings_dto.dart';
import 'package:api/src/model/update_offer_dto.dart';
import 'package:api/src/model/update_option_group_dto.dart';
import 'package:api/src/model/update_order_status_dto.dart';
import 'package:api/src/model/update_platform_settings_dto.dart';
import 'package:api/src/model/update_product_dto.dart';
import 'package:api/src/model/update_product_option_dto.dart';
import 'package:api/src/model/update_product_variant_dto.dart';
import 'package:api/src/model/update_promotion_dto.dart';
import 'package:api/src/model/update_ticket_dto.dart';
import 'package:api/src/model/update_user_dto.dart';
import 'package:api/src/model/update_vendor_branch_dto.dart';
import 'package:api/src/model/update_vendor_dto.dart';
import 'package:api/src/model/update_vendor_member_role_dto.dart';
import 'package:api/src/model/update_vendor_status_dto.dart';
import 'package:api/src/model/update_vendor_vertical_dto.dart';
import 'package:api/src/model/update_zone_dto.dart';
import 'package:api/src/model/user.dart';
import 'package:api/src/model/vehicle_type.dart';
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:api/src/model/vendor_status.dart';
import 'package:api/src/model/vendor_transaction_type.dart';
import 'package:api/src/model/vendor_wallet_transaction.dart';
import 'package:api/src/model/vendor_wallet_transaction_response_dto.dart';
import 'package:api/src/model/verify_otp_dto.dart';
import 'package:api/src/model/wallet_controller_get_active_platform_wallets200_response.dart';
import 'package:api/src/model/wallet_controller_get_my_driver_transactions200_response.dart';
import 'package:api/src/model/wallet_controller_get_pending_top_ups200_response.dart';
import 'package:api/src/model/wallet_controller_process_driver_transaction200_response.dart';
import 'package:api/src/model/wallet_controller_process_vendor_transaction200_response.dart';
import 'package:api/src/model/wallet_top_up_request.dart';
import 'package:api/src/model/wallet_top_up_request_response_dto.dart';
import 'package:api/src/model/wallet_transaction_type.dart';
import 'package:api/src/model/wallet_type.dart';
import 'package:api/src/model/zone.dart';

part 'serializers.g.dart';

@SerializersFor([
  AcceptLegalDocumentDto,
  AddCartItemDto,
  AddVendorMemberDto,
  AdminAssignDriverDto,
  AdminAssignShiftDto,
  AdminBookWeeklyShiftsDto,
  AdminBulkAssignShiftsDto,
  AdminBulkRemoveShiftsDto,
  AdminCreateDriverDto,
  AdminUpdateDriverDto,
  AdminUpdateUserDto,
  ApiControllerRoot200Response,
  ApiResponseDto,$ApiResponseDto,
  AppVersionCheckDto,
  AssignAssistDriverDto,
  AssignDriversToManagerDto,
  AuditActionType,
  AuditLogResponseDto,
  AuditLogsControllerFindAll200Response,
  BanUserDto,
  BookOvertimeShiftDto,
  BookWeeklyShiftsDto,
  CancelOrderDto,
  CartItem,
  CartItemOption,
  ChangeEmailDto,
  ChangePasswordDto,
  CheckLocationDto,
  ConfirmPaymentDto,
  CreateAddressDto,
  CreateDirectConversationDto,
  CreateDriverShiftDto,
  CreateLegalDocumentDto,
  CreateMenuCategoryDto,
  CreateMobileWalletDto,
  CreateOfferDto,
  CreateOptionGroupDto,
  CreateOrderConversationDto,
  CreateProductDto,
  CreateProductOptionDto,
  CreateProductVariantDto,
  CreateReviewDto,
  CreateSupportConversationDto,
  CreateTicketDto,
  CreateVendorBranchDto,
  CreateVendorConversationDto,
  CreateVendorDto,
  CreateVendorVerticalDto,
  CreateWalletTopUpDto,
  CreateZoneDto,
  Customer,
  CustomerDecideAssistDto,
  CustomerUserSummaryDto,
  DecideAssistRequestDto,
  DeliveryGroupRatingInputDto,
  DeliveryGroupStatus,
  DeliveryIncidentResponsibility,
  DeliveryIncidentType,
  DispatchAnnouncementDto,
  DispatchStatus,
  Driver,
  DriverBreak,
  DriverBreakReason,
  DriverBreakStatus,
  DriverDeliveryIncidentDto,
  DriverMetricsSnapshotDto,
  DriverMyRankSummaryResponseDto,
  DriverRankChangeReason,
  DriverRankHistoryEntryDto,
  DriverRankingControllerGetDriverHistory200Response,
  DriverRankingControllerGetMyRankSummary200Response,
  DriverRankingControllerGetRunDetails200Response,
  DriverRankingControllerGetScheduleStatus200Response,
  DriverRankingControllerListIncidents200Response,
  DriverRankingControllerListRuns200Response,
  DriverRankingControllerOverrideDriverTier200Response,
  DriverRankingControllerPreviewEvaluation200Response,
  DriverRankingControllerReviewIncident200Response,
  DriverRankingControllerRunEvaluationNow200Response,
  DriverRankingEvaluationRunDto,
  DriverRankingOutcome,
  DriverRankingPaginationMetaDto,
  DriverRankingPreviewItemDto,
  DriverRankingPreviewResponseDto,
  DriverRankingRunDetailsResponseDto,
  DriverRankingRunStatus,
  DriverRankingScheduleStatusDto,
  DriverRankingTriggerSource,
  DriverShift,
  DriverShiftResponseDto,
  DriverShiftStatus,
  DriverShiftsControllerExcuseShift200Response,
  DriverStatus,
  DriverTier,
  DriverWalletBalanceResponseDto,
  DriverWalletTransaction,
  DriverWalletTransactionResponseDto,
  DriverWalletTransactionsResponseDto,
  DriversControllerGetMyBreaks200Response,
  DriversControllerGetWalletBalance200Response,
  DriversControllerGetWalletTransactions200Response,
  DriversControllerMyAssistRequests200Response,
  DriversControllerStartBreak200Response,
  ExcludedIncidentsSummaryDto,
  ExcuseDriverShiftDto,
  FavoriteProduct,
  ForgotPasswordDto,
  FulfillmentRatingInputDto,
  GenerateShiftPoolsDto,
  JoinWaitlistDto,
  Language,
  LoginDto,
  LogoutDto,
  MarkNotificationsReadDto,
  MarkReadDto,
  MenuCategory,
  MobileWallet,
  MobileWalletResponseDto,
  Offer,
  Order,
  OrderActorSummaryDto,
  OrderCancelledByDto,
  OrderDeliveryGroup,
  OrderDeliveryGroupItem,
  OrderDispatch,
  OrderFeeEstimateDto,
  OrderItem,
  OrderItemOption,
  OrderResponseDto,
  OrderReview,
  OrderStatus,
  OrderStatusEvent,
  OrderType,
  OrderVendorFulfillment,
  OrderVendorFulfillmentStatus,
  OrdersControllerEstimateCustomOrder200Response,
  OrdersControllerPlaceOrder200Response,
  OverrideDriverRankDto,
  PaginatedDeliveryIncidentsResponseDto,
  PaginatedDriverRankHistoryResponseDto,
  PaginatedRankingRunsResponseDto,
  PaginatedReviewsResponseDto,
  PaginationMetaDto,
  PaymentMethod,
  PaymentStatus,
  Permission,
  PlaceCustomOrderDto,
  PlaceDirectOrderDto,
  PlaceMultiVendorOrderDto,
  PlaceOrderDto,
  ProcessManualTransactionDto,
  Product,
  ProductBranchAvailability,
  ProductOption,
  ProductOptionGroup,
  ProductOptionGroupResponseDto,
  ProductOptionResponseDto,
  ProductResponseDto,
  ProductVariant,
  ProductVariantResponseDto,
  ProductsControllerCreate200Response,
  ProductsControllerUpdateOption200Response,
  ProductsControllerUpdateOptionGroup200Response,
  ProductsControllerUpdateVariant200Response,
  Promotion,
  PromotionType,
  RankingWeekWindowDto,
  RegisterDeviceDto,
  RegisterDriverDto,
  RegisterDto,
  RejectVendorFulfillmentDto,
  ReorderCategoriesDto,
  RequestAssistDriverDto,
  ResetPasswordDto,
  RespondAssistOfferDto,
  RespondToDispatchDto,
  ReviewCustomerDto,
  ReviewCustomerUserDto,
  ReviewDto,
  ReviewTargetType,
  ReviewWalletTopUpDto,
  ReviewsControllerGetVendorReviews200Response,
  Role,
  SearchCustomersInPolygonDto,
  SendMessageDto,
  SendOtpDto,
  Session,
  SetPasswordDto,
  ShiftPool,
  ShiftSwapRequest,
  SocialLoginDto,
  StartBreakDto,
  SupportTicket,
  SwapRequestStatus,
  TicketCategory,
  TicketPriority,
  TicketStatus,
  TopUpStatus,
  UnassignDriversFromManagerDto,
  UpdateAddressDto,
  UpdateCartItemDto,
  UpdateDeliveryIncidentDto,
  UpdateDriverProfileDto,
  UpdateDriverStatusDto,
  UpdateLegalDocumentDto,
  UpdateMenuCategoryDto,
  UpdateNotificationSettingsDto,
  UpdateOfferDto,
  UpdateOptionGroupDto,
  UpdateOrderStatusDto,
  UpdatePlatformSettingsDto,
  UpdateProductDto,
  UpdateProductOptionDto,
  UpdateProductVariantDto,
  UpdatePromotionDto,
  UpdateTicketDto,
  UpdateUserDto,
  UpdateVendorBranchDto,
  UpdateVendorDto,
  UpdateVendorMemberRoleDto,
  UpdateVendorStatusDto,
  UpdateVendorVerticalDto,
  UpdateZoneDto,
  User,
  VehicleType,
  Vendor,
  VendorBranch,
  VendorStatus,
  VendorTransactionType,
  VendorWalletTransaction,
  VendorWalletTransactionResponseDto,
  VerifyOtpDto,
  WalletControllerGetActivePlatformWallets200Response,
  WalletControllerGetMyDriverTransactions200Response,
  WalletControllerGetPendingTopUps200Response,
  WalletControllerProcessDriverTransaction200Response,
  WalletControllerProcessVendorTransaction200Response,
  WalletTopUpRequest,
  WalletTopUpRequestResponseDto,
  WalletTransactionType,
  WalletType,
  Zone,
])
Serializers serializers = (_$serializers.toBuilder()
      ..add(ApiResponseDto.serializer)
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
