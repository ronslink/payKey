import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/support_message.dart';
import '../models/support_ticket.dart';
import '../presentation/providers/support_provider.dart';
import '../../../../core/services/notification_service.dart';

// ── Status/category colour helpers (kept local so no cross-import needed) ────
const _statusColors = {
  TicketStatus.OPEN: Color(0xFFEF4444),
  TicketStatus.IN_PROGRESS: Color(0xFF3B82F6),
  TicketStatus.RESOLVED: Color(0xFF22C55E),
  TicketStatus.CLOSED: Color(0xFF94A3B8),
};

const _statusLabels = {
  TicketStatus.OPEN: 'Open',
  TicketStatus.IN_PROGRESS: 'In Progress',
  TicketStatus.RESOLVED: 'Resolved',
  TicketStatus.CLOSED: 'Closed',
};

// ── SupportChatPage ──────────────────────────────────────────────────────────
class SupportChatPage extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportChatPage({super.key, required this.ticketId});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<RemoteMessage>? _notifSubscription;

  // Subtle header-collapse animation
  late final AnimationController _headerController;
  late final Animation<double> _headerHeight;
  bool _headerExpanded = true;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _headerHeight = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    );

    // Collapse header when user scrolls down
    _scrollController.addListener(() {
      final atTop = _scrollController.offset < 20;
      if (atTop && !_headerExpanded) {
        setState(() => _headerExpanded = true);
        _headerController.forward();
      } else if (!atTop && _headerExpanded) {
        setState(() => _headerExpanded = false);
        _headerController.reverse();
      }
    });

    // When a SUPPORT_REPLY push arrives while this chat is open, refresh silently
    _notifSubscription = NotificationService().onMessage.listen((message) {
      if (message.data['type'] == 'SUPPORT_REPLY' &&
          message.data['ticketId'] == widget.ticketId) {
        ref.invalidate(currentTicketProvider(widget.ticketId));
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(currentTicketProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(ticketAsync),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
        data: (ticket) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom(animated: false));
          return Column(
            children: [
              // Collapsible ticket info header
              _CollapsibleTicketHeader(
                ticket: ticket,
                animation: _headerHeight,
              ),
              // Message list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(currentTicketProvider(widget.ticketId)),
                  child: ticket.messages.isEmpty
                      ? _buildEmptyMessages()
                      : _buildMessageList(ticket),
                ),
              ),
              // Input
              if (ticket.status != TicketStatus.CLOSED &&
                  ticket.status != TicketStatus.RESOLVED)
                _buildMessageInput(context),

              // Closed/resolved notice
              if (ticket.status == TicketStatus.CLOSED ||
                  ticket.status == TicketStatus.RESOLVED)
                _buildClosedNotice(ticket.status),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AsyncValue<SupportTicket> ticketAsync) {
    return AppBar(
      title: ticketAsync.when(
        loading: () => const Text('Support Chat'),
        error: (_, __) => const Text('Support Chat'),
        data: (ticket) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Chat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '#${ticket.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(currentTicketProvider(widget.ticketId)),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load conversation',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(currentTicketProvider(widget.ticketId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty messages placeholder ─────────────────────────────────────────────
  Widget _buildEmptyMessages() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 52, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 20),
              const Text(
                'No messages yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start the conversation below',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────
  Widget _buildMessageList(SupportTicket ticket) {
    // Group by date for date separators
    final messages = ticket.messages;
    final items = <_ChatItem>[];
    DateTime? lastDate;
    for (final msg in messages) {
      final msgDate =
          DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (lastDate == null || msgDate != lastDate) {
        items.add(_ChatItem.dateSeparator(msgDate));
        lastDate = msgDate;
      }
      items.add(_ChatItem.message(msg));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDateSeparator) {
          return _DateSeparator(date: item.date!);
        }
        return _MessageBubble(message: item.message!);
      },
    );
  }

  // ── Message input ──────────────────────────────────────────────────────────
  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 10),
          Consumer(
            builder: (context, ref, _) {
              final isSending =
                  ref.watch(supportNotifierProvider).isLoading;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSending
                      ? Colors.grey.shade300
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                  onPressed: isSending ? null : _sendMessage,
                  padding: const EdgeInsets.all(12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Closed notice ──────────────────────────────────────────────────────────
  Widget _buildClosedNotice(TicketStatus status) {
    final isResolved = status == TicketStatus.RESOLVED;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isResolved
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResolved
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isResolved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: isResolved
                ? const Color(0xFF22C55E)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            isResolved
                ? 'This ticket has been resolved'
                : 'This ticket is closed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isResolved
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    try {
      await ref
          .read(supportNotifierProvider.notifier)
          .addReply(widget.ticketId, text);
      ref.invalidate(currentTicketProvider(widget.ticketId));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _messageController.text = text; // restore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ── _ChatItem ─────────────────────────────────────────────────────────────────
class _ChatItem {
  final bool isDateSeparator;
  final DateTime? date;
  final SupportMessage? message;

  const _ChatItem._({required this.isDateSeparator, this.date, this.message});

  factory _ChatItem.dateSeparator(DateTime date) =>
      _ChatItem._(isDateSeparator: true, date: date);

  factory _ChatItem.message(SupportMessage msg) =>
      _ChatItem._(isDateSeparator: false, message: msg);
}

// ── _DateSeparator ────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == yesterday) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }
}

// ── _MessageBubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.senderRole == SenderRole.ADMIN;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Column(
                crossAxisAlignment: isAdmin
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'Support Team',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.white : primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isAdmin ? 4 : 18),
                        bottomRight: Radius.circular(isAdmin ? 18 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isAdmin ? Colors.black : primaryColor)
                              .withValues(alpha: isAdmin ? 0.05 : 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isAdmin ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isAdmin ? 4 : 0,
                        right: isAdmin ? 0 : 4),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_rounded, size: 16, color: primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── _CollapsibleTicketHeader ──────────────────────────────────────────────────
class _CollapsibleTicketHeader extends StatelessWidget {
  const _CollapsibleTicketHeader({
    required this.ticket,
    required this.animation,
  });

  final SupportTicket ticket;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[ticket.status] ?? const Color(0xFF94A3B8);
    final statusLabel = _statusLabels[ticket.status] ?? ticket.status.name;

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (ticket.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
