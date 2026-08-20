import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for ReviewsApi
void main() {
  final instance = Api().getReviewsApi();

  group(ReviewsApi, () {
    // [Admin] Get paginated reviews for a specific driver
    //
    //Future<ReviewsControllerGetVendorReviews200Response> reviewsControllerGetDriverReviews(String driverId, { num page, num limit }) async
    test('test reviewsControllerGetDriverReviews', () async {
      // TODO
    });

    // Driver views their own reviews
    //
    //Future<ReviewsControllerGetVendorReviews200Response> reviewsControllerGetMyDriverReviews({ num page, num limit }) async
    test('test reviewsControllerGetMyDriverReviews', () async {
      // TODO
    });

    // Get paginated reviews for a specific vendor
    //
    //Future<ReviewsControllerGetVendorReviews200Response> reviewsControllerGetVendorReviews(String vendorId, { num page, num limit }) async
    test('test reviewsControllerGetVendorReviews', () async {
      // TODO
    });

    // Submit a rating/review for a delivered order
    //
    //Future reviewsControllerSubmitReview(String orderId, CreateReviewDto createReviewDto) async
    test('test reviewsControllerSubmitReview', () async {
      // TODO
    });

  });
}
