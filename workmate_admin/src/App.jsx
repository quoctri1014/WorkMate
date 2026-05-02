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

  // State quản lý ngày lọc chấm công toàn cục
  const [attendanceFilterDate, setAttendanceFilterDate] = useState(new Date().toISOString().split('T')[0]);

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
    
    // Ưu tiên date truyền vào, nếu không dùng attendanceFilterDate hiện tại
    const dateToFilter = params.date || attendanceFilterDate;

    try {
      await Promise.all([
        fetch('/employees', setEmployees),
        fetch('/attendance', setAttendance, { date: dateToFilter }),
        fetch('/approvals', setApprovals),
        fetch('/departments', setDepts),
        fetch('/meetings', setMeetings),
        fetch('/config', setConfig)
      ]);
    } finally {
      setLoading(false);
    }
  };

  // Cập nhật filter date từ các component con
  const handleAttendanceDateChange = (newDate) => {
    setAttendanceFilterDate(newDate);
    fetchData({ date: newDate });
  };

  useEffect(() => {
    if (!user) return;
    fetchData();
    socket.on('new_attendance', () => fetchData({ date: attendanceFilterDate }));
    socket.on('new_approval', () => fetchData());
    socket.on('approval_updated', fetchData);
    socket.on('online_users', (users) => {
      setOnlineUsers(users.map(Number));
    });

    return () => {
      socket.off('new_attendance');
      socket.off('new_approval');
      socket.off('approval_updated');
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
    <div className="min-h-screen bg-surface text-on-surface transition-colors">
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      
      {/* Top Header */}
      <header className="ml-72 h-20 bg-surface/80 backdrop-blur-md border-b border-surface-container-low flex items-center justify-between px-8 sticky top-0 z-40 transition-colors">
        <div className="flex items-center gap-4 bg-surface-container-low px-4 py-2 rounded-2xl w-96 border border-white/5 shadow-sm transition-colors">
          <Icon name="search" className="text-on-surface-variant !text-[20px]" />
          <input type="text" placeholder="Tìm kiếm nhân sự, báo cáo..." className="bg-transparent border-none outline-none text-sm w-full font-medium" />
        </div>
        
        <div className="flex items-center gap-6">
           <button className="relative p-2 hover:bg-surface-container-low rounded-xl transition-colors">
             <Icon name="notifications" className="text-on-surface-variant" />
             <span className="absolute top-2 right-2 w-2 h-2 bg-error rounded-full border-2 border-surface" />
           </button>
           <div className="h-8 w-px bg-surface-container-low" />
           <div className="flex items-center gap-3 pl-2">
            <div className="text-right hidden md:block">
              <p className="text-sm font-black tracking-tight">{user.name}</p>
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
             {activeTab === 'approvals' && <ApprovalsView approvals={approvals} onRefresh={fetchData} />}
             {activeTab === 'attendance' && (
               <AttendanceView 
                 attendance={attendance} 
                 onRefresh={fetchData} 
                 selectedDate={attendanceFilterDate}
                 onDateChange={handleAttendanceDateChange}
               />
             )}
             {activeTab === 'settings' && <SettingsView config={config} onRefresh={fetchData} />}
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
};

export default App;
