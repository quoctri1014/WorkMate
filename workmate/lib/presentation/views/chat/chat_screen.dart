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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final user = context.read<ProfileViewModel>().user;
    if (user != null) {
      _chatService.initSocket(user.id, (data) {
        if (mounted) {
          final newMsg = ChatMessage.fromMap(data);
          setState(() {
            // Tránh trùng lặp tin nhắn nếu đã có ID này
            if (!_messages.any((m) => m.id != 0 && m.id == newMsg.id)) {
              _messages.add(newMsg);
            }
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
              id: DateTime.now().millisecondsSinceEpoch, // Tạm thời
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
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Trợ lý WorkMate', 
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 18)
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Online', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w700)),
              ],
            )
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, size: 16), SizedBox(width: 8), Text('TRỢ LÝ AI')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.headset_mic_rounded, size: 16), SizedBox(width: 8), Text('ADMIN')])),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://www.toptal.com/designers/subtlepatterns/patterns/double-bubble.png'),
                  opacity: 0.03,
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                itemCount: _messages.length + (_isLoadingAI ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return _buildLoadingBubble();
                  }
                  final msg = _messages[i];
                  final isMe = msg.senderId == context.read<ProfileViewModel>().user?.id;
                  
                  if (_tabController.index == 0 && !msg.isAi && msg.receiverId != null) return const SizedBox();
                  if (_tabController.index == 1 && msg.isAi) return const SizedBox();
                  
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isMe 
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withBlue(180)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  )
                : null,
              color: isMe ? null : (msg.isAi ? Colors.white : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isMe ? 22 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
              border: isMe ? null : Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.isAi)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text('AI WORKMATE', 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade700, letterSpacing: 1)
                        ),
                      ],
                    ),
                  ),
                Text(
                  msg.message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: Text(
              isMe ? 'Bạn • 19:48' : (msg.isAi ? 'AI • Vừa xong' : 'Admin • 19:49'), // Tạm thời hardcode time
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber.shade600),
            ),
            const SizedBox(width: 12),
            Text('AI đang suy nghĩ...', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 20, 
        bottom: MediaQuery.of(context).padding.bottom + 20
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _tabController.index == 0 ? 'Hỏi AI bất cứ điều gì...' : 'Nhắn cho Admin...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withBlue(200)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                ]
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
