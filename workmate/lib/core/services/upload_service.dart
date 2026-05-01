import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class UploadResult {
  final bool success;
  final String? url;
  final String? error;
  UploadResult({required this.success, this.url, this.error});
}

class UploadService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<UploadResult> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var data = json.decode(responseData);
        return UploadResult(success: true, url: data['url']);
      } else {
        return UploadResult(success: false, error: 'Server Error: ${response.statusCode}\n$responseData');
      }
    } catch (e) {
      return UploadResult(success: false, error: 'Connection Error: $e');
    }
  }

  static Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}
