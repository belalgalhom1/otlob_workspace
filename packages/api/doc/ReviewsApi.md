# api.api.ReviewsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reviewsControllerGetDriverReviews**](ReviewsApi.md#reviewscontrollergetdriverreviews) | **GET** /reviews/driver/{driverId} | [Admin] Get paginated reviews for a specific driver
[**reviewsControllerGetMyDriverReviews**](ReviewsApi.md#reviewscontrollergetmydriverreviews) | **GET** /reviews/driver/me | Driver views their own reviews
[**reviewsControllerGetVendorReviews**](ReviewsApi.md#reviewscontrollergetvendorreviews) | **GET** /reviews/vendor/{vendorId} | Get paginated reviews for a specific vendor
[**reviewsControllerSubmitReview**](ReviewsApi.md#reviewscontrollersubmitreview) | **POST** /reviews/order/{orderId} | Submit a rating/review for a delivered order


# **reviewsControllerGetDriverReviews**
> ReviewsControllerGetVendorReviews200Response reviewsControllerGetDriverReviews(driverId, page, limit)

[Admin] Get paginated reviews for a specific driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getReviewsApi();
final String driverId = driverId_example; // String | 
final num page = 1; // num | Page number
final num limit = 20; // num | Items per page

try {
    final response = api.reviewsControllerGetDriverReviews(driverId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReviewsApi->reviewsControllerGetDriverReviews: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **page** | **num**| Page number | [optional] 
 **limit** | **num**| Items per page | [optional] 

### Return type

[**ReviewsControllerGetVendorReviews200Response**](ReviewsControllerGetVendorReviews200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reviewsControllerGetMyDriverReviews**
> ReviewsControllerGetVendorReviews200Response reviewsControllerGetMyDriverReviews(page, limit)

Driver views their own reviews

### Example
```dart
import 'package:api/api.dart';

final api = Api().getReviewsApi();
final num page = 1; // num | Page number
final num limit = 20; // num | Items per page

try {
    final response = api.reviewsControllerGetMyDriverReviews(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReviewsApi->reviewsControllerGetMyDriverReviews: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**| Page number | [optional] 
 **limit** | **num**| Items per page | [optional] 

### Return type

[**ReviewsControllerGetVendorReviews200Response**](ReviewsControllerGetVendorReviews200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reviewsControllerGetVendorReviews**
> ReviewsControllerGetVendorReviews200Response reviewsControllerGetVendorReviews(vendorId, page, limit)

Get paginated reviews for a specific vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getReviewsApi();
final String vendorId = vendorId_example; // String | 
final num page = 1; // num | Page number
final num limit = 20; // num | Items per page

try {
    final response = api.reviewsControllerGetVendorReviews(vendorId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReviewsApi->reviewsControllerGetVendorReviews: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **page** | **num**| Page number | [optional] 
 **limit** | **num**| Items per page | [optional] 

### Return type

[**ReviewsControllerGetVendorReviews200Response**](ReviewsControllerGetVendorReviews200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reviewsControllerSubmitReview**
> ApiControllerRoot200Response reviewsControllerSubmitReview(orderId, createReviewDto)

Submit a rating/review for a delivered order

### Example
```dart
import 'package:api/api.dart';

final api = Api().getReviewsApi();
final String orderId = orderId_example; // String | 
final CreateReviewDto createReviewDto = ; // CreateReviewDto | 

try {
    final response = api.reviewsControllerSubmitReview(orderId, createReviewDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReviewsApi->reviewsControllerSubmitReview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **createReviewDto** | [**CreateReviewDto**](CreateReviewDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

