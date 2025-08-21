import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';

class TagTimelineScreen extends ConsumerStatefulWidget {
  final String tag;
  const TagTimelineScreen({super.key, required this.tag});

  @override
  ConsumerState<TagTimelineScreen> createState() => _TagTimelineScreenState();
}

class _TagTimelineScreenState extends ConsumerState<TagTimelineScreen> {
  final _state = ValueNotifier<_TagTimelineState>(_TagTimelineState.initial());
  CancelToken? _cancelToken;

  String? get _domain => ref.read(activeInstanceProvider)?.domain;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Tag screen disposed');
    _state.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    final domain = _domain;
    if (domain == null) return;
    _cancelToken?.cancel('New tag request');
    _cancelToken = CancelToken();

    _state.value = _state.value.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      final tl = ref.read(timelineServiceProvider);
      final statuses = await tl.getTagTimeline(domain, widget.tag, limit: 20);
      _state.value = _state.value.copyWith(
        statuses: statuses,
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: statuses.isNotEmpty ? statuses.last.id : null,
      );
    } catch (e) {
      _state.value = _state.value.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load #${widget.tag}: $e',
      );
    }
  }

  Future<void> _refresh() async => _load(initial: true);

  Future<void> _loadMore() async {
    final domain = _domain;
    if (domain == null) return;
    if (_state.value.isLoading || !_state.value.hasMore) return;

    _cancelToken?.cancel('Load more tag');
    _cancelToken = CancelToken();

    _state.value = _state.value.copyWith(isLoading: true);

    try {
      final tl = ref.read(timelineServiceProvider);
      final statuses = await tl.getTagTimeline(
        domain,
        widget.tag,
        limit: 20,
        maxId: _state.value.maxId,
      );
      _state.value = _state.value.copyWith(
        statuses: [..._state.value.statuses, ...statuses],
        isLoading: false,
        hasMore: statuses.length >= 20,
        maxId: statuses.isNotEmpty ? statuses.last.id : _state.value.maxId,
      );
    } catch (e) {
      _state.value = _state.value.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load more for #${widget.tag}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.tag}'),
      ),
      body: ValueListenableBuilder<_TagTimelineState>(
        valueListenable: _state,
        builder: (context, state, _) {
          return FeedList(
            statuses: state.statuses,
            isLoading: state.isLoading,
            hasError: state.hasError,
            errorMessage: state.errorMessage,
            hasMore: state.hasMore,
            onLoadMore: _loadMore,
            onRefresh: _refresh,
            onPostLiked: (status, liked) {},
            onPostReblogged: (status, reblogged) {},
            onPostBookmarked: (status, bookmarked) {},
          );
        },
      ),
    );
  }
}

class _TagTimelineState {
  final List<Status> statuses;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;

  const _TagTimelineState({
    required this.statuses,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.hasMore,
    required this.maxId,
  });

  factory _TagTimelineState.initial() => const _TagTimelineState(
        statuses: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        hasMore: true,
        maxId: null,
      );

  _TagTimelineState copyWith({
    List<Status>? statuses,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
  }) {
    return _TagTimelineState(
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
    );
  }
}
