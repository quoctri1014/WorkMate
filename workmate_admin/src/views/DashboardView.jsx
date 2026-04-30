import React from 'react';
import { motion } from 'framer-motion';
import { Icon } from '../components/Common';

const StatCard = ({ title, value, icon, color, trend }) => (
  <motion.div 
    initial={{ opacity: 0, y: 20 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true }}
    className="bg-surface-container-lowest p-8 rounded-[2.5rem] shadow-sm border border-border flex flex-col gap-4 relative overflow-hidden group transition-all hover:shadow-2xl hover:shadow-primary/5"
  >
    <div className={`absolute -right-6 -top-6 w-32 h-32 rounded-full opacity-[0.03] group-hover:opacity-[0.08] transition-all bg-${color === 'blue' ? 'blue' : color === 'emerald' ? 'emerald' : 'amber'}-500`}></div>
    
    <div className="flex justify-between items-start relative z-10">
      <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg bg-${color === 'blue' ? 'blue' : color === 'emerald' ? 'emerald' : 'amber'}-500 text-white transition-transform group-hover:rotate-12`}>
        <Icon name={icon} fill={1} className="!text-2xl" />
      </div>
      {trend && (
        <div className={`flex items-center gap-1 px-3 py-1.5 rounded-full text-[10px] font-black uppercase tracking-wider ${trend.startsWith('+') ? 'bg-emerald-500/10 text-emerald-500' : 'bg-rose-500/10 text-rose-500'}`}>
          <Icon name={trend.startsWith('+') ? 'trending_up' : 'trending_down'} className="!text-[12px]" />
          {trend}
        </div>
      )}
    </div>
    
    <div className="mt-4 relative z-10">
      <p className="text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em] mb-1">{title}</p>
      <h3 className="text-4xl font-black text-on-surface tracking-tighter transition-colors">{value}</h3>
    </div>
    
    <div className="mt-2 h-1 w-full bg-surface-container-low rounded-full overflow-hidden">
      <div className={`h-full bg-${color === 'blue' ? 'blue' : color === 'emerald' ? 'emerald' : 'amber'}-500 rounded-full`} style={{ width: '70%' }}></div>
    </div>
  </motion.div>
);

const DashboardView = ({ employees = [], attendance = [], approvals = [], meetings = [], onNavigate }) => {
  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];
  
  // Tính toán dữ liệu cho biểu đồ 7 ngày qua
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(today.getDate() - (4 - i)); // Sắp xếp để Hnay nằm ở vị trí thứ 5 (index 4) như thiết kế
    return d.toISOString().split('T')[0];
  });

  const chartData = last7Days.map(date => {
    const count = attendance.filter(a => a.date?.startsWith(date)).length;
    const total = employees.length || 1;
    return Math.min(Math.round((count / total) * 100), 100);
  });

  // Lọc dữ liệu thực tế cho ngày hôm nay
  const todayAttendance = attendance.filter(a => a.date?.startsWith(todayStr)).length;
  const pendingApprovals = approvals.filter(a => a.status === 'pending').length;
  const todayMeetings = meetings.filter(m => m.start_time?.includes(todayStr) || m.date?.includes(todayStr));

  return (
    <div className="space-y-10">
      <section className="flex justify-between items-center">
        <div>
          <h2 className="text-4xl font-black tracking-tighter text-on-surface">Bảng tổng quan</h2>
          <p className="text-on-surface-variant mt-1 font-medium italic">Chào buổi sáng, Admin. Hệ thống đang vận hành ổn định.</p>
        </div>
        <div className="flex items-center gap-3 bg-surface-container-low px-6 py-3 rounded-2xl border border-border">
          <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
          <span className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Hệ thống đang trực tuyến</span>
        </div>
      </section>

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="cursor-pointer" onClick={() => onNavigate('employees')}>
          <StatCard title="Tổng nhân sự" value={employees.length} icon="groups" color="blue" trend={`${employees.length} thành viên`} />
        </div>
        <div className="cursor-pointer" onClick={() => onNavigate('attendance')}>
          <StatCard title="Điểm danh hôm nay" value={todayAttendance} icon="check_circle" color="emerald" trend={`${((todayAttendance/employees.length || 0)*100).toFixed(0)}% diện hiện`} />
        </div>
        <div className="cursor-pointer" onClick={() => onNavigate('approvals')}>
          <StatCard title="Yêu cầu chờ duyệt" value={pendingApprovals} icon="pending" color="amber" trend={`${pendingApprovals} đơn mới`} />
        </div>
        <div className="cursor-pointer" onClick={() => onNavigate('meetings')}>
          <StatCard title="Lịch họp hôm nay" value={todayMeetings.length} icon="calendar_month" color="rose" trend={`${todayMeetings.length} cuộc họp`} />
        </div>
      </section>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <div className="xl:col-span-2 space-y-8">
          <div className="bg-surface-container-lowest rounded-[3rem] p-10 border border-border shadow-sm">
            <div className="flex items-center justify-between mb-12">
              <div>
                <h3 className="text-xl font-black tracking-tight">Hiệu suất vận hành</h3>
                <p className="text-xs text-on-surface-variant font-medium mt-1">Tỷ lệ chuyên cần trong 7 ngày qua</p>
              </div>
              <div className="flex gap-2">
                <button className="px-4 py-2 bg-primary text-white text-[10px] font-black uppercase tracking-widest rounded-xl shadow-lg shadow-primary/20 transition-all">Tuần</button>
                <button className="px-4 py-2 bg-surface-container-low text-on-surface-variant text-[10px] font-black uppercase tracking-widest rounded-xl hover:bg-surface-container-high transition-all">Tháng</button>
              </div>
            </div>
            
            <div className="h-64 flex items-end justify-between gap-6 px-4">
              {chartData.map((h, i) => (
                <div key={i} className="flex-1 flex flex-col items-center gap-4 group">
                  <div className="w-full bg-surface-container-low rounded-2xl relative h-48 overflow-hidden">
                    <motion.div 
                      initial={{ height: 0 }}
                      animate={{ height: `${h || 1}%` }}
                      transition={{ duration: 1, delay: i * 0.1, ease: "circOut" }}
                      className={`absolute bottom-0 w-full rounded-2xl transition-all duration-500 group-hover:brightness-110 ${i === 4 ? 'brand-gradient shadow-[0_0_20px_rgba(56,189,248,0.3)]' : 'bg-primary/20'}`}
                    ></motion.div>
                    <div className="absolute top-2 left-0 w-full text-center opacity-0 group-hover:opacity-100 transition-all">
                      <span className="text-[10px] font-black text-primary bg-white px-2 py-1 rounded-md shadow-sm">{h}%</span>
                    </div>
                  </div>
                  <span className={`text-[10px] font-black uppercase tracking-widest ${i === 4 ? 'text-primary animate-pulse' : 'text-on-surface-variant/50'}`}>
                    {['T2','T3','T4','T5','Hnay','T7','CN'][i]}
                  </span>
                </div>
              ))}
            </div>
          </div>

        </div>

        <div className="space-y-8">
          <div className="brand-gradient rounded-[3rem] p-10 text-white relative overflow-hidden flex flex-col min-h-[450px] shadow-2xl shadow-primary/20">
            <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32"></div>
            <div className="relative z-10">
              <div className="flex items-center gap-3 mb-10">
                <div className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-md flex items-center justify-center border border-white/20"><Icon name="event" /></div>
                <h3 className="text-lg font-black tracking-tight">Lịch trình sắp tới</h3>
              </div>
              
              <div className="space-y-4">
                {todayMeetings.length > 0 ? todayMeetings.slice(0, 3).map((m, i) => (
                  <motion.div 
                    initial={{ x: 20, opacity: 0 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.1 }}
                    key={i} 
                    className="bg-white/10 backdrop-blur-xl p-5 rounded-3xl border border-white/10 hover:bg-white/15 transition-all group cursor-pointer"
                  >
                    <p className="text-xs font-black uppercase tracking-widest text-white/60 mb-1">{m.start_time?.split('T')?.[1]?.substring(0, 5) || m.start_time}</p>
                    <p className="font-black text-sm group-hover:translate-x-1 transition-transform">{m.title}</p>
                    <div className="flex items-center gap-2 mt-3 opacity-60">
                      <Icon name="location_on" className="!text-[14px]" />
                      <span className="text-[10px] font-medium uppercase tracking-wider">{m.location}</span>
                    </div>
                  </motion.div>
                )) : (
                  <div className="py-20 text-center opacity-60">
                    <Icon name="event_busy" className="!text-5xl mb-4" />
                    <p className="text-xs font-black uppercase tracking-widest">Không có lịch họp hôm nay</p>
                  </div>
                )}
              </div>
            </div>
            <button 
              onClick={() => onNavigate('meetings')}
              className="w-full py-4 bg-white text-primary rounded-2xl font-black text-xs tracking-widest uppercase shadow-xl hover:scale-[1.02] active:scale-[0.98] transition-all mt-10"
            >
              Xem tất cả lịch
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardView;
