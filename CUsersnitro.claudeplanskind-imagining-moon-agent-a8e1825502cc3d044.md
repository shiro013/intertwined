# Implementation Plan: Community Hub (Modul 5 & 6)

## Goal
Implement the Community Hub with a premium "Book Lover" vibe, including a discovery screen and a detailed discussion flow, integrated with Supabase (via ViewModel).

## Current State
- Theme: Deep Charcoal (#121212) and Metallic Gold (#D4AF37).
- `MainScreen` has a placeholder `CommunityScreen`.
- Supabase schema exists: `groups`, `discussions`, `comments`.

## Requirements
- `CommunityScreen`: Premium layout, search bar, featured book clubs, recent discussions feed.
- `DiscussionScreen`: Post list, comments, "Create Post" functionality.
- `CommunityViewModel`: Logic for fetching clubs and discussions.
- UI/UX: Sliver layout, Gold accents, professional reader feel.

## Execution Plan

### Phase 1: Data Models
Create models to map Supabase tables to Dart objects.
- `lib/data/models/community_group.dart` (for `groups` table)
- `lib/data/models/discussion.dart` (for `discussions` table)
- `lib/data/models/comment.dart` (for `comments` table)

### Phase 2: ViewModel
Implement `CommunityViewModel` to handle business logic.
- `lib/presentation/view_models/community_view_model.dart`
- Methods: `fetchFeaturedClubs()`, `fetchRecentDiscussions()`, `createPost()`, `fetchComments(discussionId)`.
- Support for both mock data (initial UI) and real Supabase calls.

### Phase 3: Community Screen UI
Replace the placeholder `CommunityScreen`.
- `lib/presentation/screens/community_screen.dart`
- Implement `CustomScrollView` with `SliverAppBar` for a premium feel.
- Search bar implementation.
- Horizontal list for "Featured Book Clubs".
- Vertical list for "Recent Discussions".
- Use `AppColors.primary` (Gold) for key interactive elements.

### Phase 4: Discussion Screen UI
Implement the detailed discussion view.
- `lib/presentation/screens/discussion_screen.dart`
- Display post content and a list of comments.
- Implement the "Create Post" dialog/screen.
- Navigation from `CommunityScreen` \(\rightarrow\) `DiscussionScreen`.

### Phase 5: Integration & Polish
- Update `MainScreen` to use the new `CommunityScreen`.
- Ensure theme consistency (Dark Charcoal/Gold).
- Test navigation flows.

## Deliverables
- `lib/presentation/screens/community_screen.dart`
- `lib/presentation/screens/discussion_screen.dart`
- `lib/presentation/view_models/community_view_model.dart`
- Supporting models in `lib/data/models/`.
