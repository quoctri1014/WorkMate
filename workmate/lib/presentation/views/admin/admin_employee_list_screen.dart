import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/mock_data.dart';

class AdminEmployeeListScreen extends StatelessWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Quản lý nhân sự', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () {})],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, i) => ListTile(
              leading: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
              title: Text('Nhân viên ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text('Phòng kỹ thuật • ID: WM00${i+1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              onTap: () {},
            ),
          ),
        ),
      ]),
    );
  }
}
