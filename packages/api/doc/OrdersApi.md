# api.api.OrdersApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**ordersControllerAcceptFulfillment**](OrdersApi.md#orderscontrolleracceptfulfillment) | **PATCH** /orders/vendor-decisions/{fulfillmentId}/accept | [Vendor] Accept ONLY my portion — other vendors are unaffected
[**ordersControllerAdminFindAll**](OrdersApi.md#orderscontrolleradminfindall) | **GET** /orders | [Admin] List all orders with filters
[**ordersControllerAdminForceAssignDriver**](OrdersApi.md#orderscontrolleradminforceassigndriver) | **POST** /orders/{orderId}/assign-driver | [Admin] Force-assign a driver to an order
[**ordersControllerAdminPlaceDirectOrder**](OrdersApi.md#orderscontrolleradminplacedirectorder) | **POST** /orders/admin/direct | [Admin/Vendor] Create a pending order directly for a customer
[**ordersControllerCancelOrder**](OrdersApi.md#orderscontrollercancelorder) | **POST** /orders/{orderId}/cancel | Cancel an order (customer or vendor)
[**ordersControllerCustomerMarkPaid**](OrdersApi.md#orderscontrollercustomermarkpaid) | **POST** /orders/customer/{orderId}/payment/mark-paid | Customer marks mobile wallet payment as paid with receipt
[**ordersControllerDecideAssist**](OrdersApi.md#orderscontrollerdecideassist) | **POST** /orders/{orderId}/delivery-groups/{deliveryGroupId}/assist/decision | [Customer] Approve or decline an assisted delivery (and its fee)
[**ordersControllerDecideAssistOrder**](OrdersApi.md#orderscontrollerdecideassistorder) | **POST** /orders/{orderId}/assist/decision | [Customer] Approve or decline an assisted delivery (single-vendor order)
[**ordersControllerDriverConfirmDelivery**](OrdersApi.md#orderscontrollerdriverconfirmdelivery) | **POST** /orders/driver/{orderId}/delivery | Driver confirms delivery with a photo of the order (PICKED_UP to DELIVERED)
[**ordersControllerDriverConfirmFulfillmentPickup**](OrdersApi.md#orderscontrollerdriverconfirmfulfillmentpickup) | **POST** /orders/driver/{orderId}/fulfillment/{fulfillmentId}/pickup | Driver confirms pickup for a specific vendor fulfillment stop with photo
[**ordersControllerDriverConfirmPayment**](OrdersApi.md#orderscontrollerdriverconfirmpayment) | **POST** /orders/driver/{orderId}/payment/confirm | Driver confirms or denies receiving mobile wallet payment
[**ordersControllerDriverConfirmPickup**](OrdersApi.md#orderscontrollerdriverconfirmpickup) | **POST** /orders/driver/{orderId}/pickup | Driver confirms pickup with a photo of the order (STAGE to READY_FOR_PICKUP / CUSTOM_DELIVERY)
[**ordersControllerDriverUpdateStatus**](OrdersApi.md#orderscontrollerdriverupdatestatus) | **PATCH** /orders/driver/{orderId}/status | Driver updates order status (PICKED_UP / DELIVERED)
[**ordersControllerEstimateCustomOrder**](OrdersApi.md#orderscontrollerestimatecustomorder) | **POST** /orders/custom-fee-estimate | Estimate custom delivery/ride fare before placing (fee is fixed to pickup→dropoff distance)
[**ordersControllerEstimateMultiVendor**](OrdersApi.md#orderscontrollerestimatemultivendor) | **POST** /orders/multi-vendor/fee-estimate | Estimate a multi-vendor checkout, including the per-delivery fee breakdown and whether it splits
[**ordersControllerEstimateOrder**](OrdersApi.md#orderscontrollerestimateorder) | **POST** /orders/fee-estimate | Estimate delivery fee and order total before placing (fee is fixed to vendor→customer distance)
[**ordersControllerGetMyDispatches**](OrdersApi.md#orderscontrollergetmydispatches) | **GET** /orders/driver/dispatches | Get my pending dispatch requests
[**ordersControllerGetMyOrdersAsCustomer**](OrdersApi.md#orderscontrollergetmyordersascustomer) | **GET** /orders/my | Get my order history (customer)
[**ordersControllerGetMyOrdersAsDriver**](OrdersApi.md#orderscontrollergetmyordersasdriver) | **GET** /orders/driver/my | Get my orders as driver
[**ordersControllerGetOne**](OrdersApi.md#orderscontrollergetone) | **GET** /orders/{orderId} | Get a single order (customer/driver/vendor/admin)
[**ordersControllerGetVendorOrders**](OrdersApi.md#orderscontrollergetvendororders) | **GET** /orders/vendor/{vendorId} | Get orders for a vendor (vendor member or admin)
[**ordersControllerListOrderDecisions**](OrdersApi.md#orderscontrollerlistorderdecisions) | **GET** /orders/vendor-decisions/order/{orderId} | [Admin] Vendor portions and their states for an order
[**ordersControllerListVendorDecisions**](OrdersApi.md#orderscontrollerlistvendordecisions) | **GET** /orders/vendor-decisions/vendor/{vendorId} | [Vendor] All my portions for one vendor
[**ordersControllerMyPendingDecisions**](OrdersApi.md#orderscontrollermypendingdecisions) | **GET** /orders/vendor-decisions/pending | [Vendor] My vendor portions awaiting my accept/reject decision
[**ordersControllerPlaceCustomOrder**](OrdersApi.md#orderscontrollerplacecustomorder) | **POST** /orders/custom | Place a custom delivery or ride order
[**ordersControllerPlaceMultiVendorOrder**](OrdersApi.md#orderscontrollerplacemultivendororder) | **POST** /orders/multi-vendor | Place one order containing multiple vendors, grouped into deliveries
[**ordersControllerPlaceOrder**](OrdersApi.md#orderscontrollerplaceorder) | **POST** /orders | Place a new order from active cart
[**ordersControllerRejectFulfillment**](OrdersApi.md#orderscontrollerrejectfulfillment) | **PATCH** /orders/vendor-decisions/{fulfillmentId}/reject | [Vendor] Reject only my portion with an auditable reason; the customer is notified and the totals are adjusted
[**ordersControllerRespondToDispatch**](OrdersApi.md#orderscontrollerrespondtodispatch) | **POST** /orders/driver/dispatches/{dispatchId}/respond | Accept or reject a dispatch request
[**ordersControllerVendorUpdateStatus**](OrdersApi.md#orderscontrollervendorupdatestatus) | **PATCH** /orders/vendor/{orderId}/status | Vendor updates order status


# **ordersControllerAcceptFulfillment**
> ApiControllerRoot200Response ordersControllerAcceptFulfillment(fulfillmentId)

[Vendor] Accept ONLY my portion — other vendors are unaffected

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String fulfillmentId = fulfillmentId_example; // String | 

try {
    final response = api.ordersControllerAcceptFulfillment(fulfillmentId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAcceptFulfillment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **fulfillmentId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerAdminFindAll**
> ApiControllerRoot200Response ordersControllerAdminFindAll(status, vendorId, driverId, customerId, page, limit)

[Admin] List all orders with filters

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String status = status_example; // String | 
final String vendorId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String driverId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String customerId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.ordersControllerAdminFindAll(status, vendorId, driverId, customerId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **vendorId** | **String**|  | [optional] 
 **driverId** | **String**|  | [optional] 
 **customerId** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerAdminForceAssignDriver**
> OrdersControllerPlaceOrder200Response ordersControllerAdminForceAssignDriver(orderId, adminAssignDriverDto)

[Admin] Force-assign a driver to an order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final AdminAssignDriverDto adminAssignDriverDto = ; // AdminAssignDriverDto | 

try {
    final response = api.ordersControllerAdminForceAssignDriver(orderId, adminAssignDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAdminForceAssignDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **adminAssignDriverDto** | [**AdminAssignDriverDto**](AdminAssignDriverDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerAdminPlaceDirectOrder**
> OrdersControllerPlaceOrder200Response ordersControllerAdminPlaceDirectOrder(idempotencyKey, placeDirectOrderDto)

[Admin/Vendor] Create a pending order directly for a customer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final PlaceDirectOrderDto placeDirectOrderDto = ; // PlaceDirectOrderDto | 

try {
    final response = api.ordersControllerAdminPlaceDirectOrder(idempotencyKey, placeDirectOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAdminPlaceDirectOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **placeDirectOrderDto** | [**PlaceDirectOrderDto**](PlaceDirectOrderDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerCancelOrder**
> OrdersControllerPlaceOrder200Response ordersControllerCancelOrder(orderId)

Cancel an order (customer or vendor)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.ordersControllerCancelOrder(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerCancelOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerCustomerMarkPaid**
> OrdersControllerPlaceOrder200Response ordersControllerCustomerMarkPaid(orderId, file)

Customer marks mobile wallet payment as paid with receipt

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.ordersControllerCustomerMarkPaid(orderId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerCustomerMarkPaid: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDecideAssist**
> ApiControllerRoot200Response ordersControllerDecideAssist(orderId, deliveryGroupId)

[Customer] Approve or decline an assisted delivery (and its fee)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final String deliveryGroupId = deliveryGroupId_example; // String | 

try {
    final response = api.ordersControllerDecideAssist(orderId, deliveryGroupId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDecideAssist: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **deliveryGroupId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDecideAssistOrder**
> ApiControllerRoot200Response ordersControllerDecideAssistOrder(orderId)

[Customer] Approve or decline an assisted delivery (single-vendor order)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.ordersControllerDecideAssistOrder(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDecideAssistOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDriverConfirmDelivery**
> ApiControllerRoot200Response ordersControllerDriverConfirmDelivery(orderId, deliveryGroupId, file)

Driver confirms delivery with a photo of the order (PICKED_UP to DELIVERED)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final String deliveryGroupId = deliveryGroupId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.ordersControllerDriverConfirmDelivery(orderId, deliveryGroupId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDriverConfirmDelivery: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **deliveryGroupId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDriverConfirmFulfillmentPickup**
> ApiControllerRoot200Response ordersControllerDriverConfirmFulfillmentPickup(orderId, fulfillmentId, file)

Driver confirms pickup for a specific vendor fulfillment stop with photo

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final String fulfillmentId = fulfillmentId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.ordersControllerDriverConfirmFulfillmentPickup(orderId, fulfillmentId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDriverConfirmFulfillmentPickup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **fulfillmentId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDriverConfirmPayment**
> OrdersControllerPlaceOrder200Response ordersControllerDriverConfirmPayment(orderId, confirmPaymentDto)

Driver confirms or denies receiving mobile wallet payment

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final ConfirmPaymentDto confirmPaymentDto = ; // ConfirmPaymentDto | 

try {
    final response = api.ordersControllerDriverConfirmPayment(orderId, confirmPaymentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDriverConfirmPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **confirmPaymentDto** | [**ConfirmPaymentDto**](ConfirmPaymentDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDriverConfirmPickup**
> ApiControllerRoot200Response ordersControllerDriverConfirmPickup(orderId, fulfillmentId, file)

Driver confirms pickup with a photo of the order (STAGE to READY_FOR_PICKUP / CUSTOM_DELIVERY)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final String fulfillmentId = fulfillmentId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.ordersControllerDriverConfirmPickup(orderId, fulfillmentId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDriverConfirmPickup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **fulfillmentId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerDriverUpdateStatus**
> ApiControllerRoot200Response ordersControllerDriverUpdateStatus(orderId, updateOrderStatusDto)

Driver updates order status (PICKED_UP / DELIVERED)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final UpdateOrderStatusDto updateOrderStatusDto = ; // UpdateOrderStatusDto | 

try {
    final response = api.ordersControllerDriverUpdateStatus(orderId, updateOrderStatusDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerDriverUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **updateOrderStatusDto** | [**UpdateOrderStatusDto**](UpdateOrderStatusDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerEstimateCustomOrder**
> OrdersControllerEstimateCustomOrder200Response ordersControllerEstimateCustomOrder(placeCustomOrderDto)

Estimate custom delivery/ride fare before placing (fee is fixed to pickup→dropoff distance)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceCustomOrderDto placeCustomOrderDto = ; // PlaceCustomOrderDto | 

try {
    final response = api.ordersControllerEstimateCustomOrder(placeCustomOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerEstimateCustomOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placeCustomOrderDto** | [**PlaceCustomOrderDto**](PlaceCustomOrderDto.md)|  | 

### Return type

[**OrdersControllerEstimateCustomOrder200Response**](OrdersControllerEstimateCustomOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerEstimateMultiVendor**
> ApiControllerRoot200Response ordersControllerEstimateMultiVendor(placeMultiVendorOrderDto)

Estimate a multi-vendor checkout, including the per-delivery fee breakdown and whether it splits

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceMultiVendorOrderDto placeMultiVendorOrderDto = ; // PlaceMultiVendorOrderDto | 

try {
    final response = api.ordersControllerEstimateMultiVendor(placeMultiVendorOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerEstimateMultiVendor: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placeMultiVendorOrderDto** | [**PlaceMultiVendorOrderDto**](PlaceMultiVendorOrderDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerEstimateOrder**
> OrdersControllerEstimateCustomOrder200Response ordersControllerEstimateOrder(placeOrderDto)

Estimate delivery fee and order total before placing (fee is fixed to vendor→customer distance)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceOrderDto placeOrderDto = ; // PlaceOrderDto | 

try {
    final response = api.ordersControllerEstimateOrder(placeOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerEstimateOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placeOrderDto** | [**PlaceOrderDto**](PlaceOrderDto.md)|  | 

### Return type

[**OrdersControllerEstimateCustomOrder200Response**](OrdersControllerEstimateCustomOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerGetMyDispatches**
> ApiControllerRoot200Response ordersControllerGetMyDispatches()

Get my pending dispatch requests

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();

try {
    final response = api.ordersControllerGetMyDispatches();
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerGetMyDispatches: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerGetMyOrdersAsCustomer**
> ApiControllerRoot200Response ordersControllerGetMyOrdersAsCustomer(status, vendorId, driverId, customerId, page, limit)

Get my order history (customer)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String status = status_example; // String | 
final String vendorId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String driverId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String customerId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.ordersControllerGetMyOrdersAsCustomer(status, vendorId, driverId, customerId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerGetMyOrdersAsCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **vendorId** | **String**|  | [optional] 
 **driverId** | **String**|  | [optional] 
 **customerId** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerGetMyOrdersAsDriver**
> ApiControllerRoot200Response ordersControllerGetMyOrdersAsDriver(status, vendorId, driverId, customerId, page, limit)

Get my orders as driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String status = status_example; // String | 
final String vendorId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String driverId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String customerId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.ordersControllerGetMyOrdersAsDriver(status, vendorId, driverId, customerId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerGetMyOrdersAsDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **vendorId** | **String**|  | [optional] 
 **driverId** | **String**|  | [optional] 
 **customerId** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerGetOne**
> OrdersControllerPlaceOrder200Response ordersControllerGetOne(orderId)

Get a single order (customer/driver/vendor/admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.ordersControllerGetOne(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerGetOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerGetVendorOrders**
> ApiControllerRoot200Response ordersControllerGetVendorOrders(vendorId, status, vendorId2, driverId, customerId, page, limit)

Get orders for a vendor (vendor member or admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String vendorId = vendorId_example; // String | 
final String status = status_example; // String | 
final String vendorId2 = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String driverId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final String customerId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.ordersControllerGetVendorOrders(vendorId, status, vendorId2, driverId, customerId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerGetVendorOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **status** | **String**|  | [optional] 
 **vendorId2** | **String**|  | [optional] 
 **driverId** | **String**|  | [optional] 
 **customerId** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerListOrderDecisions**
> DriversControllerMyAssistRequests200Response ordersControllerListOrderDecisions(orderId)

[Admin] Vendor portions and their states for an order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.ordersControllerListOrderDecisions(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerListOrderDecisions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerListVendorDecisions**
> DriversControllerMyAssistRequests200Response ordersControllerListVendorDecisions(vendorId)

[Vendor] All my portions for one vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.ordersControllerListVendorDecisions(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerListVendorDecisions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerMyPendingDecisions**
> DriversControllerMyAssistRequests200Response ordersControllerMyPendingDecisions()

[Vendor] My vendor portions awaiting my accept/reject decision

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();

try {
    final response = api.ordersControllerMyPendingDecisions();
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerMyPendingDecisions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerMyAssistRequests200Response**](DriversControllerMyAssistRequests200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerPlaceCustomOrder**
> OrdersControllerPlaceOrder200Response ordersControllerPlaceCustomOrder(idempotencyKey, placeCustomOrderDto)

Place a custom delivery or ride order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final PlaceCustomOrderDto placeCustomOrderDto = ; // PlaceCustomOrderDto | 

try {
    final response = api.ordersControllerPlaceCustomOrder(idempotencyKey, placeCustomOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerPlaceCustomOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **placeCustomOrderDto** | [**PlaceCustomOrderDto**](PlaceCustomOrderDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerPlaceMultiVendorOrder**
> ApiControllerRoot200Response ordersControllerPlaceMultiVendorOrder(idempotencyKey, placeMultiVendorOrderDto)

Place one order containing multiple vendors, grouped into deliveries

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final PlaceMultiVendorOrderDto placeMultiVendorOrderDto = ; // PlaceMultiVendorOrderDto | 

try {
    final response = api.ordersControllerPlaceMultiVendorOrder(idempotencyKey, placeMultiVendorOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerPlaceMultiVendorOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **placeMultiVendorOrderDto** | [**PlaceMultiVendorOrderDto**](PlaceMultiVendorOrderDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerPlaceOrder**
> OrdersControllerPlaceOrder200Response ordersControllerPlaceOrder(idempotencyKey, placeOrderDto)

Place a new order from active cart

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final PlaceOrderDto placeOrderDto = ; // PlaceOrderDto | 

try {
    final response = api.ordersControllerPlaceOrder(idempotencyKey, placeOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerPlaceOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **placeOrderDto** | [**PlaceOrderDto**](PlaceOrderDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerRejectFulfillment**
> ApiControllerRoot200Response ordersControllerRejectFulfillment(fulfillmentId, rejectVendorFulfillmentDto)

[Vendor] Reject only my portion with an auditable reason; the customer is notified and the totals are adjusted

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String fulfillmentId = fulfillmentId_example; // String | 
final RejectVendorFulfillmentDto rejectVendorFulfillmentDto = ; // RejectVendorFulfillmentDto | 

try {
    final response = api.ordersControllerRejectFulfillment(fulfillmentId, rejectVendorFulfillmentDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerRejectFulfillment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **fulfillmentId** | **String**|  | 
 **rejectVendorFulfillmentDto** | [**RejectVendorFulfillmentDto**](RejectVendorFulfillmentDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerRespondToDispatch**
> ApiControllerRoot200Response ordersControllerRespondToDispatch(dispatchId, respondToDispatchDto)

Accept or reject a dispatch request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String dispatchId = dispatchId_example; // String | 
final RespondToDispatchDto respondToDispatchDto = ; // RespondToDispatchDto | 

try {
    final response = api.ordersControllerRespondToDispatch(dispatchId, respondToDispatchDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerRespondToDispatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **String**|  | 
 **respondToDispatchDto** | [**RespondToDispatchDto**](RespondToDispatchDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerVendorUpdateStatus**
> ApiControllerRoot200Response ordersControllerVendorUpdateStatus(orderId, updateOrderStatusDto)

Vendor updates order status

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 
final UpdateOrderStatusDto updateOrderStatusDto = ; // UpdateOrderStatusDto | 

try {
    final response = api.ordersControllerVendorUpdateStatus(orderId, updateOrderStatusDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerVendorUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **updateOrderStatusDto** | [**UpdateOrderStatusDto**](UpdateOrderStatusDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

