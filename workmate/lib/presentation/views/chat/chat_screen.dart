import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/mock_data.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, i) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('N${i+1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text('Đồng nghiệp ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tin nhắn mới nhất từ đồng nghiệp...', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('10:30', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (i < 2)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            onTap: () {
              // Mở chi tiết chat
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_note_rounded, color: Colors.white),
      ),
    );
  }
}
