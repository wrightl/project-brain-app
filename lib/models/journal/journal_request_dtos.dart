/// One system tag response block for create/update request.
class SystemTagResponseItem {
  final String systemTagId;
  final Map<String, dynamic> responses;

  SystemTagResponseItem({
    required this.systemTagId,
    required this.responses,
  });

  factory SystemTagResponseItem.fromJson(Map<String, dynamic> json) {
    return SystemTagResponseItem(
      systemTagId: json['systemTagId'] as String,
      responses: json['responses'] != null
          ? Map<String, dynamic>.from(json['responses'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systemTagId': systemTagId,
      'responses': responses,
    };
  }
}

/// Request body for creating a journal entry.
class JournalCreateRequest {
  final String content;
  final List<String>? tagIds;
  final List<String>? systemTagIds;
  final List<SystemTagResponseItem>? systemTagResponses;

  JournalCreateRequest({
    required this.content,
    this.tagIds,
    this.systemTagIds,
    this.systemTagResponses,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (tagIds != null && tagIds!.isNotEmpty) 'tagIds': tagIds,
      if (systemTagIds != null && systemTagIds!.isNotEmpty)
        'systemTagIds': systemTagIds,
      if (systemTagResponses != null && systemTagResponses!.isNotEmpty)
        'systemTagResponses':
            systemTagResponses!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Request body for updating a journal entry (same shape as create).
class JournalUpdateRequest {
  final String content;
  final List<String>? tagIds;
  final List<String>? systemTagIds;
  final List<SystemTagResponseItem>? systemTagResponses;

  JournalUpdateRequest({
    required this.content,
    this.tagIds,
    this.systemTagIds,
    this.systemTagResponses,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (tagIds != null && tagIds!.isNotEmpty) 'tagIds': tagIds,
      if (systemTagIds != null && systemTagIds!.isNotEmpty)
        'systemTagIds': systemTagIds,
      if (systemTagResponses != null && systemTagResponses!.isNotEmpty)
        'systemTagResponses':
            systemTagResponses!.map((e) => e.toJson()).toList(),
    };
  }
}
