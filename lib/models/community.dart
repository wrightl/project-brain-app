class CommunityChannel {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final int sortOrder;

  const CommunityChannel({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.sortOrder,
  });

  factory CommunityChannel.fromJson(Map<String, dynamic> json) {
    return CommunityChannel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      slug: (json['slug'] ?? json['Slug'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      sortOrder: (json['sortOrder'] ?? json['SortOrder'] ?? 0) as int? ?? 0,
    );
  }
}

class CommunityPost {
  final String id;
  final String channelId;
  final String channelSlug;
  final String authorUserId;
  final String authorDisplayName;
  final String body;
  final DateTime createdAt;
  final int reactionCount;
  final bool reactedByCurrentUser;
  final bool isOwnPost;

  const CommunityPost({
    required this.id,
    required this.channelId,
    required this.channelSlug,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.body,
    required this.createdAt,
    required this.reactionCount,
    required this.reactedByCurrentUser,
    required this.isOwnPost,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      channelId: (json['channelId'] ?? json['ChannelId'] ?? '').toString(),
      channelSlug:
          (json['channelSlug'] ?? json['ChannelSlug'] ?? '').toString(),
      authorUserId:
          (json['authorUserId'] ?? json['AuthorUserId'] ?? '').toString(),
      authorDisplayName:
          (json['authorDisplayName'] ?? json['AuthorDisplayName'] ?? 'Member')
              .toString(),
      body: (json['body'] ?? json['Body'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      reactionCount:
          (json['reactionCount'] ?? json['ReactionCount'] ?? 0) as int? ?? 0,
      reactedByCurrentUser: json['reactedByCurrentUser'] == true ||
          json['ReactedByCurrentUser'] == true,
      isOwnPost: json['isOwnPost'] == true || json['IsOwnPost'] == true,
    );
  }

  CommunityPost copyWith({
    int? reactionCount,
    bool? reactedByCurrentUser,
  }) {
    return CommunityPost(
      id: id,
      channelId: channelId,
      channelSlug: channelSlug,
      authorUserId: authorUserId,
      authorDisplayName: authorDisplayName,
      body: body,
      createdAt: createdAt,
      reactionCount: reactionCount ?? this.reactionCount,
      reactedByCurrentUser: reactedByCurrentUser ?? this.reactedByCurrentUser,
      isOwnPost: isOwnPost,
    );
  }
}

class CommunityPostsPage {
  final List<CommunityPost> items;
  final String? nextCursor;

  const CommunityPostsPage({required this.items, this.nextCursor});

  factory CommunityPostsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] ?? json['Items'] ?? []) as List<dynamic>;
    return CommunityPostsPage(
      items: rawItems
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: (json['nextCursor'] ?? json['NextCursor'])?.toString(),
    );
  }
}
