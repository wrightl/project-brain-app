import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/models/onboarding_data.dart';

void main() {
  test('leaves out an empty date of birth and pronoun', () {
    final json = UserOnboardingData(
      email: 'a@test.com',
      fullName: 'Alex',
      doB: '',
      preferredPronoun: '',
    ).toJson();

    expect(json.containsKey('doB'), isFalse);
    expect(json.containsKey('preferredPronoun'), isFalse);
    expect(json['fullName'], 'Alex');
  });

  test('sends them when given', () {
    final json = UserOnboardingData(
      email: 'a@test.com',
      fullName: 'Alex',
      doB: '1990-01-02',
      preferredPronoun: 'they/them',
    ).toJson();

    expect(json['doB'], '1990-01-02');
    expect(json['preferredPronoun'], 'they/them');
  });
}
