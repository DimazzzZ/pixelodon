/// Result class for paginated API responses
class PaginatedResult<T> {
  final List<T> items;
  final String? nextMaxId;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.nextMaxId,
    required this.hasMore,
  });

  /// Parse Link header to extract pagination information
  static String? _extractMaxIdFromUrl(String? url) {
    if (url == null) return null;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    
    return uri.queryParameters['max_id'];
  }

  /// Parse Link header for pagination
  static PaginatedResult<T> fromResponse<T>(
    List<T> items,
    Map<String, List<String>>? headers,
  ) {
    String? nextMaxId;
    bool hasMore = false;

    // Parse Link header for pagination
    final linkHeader = headers?['link']?.first;
    if (linkHeader != null) {
      // Split by comma to get individual links
      final links = linkHeader.split(',');
      
      for (final link in links) {
        final trimmed = link.trim();
        // Look for rel="next" which indicates there are more items
        if (trimmed.contains('rel="next"')) {
          hasMore = true;
          // Extract URL from < >
          final urlMatch = RegExp(r'<([^>]+)>').firstMatch(trimmed);
          if (urlMatch != null) {
            nextMaxId = _extractMaxIdFromUrl(urlMatch.group(1));
          }
          break;
        }
      }
    }

    // If we didn't find rel="next" but have items, use the last item's ID as maxId
    // and determine hasMore based on the requested limit (typically 40 for followers)
    if (!hasMore && items.isNotEmpty) {
      // For backwards compatibility, if the response has exactly the limit count,
      // assume there might be more items
      hasMore = items.length >= 40; // Default limit for followers/following
      
      // Try to extract ID from the last item if it has an 'id' property
      final lastItem = items.last;
      if (lastItem is Map && lastItem.containsKey('id')) {
        nextMaxId = lastItem['id'].toString();
      } else {
        // Try to use reflection-like approach for objects with id property
        try {
          final dynamic itemWithId = lastItem;
          nextMaxId = itemWithId.id?.toString();
        } catch (_) {
          // If we can't extract ID, set nextMaxId to null
          nextMaxId = null;
          hasMore = false;
        }
      }
    }

    return PaginatedResult(
      items: items,
      nextMaxId: nextMaxId,
      hasMore: hasMore,
    );
  }
}
