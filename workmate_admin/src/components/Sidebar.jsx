import React from 'react';
import { Icon, NavItem } from './Common';

const Sidebar = ({ activeTab, onTabChange }) => {
  const menuItems = [
    { id: 'dashboard', label: 'Bảng tổng quan', icon: 'grid_view' },
    { id: 'employees', label: 'Đội ngũ nhân sự', icon: 'group' },
    { id: 'departments', label: 'Cơ cấu tổ chức', icon: 'account_tree' },
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
    <aside className="fixed left-0 top-0 bottom-0 w-72 bg-surface-container-lowest border-r border-surface-container-low flex flex-col p-6 z-50 transition-colors">
      <div className="flex items-center gap-4 px-4 py-8 mb-8">
        <div className="w-12 h-12 brand-gradient rounded-2xl flex items-center justify-center text-white shadow-xl shadow-primary/20">
          <Icon name="business_center" fill={1} className="!text-2xl" />
        </div>
        <div>
          <h1 className="text-xl font-black text-primary tracking-tighter leading-none">WorkMate</h1>
          <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-widest mt-1">Hệ thống Core</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1">
        <p className="px-6 text-[10px] font-black text-on-surface-variant uppercase tracking-widest mb-4 mt-8 opacity-50">Menu điều hành</p>
        {menuItems.slice(0, 3).map(item => (
          <NavItem 
            key={item.id}
            active={activeTab === item.id}
            label={item.label}
            icon={item.icon}
            onClick={() => onTabChange(item.id)}
          />
        ))}

        <p className="px-6 text-[10px] font-black text-on-surface-variant uppercase tracking-widest mb-4 mt-8 opacity-50">Quản lý nghiệp vụ</p>
        {menuItems.slice(3).map(item => (
          <NavItem 
            key={item.id}
            active={activeTab === item.id}
            label={item.label}
            icon={item.icon}
            onClick={() => onTabChange(item.id)}
          />
        ))}
      </nav>

      <div className="mt-auto pt-8 border-t border-surface-container-low">
        <button 
          onClick={handleLogout}
          className="w-full flex items-center gap-4 px-8 py-4 text-on-surface-variant hover:bg-error/10 hover:text-error rounded-2xl transition-all font-bold text-xs"
        >
          <Icon name="logout" className="!text-xl rotate-180" />
          <span>ĐĂNG XUẤT</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
