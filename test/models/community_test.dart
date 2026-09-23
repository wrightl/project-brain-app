import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/models/community.dart';

void main() {
  test('CommunityChannel.fromJson parses camelCase', () {
    final channel = CommunityChannel.fromJson({
      'id': '11111111-1111-1111-1111-111111111101',
      'slug': 'wins',
      'name': 'Wins',
      'description': 'Celebrate',
      'sortOrder': 2,
    });

    expect(channel.slug, 'wins');
    expect(channel.name, 'Wins');
    expect(channel.sortOrder, 2);
  });

  test('CommunityPost.fromJson and copyWith update reaction state', () {
    final post = CommunityPost.fromJson({
      'id': '22222222-2222-2222-2222-222222222222',
      'channelId': '11111111-1111-1111-1111-111111111102',
      'channelSlug': 'wins',
      'authorUserId': 'auth0|1',
      'authorDisplayName': 'Lee',
      'body': 'Hello',
      'createdAt': '2026-08-10T12:00:00Z',
      'reactionCount': 1,
      'reactedByCurrentUser': false,
      'isOwnPost': true,
    });

    final updated = post.copyWith(
      reactedByCurrentUser: true,
      reactionCount: 2,
    );

    expect(updated.reactedByCurrentUser, isTrue);
    expect(updated.reactionCount, 2);
    expect(updated.isOwnPost, isTrue);
    expect(updated.body, 'Hello');
  });

  test('CommunityPostsPage.fromJson parses items and cursor', () {
    final page = CommunityPostsPage.fromJson({
      'items': [
        {
          'id': '22222222-2222-2222-2222-222222222222',
          'channelId': '11111111-1111-1111-1111-111111111102',
          'channelSlug': 'wins',
          'authorUserId': 'auth0|1',
          'authorDisplayName': 'Lee',
          'body': 'Hello',
          'createdAt': '2026-08-10T12:00:00Z',
          'reactionCount': 0,
          'reactedByCurrentUser': false,
          'isOwnPost': false,
        }
      ],
      'nextCursor': 'cursor-1',
    });

    expect(page.items, hasLength(1));
    expect(page.nextCursor, 'cursor-1');
  });
}
