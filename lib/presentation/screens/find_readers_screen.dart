import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/follow_repository_impl.dart';
import '../../domain/entities/follow_entities.dart';
import '../../domain/repositories/follow_repository.dart';
import '../navigation/profile_navigation.dart';
import '../widgets/user_list_tile.dart';

/// Cari pembaca lain lewat username / nama, lalu buka profilnya untuk di-follow.
class FindReadersScreen extends StatefulWidget {
  const FindReadersScreen({super.key});

  @override
  State<FindReadersScreen> createState() => _FindReadersScreenState();
}

class _FindReadersScreenState extends State<FindReadersScreen> {
  final FollowRepository _repository = FollowRepositoryImpl();
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  int _searchToken = 0; // abaikan hasil pencarian lama yang datang terlambat
  List<UserSummary> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _searchToken++;
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final token = ++_searchToken;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await _repository.searchUsers(query);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint('Search readers failed: $e');
      if (!mounted || token != _searchToken) return;
      setState(() => _error = 'Search failed. Please try again.');
    } finally {
      if (mounted && token == _searchToken) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Find Readers',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                hintStyle: const TextStyle(color: AppColors.textDisabled),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching && _results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return _message(_error!);
    }
    if (!_hasSearched) {
      return _message('Type at least 2 characters to find other readers.');
    }
    if (_results.isEmpty) {
      return _message('No readers found.');
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.surface),
      itemBuilder: (context, index) {
        final person = _results[index];
        return UserListTile(
          person: person,
          onTap: () => openUserProfile(context, person.id),
        );
      },
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
