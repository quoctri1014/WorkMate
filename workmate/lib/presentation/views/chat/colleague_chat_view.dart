import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/data/repositories/api_service.dart';
import 'chat_room_screen.dart'; // Thêm import này

class ColleagueChatView extends StatefulWidget {
  const ColleagueChatView({super.key});
  @override
  State<ColleagueChatView> createState() => _ColleagueChatViewState();
}

class _ColleagueChatViewState extends State<ColleagueChatView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _directConvs  = [];
  List<Map<String, dynamic>> _groupConvs   = [];
  bool _loading = true;

  static const Color primaryColor = Color(0xFF854F0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;
    
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/conversations?userId=${user.id}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _directConvs = data.where((c) => c['type'] == 'direct').cast<Map<String, dynamic>>().toList();
            _groupConvs  = data.where((c) => c['type'] == 'group').cast<Map<String, dynamic>>().toList();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1a1a2e),
          child: TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Cá nhân'), Tab(text: 'Nhóm')],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildConvList(_directConvs, 'direct'),
                        _buildConvList(_groupConvs, 'group'),
                      ],
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        backgroundColor: primaryColor,
                        child: const Icon(Icons.edit_rounded, color: Colors.white),
                        onPressed: _showCreateGroup,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConvList(List<Map<String, dynamic>> convs, String type) {
    if (convs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(type == 'direct' ? Icons.chat_bubble_outline : Icons.group_outlined,
              size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(type == 'direct' ? 'Chưa có tin nhắn nào' : 'Chưa có nhóm nào',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        itemCount: convs.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 0.5, indent: 70, color: Color(0xFFE5E7EB)),
        itemBuilder: (_, i) => _buildConvItem(convs[i], type),
      ),
    );
  }

  Widget _buildConvItem(Map<String, dynamic> conv, String type) {
    final isGroup   = type == 'group';
    final unread    = int.tryParse(conv['unread_count'].toString()) ?? 0;
    final isOnline  = conv['is_online'] ?? false;
    final lastMsg   = conv['last_message'] ?? 'Bắt đầu trò chuyện';
    final lastTime  = _formatTime(conv['last_message_time']);
    final name      = conv['display_name'] ?? conv['name'] ?? 'Đồng nghiệp';
    final initials  = _getInitials(name);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(children: [
        // Avatar
        isGroup
            ? Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.people_rounded, color: Colors.white, size: 22),
              )
            : CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(name),
                child: Text(initials,
                    style: TextStyle(color: _getAvatarFgColor(name),
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
        // Online dot
        if (!isGroup && isOnline)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ]),
      title: Text(name,
          style: TextStyle(
            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            color: Colors.white // Đổi thành màu trắng cho dễ nhìn trên nền tối
          )),
      subtitle: Text(
        isGroup && conv['sender_name'] != null ? '${conv['sender_name']}: $lastMsg' : lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: unread > 0 ? Colors.white : Colors.grey.shade400, // Đổi màu subtitle
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(lastTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              conversation: conv,
              chatType: type,
            ),
          ),
        ).then((_) {
          // Refresh list when going back
          _loadConversations();
        });
      },
    );
  }

  // ── Tạo nhóm mới ─────────────────────────────────────
  void _showCreateGroup() {
    final nameCtrl = TextEditingController();
    final selectedIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tạo nhóm chat mới',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Nhập tên nhóm...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true, fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                ),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Chọn thành viên:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1a1a1a)))),
              const SizedBox(height: 8),
              // Danh sách nhân viên để chọn
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: FutureBuilder<List>(
                  future: _fetchChattedColleagues(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      itemCount: snap.data!.length,
                      itemBuilder: (_, i) {
                        final user = snap.data![i];
                        final selected = selectedIds.contains(user['id']);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _getAvatarColor(user['full_name']),
                            child: Text(_getInitials(user['full_name']),
                                style: TextStyle(color: _getAvatarFgColor(user['full_name']),
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(user['full_name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(user['department'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: selected ? primaryColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? primaryColor : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                          onTap: () => setModalState(() {
                            selected ? selectedIds.remove(user['id']) : selectedIds.add(user['id']);
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selectedIds.isEmpty ? null : () async {
                    await _createGroup(nameCtrl.text, selectedIds.toList());
                    Navigator.pop(ctx);
                    _loadConversations();
                  },
                  child: Text('Tạo nhóm (${selectedIds.length} người)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup(String name, List<int> memberIds) async {
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return;
    await http.post(
      Uri.parse('${ApiService.baseUrl}/conversations/group'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'createdBy': user.id, 'memberIds': memberIds}),
    );
  }

  Future<List> _fetchChattedColleagues() async {
    final user = context.read<ProfileViewModel>().user;
    if (user == null) return [];
    final res = await http.get(Uri.parse('${ApiService.baseUrl}/users/chatted-colleagues?userId=${user.id}'));
    return jsonDecode(res.body) as List;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFFAEEDA), const Color(0xFFE1F5EE),
      const Color(0xFFEEEDFE), const Color(0xFFFAECE7),
      const Color(0xFFFBEAF0),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Color _getAvatarFgColor(String name) {
    final colors = [
      const Color(0xFF633806), const Color(0xFF0F6E56),
      const Color(0xFF534AB7), const Color(0xFF993C1D),
      const Color(0xFF993556),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    final now = DateTime.now();
    final localDt = dt.toLocal();
    if (localDt.day == now.day && localDt.month == now.month && localDt.year == now.year) {
      return '${localDt.hour.toString().padLeft(2,'0')}:${localDt.minute.toString().padLeft(2,'0')}';
    }
    if (now.difference(localDt).inDays == 1) return 'Hôm qua';
    return '${localDt.day}/${localDt.month}';
  }
}
