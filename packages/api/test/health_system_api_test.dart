import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for HealthSystemApi
void main() {
  final instance = Api().getHealthSystemApi();

  group(HealthSystemApi, () {
    // API Health Check
    //
    //Future apiControllerRoot() async
    test('test apiControllerRoot', () async {
      // TODO
    });

  });
}
