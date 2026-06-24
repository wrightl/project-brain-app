import 'package:projectbrain/models/user_memory/user_episode_memory.dart';
import 'package:projectbrain/models/user_memory/user_fact_memory.dart';

/// Response from GET /user/memory.
class UserMemoryList {
  final List<UserFactMemory> facts;
  final List<UserEpisodeMemory> episodes;

  UserMemoryList({
    required this.facts,
    required this.episodes,
  });

  factory UserMemoryList.fromJson(Map<String, dynamic> json) {
    final factsJson = json['facts'] as List<dynamic>? ?? [];
    final episodesJson = json['episodes'] as List<dynamic>? ?? [];
    return UserMemoryList(
      facts: factsJson
          .map((e) => UserFactMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
      episodes: episodesJson
          .map((e) => UserEpisodeMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
