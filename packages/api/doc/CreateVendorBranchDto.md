# api.model.CreateVendorBranchDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**nameAr** | **String** |  | [optional] 
**address** | **String** |  | 
**phone** | **String** |  | [optional] 
**location** | **BuiltList&lt;String&gt;** |  | 
**zoneId** | **String** |  | [optional] 
**isOpen** | **bool** |  | [optional] [default to true]
**isContracted** | **bool** | Contracted status override for this branch. If null/undefined, falls back to vendor.isContracted. | [optional] 
**commissionRate** | **num** | Commission rate override for this branch in percent (e.g. 10 for 10%). If null/undefined, falls back to vendor.commissionRate. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


