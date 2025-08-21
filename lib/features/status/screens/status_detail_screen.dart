import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';

/// Screen that shows details for a single status (post) and its conversation
class StatusDetailScreen extends ConsumerStatefulWidget {
  final String statusId;

  const StatusDetailScreen({super.key, required this.statusId});

  @override
  ConsumerState<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends ConsumerState<StatusDetailScreen> {
  late Future<_LoadedStatus> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<_LoadedStatus> _load() async {
    final instance = ref.read(activeInstanceProvider);
    if (instance == null) {
      throw Exception('No active instance');
    }
    final domain = instance.domain;
    final tl = ref.read(timelineServiceProvider);

    final status = await tl.getStatus(domain, widget.statusId);
    final context = await tl.getStatusContext(domain, widget.statusId);
    final ancestors = context['ancestors'] ?? <Status>[];
    final descendants = context['descendants'] ?? <Status>[];

    return _LoadedStatus(
      domain: domain,
      status: status,
      ancestors: ancestors,
      descendants: descendants,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: FutureBuilder<_LoadedStatus>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load post',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loader = _load();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loader = _load();
              });
              await _loader;
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // If there are ancestors (thread above), show them in order
                if (data.ancestors.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('Conversation', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final s in data.ancestors)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PostCard(
                        status: s,
                        domain: data.domain,
                        showFullContent: true,
                      ),
                    ),
                  const Divider(height: 1),
                ],

                // The main status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PostCard(
                    status: data.status,
                    domain: data.domain,
                    showFullContent: true,
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),

                // Replies header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 8),
                      Text('Replies', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),

                if (data.descendants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Text(
                      'No replies yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                else
                  for (final s in data.descendants)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: PostCard(
                        status: s,
                        domain: data.domain,
                        showFullContent: true,
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadedStatus {
  final String domain;
  final Status status;
  final List<Status> ancestors;
  final List<Status> descendants;

  _LoadedStatus({
    required this.domain,
    required this.status,
    required this.ancestors,
    required this.descendants,
  });
}
