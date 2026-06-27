import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isPosting = false;
  bool _isComposerVisible = false;
  String _authorName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['name'] != null) {
        setState(() {
          _authorName = data['name'] as String;
        });
      }
    }
  }

  Future<void> _postThread() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and message.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to post.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('forums').add({
        'title': title,
        'message': message,
        'authorId': user.uid,
        'authorName': _authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'commentsCount': 0,
      });
      _titleController.clear();
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        _isComposerVisible = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to the forum.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _deleteThread(String threadId) async {
    try {
      final threadRef = FirebaseFirestore.instance.collection('forums').doc(threadId);
      final commentsRef = threadRef.collection('comments');

      final commentsSnap = await commentsRef.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in commentsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(threadRef);
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread deleted.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete thread: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editThread(String threadId, String currentTitle, String currentMessage) async {
    final titleController = TextEditingController(text: currentTitle);
    final messageController = TextEditingController(text: currentMessage);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit thread'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      final newTitle = titleController.text.trim();
      final newMessage = messageController.text.trim();
      if (newTitle.isEmpty || newMessage.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and message cannot be empty.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('forums').doc(threadId).update({
          'title': newTitle,
          'message': newMessage,
          'editedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread updated.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update thread: $e'), backgroundColor: Colors.red),
        );
      } finally {
        titleController.dispose();
        messageController.dispose();
      }
    } else {
      titleController.dispose();
      messageController.dispose();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
        title: const Text(
          'Forum',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6200EE),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Forum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Share ideas, ask questions, and connect with other students.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isComposerVisible = !_isComposerVisible;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(_isComposerVisible ? Icons.close : Icons.edit_outlined),
                      label: Text(
                        _isComposerVisible
                            ? 'Close message form'
                            : 'Please write your message forum',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isComposerVisible)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send a message',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Post title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Your message',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPosting ? null : _postThread,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6200EE),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  _isPosting ? 'Sending...' : 'Send Message',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('forums')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Failed to load forum: ${snapshot.error}'),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Forum is empty. Send a message and invite friends to comment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            return _buildForumCard(
                              title: data['title'] as String? ?? 'No title',
                              message: data['message'] as String? ?? '',
                              author: data['authorName'] as String? ?? 'Unknown',
                              authorId: data['authorId'] as String? ?? '',
                              docId: doc.id,
                              time: _formatTimestamp(data['createdAt'] as Timestamp?),
                              comments: (data['commentsCount'] as int?) ?? 0,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ForumThreadPage(
                                      threadId: doc.id,
                                      threadData: data,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} mins ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  Widget _buildForumCard({
    required String title,
    required String message,
    required String author,
    required String authorId,
    required String docId,
    required String time,
    required int comments,
    required VoidCallback onTap,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF6200EE),
                  child: Icon(Icons.forum_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$author • $time',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (currentUserId != null && currentUserId == authorId) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    onPressed: () async {
                      await _editThread(docId, title, message);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete thread'),
                          content: const Text('Are you sure you want to delete this thread? This will remove all comments.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _deleteThread(docId);
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[800]),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '$comments comments',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForumThreadPage extends StatefulWidget {
  final String threadId;
  final Map<String, dynamic> threadData;

  const ForumThreadPage({super.key, required this.threadId, required this.threadData});

  @override
  State<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends State<ForumThreadPage> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  String _commentAuthor = 'Student';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['name'] != null) {
        setState(() {
          _commentAuthor = data['name'] as String;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to comment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    final commentRef = FirebaseFirestore.instance
        .collection('forums')
        .doc(widget.threadId)
        .collection('comments');

    final threadRef = FirebaseFirestore.instance.collection('forums').doc(widget.threadId);

    try {
      await commentRef.add({
        'text': commentText,
        'authorId': user.uid,
        'authorName': _commentAuthor,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await threadRef.update({
        'commentsCount': FieldValue.increment(1),
      });
      _commentController.clear();

      await NotificationService.addNotification(
        userId: widget.threadData['authorId']?.toString() ?? '',
        title: 'New comment on your post',
        body: '$_commentAuthor commented on your forum post.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection('forums')
          .doc(widget.threadId)
          .collection('comments')
          .doc(commentId);

      final threadRef = FirebaseFirestore.instance.collection('forums').doc(widget.threadId);

      final batch = FirebaseFirestore.instance.batch();
      batch.delete(commentRef);
      batch.update(threadRef, {'commentsCount': FieldValue.increment(-1)});
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editComment(String commentId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Comment'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      final newText = controller.text.trim();
      if (newText.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment cannot be empty.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('forums')
            .doc(widget.threadId)
            .collection('comments')
            .doc(commentId)
            .update({'text': newText, 'editedAt': FieldValue.serverTimestamp()});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update comment: $e'), backgroundColor: Colors.red),
        );
      } finally {
        controller.dispose();
      }
    } else {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.threadData['title'] as String? ?? 'Forum Thread';
    final message = widget.threadData['message'] as String? ?? '';
    final author = widget.threadData['authorName'] as String? ?? 'Unknown';
    final timestamp = widget.threadData['createdAt'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        title: const Text('Discussion'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$author • ${_formatTimestamp(timestamp)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('forums')
                  .doc(widget.threadId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Unable to load comments: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be the first to respond.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return _buildCommentCard(
                      commentId: doc.id,
                      author: data['authorName'] as String? ?? 'Unknown',
                      authorId: data['authorId'] as String? ?? '',
                      text: data['text'] as String? ?? '',
                      time: _formatTimestamp(data['createdAt'] as Timestamp?),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSubmittingComment ? null : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      _isSubmittingComment ? 'Sending' : 'Post',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard({
    required String commentId,
    required String author,
    required String authorId,
    required String text,
    required String time,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6200EE),
                child: Text(
                  author.isEmpty ? 'S' : author[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (currentUserId != null && currentUserId == authorId) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  onPressed: () async {
                    await _editComment(commentId, text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete comment'),
                        content: const Text('Are you sure you want to delete this comment?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _deleteComment(commentId);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} mins ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}
