import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/community_entities.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository;
  final VoidCallback? _onMembershipChanged;

  CommunityViewModel(
    this._repository, {
    VoidCallback? onMembershipChanged,
  }) : _onMembershipChanged = onMembershipChanged;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  // ---- Community hub
  bool _isLoading = false; // hanya untuk load awal hub (spinner layar penuh)
  bool _hasLoaded = false;
  List<CommunityGroup> _groups = [];
  List<CommunityDiscussion> _recentDiscussions = [];
  Set<String> _joinedGroupIds = {};
  final Set<String> _busyGroupIds = {};
  String _searchQuery = '';

  // ---- Halaman satu grup / satu buku
  CommunityGroup? _activeGroup;
  List<CommunityDiscussion> _groupDiscussions = [];
  bool _isGroupLoading = false;
  String? _groupError;
  bool _isPosting = false;

  // ---- Komentar
  List<CommunityComment> _comments = [];
  String? _activeDiscussionId;
  bool _isCommentsLoading = false;

  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  List<CommunityGroup> get groups => _groups;
  List<CommunityDiscussion> get recentDiscussions => _recentDiscussions;
  String get searchQuery => _searchQuery;

  CommunityGroup? get activeGroup => _activeGroup;
  List<CommunityDiscussion> get groupDiscussions => _groupDiscussions;
  bool get isGroupLoading => _isGroupLoading;
  String? get groupError => _groupError;
  bool get isPosting => _isPosting;

  List<CommunityComment> get comments => _comments;
  String? get activeDiscussionId => _activeDiscussionId;
  bool get isCommentsLoading => _isCommentsLoading;

  String? get errorMessage => _errorMessage;
  void clearError() => _errorMessage = null;

  bool isJoined(String groupId) => _joinedGroupIds.contains(groupId);
  bool isGroupBusy(String groupId) => _busyGroupIds.contains(groupId);
  bool get isActiveGroupJoined =>
      _activeGroup != null && _joinedGroupIds.contains(_activeGroup!.id);

  // ------------------------------------------------------------------ search

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<CommunityGroup> get filteredGroups {
    if (_searchQuery.isEmpty) return _groups;
    return _groups
        .where((g) =>
            g.name.toLowerCase().contains(_searchQuery) ||
            g.description.toLowerCase().contains(_searchQuery))
        .toList();
  }

  /// Klub yang SUDAH diikuti user (ikut terfilter oleh pencarian).
  List<CommunityGroup> get joinedGroups =>
      filteredGroups.where((g) => _joinedGroupIds.contains(g.id)).toList();

  /// Klub yang BELUM diikuti user.
  List<CommunityGroup> get discoverGroups =>
      filteredGroups.where((g) => !_joinedGroupIds.contains(g.id)).toList();

  /// Jumlah klub yang diikuti, tanpa terpengaruh pencarian (untuk judul bagian).
  int get joinedCount => _groups.where((g) => _joinedGroupIds.contains(g.id)).length;

  List<CommunityDiscussion> get filteredDiscussions {
    if (_searchQuery.isEmpty) return _recentDiscussions;
    return _recentDiscussions
        .where((d) =>
            d.content.toLowerCase().contains(_searchQuery) ||
            (d.username ?? '').toLowerCase().contains(_searchQuery) ||
            (d.groupName ?? '').toLowerCase().contains(_searchQuery))
        .toList();
  }

  // --------------------------------------------------------------- hub data

  /// [silent] = refresh tanpa spinner layar penuh (pull-to-refresh, setelah posting).
  Future<void> fetchCommunityData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final uid = _userId;
      final results = await Future.wait([
        _repository.fetchGroups(),
        // "Recent Discussions" = hanya postingan milik user yang sedang login
        uid == null
            ? Future.value(<CommunityDiscussion>[])
            : _repository.fetchRecentDiscussions(uid),
        uid == null
            ? Future.value(<String>{})
            : _repository.fetchJoinedGroupIds(uid),
      ]);
      _groups = results[0] as List<CommunityGroup>;
      _recentDiscussions = results[1] as List<CommunityDiscussion>;
      _joinedGroupIds = results[2] as Set<String>;
    } catch (e) {
      _errorMessage = 'Failed to load community data: $e';
      debugPrint('Error fetching community data: $e');
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  // ----------------------------------------------------- group / book thread

  /// Buka diskusi untuk sebuah buku. Grup dibuat otomatis kalau belum ada.
  Future<void> openGroupForBook({
    required String bookUuid,
    required String bookTitle,
  }) async {
    _beginGroupLoad();
    try {
      _activeGroup = await _repository.ensureGroupForBook(
        bookUuid: bookUuid,
        bookTitle: bookTitle,
      );
      await _loadActiveGroupContent();
    } catch (e) {
      _groupError = 'Failed to open book discussion: $e';
      debugPrint('openGroupForBook error: $e');
    } finally {
      _isGroupLoading = false;
      notifyListeners();
    }
  }

  Future<void> openGroup(CommunityGroup group) async {
    _beginGroupLoad();
    _activeGroup = group;
    notifyListeners();
    try {
      await _loadActiveGroupContent();
    } catch (e) {
      _groupError = 'Failed to load discussions: $e';
      debugPrint('openGroup error: $e');
    } finally {
      _isGroupLoading = false;
      notifyListeners();
    }
  }

  void _beginGroupLoad() {
    _isGroupLoading = true;
    _groupError = null;
    _activeGroup = null;
    _groupDiscussions = [];
    notifyListeners();
  }

  Future<void> _loadActiveGroupContent() async {
    final group = _activeGroup;
    if (group == null) return;

    final uid = _userId;
    final results = await Future.wait([
      _repository.fetchDiscussions(group.id),
      uid == null
          ? Future.value(<String>{})
          : _repository.fetchJoinedGroupIds(uid),
    ]);
    _groupDiscussions = results[0] as List<CommunityDiscussion>;
    _joinedGroupIds = results[1] as Set<String>;
  }

  Future<void> refreshActiveGroup() async {
    if (_activeGroup == null) return;
    try {
      await _loadActiveGroupContent();
      _groupError = null;
    } catch (e) {
      _errorMessage = 'Failed to refresh: $e';
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- membership

  Future<void> toggleMembership(String groupId) async {
    final uid = _userId;
    if (uid == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return;
    }
    if (_busyGroupIds.contains(groupId)) return;

    final wasJoined = _joinedGroupIds.contains(groupId);
    _busyGroupIds.add(groupId);
    _applyMembership(groupId, !wasJoined); // optimistic
    notifyListeners();

    try {
      if (wasJoined) {
        await _repository.leaveGroup(uid, groupId);
      } else {
        await _repository.joinGroup(uid, groupId);
      }
      _onMembershipChanged?.call();
    } catch (e) {
      debugPrint('toggleMembership error: $e');
      _applyMembership(groupId, wasJoined); // rollback
      _errorMessage = wasJoined ? 'Failed to leave club: $e' : 'Failed to join club: $e';
    } finally {
      _busyGroupIds.remove(groupId);
      notifyListeners();
    }
  }

  void _applyMembership(String groupId, bool joined) {
    if (joined) {
      _joinedGroupIds.add(groupId);
    } else {
      _joinedGroupIds.remove(groupId);
    }
    final delta = joined ? 1 : -1;

    CommunityGroup bump(CommunityGroup g) => g.id == groupId
        ? g.copyWith(memberCount: math.max(0, g.memberCount + delta))
        : g;

    _groups = _groups.map(bump).toList();
    if (_activeGroup != null) _activeGroup = bump(_activeGroup!);
  }

  // ------------------------------------------------------------ discussions

  /// Membuat diskusi baru. Posting di sebuah klub otomatis membuat user jadi anggota.
  Future<bool> createDiscussion(String groupId, String content) async {
    final uid = _userId;
    if (uid == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return false;
    }

    _isPosting = true;
    notifyListeners();
    var ok = false;
    try {
      var joinedNow = false;
      if (!_joinedGroupIds.contains(groupId)) {
        await _repository.joinGroup(uid, groupId);
        _applyMembership(groupId, true);
        joinedNow = true;
      }
      await _repository.createDiscussion(uid, groupId, content);
      ok = true;

      if (_activeGroup?.id == groupId) {
        _groupDiscussions = await _repository.fetchDiscussions(groupId);
      }
      _recentDiscussions = await _repository.fetchRecentDiscussions(uid);
      if (joinedNow) _onMembershipChanged?.call();
    } catch (e) {
      if (!ok) _errorMessage = 'Failed to post discussion: $e';
      debugPrint('Error creating discussion: $e');
    } finally {
      _isPosting = false;
      notifyListeners();
    }
    return ok;
  }

  CommunityDiscussion? discussionById(String id) {
    for (final d in _groupDiscussions) {
      if (d.id == id) return d;
    }
    for (final d in _recentDiscussions) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _updateDiscussion(String id, CommunityDiscussion Function(CommunityDiscussion) change) {
    CommunityDiscussion apply(CommunityDiscussion d) => d.id == id ? change(d) : d;
    _groupDiscussions = _groupDiscussions.map(apply).toList();
    _recentDiscussions = _recentDiscussions.map(apply).toList();
  }

  Future<void> toggleDiscussionLike(String discussionId) async {
    final uid = _userId;
    if (uid == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return;
    }
    final before = discussionById(discussionId);
    if (before == null) return;

    final nowLiked = !before.likedByMe;
    _updateDiscussion(
      discussionId,
      (d) => d.copyWith(
        likedByMe: nowLiked,
        likeCount: math.max(0, d.likeCount + (nowLiked ? 1 : -1)),
      ),
    );
    notifyListeners();

    try {
      await _repository.setLike(uid, discussionId, 'discussion', nowLiked);
    } catch (e) {
      debugPrint('Discussion like error: $e');
      _updateDiscussion(
        discussionId,
        (d) => d.copyWith(likedByMe: before.likedByMe, likeCount: before.likeCount),
      );
      _errorMessage = 'Gagal menyimpan like';
      notifyListeners();
    }
  }

  // --------------------------------------------------------------- comments

  Future<void> loadComments(String discussionId) async {
    if (_activeDiscussionId != discussionId) _comments = [];
    _activeDiscussionId = discussionId;
    _isCommentsLoading = true;
    notifyListeners();
    try {
      final list = await _repository.fetchComments(discussionId);
      if (_activeDiscussionId == discussionId) {
        _comments = list;
        _syncReplyCount(discussionId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load comments: $e';
      debugPrint('Error loading comments: $e');
    } finally {
      _isCommentsLoading = false;
      notifyListeners();
    }
  }

  /// [parentCommentId] = id komentar yang dibalas (null = komentar tingkat atas).
  Future<bool> submitComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final uid = _userId;
    if (uid == null) {
      _errorMessage = 'Kamu harus login dulu';
      notifyListeners();
      return false;
    }

    try {
      await _repository.postComment(
        uid,
        discussionId,
        content,
        parentCommentId: parentCommentId,
      );
    } catch (e) {
      _errorMessage = 'Failed to post comment: $e';
      debugPrint('Error posting comment: $e');
      notifyListeners();
      return false;
    }

    // Komentar sudah tersimpan -> kegagalan refresh di bawah tidak membatalkan.
    try {
      final list = await _repository.fetchComments(discussionId);
      if (_activeDiscussionId == discussionId) _comments = list;
      _syncReplyCount(discussionId, total: list.length);
    } catch (e) {
      debugPrint('Refresh comments error: $e');
    }
    notifyListeners();
    return true;
  }

  void _syncReplyCount(String discussionId, {int? total}) {
    final count = total ?? _comments.length;
    _updateDiscussion(discussionId, (d) => d.copyWith(replyCount: count));
  }
}
