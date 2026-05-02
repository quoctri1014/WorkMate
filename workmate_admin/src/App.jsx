import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { io } from "socket.io-client";
import { motion, AnimatePresence } from 'framer-motion';
import Sidebar from './components/Sidebar';
import DashboardView from './views/DashboardView';
import EmployeesView from './views/EmployeesView';
import DepartmentsView from './views/DepartmentsView';
import MeetingsView from './views/MeetingsView';
import ApprovalsView from './views/ApprovalsView';
import AttendanceView from './views/AttendanceView';
import SettingsView from './views/SettingsView';
import ChatView from './views/ChatView';
import Login from './views/LoginView';
import { Icon, API_URL } from './components/Common';

const socket = io("http://localhost:5000");

const App = () => {
  const [user, setUser] = useState(JSON.parse(localStorage.getItem('admin_user')));
  const [activeTab, setActiveTab] = useState('dashboard');
  const [employees, setEmployees] = useState([]);
  const [attendance, setAttendance] = useState([]);
  const [approvals, setApprovals] = useState([]);
  const [depts, setDepts] = useState([]);
  const [meetings, setMeetings] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [config, setConfig] = useState({});
  const [loading, setLoading] = useState(true);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const [isDarkMode, setIsDarkMode] = useState(localStorage.getItem('theme') === 'dark');

  // State quản lý ngày lọc chấm công toàn cục
  const [attendanceFilterDate, setAttendanceFilterDate] = useState(new Date().toISOString().split('T')[0]);

  const toggleDarkMode = () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    localStorage.setItem('theme', newMode ? 'dark' : 'light');
    if (newMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const fetch = async (url, setter, p = {}) => {
    try {
      const res = await axios.get(`${API_URL}${url}`, { params: p });
      setter(res.data);
      return res.data;
    } catch (err) {
      console.error(`Error fetching ${url}:`, err);
    }
  };

  const fetchData = async (params = {}) => {
    if (!user) return;
    setLoading(true);
    
    const dateToFilter = params.date || attendanceFilterDate;

    try {
      await Promise.all([
        fetch('/employees', setEmployees),
        fetch('/attendance', setAttendance, { date: dateToFilter }),
        fetch('/approvals', setApprovals),
        fetch('/departments', setDepts),
        fetch('/meetings', setMeetings),
        fetch('/config', setConfig),
        fetch('/notifications', setNotifications)
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleAttendanceDateChange = (newDate) => {
    setAttendanceFilterDate(newDate);
    fetchData({ date: newDate });
  };

  useEffect(() => {
    if (localStorage.getItem('theme') === 'dark') {
      document.documentElement.classList.add('dark');
    }
    
    if (!user) return;
    fetchData();
    socket.on('new_attendance', () => fetchData({ date: attendanceFilterDate }));
    socket.on('new_approval', () => fetchData());
    socket.on('approval_updated', fetchData);
    socket.on('new_notification', () => fetchData());
    socket.on('online_users', (users) => {
      setOnlineUsers(users.map(Number));
    });

    return () => {
      socket.off('new_attendance');
      socket.off('new_approval');
      socket.off('approval_updated');
      socket.off('new_notification');
      socket.off('online_users');
    };
  }, [user, attendanceFilterDate]);

  if (!user) return <Login onLogin={setUser} />;
  
  if (loading && employees.length === 0) return (
    <div className="h-screen flex items-center justify-center bg-surface transition-colors">
      <div className="flex flex-col items-center gap-4">
        <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
        <p className="text-on-surface-variant font-bold animate-pulse">Đang tải dữ liệu...</p>
      </div>
    </div>
  );

  return (
    <div className={`min-h-screen transition-colors ${isDarkMode ? 'dark bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'}`}>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      
      {/* Top Header */}
      <header className="ml-72 h-20 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 flex items-center justify-end px-8 sticky top-0 z-40 transition-colors">
        
        <div className="flex items-center gap-4">
           {/* Dark Mode Toggle */}
           <button 
             onClick={toggleDarkMode}
             className="p-2.5 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition-all text-slate-500 dark:text-slate-400 group"
           >
             <Icon name={isDarkMode ? "light_mode" : "dark_mode"} className="group-active:rotate-90 transition-transform duration-500" />
           </button>

           <div className="h-6 w-px bg-slate-200 dark:bg-slate-800 mx-2" />

           <button className="relative p-2.5 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition-all text-slate-500 dark:text-slate-400 group">
             <Icon name="notifications" className="group-hover:scale-110 transition-transform" />
             {approvals.filter(a => a.status === 'pending').length > 0 && (
               <span className="absolute top-1.5 right-1.5 bg-rose-500 text-white text-[10px] font-black w-5 h-5 flex items-center justify-center rounded-full border-2 border-white dark:border-slate-900 shadow-sm animate-bounce">
                 {approvals.filter(a => a.status === 'pending').length > 9 ? '9+' : approvals.filter(a => a.status === 'pending').length}
               </span>
             )}
           </button>

           <div className="h-6 w-px bg-slate-200 dark:bg-slate-800 mx-2" />

           <div className="flex items-center gap-3 pl-2">
            <div className="text-right hidden md:block">
              <p className="text-sm font-black tracking-tight">{user.name}</p>
              <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest opacity-70">Quản trị viên</p>
            </div>
            <div className="w-10 h-10 rounded-2xl brand-gradient text-white flex items-center justify-center font-black border-2 border-white dark:border-slate-800 shadow-lg shadow-primary/20 transition-all">{user.name?.[0]}</div>
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
             {activeTab === 'approvals' && <ApprovalsView approvals={approvals} onRefresh={fetchData} />}
             {activeTab === 'attendance' && (
               <AttendanceView 
                 attendance={attendance} 
                 onRefresh={fetchData} 
                 selectedDate={attendanceFilterDate}
                 onDateChange={handleAttendanceDateChange}
               />
             )}
             {activeTab === 'chat' && <ChatView adminUser={user} />}
             {activeTab === 'settings' && <SettingsView config={config} onRefresh={fetchData} />}
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
};

export default App;
