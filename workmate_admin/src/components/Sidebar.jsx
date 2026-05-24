import React from 'react';
import { useTranslation } from 'react-i18next';
import { Icon, NavItem } from './Common';

const Sidebar = ({ activeTab, onTabChange, isOpen, onClose }) => {
  const { t, i18n } = useTranslation();

  const adminMenu = [
    { id: 'dashboard', label: t('dashboard'), icon: 'grid_view' },
    { id: 'employees', label: t('employees'), icon: 'group' },
    { id: 'departments', label: t('departments'), icon: 'account_tree' },
    { id: 'chat', label: t('chat'), icon: 'chat' },
  ];

  const businessMenu = [
    { id: 'meetings', label: t('meetings'), icon: 'event' },
    { id: 'approvals', label: t('approvals'), icon: 'fact_check' },
    { id: 'attendance', label: t('attendance'), icon: 'calendar_month' },
    { id: 'settings', label: t('settings'), icon: 'settings' },
  ];

  const handleLogout = () => {
    localStorage.removeItem('admin_user');
    window.location.reload();
  };

  const handleTabClick = (id) => {
    onTabChange(id);
    if (window.innerWidth < 1024) onClose();
  };

  const toggleLanguage = () => {
    const newLang = i18n.language === 'vi' ? 'en' : 'vi';
    i18n.changeLanguage(newLang);
  };

  return (
    <>
      {/* Mobile Overlay */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      <aside className={`fixed left-0 top-0 bottom-0 w-72 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col z-50 transition-all duration-500 shadow-xl shadow-slate-200/50 dark:shadow-none ${isOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        {/* Brand Logo Section */}
        <div className="p-8 mb-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="relative group">
              <div className="absolute -inset-1 bg-gradient-to-r from-primary to-blue-600 rounded-2xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"></div>
              <div className="relative w-14 h-14 brand-gradient rounded-2xl flex items-center justify-center text-white shadow-2xl shadow-primary/20 transform group-hover:rotate-6 transition-transform duration-500 overflow-hidden">
                <img src="/favicon.png" className="w-10 h-10 object-contain" alt="Logo" />
              </div>
            </div>
            <div>
              <h1 className="text-2xl font-black text-slate-900 dark:text-white tracking-tighter leading-none mb-1.5">WorkMate</h1>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">{t('core_system')}</p>
            </div>
          </div>
          <button onClick={onClose} className="lg:hidden p-2 text-slate-400 hover:text-primary transition-colors">
            <Icon name="close" />
          </button>
        </div>

        {/* Navigation Section */}
        <div className="flex-1 overflow-y-auto px-4 space-y-8 no-scrollbar">
          {/* Admin Section */}
          <div>
            <p className="px-6 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.25em] mb-4 opacity-70">{t('admin_menu')}</p>
            <div className="space-y-1">
              {adminMenu.map(item => (
                <NavItem 
                  key={item.id}
                  active={activeTab === item.id}
                  label={item.label}
                  icon={item.icon}
                  onClick={() => handleTabClick(item.id)}
                />
              ))}
            </div>
          </div>

          {/* Business Section */}
          <div>
            <p className="px-6 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.25em] mb-4 opacity-70">{t('business_management')}</p>
            <div className="space-y-1">
              {businessMenu.map(item => (
                <NavItem 
                  key={item.id}
                  active={activeTab === item.id}
                  label={item.label}
                  icon={item.icon}
                  onClick={() => handleTabClick(item.id)}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Footer Section */}
        <div className="p-6 mt-auto">
          <div className="flex gap-2 mb-4">
            <button 
              onClick={toggleLanguage}
              className="flex-1 flex items-center justify-center gap-2 bg-slate-50 dark:bg-slate-800/50 rounded-[1.25rem] py-3 border border-slate-100 dark:border-slate-800 hover:bg-slate-100 transition-colors text-[11px] font-black uppercase tracking-widest text-slate-500"
            >
              <Icon name="language" className="!text-lg" />
              {i18n.language === 'vi' ? 'English' : 'Tiếng Việt'}
            </button>
          </div>
          <div className="bg-slate-50 dark:bg-slate-800/50 rounded-3xl p-2 border border-slate-100 dark:border-slate-800">
            <button 
              onClick={handleLogout}
              className="w-full flex items-center gap-4 px-6 py-4 text-slate-500 dark:text-slate-400 hover:bg-rose-500/10 hover:text-rose-500 rounded-[1.25rem] transition-all font-black text-[11px] uppercase tracking-widest group"
            >
              <Icon name="logout" className="!text-xl rotate-180 group-hover:-translate-x-1 transition-transform" />
              <span>{t('logout')}</span>
            </button>
          </div>
          <p className="text-center text-[10px] text-slate-400 mt-6 font-bold tracking-widest opacity-40">VERSION 2.4.0 • 2026</p>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
