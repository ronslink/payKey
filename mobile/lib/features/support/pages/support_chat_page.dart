import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_message.dart';
import '../models/support_ticket.dart';
import '../presentation/providers/support_provider.dart';

class SupportChatPage extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportChatPage({super.key, required this.ticketId});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(currentTicketProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (ticket) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          
          return Column(
            children: [
              _buildTicketInfo(ticket),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final msg = ticket.messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
              if (ticket.status != TicketStatus.CLOSED && ticket.status != TicketStatus.RESOLVED) 
                _buildMessageInput(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketInfo(SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildStatusBadge(ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(ticket.description, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge(TicketStatus status) {
    Color color;
    switch (status) {
      case TicketStatus.OPEN: color = Colors.red; break;
      case TicketStatus.IN_PROGRESS: color = Colors.blue; break;
      case TicketStatus.RESOLVED: color = Colors.green; break;
      case TicketStatus.CLOSED: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, color: color, fontWeight: 'bold'),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final isAdmin = message.senderRole == SenderRole.ADMIN;
    
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: MediaQuery.of(context).size.width * 0.75,
        child: Row(
          mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isAdmin) ...[
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.support_agent, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            
            Expanded(
              child: Column(
                crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAdmin 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAdmin ? 4 : 16),
                        bottomRight: Radius.circular(isAdmin ? 16 : 4),
                      ),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        color: isAdmin ? null : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            if (!isAdmin) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Consumer(
            builder: (context, ref, _) {
              final isSending = ref.watch(supportNotifierProvider).isLoading;
              
              return CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: isSending 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: isSending ? null : _sendMessage,
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    FocusScope.of(context).unfocus();
    
    try {
      await ref.read(supportNotifierProvider.notifier).addReply(widget.ticketId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to send message: $e')),
        );
        _messageController.text = text; // restore text
      }
    }
  }
}
