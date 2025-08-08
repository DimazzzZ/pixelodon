import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';

/// Provider for the compose screen state
final composeProvider = StateNotifierProvider.autoDispose<ComposeNotifier, ComposeState>((ref) {
  final timelineService = ref.watch(timelineServiceProvider);
  final mediaService = ref.watch(mediaServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);
  
  return ComposeNotifier(
    timelineService: timelineService,
    mediaService: mediaService,
    domain: activeInstance?.domain,
  );
});

/// State for the compose screen
class ComposeState {
  final String text;
  final List<File> mediaFiles;
  final List<model.MediaAttachment> uploadedMedia;
  final bool isSensitive;
  final String? contentWarning;
  final model.Visibility visibility;
  final bool isSubmitting;
  final bool hasError;
  final String? errorMessage;
  final model.Status? replyToStatus;
  final model.Status? editStatus;
  
  ComposeState({
    this.text = '',
    this.mediaFiles = const [],
    this.uploadedMedia = const [],
    this.isSensitive = false,
    this.contentWarning,
    this.visibility = model.Visibility.public,
    this.isSubmitting = false,
    this.hasError = false,
    this.errorMessage,
    this.replyToStatus,
    this.editStatus,
  });
  
  ComposeState copyWith({
    String? text,
    List<File>? mediaFiles,
    List<model.MediaAttachment>? uploadedMedia,
    bool? isSensitive,
    String? contentWarning,
    model.Visibility? visibility,
    bool? isSubmitting,
    bool? hasError,
    String? errorMessage,
    model.Status? replyToStatus,
    model.Status? editStatus,
  }) {
    return ComposeState(
      text: text ?? this.text,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      uploadedMedia: uploadedMedia ?? this.uploadedMedia,
      isSensitive: isSensitive ?? this.isSensitive,
      contentWarning: contentWarning ?? this.contentWarning,
      visibility: visibility ?? this.visibility,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      replyToStatus: replyToStatus ?? this.replyToStatus,
      editStatus: editStatus ?? this.editStatus,
    );
  }
  
  bool get isEditing => editStatus != null;
  bool get isReplying => replyToStatus != null && !isEditing;
  bool get hasMedia => mediaFiles.isNotEmpty || uploadedMedia.isNotEmpty;
  bool get canSubmit => text.isNotEmpty || hasMedia;
  bool get showContentWarning => contentWarning != null;
  int get remainingCharacters => 500 - text.length;
  bool get isOverCharacterLimit => remainingCharacters < 0;
}

/// Notifier for the compose screen
class ComposeNotifier extends StateNotifier<ComposeState> {
  final timelineService;
  final mediaService;
  final String? domain;
  
  ComposeNotifier({
    required this.timelineService,
    required this.mediaService,
    this.domain,
    model.Status? replyToStatus,
    model.Status? editStatus,
  }) : super(ComposeState(
          replyToStatus: replyToStatus,
          editStatus: editStatus,
          text: editStatus?.content ?? '',
          contentWarning: editStatus?.spoilerText,
          isSensitive: editStatus?.sensitive ?? false,
          visibility: editStatus?.visibility ?? model.Visibility.public,
          uploadedMedia: editStatus?.mediaAttachments ?? [],
        ));
  
  /// Update the post text
  void updateText(String text) {
    state = state.copyWith(
      text: text,
      hasError: false,
      errorMessage: null,
    );
  }
  
  /// Toggle content warning
  void toggleContentWarning() {
    state = state.copyWith(
      contentWarning: state.showContentWarning ? null : '',
    );
  }
  
  /// Update content warning text
  void updateContentWarning(String text) {
    state = state.copyWith(
      contentWarning: text,
    );
  }
  
  /// Toggle sensitive content
  void toggleSensitive() {
    state = state.copyWith(
      isSensitive: !state.isSensitive,
    );
  }
  
  /// Set visibility
  void setVisibility(model.Visibility visibility) {
    state = state.copyWith(
      visibility: visibility,
    );
  }
  
  /// Add media from gallery
  Future<void> addMediaFromGallery() async {
    if (state.mediaFiles.length + state.uploadedMedia.length >= 4) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Maximum of 4 media attachments allowed',
      );
      return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      state = state.copyWith(
        mediaFiles: [...state.mediaFiles, file],
        hasError: false,
        errorMessage: null,
      );
    }
  }
  
  /// Add media from camera
  Future<void> addMediaFromCamera() async {
    if (state.mediaFiles.length + state.uploadedMedia.length >= 4) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Maximum of 4 media attachments allowed',
      );
      return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      state = state.copyWith(
        mediaFiles: [...state.mediaFiles, file],
        hasError: false,
        errorMessage: null,
      );
    }
  }
  
  /// Remove media file
  void removeMediaFile(int index) {
    final mediaFiles = List<File>.from(state.mediaFiles);
    mediaFiles.removeAt(index);
    
    state = state.copyWith(
      mediaFiles: mediaFiles,
    );
  }
  
  /// Remove uploaded media
  void removeUploadedMedia(int index) {
    final uploadedMedia = List<model.MediaAttachment>.from(state.uploadedMedia);
    uploadedMedia.removeAt(index);
    
    state = state.copyWith(
      uploadedMedia: uploadedMedia,
    );
  }
  
  /// Upload media files
  Future<bool> _uploadMediaFiles() async {
    if (domain == null || state.mediaFiles.isEmpty) return true;
    
    try {
      final uploadedMedia = List<model.MediaAttachment>.from(state.uploadedMedia);
      
      for (final file in state.mediaFiles) {
        final media = await mediaService.uploadMedia(
          domain!,
          file: file,
        );
        
        uploadedMedia.add(media);
      }
      
      state = state.copyWith(
        uploadedMedia: uploadedMedia,
        mediaFiles: [],
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        hasError: true,
        errorMessage: 'Failed to upload media: $e',
      );
      
      return false;
    }
  }
  
  /// Submit the post
  Future<bool> submitPost() async {
    if (domain == null) return false;
    
    if (state.text.isEmpty && !state.hasMedia) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Post cannot be empty',
      );
      return false;
    }
    
    if (state.isOverCharacterLimit) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Post exceeds character limit',
      );
      return false;
    }
    
    state = state.copyWith(
      isSubmitting: true,
      hasError: false,
      errorMessage: null,
    );
    
    // Upload any pending media files
    if (state.mediaFiles.isNotEmpty) {
      final success = await _uploadMediaFiles();
      if (!success) return false;
    }
    
    try {
      if (state.isEditing) {
        // TODO: Implement edit post when API is available
        // For now, just simulate success
        await Future.delayed(const Duration(seconds: 1));
        
        state = state.copyWith(
          isSubmitting: false,
        );
        
        return true;
      } else {
        // Create new post
        await timelineService.createStatus(
          domain!,
          status: state.text,
          inReplyToId: state.replyToStatus?.id,
          mediaIds: state.uploadedMedia.map((media) => media.id).toList(),
          sensitive: state.isSensitive || state.showContentWarning,
          spoilerText: state.contentWarning,
          visibility: state.visibility,
        );
        
        state = state.copyWith(
          isSubmitting: false,
        );
        
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        hasError: true,
        errorMessage: 'Failed to submit post: $e',
      );
      
      return false;
    }
  }
}

/// Screen for composing a new post or editing an existing one
class ComposeScreen extends ConsumerStatefulWidget {
  /// The status to reply to
  final model.Status? replyToStatus;
  
  /// The status to edit
  final model.Status? editStatus;
  
  /// Constructor
  const ComposeScreen({
    super.key,
    this.replyToStatus,
    this.editStatus,
  });

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  late TextEditingController _textController;
  late TextEditingController _contentWarningController;
  late FocusNode _textFocusNode;
  
  @override
  void initState() {
    super.initState();
    
    // Create a new provider instance with the reply or edit status
    ProviderContainer().read(composeProvider.notifier);
    
    _textController = TextEditingController();
    _contentWarningController = TextEditingController();
    _textFocusNode = FocusNode();
    
    // Focus the text field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _contentWarningController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(composeProvider);
    final composeNotifier = ref.read(composeProvider.notifier);
    final activeAccount = ref.watch(activeAccountProvider);
    
    // Update controllers when state changes
    if (_textController.text != composeState.text) {
      _textController.text = composeState.text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    
    if (composeState.showContentWarning && 
        _contentWarningController.text != composeState.contentWarning) {
      _contentWarningController.text = composeState.contentWarning ?? '';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(composeState.isEditing ? 'Edit Post' : composeState.isReplying ? 'Reply' : 'New Post'),
        actions: [
          TextButton(
            onPressed: composeState.canSubmit && !composeState.isSubmitting
                ? () async {
                    final success = await composeNotifier.submitPost();
                    if (success && mounted) {
                      context.pop();
                    }
                  }
                : null,
            child: composeState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('POST'),
          ),
        ],
      ),
      body: activeAccount == null
          ? const Center(
              child: Text('No active account selected'),
            )
          : Column(
              children: [
                // Error message
                if (composeState.hasError) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Text(
                      composeState.errorMessage ?? 'An error occurred',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                
                // Reply to status
                if (composeState.isReplying) ...[
                  _buildReplyingTo(context, composeState.replyToStatus!),
                ],
                
                // Content warning
                if (composeState.showContentWarning) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _contentWarningController,
                      decoration: const InputDecoration(
                        hintText: 'Content warning',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: composeNotifier.updateContentWarning,
                    ),
                  ),
                ],
                
                // Compose area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // User info and text field
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: activeAccount.avatar != null
                                  ? CachedNetworkImageProvider(activeAccount.avatar!)
                                  : null,
                              child: activeAccount.avatar == null
                                  ? Text(activeAccount.displayName[0])
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            
                            // Text field
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'What\'s on your mind?',
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                                onChanged: composeNotifier.updateText,
                              ),
                            ),
                          ],
                        ),
                        
                        // Media preview
                        if (composeState.hasMedia) ...[
                          const SizedBox(height: 16),
                          _buildMediaPreview(context, composeState, composeNotifier),
                        ],
                        
                        const Spacer(),
                        
                        // Character count
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${composeState.remainingCharacters}',
                            style: TextStyle(
                              color: composeState.isOverCharacterLimit
                                  ? Colors.red
                                  : composeState.remainingCharacters < 20
                                      ? Colors.orange
                                      : Colors.grey,
                              fontWeight: composeState.isOverCharacterLimit
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom toolbar
                _buildBottomToolbar(context, composeState, composeNotifier),
              ],
            ),
    );
  }
  
  /// Build the replying to widget
  Widget _buildReplyingTo(BuildContext context, model.Status status) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: 'Replying to ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: status.account.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the media preview
  Widget _buildMediaPreview(
    BuildContext context,
    ComposeState state,
    ComposeNotifier notifier,
  ) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Uploaded media
          ...state.uploadedMedia.asMap().entries.map((entry) {
            final index = entry.key;
            final media = entry.value;
            
            return _buildMediaItem(
              context,
              media.previewUrl ?? media.url,
              () => notifier.removeUploadedMedia(index),
              isNetwork: true,
            );
          }),
          
          // Local media files
          ...state.mediaFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            
            return _buildMediaItem(
              context,
              file.path,
              () => notifier.removeMediaFile(index),
              isNetwork: false,
            );
          }),
        ],
      ),
    );
  }
  
  /// Build a media item
  Widget _buildMediaItem(
    BuildContext context,
    String path,
    VoidCallback onRemove,
    {bool isNetwork = false}
  ) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isNetwork
                ? CachedNetworkImage(
                    imageUrl: path,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                  ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the bottom toolbar
  Widget _buildBottomToolbar(
    BuildContext context,
    ComposeState state,
    ComposeNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Media button
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: state.mediaFiles.length + state.uploadedMedia.length < 4
                ? () {
                    _showMediaPickerDialog(context, notifier);
                  }
                : null,
          ),
          
          // Poll button (not implemented)
          IconButton(
            icon: const Icon(Icons.poll),
            onPressed: null, // TODO: Implement polls
          ),
          
          // Content warning button
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: state.showContentWarning ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: notifier.toggleContentWarning,
          ),
          
          // Sensitive content button
          IconButton(
            icon: Icon(
              Icons.visibility_off,
              color: state.isSensitive ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: notifier.toggleSensitive,
          ),
          
          const Spacer(),
          
          // Visibility dropdown
          DropdownButton<model.Visibility>(
            value: state.visibility,
            onChanged: (value) {
              if (value != null) {
                notifier.setVisibility(value);
              }
            },
            icon: _getVisibilityIcon(state.visibility),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: model.Visibility.public,
                child: Row(
                  children: [
                    const Icon(Icons.public),
                    const SizedBox(width: 8),
                    const Text('Public'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: model.Visibility.unlisted,
                child: Row(
                  children: [
                    const Icon(Icons.lock_open),
                    const SizedBox(width: 8),
                    const Text('Unlisted'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: model.Visibility.private,
                child: Row(
                  children: [
                    const Icon(Icons.lock),
                    const SizedBox(width: 8),
                    const Text('Followers only'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: model.Visibility.direct,
                child: Row(
                  children: [
                    const Icon(Icons.mail),
                    const SizedBox(width: 8),
                    const Text('Direct'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Get the visibility icon
  Widget _getVisibilityIcon(model.Visibility visibility) {
    switch (visibility) {
      case model.Visibility.public:
        return const Icon(Icons.public);
      case model.Visibility.unlisted:
        return const Icon(Icons.lock_open);
      case model.Visibility.private:
        return const Icon(Icons.lock);
      case model.Visibility.direct:
        return const Icon(Icons.mail);
      default:
        return const Icon(Icons.public); // Default case to avoid null return
    }
  }
  
  /// Show media picker dialog
  void _showMediaPickerDialog(BuildContext context, ComposeNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  notifier.addMediaFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  notifier.addMediaFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
