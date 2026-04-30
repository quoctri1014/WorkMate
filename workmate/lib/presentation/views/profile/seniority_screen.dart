import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class SeniorityScreen extends StatelessWidget {
  const SeniorityScreen({super.key});

  void _showInstruction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Hướng dẫn đạt thành tích', style: TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _InstructionStep(
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.amber,
                      title: 'Cách tích lũy điểm',
                      description: 'Mỗi ngày làm việc bạn sẽ nhận được 100 điểm thâm niên. Điểm này thể hiện sự gắn bó và cống hiến bền bỉ của bạn với WorkMate.',
                    ),
                    _InstructionStep(
                      icon: Icons.psychology_rounded,
                      color: Colors.blue,
                      title: 'Điểm kỹ năng',
                      description: 'Được đánh giá dựa trên kết quả công việc (Kỹ thuật), khả năng phối hợp (Teamwork) và các ý kiến đóng góp (Sáng tạo) hàng tháng.',
                    ),
                    _InstructionStep(
                      icon: Icons.military_tech_rounded,
                      color: Colors.purple,
                      title: 'Các cột mốc vinh danh',
                      description: 'Hoàn thành các cột mốc thời gian (3 tháng, 1 năm, 3 năm) để nhận được các danh hiệu và phần thưởng đặc biệt từ công ty.',
                    ),
                    _InstructionStep(
                      icon: Icons.trending_up_rounded,
                      color: Colors.green,
                      title: 'Bảng xếp hạng',
                      description: 'Thứ hạng phần trăm (Top %) dựa trên tổng điểm của bạn so với toàn bộ nhân viên trong công ty.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Đã hiểu', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final user = homeVM.user;
    
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final now = DateTime.now();
    final joinDate = user.joinDate ?? now;
    final diff = now.difference(joinDate);
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;
    final totalDays = diff.inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thâm niên công tác',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 24),
            onPressed: () => _showInstruction(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Hero card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(children: [
              Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40)),
              const SizedBox(height: 16),
              const Text('Hành trình tuyệt vời!', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Colors.white70, letterSpacing: 1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$years năm $months tháng', style: const TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text('$totalDays ngày đồng hành cùng WorkMate', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text('Tích lũy: ${user.seniorityPoints} điểm', style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Milestones
          _MilestoneCard(
            icon: Icons.cake_rounded, iconColor: const Color(0xFF10B981),
            title: '3 Tháng Thử Việc', subtitle: 'Hoàn thành xuất sắc giai đoạn thử việc',
            date: joinDate.add(const Duration(days: 90)),
            achieved: totalDays >= 90,
          ),
          const SizedBox(height: 12),
          _MilestoneCard(
            icon: Icons.workspace_premium_rounded, iconColor: const Color(0xFFF59E0B),
            title: '1 Năm Cống Hiến', subtitle: 'Nhân viên chính thức',
            date: joinDate.add(const Duration(days: 365)),
            achieved: totalDays >= 365,
          ),
          const SizedBox(height: 12),
          _MilestoneCard(
            icon: Icons.diamond_rounded, iconColor: const Color(0xFF6366F1),
            title: '3 Năm Kinh Nghiệm', subtitle: 'Senior Member',
            date: joinDate.add(const Duration(days: 365 * 3)),
            achieved: totalDays >= 365 * 3,
          ),
          const SizedBox(height: 24),

          // Score board
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(32), 
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ĐIỂM KỸ NĂNG', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _ScoreCircle(label: 'Kỹ thuật', score: user.technicalScore, color: const Color(0xFF6366F1)),
                _ScoreCircle(label: 'Teamwork', score: user.teamworkScore, color: const Color(0xFF10B981)),
                _ScoreCircle(label: 'Sáng tạo', score: user.creativityScore, color: const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 32),
              const Text('ĐIỂM TỔNG KẾT', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(children: [
                Text(
                  (user.seniorityPoints + user.technicalScore + user.teamworkScore + user.creativityScore).toString(), 
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                  child: const Text('TOP 15%', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)))),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _InstructionStep({required this.icon, required this.color, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final DateTime date;
  final bool achieved;
  const _MilestoneCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.date, required this.achieved});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(24), 
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
      ],
      border: achieved ? Border.all(color: iconColor.withOpacity(0.2), width: 1) : null,
    ),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: iconColor, size: 24)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        Text(subtitle, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: achieved ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Text(achieved ? 'Đạt ✓' : 'Sắp đến', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: achieved ? const Color(0xFF059669) : const Color(0xFF94A3B8)))),
    ]),
  );
}

class _ScoreCircle extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreCircle({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Stack(alignment: Alignment.center, children: [
      SizedBox(width: 64, height: 64, child: CircularProgressIndicator(
        value: score / 100, strokeWidth: 8, backgroundColor: const Color(0xFFF1F5F9),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      )),
      Text('$score', style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
    ]),
    const SizedBox(height: 10),
    Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
  ]);
}
