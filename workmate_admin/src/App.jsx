import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { io } from 'socket.io-client';
import { motion, AnimatePresence } from 'framer-motion';

// Components & Views
import { Icon, NavItem, API_URL } from './components/Common';
import DashboardView from './views/DashboardView';
import EmployeesView from './views/EmployeesView';
import DepartmentsView from './views/DepartmentsView';
import MeetingsView from './views/MeetingsView';
import ApprovalsView from './views/ApprovalsView';
import AttendanceView from './views/AttendanceView';
import SettingsView from './views/SettingsView';
import LoginView from './views/LoginView';

const socket = io("http://localhost:5000");

const App = () => {
  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [employees, setEmployees] = useState([]);
  const [attendance, setAttendance] = useState([]);
  const [depts, setDepts] = useState([]);
  const [approvals, setApprovals] = useState([]);
  const [meetings, setMeetings] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const calculateNotifications = (apps = [], meets = []) => {
    const pendingApps = (apps || []).filter(a => a.status === 'pending').length;
    const upcomingMeets = (meets || []).filter(m => {
      const now = new Date();
      const start = new Date(m.start_time);
      const diff = start - now;
      return diff > 0 && diff < 24 * 60 * 60 * 1000;
    }).length;
    setUnreadCount(pendingApps + upcomingMeets);
  };

  useEffect(() => {
    calculateNotifications(approvals, meetings);
  }, [approvals, meetings]);
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(false);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const [isDarkMode, setIsDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark' || 
           (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: dark)').matches);
  });

  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [isDarkMode]);

  const toggleDarkMode = () => setIsDarkMode(!isDarkMode);

  useEffect(() => {
    const saved = localStorage.getItem('workmate_user');
    if (saved) setUser(JSON.parse(saved));
  }, []);

  const fetchData = async () => {
    if (loading) return;
    setLoading(true);
    try {
      // Dùng individual await để nếu 1 cái lỗi cái khác vẫn chạy
      const fetch = async (url, setter) => {
        try {
          const res = await axios.get(`${API_URL}${url}`);
          if (url === '/attendance') console.log('📅 Attendance Data:', res.data);
          setter(res.data);
        } catch (e) { console.error(`Lỗi tải ${url}:`, e); }
      };

      await Promise.all([
        fetch('/employees', setEmployees),
        fetch('/attendance', setAttendance),
        fetch('/departments', setDepts),
        fetch('/approvals', setApprovals),
        fetch('/meetings', setMeetings),
        fetch('/notifications', setNotifications),
        fetch('/company/config', setConfig)
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!user) return;
    fetchData();
    socket.on('new_attendance', fetchData);
    socket.on('new_approval', fetchData);
    socket.on('approval_updated', fetchData);
    socket.on('online_users', (users) => {
      setOnlineUsers(users.map(Number));
    });

    const onConnect = () => {
      socket.emit('register', Number(user.id));
    };

    socket.on('connect', onConnect);
    if (socket.connected) onConnect();

    return () => {
      socket.off('new_attendance', fetchData);
      socket.off('new_approval', fetchData);
      socket.off('approval_updated', fetchData);
      socket.off('online_users');
      socket.off('connect', onConnect);
    };
  }, [user]);

  if (!user) return <LoginView onLogin={(u) => { setUser(u); localStorage.setItem('workmate_user', JSON.stringify(u)); }} />;

  return (
    <div className={`min-h-screen bg-surface font-sans text-on-surface transition-colors duration-300 ${isDarkMode ? 'dark' : ''}`}>
      {/* Sidebar */}
      <aside className="fixed left-0 top-0 h-full z-40 w-72 bg-surface-container-lowest shadow-[10px_0_30px_rgba(0,0,0,0.03)] flex flex-col transition-colors border-r border-border">
        <div className="p-10 mb-4">
          <div className="flex items-center gap-4 group cursor-pointer">
            <div className="w-12 h-12 rounded-2xl brand-gradient flex items-center justify-center shadow-lg shadow-primary/20 group-hover:scale-110 transition-all duration-500">
              <Icon name="work" fill={1} className="text-white !font-normal !text-2xl" />
            </div>
            <div>
              <h1 className="text-2xl font-black bg-gradient-to-br from-sky-400 to-blue-600 bg-clip-text text-transparent tracking-tighter">WorkMate</h1>
              <div className="flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <p className="text-[10px] text-on-surface-variant font-black uppercase tracking-[0.2em]">Hệ thống Core</p>
              </div>
            </div>
          </div>
        </div>
        <nav className="flex-1 px-6 space-y-1.5 overflow-y-auto custom-scrollbar">
           <div className="text-[9px] font-black text-on-surface-variant/40 uppercase tracking-[0.3em] ml-4 mb-4">Menu điều hành</div>
            <NavItem icon="dashboard" label="Bảng tổng quan" active={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} />
            <NavItem icon="groups" label="Đội ngũ nhân sự" active={activeTab === 'employees'} onClick={() => setActiveTab('employees')} />
            <NavItem icon="corporate_fare" label="Cơ cấu tổ chức" active={activeTab === 'departments'} onClick={() => setActiveTab('departments')} />
            <div className="h-4"></div>
            <div className="text-[9px] font-black text-on-surface-variant/40 uppercase tracking-[0.3em] ml-4 mb-4">Quản lý nghiệp vụ</div>
            <NavItem icon="video_chat" label="Lịch họp & Sự kiện" active={activeTab === 'meetings'} onClick={() => setActiveTab('meetings')} />
            <NavItem icon="fact_check" label="Phê duyệt yêu cầu" active={activeTab === 'approvals'} onClick={() => setActiveTab('approvals')} />
            <NavItem icon="event_available" label="Chấm công & Lịch" active={activeTab === 'attendance'} onClick={() => setActiveTab('attendance')} />
            <NavItem icon="settings" label="Cài đặt hệ thống" active={activeTab === 'settings'} onClick={() => setActiveTab('settings')} />
        </nav>
        <div className="p-6 mt-auto">
          <button 
            onClick={() => { localStorage.removeItem('workmate_user'); setUser(null); }}
            className="w-full py-3 bg-surface-container-low text-on-surface-variant text-xs rounded-xl font-bold hover:bg-error/10 hover:text-error transition-all flex items-center justify-center gap-2"
          >
            <Icon name="logout" className="!text-[16px]" /> ĐĂNG XUẤT
          </button>
        </div>
      </aside>

      {/* TopNavBar */}
      <header className="flex justify-between items-center h-16 w-[calc(100%-18rem)] ml-72 px-8 sticky top-0 z-30 bg-surface/80 backdrop-blur-xl border-b border-border transition-colors">
        <div className="flex items-center gap-4 flex-1">
          <div className="relative w-full max-w-md group">
            <Icon name="search" className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input className="w-full pl-10 pr-4 py-2 bg-surface-container-low border-none rounded-full text-sm focus:ring-2 focus:ring-primary/20 transition-all outline-none text-on-surface" placeholder="Tìm kiếm nhân sự, báo cáo..." />
          </div>
          {loading && <div className="text-[10px] text-primary animate-pulse font-bold uppercase tracking-widest">Đang cập nhật dữ liệu...</div>}
        </div>
        <div className="flex items-center gap-4">
          <button 
            onClick={toggleDarkMode}
            className="p-2 text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors"
          >
            <Icon name={isDarkMode ? 'light_mode' : 'dark_mode'} />
          </button>
          <button className="relative p-2 text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors">
            <Icon name="notifications" />
            {unreadCount > 0 && (
              <span className="absolute top-1 right-1 min-w-[18px] h-[18px] px-1 bg-error text-white text-[9px] font-black rounded-full border-2 border-surface flex items-center justify-center transition-all scale-110">
                {unreadCount}
              </span>
            )}
          </button>
          <div className="h-8 w-px bg-border mx-2"></div>
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-xs font-bold text-on-surface">{user.name}</p>
              <p className="text-[10px] text-on-surface-variant">Quản trị viên</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold border-2 border-surface shadow-sm transition-colors">{user.name?.[0]}</div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="ml-72 p-8 min-h-screen">
        <AnimatePresence mode="wait">
          <motion.div key={activeTab} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} transition={{ duration: 0.3 }}>
             {activeTab === 'dashboard' && <DashboardView employees={employees} attendance={attendance} approvals={approvals} meetings={meetings} onNavigate={setActiveTab} />}
             {activeTab === 'employees' && <EmployeesView employees={employees} depts={depts} onRefresh={fetchData} onlineUsers={onlineUsers} />}
             {activeTab === 'departments' && <DepartmentsView depts={depts} onRefresh={fetchData} />}
             {activeTab === 'meetings' && <MeetingsView meetings={meetings} notifications={notifications} depts={depts} onRefresh={fetchData} />}
             {activeTab === 'approvals' && <ApprovalsView approvals={approvals} />}
             {activeTab === 'attendance' && <AttendanceView attendance={attendance} onRefresh={fetchData} />}
             {activeTab === 'settings' && <SettingsView config={config} onRefresh={fetchData} />}
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
};

export default App;
