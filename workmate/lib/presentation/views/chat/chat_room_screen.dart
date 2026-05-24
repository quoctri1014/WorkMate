import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final String chatType;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
    required this.chatType,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  late IO.Socket _socket;
  
  // Rich chat variables
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _showEmoji = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initSocket();
  }

  Future<void> _fetchMessages() async {
    final convId = widget.conversation['id'];
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/conversations/$convId/messages'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _messages = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
            _loading = false;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) setState(() => _loading = false);
        print('❌ Lỗi lấy tin nhắn: ${res.body}');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      print('❌ Ngoại lệ lấy tin nhắn: $e');
    }
  }

  void _initSocket() {
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;
    
    _socket = IO.io(ApiService.baseHost, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());
      
    _socket.connect();
    _socket.onConnect((_) {
      _socket.emit('register', user.id);
    });

    final convId = widget.conversation['id'];
    _socket.on('receive_message_conv_$convId', (data) {
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    });

    _socket.on('message_recalled_conv_$convId', (data) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == data['id']);
          if (idx != -1) {
            _messages[idx]['is_recalled'] = true;
            _messages[idx]['message'] = 'Tin nhắn đã được thu hồi';
          }
        });
      }
    });

    _socket.on('error_message', (data) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi không xác định')));
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 500, // Thêm khoảng bù trừ
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? text, String type = 'text', String? fileUrl}) {
    final messageText = text ?? _inputCtrl.text.trim();
    if (messageText.isEmpty && fileUrl == null) return;
    
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;

    final convId = widget.conversation['id'];
    final data = {
      'sender_id': user.id,
      'message': messageText,
      'is_ai': false,
      'chat_type': widget.chatType,
      'conversation_id': convId,
      'message_type': type,
      'file_url': fileUrl,
    };

    _socket.emit('send_message', data);
    if (text == null) _inputCtrl.clear();
    if (_showEmoji) setState(() => _showEmoji = false);
  }

  Future<String?> _uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var resData = await response.stream.bytesToString();
        return jsonDecode(resData)['url'];
      }
    } catch (e) {
      print('❌ Upload error: $e');
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final url = await _uploadFile(File(image.path));
      if (url != null) _sendMessage(type: 'image', fileUrl: url);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final url = await _uploadFile(File(result.files.single.path!));
      if (url != null) _sendMessage(text: result.files.single.name, type: 'file', fileUrl: url);
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
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
      }
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    final localDt = dt.toLocal();
    return '${localDt.hour.toString().padLeft(2,'0')}:${localDt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<ProfileViewModel>().user;
    final title = widget.conversation['display_name'] ?? widget.conversation['name'] ?? 'Đồng nghiệp';
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isMe = m['sender_id'] == user?.id;
                    return _buildMessageBubble(m, isMe);
                  },
                ),
          ),
          if (_showEmoji) 
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _inputCtrl.text += emoji.emoji;
                },
                config: const Config(),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, bool isMe) {
    final isGroup = widget.chatType == 'group';
    final type = m['message_type'] ?? 'text';
    final url = m['file_url'];
    final isRecalled = m['is_recalled'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isGroup && !isMe) ...[
            Text(m['sender_name'] ?? 'Đồng nghiệp', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
          ],
          GestureDetector(
            onLongPress: () {
              if (isMe && !isRecalled && m['id'] != null) {
                _showRecallOption(m);
              }
            },
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe && isGroup)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.2), shape: BoxShape.circle),
                    child: Center(child: Text((m['sender_name'] ?? '?')[0], style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
                  ),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: (type == 'text' || isRecalled) ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: isMe ? (isRecalled ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]) : const Color(0xFF4F46E5)) : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                      border: isRecalled ? Border.all(color: Colors.grey[400]!) : (Theme.of(context).brightness == Brightness.dark && !isMe ? Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)) : null),
                    ),
                    child: isRecalled
                        ? Text('Tin nhắn đã được thu hồi', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13))
                        : _buildRichContent(type, m['message'], url, isMe),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(_formatTime(m['created_at']), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildRichContent(String type, String? text, String? url, bool isMe) {
    if (type == 'image' && url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
      );
    } else if (type == 'audio' && url != null) {
      return IconButton(
        icon: const Icon(Icons.play_circle_fill, size: 40),
        color: isMe ? Colors.white : const Color(0xFF4F46E5),
        onPressed: () => _audioPlayer.play(UrlSource(url)),
      );
    } else if (type == 'file' && url != null) {
      return InkWell(
        onTap: () {}, // Download logic
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: isMe ? Colors.white : const Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Flexible(child: Text(text ?? 'File', style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, decoration: TextDecoration.underline))),
            ],
          ),
        ),
      );
    }
    return Text(
      text ?? '',
      style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 14),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: () => setState(() => _showEmoji = !_showEmoji),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                  onPressed: _showAttachOptions,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _isRecording 
                  ? GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.stop, color: Colors.white, size: 20),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.mic_none, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      onPressed: _toggleRecording,
                    ),
                if (!_isRecording) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _attachItem(Icons.image, 'Ảnh', () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
            _attachItem(Icons.camera_alt, 'Máy ảnh', () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
            _attachItem(Icons.insert_drive_file, 'Tài liệu', () { Navigator.pop(ctx); _pickFile(); }),
          ],
        ),
      ),
    );
  }

  Widget _attachItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, size: 30, color: const Color(0xFF854F0B)), onPressed: onTap),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  void _showRecallOption(Map<String, dynamic> msg) {
    final sentAt = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(sentAt).inHours;

    if (diff >= 1) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            leading: const Icon(Icons.undo, color: Colors.red),
            title: const Text('Thu hồi tin nhắn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(ctx);
              _socket.emit('recall_message', {'message_id': msg['id']});
            },
          ),
        ],
      ),
    ),
  );
}
}
