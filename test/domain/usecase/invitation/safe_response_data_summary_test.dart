import 'package:fluffychat/domain/usecase/invitation/safe_response_data_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summarizes response data without exposing its values', () {
    expect(safeResponseDataSummary(null), 'null');
    expect(
      safeResponseDataSummary({'message': 'sensitive response'}),
      'Map(keys=message)',
    );
    expect(safeResponseDataSummary('sensitive response'), 'String');
  });
}
