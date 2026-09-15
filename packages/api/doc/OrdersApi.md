# api.api.OrdersApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**ordersControllerAcceptOrderChanges**](OrdersApi.md#orderscontrolleracceptorderchanges) | **POST** /orders/{id}/accept-changes | 
[**ordersControllerAdminFindAll**](OrdersApi.md#orderscontrolleradminfindall) | **GET** /orders | [Admin] List all orders with filters
[**ordersControllerAdminForceAssignDriver**](OrdersApi.md#orderscontrolleradminforceassigndriver) | **POST** /orders/{orderId}/assign-driver | [Admin] Force-assign a driver to an order
[**ordersControllerAdminPlaceDirectOrder**](OrdersApi.md#orderscontrolleradminplacedirectorder) | **POST** /orders/admin/direct | [Admin/Vendor] Create a pending order directly for a customer
[**ordersControllerCancelOrder**](OrdersApi.md#orderscontrollercancelorder) | **POST** /orders/{orderId}/cancel | Cancel an order (customer or vendor)
[**ordersControllerCustomerMarkPaid**](OrdersApi.md#orderscontrollercustomermarkpaid) | **POST** /orders/customer/{orderId}/payment/mark-paid | Customer marks mobile wallet payment as paid
[**ordersControllerDriverConfirmPayment**](OrdersApi.md#orderscontrollerdriverconfirmpayment) | **POST** /orders/driver/{orderId}/payment/confirm | Driver confirms or denies receiving mobile wallet payment
[**ordersControllerDriverUpdateStatus**](OrdersApi.md#orderscontrollerdriverupdatestatus) | **PATCH** /orders/driver/{orderId}/status | Driver updates order status (PICKED_UP / DELIVERED)
[**ordersControllerEditOrderItems**](OrdersApi.md#orderscontrollereditorderitems) | **PATCH** /orders/{id}/items | 
[**ordersControllerEstimateCustomOrder**](OrdersApi.md#orderscontrollerestimatecustomorder) | **POST** /orders/custom-fee-estimate | Estimate custom delivery/ride fare before placing (fee is fixed to pickup→dropoff distance)
[**ordersControllerEstimateOrder**](OrdersApi.md#orderscontrollerestimateorder) | **POST** /orders/fee-estimate | Estimate delivery fee and order total before placing (fee is fixed to vendor→customer distance)
[**ordersControllerGetMyDispatches**](OrdersApi.md#orderscontrollergetmydispatches) | **GET** /orders/driver/dispatches | Get my pending dispatch requests
[**ordersControllerGetMyOrdersAsCustomer**](OrdersApi.md#orderscontrollergetmyordersascustomer) | **GET** /orders/my | Get my order history (customer)
[**ordersControllerGetMyOrdersAsDriver**](OrdersApi.md#orderscontrollergetmyordersasdriver) | **GET** /orders/driver/my | Get my orders as driver
[**ordersControllerGetOne**](OrdersApi.md#orderscontrollergetone) | **GET** /orders/{orderId} | Get a single order (customer/driver/vendor/admin)
[**ordersControllerGetVendorOrders**](OrdersApi.md#orderscontrollergetvendororders) | **GET** /orders/vendor/{vendorId} | Get orders for a vendor (vendor member or admin)
[**ordersControllerPlaceCustomOrder**](OrdersApi.md#orderscontrollerplacecustomorder) | **POST** /orders/custom | Place a custom delivery or ride order
[**ordersControllerPlaceOrder**](OrdersApi.md#orderscontrollerplaceorder) | **POST** /orders | Place a new order from active cart
[**ordersControllerRejectOrderChanges**](OrdersApi.md#orderscontrollerrejectorderchanges) | **POST** /orders/{id}/reject-changes | 
[**ordersControllerRespondToDispatch**](OrdersApi.md#orderscontrollerrespondtodispatch) | **POST** /orders/driver/dispatches/{dispatchId}/respond | Accept or reject a dispatch request
[**ordersControllerVendorUpdateStatus**](OrdersApi.md#orderscontrollervendorupdatestatus) | **PATCH** /orders/vendor/{orderId}/status | Vendor updates order status


# **ordersControllerAcceptOrderChanges**
> OrdersControllerPlaceOrder200Response ordersControllerAcceptOrderChanges(id)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String id = id_example; // String | 

try {
    final response = api.ordersControllerAcceptOrderChanges(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAcceptOrderChanges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

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
> OrdersControllerPlaceOrder200Response ordersControllerAdminPlaceDirectOrder(placeDirectOrderDto)

[Admin/Vendor] Create a pending order directly for a customer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceDirectOrderDto placeDirectOrderDto = ; // PlaceDirectOrderDto | 

try {
    final response = api.ordersControllerAdminPlaceDirectOrder(placeDirectOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerAdminPlaceDirectOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
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
> OrdersControllerPlaceOrder200Response ordersControllerCustomerMarkPaid(orderId)

Customer marks mobile wallet payment as paid

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String orderId = orderId_example; // String | 

try {
    final response = api.ordersControllerCustomerMarkPaid(orderId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerCustomerMarkPaid: $e\n');
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

# **ordersControllerEditOrderItems**
> OrdersControllerPlaceOrder200Response ordersControllerEditOrderItems(id, editOrderItemsDto)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String id = id_example; // String | 
final EditOrderItemsDto editOrderItemsDto = ; // EditOrderItemsDto | 

try {
    final response = api.ordersControllerEditOrderItems(id, editOrderItemsDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerEditOrderItems: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **editOrderItemsDto** | [**EditOrderItemsDto**](EditOrderItemsDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

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

# **ordersControllerPlaceCustomOrder**
> OrdersControllerPlaceOrder200Response ordersControllerPlaceCustomOrder(placeCustomOrderDto)

Place a custom delivery or ride order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceCustomOrderDto placeCustomOrderDto = ; // PlaceCustomOrderDto | 

try {
    final response = api.ordersControllerPlaceCustomOrder(placeCustomOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerPlaceCustomOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placeCustomOrderDto** | [**PlaceCustomOrderDto**](PlaceCustomOrderDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerPlaceOrder**
> OrdersControllerPlaceOrder200Response ordersControllerPlaceOrder(placeOrderDto)

Place a new order from active cart

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final PlaceOrderDto placeOrderDto = ; // PlaceOrderDto | 

try {
    final response = api.ordersControllerPlaceOrder(placeOrderDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerPlaceOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **placeOrderDto** | [**PlaceOrderDto**](PlaceOrderDto.md)|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ordersControllerRejectOrderChanges**
> OrdersControllerPlaceOrder200Response ordersControllerRejectOrderChanges(id)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getOrdersApi();
final String id = id_example; // String | 

try {
    final response = api.ordersControllerRejectOrderChanges(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OrdersApi->ordersControllerRejectOrderChanges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**OrdersControllerPlaceOrder200Response**](OrdersControllerPlaceOrder200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
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

