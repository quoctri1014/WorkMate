import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/chat_service.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = context.read<ProfileViewModel>().user;
    if (user != null) {
      _chatService.initSocket(user.id, (data) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage.fromMap(data));
          });
          _scrollToBottom();
        }
      });
      _loadHistory(user.id);
    }
  }

  void _loadHistory(int userId) async {
    final history = await _chatService.getChatHistory(userId);
    if (mounted) {
      setState(() {
        _messages = history.map((e) => ChatMessage.fromMap(e)).toList();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;

    _textController.clear();

    if (_tabController.index == 0) {
      // AI Mode
      setState(() {
        _messages.add(ChatMessage(
          id: 0,
          senderId: user.id,
          message: text,
          createdAt: DateTime.now(),
        ));
        _isLoadingAI = true;
      });
      _scrollToBottom();

      try {
        final res = await _chatService.askAI(user.id, text);
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              id: 0,
              senderId: 0, // Bot
              message: res['reply'],
              isAi: true,
              createdAt: DateTime.now(),
            ));
            _isLoadingAI = false;
          });
          _scrollToBottom();
          
          if (res['suggestAdmin'] == true) {
            _showAdminSuggestion();
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingAI = false);
      }
    } else {
      // Admin Mode
      _chatService.sendMessage(user.id, null, text);
    }
  }

  void _showAdminSuggestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('AI không thể giải quyết? Hãy trò chuyện với Admin.'),
        action: SnackBarAction(
          label: 'CHAT NGAY',
          textColor: Colors.white,
          onPressed: () => _tabController.animateTo(1),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trợ lý WorkMate', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'TRỢ LÝ AI', icon: Icon(Icons.smart_toy_rounded)),
            Tab(text: 'QUẢN TRỊ VIÊN', icon: Icon(Icons.admin_panel_settings_rounded)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoadingAI ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[i];
                final isMe = msg.senderId == context.read<ProfileViewModel>().user?.id;
                
                // Lọc tin nhắn theo Tab (AI messages only in AI tab, Admin messages only in Admin tab)
                // Hoặc cho phép xem lịch sử chung nhưng đánh dấu.
                // Theo yêu cầu User: "User chuyển sang tab Chat Admin" -> Tách biệt.
                
                if (_tabController.index == 0 && !msg.isAi && msg.receiverId != null) return const SizedBox();
                if (_tabController.index == 1 && msg.isAi) return const SizedBox();
                // Admin chat logic: receiverId is NULL for broadcast to admins or specific admin ID.
                // In this simplified version, if not AI and not from Me to Me, it's admin chat.
                
                return _buildMessageBubble(msg, isMe);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isMe 
            ? AppColors.primary 
            : (msg.isAi ? Colors.amber.shade50 : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isAi)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('AI WORKMATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber)),
                  ],
                ),
              ),
            Text(
              msg.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 15, 
        bottom: MediaQuery.of(context).padding.bottom + 15
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi tại đây...',
                  border: InputNavigator.none,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
