import 'package:flutter/material.dart';

import '../../domain/entities/community_entities.dart';
import '../../domain/repositories/community_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _communityRepository;

  CommunityViewModel(this._communityRepository);

  bool _isLoading = false;
  List<CommunityGroup> _groups = [];
  List<CommunityDiscussion> _recentDiscussions = [];
  List<CommunityDiscussion> _bookDiscussions = [];
  List<CommunityComment> _comments = [];
  String? _activeDiscussionId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<CommunityGroup> get groups => _groups;
  List<CommunityDiscussion> get recentDiscussions => _recentDiscussions;
  List<CommunityDiscussion> get bookDiscussions => _bookDiscussions;
  List<CommunityComment> get comments => _comments;
  String? get activeDiscussionId => _activeDiscussionId;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCommunityData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _communityRepository.fetchGroups(),
        _communityRepository.fetchRecentDiscussions(),
      ]);

      _groups = results[0] as List<CommunityGroup>;
      _recentDiscussions = results[1] as List<CommunityDiscussion>;
    } catch (e) {
      _errorMessage = 'Failed to load community data: $e';
      debugPrint('Error fetching community data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookDiscussions(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Find the group associated with this book
      final group = _groups.firstWhere(
        (g) => g.relatedBookId == bookId,
        orElse: () => throw Exception('No community group found for this book'),
      );

      // 2. Fetch discussions for that group
      _bookDiscussions = await _communityRepository.fetchDiscussions(group.id);
    } catch (e) {
      _errorMessage = 'Failed to load book discussions: $e';
      debugPrint('Error fetching book discussions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadComments(String discussionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _activeDiscussionId = discussionId;
      _comments = await _communityRepository.fetchComments(discussionId);
    } catch (e) {
      _errorMessage = 'Failed to load comments: $e';
      debugPrint('Error loading comments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitComment(
    String discussionId,
    String content, {
    String? parentId,
    String? parentCommentId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _communityRepository.postComment(
        user.id,
        discussionId,
        content,
        parentCommentId: parentId,
      );
      // Refresh comments if we are currently viewing this thread
      if (_activeDiscussionId == discussionId) {
        await loadComments(discussionId);
      }
    } catch (e) {
      _errorMessage = 'Failed to post comment: $e';
      debugPrint('Error posting comment: $e');
    }
  }

  Future<void> joinGroup(String groupId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to join a group';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _communityRepository.joinGroup(user.id, groupId);
    } catch (e) {
      _errorMessage = 'Failed to join group: $e';
      debugPrint('Error joining group: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createDiscussion(String groupId, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _communityRepository.createDiscussion(user.id, groupId, content);
      // Refresh relevant list based on context
      if (_bookDiscussions.isNotEmpty) {
        final group = _groups.firstWhere(
          (g) => g.relatedBookId == _bookDiscussions.first.groupId,
        );
        await fetchBookDiscussions(group.relatedBookId!);
      } else {
        await fetchCommunityData();
      }
    } catch (e) {
      _errorMessage = 'Failed to post discussion: $e';
      debugPrint('Error creating discussion: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    // Using submitComment for unified logic
    await submitComment(
      discussionId,
      content,
      parentCommentId: parentCommentId,
    );
  }
}
