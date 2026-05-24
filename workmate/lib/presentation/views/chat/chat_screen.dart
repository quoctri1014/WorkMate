import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:workmate/data/repositories/chat_service.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/data/models/models.dart';
import 'colleague_chat_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _aiMessages    = [];
  List<Map<String, dynamic>> _adminMessages = [];
  bool _isTyping = false;
  int _currentTab = 0;

  final List<Color> tabColors = [
    const Color(0xFF4F46E5),
    const Color(0xFF4F46E5),
    const Color(0xFF4F46E5),
  ];

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() => _currentTab = _tabController.index));
    
    final user = context.read<ProfileViewModel>().user;
    if (user != null) {
      _initWebSocket(user);
      _loadHistories(user.id);
    }
  }

  void _loadHistories(int userId) async {
    final aiHistory = await _chatService.getAIHistory(userId);
    final adminHistory = await _chatService.getAdminHistory(userId);
    
    if (mounted) {
      setState(() {
        _aiMessages = aiHistory.map((e) {
          final isUser = e['sender_id'] == userId && e['is_ai'] == false;
          return {
            'id': e['id'],
            'role': isUser ? 'user' : 'bot',
            'text': e['message'],
            'message_type': e['message_type'] ?? 'text',
            'file_url': e['file_url'],
            'source': 'rule',
            'time': _formatTimeStr(e['created_at']),
            'is_recalled': e['is_recalled'] ?? false,
            'created_at': e['created_at'],
          };
        }).toList();

        _adminMessages = adminHistory.map((e) {
          final isUser = e['sender_id'] == userId;
          return {
            'id': e['id'],
            'role': isUser ? 'user' : 'admin',
            'text': e['message'],
            'message_type': e['message_type'] ?? 'text',
            'file_url': e['file_url'],
            'time': _formatTimeStr(e['created_at']),
            'is_recalled': e['is_recalled'] ?? false,
            'created_at': e['created_at'],
          };
        }).toList();

        if (_aiMessages.isEmpty) _addWelcomeMessage();
      });
      _scrollToBottom();
    }
  }

  void _addWelcomeMessage() {
    _aiMessages.add({
      'role': 'bot',
      'text': 'Chào bạn! 👋 Tôi là trợ lý AI tự động. Tôi có thể giúp bạn về chấm công, lương, phép và nhiều hơn nữa.',
      'message_type': 'text',
      'time': _formatTime(DateTime.now()),
      'suggestions': ['Hôm nay chấm công chưa?', 'Còn mấy ngày phép?'],
    });
  }

  void _initWebSocket(UserModel user) {
    _chatService.initSocket(user.id, (data) {
      if (mounted) {
        if (data['sender_id'] == user.id) {
          // Update the last message with real ID from DB
          setState(() {
            if (data['chat_type'] == 'admin') {
               final idx = _adminMessages.indexWhere((m) => m['id'] == null && m['text'] == data['message']);
               if (idx != -1) _adminMessages[idx]['id'] = data['id'];
            }
          });
          return;
        }
        setState(() {
          _adminMessages.add({
            'id': data['id'],
            'role': 'admin',
            'text': data['message'],
            'message_type': data['message_type'] ?? 'text',
            'file_url': data['file_url'],
            'time': _formatTime(DateTime.now()),
            'is_recalled': data['is_recalled'] ?? false,
            'created_at': data['created_at'],
          });
        });
        if (_currentTab == 1) _scrollToBottom();
      }
    });

    _chatService.socket.on('message_recalled_${user.id}', (data) {
      if (mounted) {
        setState(() {
          _updateMessageRecalled(_aiMessages, data);
          _updateMessageRecalled(_adminMessages, data);
        });
      }
    });

    _chatService.socket.on('message_recalled_admin', (data) {
      if (mounted) {
        setState(() {
          _updateMessageRecalled(_adminMessages, data);
        });
      }
    });

    _chatService.socket.on('error_message', (data) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi không xác định')));
    });
  }

  void _updateMessageRecalled(List<Map<String, dynamic>> list, dynamic data) {
    final idx = list.indexWhere((m) => m['id'] == data['id']);
    if (idx != -1) {
      list[idx]['is_recalled'] = true;
      list[idx]['text'] = 'Tin nhắn đã được thu hồi';
    }
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  String _formatTimeStr(String? iso) {
    if (iso == null) return '';
    try {
      return _formatTime(DateTime.parse(iso).toLocal());
    } catch (e) {
      return '';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage({String? text, String type = 'text', String? fileUrl}) {
    final msg = text ?? _inputController.text.trim();
    if (msg.isEmpty && fileUrl == null) return;
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;

    if (_currentTab == 0) {
      if (type != 'text') {
        _aiMessages.add({'role': 'bot', 'text': 'AI chỉ hỗ trợ văn bản.', 'time': _formatTime(DateTime.now())});
      } else {
        _handleAISend(user.id, msg);
      }
    } else {
      _chatService.sendMessage(user.id, null, msg, chatType: 'admin', messageType: type, fileUrl: fileUrl);
      setState(() {
        _adminMessages.add({
          'id': null, // Temporary
          'role': 'user', 'text': msg, 'message_type': type, 'file_url': fileUrl, 'time': _formatTime(DateTime.now()),
          'created_at': DateTime.now().toIso8601String()
        });
      });
      if (text == null) _inputController.clear();
    }
    if (_showEmoji) setState(() => _showEmoji = false);
    _scrollToBottom();
  }

  void _handleAISend(int userId, String msg) async {
    setState(() {
      _aiMessages.add({'role': 'user', 'text': msg, 'time': _formatTime(DateTime.now())});
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();
    final response = await _chatService.askAI(userId, msg);
    if (mounted) {
      setState(() {
        _isTyping = false;
        _aiMessages.add({
          'id': response['id'],
          'role': 'bot', 'text': response['reply'], 'suggestions': List<String>.from(response['suggestions'] ?? []),
          'source': response['source'] ?? 'ai', 'time': _formatTime(DateTime.now()),
          'created_at': DateTime.now().toIso8601String()
        });
      });
      _scrollToBottom();
    }
  }

  Future<String?> _uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) return jsonDecode(await response.stream.bytesToString())['url'];
    } catch (e) { print(e); }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatView(_aiMessages, 0),
                _buildChatView(_adminMessages, 1),
                const ColleagueChatView(),
              ],
            ),
          ),
          if (_currentTab == 0) _buildSuggestions(),
          if (_currentTab != 2 && _showEmoji) 
            SizedBox(height: 250, child: EmojiPicker(
              onEmojiSelected: (_, emoji) => _inputController.text += emoji.emoji,
              config: const Config(),
            )),
          if (_currentTab != 2) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    // Tìm gợi ý từ tin nhắn bot cuối cùng có chứa suggestions
    List<String> suggestions = [];
    for (var i = _aiMessages.length - 1; i >= 0; i--) {
      if (_aiMessages[i]['role'] == 'bot' && _aiMessages[i]['suggestions'] != null) {
        suggestions = List<String>.from(_aiMessages[i]['suggestions']);
        break;
      }
    }

    // Gợi ý mặc định nếu không có gợi ý từ tin nhắn cuối
    if (suggestions.isEmpty) {
      suggestions = ['Hôm nay chấm công chưa?', 'Đơn từ của tôi', 'Còn mấy ngày phép?'];
    }

    return Container(
      height: 50,
      color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor.withOpacity(0.5) : const Color(0xFFF0F2F5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0,
              pressElevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              label: Text(suggestions[i], style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.w500)),
              onPressed: () => _sendMessage(text: suggestions[i]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF4F46E5), width: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['AI Assistant', 'Admin Support', 'Đồng nghiệp'];
    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : const Color(0xFF1a1a2e),
      elevation: 0,
      leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
      title: Text(titles[_currentTab], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTabBar() {
    final labels = ['AI Bot', 'Admin', 'Đồng nghiệp'];
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : const Color(0xFF1a1a2e),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: GestureDetector(
            onTap: () => _tabController.animateTo(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _currentTab == i ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(labels[i], style: TextStyle(color: _currentTab == i ? Colors.white : Colors.white60, fontSize: 12))),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildChatView(List<Map<String, dynamic>> messages, int tabIndex) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: messages.length + (_isTyping && _currentTab == tabIndex ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (_isTyping && _currentTab == tabIndex && i == messages.length) return _buildTypingIndicator(tabIndex);
          return _buildMessageItem(messages[i], tabIndex);
        },
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg, int tabIndex) {
    final isUser = msg['role'] == 'user';
    final type = msg['message_type'] ?? 'text';
    final url = msg['file_url'];
    final color = tabColors[tabIndex];
    final isRecalled = msg['is_recalled'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              if (isUser && !isRecalled && msg['id'] != null) {
                _showRecallOption(msg);
              }
            },
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.2), child: Icon(tabIndex == 0 ? Icons.auto_awesome : Icons.support_agent, size: 14, color: color)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: (type == 'text' || isRecalled) ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: isUser ? (isRecalled ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]) : color) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: isRecalled ? Border.all(color: Colors.grey[400]!) : null,
                    ),
                    child: isRecalled 
                      ? Text('Tin nhắn đã được thu hồi', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13))
                      : _buildRichContent(type, msg['text'], url, isUser),
                  ),
                ),
              ],
            ),
          ),
          if (tabIndex == 0 && !isUser && (msg['suggestions'] as List?)?.isNotEmpty == true && !isRecalled)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: Wrap(spacing: 8, children: (msg['suggestions'] as List).map((s) => ActionChip(label: Text(s, style: TextStyle(fontSize: 12, color: color)), onPressed: () => _sendMessage(text: s))).toList()),
            ),
        ],
      ),
    );
  }

  void _showRecallOption(Map<String, dynamic> msg) {
    final sentAt = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(sentAt).inHours;

    if (diff >= 1) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.undo, color: Colors.red),
            title: const Text('Thu hồi tin nhắn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(ctx);
              _chatService.recallMessage(msg['id']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRichContent(String type, String? text, String? url, bool isMe) {
    String? fullUrl;
    if (url != null) {
      fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl.replaceAll('/api', '')}$url';
    }

    if (type == 'image' && fullUrl != null) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(fullUrl!)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), 
          child: Image.network(fullUrl, width: 200, errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.grey, size: 50))
        )
      );
    }
    
    if (type == 'video' && fullUrl != null) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(fullUrl!)),
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(Icons.play_circle_fill, size: 50, color: isMe ? Colors.white : Colors.blue),
          ),
        ),
      );
    }

    if (type == 'audio' && fullUrl != null) {
      return IconButton(
        icon: const Icon(Icons.play_circle), 
        color: isMe ? Colors.white : Colors.blue, 
        onPressed: () => _audioPlayer.play(UrlSource(fullUrl!))
      );
    }
    
    if (type == 'file' && fullUrl != null) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(fullUrl!), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(10), 
          child: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Icon(Icons.description, color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface), 
              const SizedBox(width: 8), 
              Flexible(child: Text(text ?? 'Tài liệu', style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, decoration: TextDecoration.underline)))
            ]
          )
        )
      );
    }

    return Text(text ?? '', style: TextStyle(color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)));
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: () => setState(() => _showEmoji = !_showEmoji)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showAttachOptions),
            Expanded(
              child: TextField(
                controller: _inputController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...', 
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  filled: true, 
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200], 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.red : Colors.grey),
              onPressed: _toggleRecording,
            ),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFF4F46E5)), onPressed: () => _sendMessage()),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(context: context, builder: (ctx) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.image), onPressed: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
        IconButton(icon: const Icon(Icons.camera_alt), onPressed: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
        IconButton(icon: const Icon(Icons.file_present), onPressed: () { Navigator.pop(ctx); _pickFile(); }),
      ],
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final url = await _uploadFile(File(image.path));
      if (url != null) _sendMessage(type: 'image', fileUrl: url);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles();
    if (res != null) {
      final url = await _uploadFile(File(res.files.single.path!));
      if (url != null) _sendMessage(text: res.files.single.name, type: 'file', fileUrl: url);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final url = await _uploadFile(File(path));
        if (url != null) _sendMessage(type: 'audio', fileUrl: url);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/m_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Widget _buildTypingIndicator(int tabIndex) => const Padding(padding: EdgeInsets.all(8), child: Text('Đang nhập...', style: TextStyle(fontSize: 12, color: Colors.grey)));

  @override
  void dispose() {
    _tabController.dispose(); _inputController.dispose(); _scrollController.dispose(); _chatService.dispose(); _recorder.dispose(); _audioPlayer.dispose();
    super.dispose();
  }
}
