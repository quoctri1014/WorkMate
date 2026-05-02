import React from 'react';
import { Icon, NavItem } from './Common';

const Sidebar = ({ activeTab, onTabChange }) => {
  const adminMenu = [
    { id: 'dashboard', label: 'Bảng tổng quan', icon: 'grid_view' },
    { id: 'employees', label: 'Đội ngũ nhân sự', icon: 'group' },
    { id: 'departments', label: 'Cơ cấu tổ chức', icon: 'account_tree' },
    { id: 'chat', label: 'Hỗ trợ trực tuyến', icon: 'chat' },
  ];

  const businessMenu = [
    { id: 'meetings', label: 'Lịch họp & Sự kiện', icon: 'event' },
    { id: 'approvals', label: 'Phê duyệt yêu cầu', icon: 'fact_check' },
    { id: 'attendance', label: 'Chấm công & Lịch', icon: 'calendar_month' },
    { id: 'settings', label: 'Cài đặt hệ thống', icon: 'settings' },
  ];

  const handleLogout = () => {
    localStorage.removeItem('admin_user');
    window.location.reload();
  };

  return (
    <aside className="fixed left-0 top-0 bottom-0 w-72 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col z-50 transition-all duration-500 shadow-xl shadow-slate-200/50 dark:shadow-none">
      {/* Brand Logo Section */}
      <div className="p-8 mb-4">
        <div className="flex items-center gap-4">
          <div className="relative group">
            <div className="absolute -inset-1 bg-gradient-to-r from-primary to-blue-600 rounded-2xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"></div>
            <div className="relative w-14 h-14 brand-gradient rounded-2xl flex items-center justify-center text-white shadow-2xl shadow-primary/20 transform group-hover:rotate-6 transition-transform duration-500">
              <Icon name="business_center" fill={1} className="!text-3xl" />
            </div>
          </div>
          <div>
            <h1 className="text-2xl font-black text-slate-900 dark:text-white tracking-tighter leading-none mb-1.5">WorkMate</h1>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Hệ thống Core</p>
          </div>
        </div>
      </div>

      {/* Navigation Section */}
      <div className="flex-1 overflow-y-auto px-4 space-y-8 no-scrollbar">
        {/* Admin Section */}
        <div>
          <p className="px-6 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.25em] mb-4 opacity-70">Menu điều hành</p>
          <div className="space-y-1">
            {adminMenu.map(item => (
              <NavItem 
                key={item.id}
                active={activeTab === item.id}
                label={item.label}
                icon={item.icon}
                onClick={() => onTabChange(item.id)}
              />
            ))}
          </div>
        </div>

        {/* Business Section */}
        <div>
          <p className="px-6 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.25em] mb-4 opacity-70">Quản lý nghiệp vụ</p>
          <div className="space-y-1">
            {businessMenu.map(item => (
              <NavItem 
                key={item.id}
                active={activeTab === item.id}
                label={item.label}
                icon={item.icon}
                onClick={() => onTabChange(item.id)}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Footer Section */}
      <div className="p-6 mt-auto">
        <div className="bg-slate-50 dark:bg-slate-800/50 rounded-3xl p-2 border border-slate-100 dark:border-slate-800">
          <button 
            onClick={handleLogout}
            className="w-full flex items-center gap-4 px-6 py-4 text-slate-500 dark:text-slate-400 hover:bg-rose-500/10 hover:text-rose-500 rounded-[1.25rem] transition-all font-black text-[11px] uppercase tracking-widest group"
          >
            <Icon name="logout" className="!text-xl rotate-180 group-hover:-translate-x-1 transition-transform" />
            <span>ĐĂNG XUẤT</span>
          </button>
        </div>
        <p className="text-center text-[10px] text-slate-400 mt-6 font-bold tracking-widest opacity-40">VERSION 2.4.0 • 2026</p>
      </div>
    </aside>
  );
};

export default Sidebar;
