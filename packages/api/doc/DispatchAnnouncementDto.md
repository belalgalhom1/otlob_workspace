# api.model.DispatchAnnouncementDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**audience** | **String** | Target audience for the broadcast | 
**title** | **String** |  | 
**titleAr** | **String** |  | [optional] 
**body** | **String** |  | 
**bodyAr** | **String** |  | [optional] 
**data** | [**JsonObject**](.md) | Optional deep link or analytics payload | [optional] 
**type** | **String** | The type of notification to send. Defaults to ANNOUNCEMENT. | [optional] [default to 'ANNOUNCEMENT']

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


