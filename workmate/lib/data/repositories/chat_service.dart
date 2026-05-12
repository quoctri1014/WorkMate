import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ChatService {
  late IO.Socket socket;
  final String baseUrl = ApiService.baseUrl;
  final String baseHost = ApiService.baseHost;

  void initSocket(int userId, Function(Map<String, dynamic>) onMessageReceived) {
    socket = IO.io(baseHost, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    socket.connect();

    socket.onConnect((_) {
      print('🔌 Connected to Chat Server');
      socket.emit('register', userId);
    });

    socket.on('receive_message_$userId', (data) {
      onMessageReceived(data);
    });

    socket.on('receive_message_admin', (data) {
      onMessageReceived(data);
    });
  }

  /// Lấy lịch sử tin nhắn AI riêng
  Future<List<dynamic>> getAIHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/ai-history/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('❌ Lỗi tải lịch sử AI: $e');
    }
    return [];
  }

  /// Lấy lịch sử tin nhắn Admin riêng
  Future<List<dynamic>> getAdminHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/admin-history/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('❌ Lỗi tải lịch sử Admin: $e');
    }
    return [];
  }

  /// Giữ tương thích ngược
  Future<List<dynamic>> getChatHistory(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/chat/history/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> askAI(int userId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'message': message}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          'reply': body['reply'] ?? 'Xin lỗi, hệ thống đang gặp sự cố. Vui lòng thử lại sau.',
          'suggestAdmin': true,
        };
      }
    } catch (e) {
      return {
        'reply': 'Không thể kết nối đến server AI. Vui lòng kiểm tra kết nối mạng.',
        'suggestAdmin': true,
      };
    }
  }

  void sendMessage(int senderId, int? receiverId, String message, {String chatType = 'admin', int? conversationId, String messageType = 'text', String? fileUrl}) {
    socket.emit('send_message', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_ai': false,
      'chat_type': chatType,
      'conversation_id': conversationId,
      'message_type': messageType,
      'file_url': fileUrl,
    });
  }

  void recallMessage(int messageId) {
    socket.emit('recall_message', {'message_id': messageId});
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
