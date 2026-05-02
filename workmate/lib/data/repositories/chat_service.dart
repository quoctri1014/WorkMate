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
      // Dành cho Admin nếu dùng App này, nhưng ở đây chủ yếu là User nhận từ Admin
      onMessageReceived(data);
    });
  }

  Future<List<dynamic>> getChatHistory(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/chat/history/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> askAI(int userId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/ai'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'message': message}),
    );
    return jsonDecode(response.body);
  }

  void sendMessage(int senderId, int? receiverId, String message) {
    socket.emit('send_message', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_ai': false
    });
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
