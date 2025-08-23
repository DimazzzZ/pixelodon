import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/core/network/api_service.dart' show NotFoundException;
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
    final tl = ref.read(timelineServiceProvider);

    Future<_LoadedStatus> _fetchForDomain(String domain) async {
      final ctx = await tl.getStatusContext(domain, widget.statusId);
      final status = await tl.getStatus(domain, widget.statusId);
      final ancestors = ctx['ancestors'] ?? <Status>[];
      final descendants = ctx['descendants'] ?? <Status>[];
      return _LoadedStatus(
        domain: domain,
        status: status,
        ancestors: ancestors,
        descendants: descendants,
      );
    }

    // Try with the active instance first
    try {
      return await _fetchForDomain(instance.domain);
    } on NotFoundException catch (_) {
      // If active instance is Pixelfed, try fallback to a Mastodon instance
      if (instance.isPixelfed) {
        final instances = ref.read(instancesProvider);
        String? mastodonDomain;
        for (final inst in instances) {
          if (!inst.isPixelfed) {
            mastodonDomain = inst.domain;
            break;
          }
        }
        if (mastodonDomain != null) {
          return await _fetchForDomain(mastodonDomain);
        }
      }
      rethrow;
    }
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
                  Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
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
                Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),

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
                else ...[
                  for (int i = 0; i < data.descendants.length; i++)
                    _ThreadedReplyCard(
                      isFirst: i == 0,
                      isLast: i == data.descendants.length - 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PostCard(
                          status: data.descendants[i],
                          domain: data.domain,
                          showFullContent: true,
                        ),
                      ),
                    ),
                ]
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


/// A wrapper that draws a light-grey vertical connector line on the left side
/// to visually connect reply cards like Bluesky.
class _ThreadedReplyCard extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const _ThreadedReplyCard({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Colors.grey.shade300;

    return Stack(
      children: [
        // Left gutter with the vertical connector line
        Positioned.fill(
          left: 8, // gutter offset left of the card padding so the line stays in the gutter
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ThreadConnectorPainter(
                color: lineColor,
                topGap: isFirst ? 8.0 : 0.0,
                bottomGap: isLast ? 12.0 : 0.0,
              ),
            ),
          ),
        ),
        // The reply content itself
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFirst) const SizedBox(height: 4),
            child,
          ],
        ),
      ],
    );
  }
}

class _ThreadConnectorPainter extends CustomPainter {
  final Color color;
  final double topGap;
  final double bottomGap;

  _ThreadConnectorPainter({
    required this.color,
    required this.topGap,
    required this.bottomGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw near the left edge of the Positioned.fill area.
    final double x = 0;
    final double startY = topGap;
    final double endY = size.height - bottomGap;

    if (endY > startY) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadConnectorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.topGap != topGap ||
        oldDelegate.bottomGap != bottomGap;
  }
}
