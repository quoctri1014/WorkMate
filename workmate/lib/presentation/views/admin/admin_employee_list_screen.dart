import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/mock_data.dart';

class AdminEmployeeListScreen extends StatelessWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý nhân sự'),
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () {})],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, i) => ListTile(
              leading: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
              title: Text('Nhân viên ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Phòng kỹ thuật • ID: WM00${i+1}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ),
      ]),
    );
  }
}
