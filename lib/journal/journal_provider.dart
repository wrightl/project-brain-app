import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:projectbrain/services/journal_service.dart';
import 'package:projectbrain/services/tag_service.dart';
import 'package:projectbrain/services/user_service.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/models/journal/journal_streak_summary.dart';
import 'package:projectbrain/models/journal/journal_tag.dart';
import 'package:projectbrain/models/journal/system_tag.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Provider for journal list, CRUD, system tags, user tags, and streak.
class JournalProvider extends ChangeNotifier {
  final JournalService journalService;
  final TagService tagService;
  final UserService? userService;

  List<JournalEntry> _items = [];
  int _page = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  JournalEntry? _currentEntry;
  List<SystemTag> _systemTags = [];
  List<JournalTag> _userTags = [];
  JournalStreakSummary? _streakSummary;
  int? _entryCount;
  List<JournalEntry> _recentEntries = [];

  List<JournalEntry> get items => List.unmodifiable(_items);
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNextPage => _hasNextPage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  JournalEntry? get currentEntry => _currentEntry;
  List<SystemTag> get systemTags => List.unmodifiable(_systemTags);
  List<JournalTag> get userTags => List.unmodifiable(_userTags);
  JournalStreakSummary? get streakSummary => _streakSummary;
  int? get entryCount => _entryCount;
  List<JournalEntry> get recentEntries => List.unmodifiable(_recentEntries);

  JournalProvider({
    required this.journalService,
    required this.tagService,
    this.userService,
  });

  /// Refresh list (page 1).
  Future<void> refresh() async {
    _page = 1;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final paged =
          await journalService.listEntries(page: 1, pageSize: _pageSize);
      _items = paged.items;
      _totalCount = paged.totalCount;
      _totalPages = paged.totalPages;
      _hasNextPage = paged.hasNextPage;
    } catch (e) {
      logError('[JournalProvider] refresh failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to load entries';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page and append.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNextPage) return;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final paged =
          await journalService.listEntries(page: nextPage, pageSize: _pageSize);
      _items = [..._items, ...paged.items];
      _page = nextPage;
      _totalCount = paged.totalCount;
      _totalPages = paged.totalPages;
      _hasNextPage = paged.hasNextPage;
    } catch (e) {
      logError('[JournalProvider] loadMore failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to load more';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch a single entry (for view/edit).
  Future<JournalEntry?> fetchEntry(String id) async {
    _errorMessage = null;
    _currentEntry = null;
    notifyListeners();
    try {
      final entry = await journalService.getEntry(id);
      _currentEntry = entry;
      notifyListeners();
      return entry;
    } catch (e) {
      logError('[JournalProvider] fetchEntry failed', e);
      _errorMessage = e is Exception ? e.toString() : 'Failed to load entry';
      notifyListeners();
      return null;
    }
  }

  /// Create entry; returns new entry on success, throws on failure.
  Future<JournalEntry> createEntry(JournalCreateRequest request) async {
    _errorMessage = null;
    final entry = await journalService.createEntry(request);
    _currentEntry = entry;
    _items = [entry, ..._items];
    _totalCount = (_totalCount + 1).clamp(0, 999999);
    await loadStreakSummary();
    notifyListeners();
    return entry;
  }

  /// Update entry; returns updated entry on success, throws on failure.
  Future<JournalEntry> updateEntry(
      String id, JournalUpdateRequest request) async {
    _errorMessage = null;
    final entry = await journalService.updateEntry(id, request);
    _currentEntry = entry;
    final index = _items.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _items = [..._items]..[index] = entry;
    }
    await loadStreakSummary();
    notifyListeners();
    return entry;
  }

  /// Delete entry. Throws on failure.
  Future<void> deleteEntry(String id) async {
    _errorMessage = null;
    await journalService.deleteEntry(id);
    _items = _items.where((e) => e.id != id).toList();
    _totalCount = (_totalCount - 1).clamp(0, 999999);
    if (_currentEntry?.id == id) _currentEntry = null;
    await loadStreakSummary();
    notifyListeners();
  }

  /// Load system tags catalog (cache).
  Future<void> loadSystemTags() async {
    if (_systemTags.isNotEmpty) return;
    try {
      _systemTags = await journalService.getSystemTags();
      notifyListeners();
    } catch (e) {
      logError('[JournalProvider] loadSystemTags failed', e);
    }
  }

  /// Load user tags (refresh cache).
  Future<void> loadUserTags() async {
    try {
      _userTags = await tagService.listTags();
      notifyListeners();
    } catch (e) {
      logError('[JournalProvider] loadUserTags failed', e);
    }
  }

  /// Create a new user tag and refresh list.
  Future<JournalTag> createTag(String name) async {
    final tag = await tagService.createTag(name.trim());
    _userTags = [..._userTags, tag];
    notifyListeners();
    return tag;
  }

  /// Load streak summary (and ensure user timezone is set for accurate streak).
  Future<void> loadStreakSummary() async {
    try {
      await _ensureTimezoneSet();
      _streakSummary = await journalService.getStreakSummary();
      notifyListeners();
    } catch (e) {
      logError('[JournalProvider] loadStreakSummary failed', e);
    }
  }

  /// If user timezone is null or missing, set it from device IANA so streak uses local day.
  Future<void> _ensureTimezoneSet() async {
    if (userService == null) return;
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final deviceIdentifier = tzInfo.identifier;
      if (deviceIdentifier.isEmpty) return;
      final current = await userService!.getTimezone();
      if (current.timezone == null ||
          current.timezone!.isEmpty ||
          current.timezone != deviceIdentifier) {
        await userService!.setTimezone(deviceIdentifier);
        logDebug('[JournalProvider] Set user timezone to $deviceIdentifier');
      }
    } catch (e) {
      logDebug('[JournalProvider] Timezone sync skipped: $e');
    }
  }

  /// Load entry count for dashboard.
  Future<void> loadEntryCount() async {
    try {
      _entryCount = await journalService.getEntryCount();
      notifyListeners();
    } catch (e) {
      logError('[JournalProvider] loadEntryCount failed', e);
    }
  }

  /// Load recent entries for dashboard.
  Future<void> loadRecentEntries({int count = 3}) async {
    try {
      _recentEntries = await journalService.getRecentEntries(count: count);
      notifyListeners();
    } catch (e) {
      logError('[JournalProvider] loadRecentEntries failed', e);
    }
  }

  void clearCurrentEntry() {
    _currentEntry = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all journal state so it does not leak into the next session.
  void resetOnLogout() {
    _items = [];
    _page = 1;
    _totalCount = 0;
    _totalPages = 0;
    _hasNextPage = false;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentEntry = null;
    _systemTags = [];
    _userTags = [];
    _streakSummary = null;
    _entryCount = null;
    _recentEntries = [];
    notifyListeners();
    logDebug('[JournalProvider] Reset on logout');
  }
}
