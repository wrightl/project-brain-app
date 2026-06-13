import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/services/coach_service.dart';

void main() {
  group('CoachService.buildCoachSearchQuery', () {
    test('builds geo search query with distanceMiles', () {
      final query = CoachService.buildCoachSearchQuery(
        latitude: 51.5072,
        longitude: -0.1276,
        distanceMiles: 25,
      );

      expect(query, contains('latitude=51.5072'));
      expect(query, contains('longitude=-0.1276'));
      expect(query, contains('distanceMiles=25'));
      expect(query, isNot(contains('city=')));
      expect(query, isNot(contains('neurodiverseTraits')));
    });

    test('uses repeated keys for ageGroups and specialisms', () {
      final query = CoachService.buildCoachSearchQuery(
        city: 'London',
        country: 'United Kingdom',
        ageGroups: ['Children (5-12)', 'Teens (13-17)'],
        specialisms: ['ADHD', 'Autism'],
      );

      expect(query, contains('city=London'));
      expect(query, contains('country=United'));
      expect(query.split('ageGroups=').length - 1, 2);
      expect(query.split('specialisms=').length - 1, 2);
      expect(query, isNot(contains('neurodiverseTraits')));
      expect(query, isNot(contains('postcode')));
    });

    test('prefers geo search when center and distance are provided', () {
      final query = CoachService.buildCoachSearchQuery(
        city: 'London',
        country: 'United Kingdom',
        latitude: 51.5072,
        longitude: -0.1276,
        distanceMiles: 10,
      );

      expect(query, contains('latitude=51.5072'));
      expect(query, contains('distanceMiles=10'));
      expect(query, isNot(contains('city=')));
      expect(query, isNot(contains('country=')));
    });

    test('returns empty string when no params provided', () {
      expect(CoachService.buildCoachSearchQuery(), '');
    });
  });
}
