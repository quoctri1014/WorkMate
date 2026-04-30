import React, { useState } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';

export const MeetingModal = ({ depts = [], onClose, initialData = null, defaultType = 'meeting' }) => {
  const isEdit = !!initialData;
  const [type, setType] = useState(initialData?.type || (initialData && !initialData.location ? 'notification' : defaultType));
  const [data, setData] = useState(initialData || { 
    title: '', 
    content: '', 
    department_ids: [], 
    start_time: '', 
    location: '', 
    is_online: false 
  });
  
  const handleToggleDept = (id) => {
    const current = [...data.department_ids];
    if (current.includes(id)) {
      setData({...data, department_ids: current.filter(x => x !== id)});
    } else {
      setData({...data, department_ids: [...current, id]});
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (data.department_ids.length === 0) return alert("Vui lòng chọn ít nhất 1 phòng ban!");
    try {
      const endpoint = type === 'meeting' ? '/meetings' : '/notifications';
      if (isEdit) {
        await axios.put(`${API_URL}${endpoint}/${initialData.id}`, data);
        alert(`✅ Đã cập nhật ${type === 'meeting' ? 'lịch họp' : 'thông báo'}!`);
      } else {
        await axios.post(`${API_URL}${endpoint}`, data);
        alert(`✅ Đã tạo ${type === 'meeting' ? 'lịch họp' : 'thông báo'} thành công!`);
      }
      onClose(); window.location.reload();
    } catch (err) {
      console.error(err);
      alert(`❌ Lỗi: ${err.response?.data?.error || "Không thể thực hiện thao tác"}`);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="bg-surface-container-lowest w-full max-w-2xl rounded-[2.5rem] p-10 shadow-2xl relative overflow-y-auto max-h-[90vh] transition-colors">
        <button onClick={onClose} className="absolute top-8 right-8 text-slate-400 hover:text-red-500 transition-colors"><Icon name="close" /></button>
        
        <div className="mb-8">
          <h2 className="text-2xl font-black text-on-surface mb-6">{isEdit ? "Chỉnh sửa" : "Tạo mới"}</h2>
          {!isEdit && (
            <div className="flex p-1 bg-surface-container-low rounded-2xl border border-border max-w-sm">
              <button onClick={() => setType('meeting')} className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-[10px] font-black tracking-widest transition-all ${type === 'meeting' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-on-surface-variant hover:text-on-surface'}`}>
                <Icon name="groups" className="!text-lg" /> CUỘC HỌP
              </button>
              <button onClick={() => setType('notification')} className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-[10px] font-black tracking-widest transition-all ${type === 'notification' ? 'bg-amber-500 text-white shadow-lg shadow-amber-500/20' : 'text-on-surface-variant hover:text-on-surface'}`}>
                <Icon name="campaign" className="!text-lg" /> THÔNG BÁO
              </button>
            </div>
          )}
        </div>
        
        <form onSubmit={handleSave} className="space-y-6 text-left">
          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">{type === 'meeting' ? 'Tiêu đề cuộc họp' : 'Tiêu đề thông báo'}</label>
            <input required className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl py-4 px-5 outline-none font-bold focus:border-primary transition-all text-slate-700 dark:text-slate-200" value={data.title} onChange={e => setData({...data, title: e.target.value})} />
          </div>

          <div className="space-y-2">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">{type === 'meeting' ? 'Nội dung họp' : 'Nội dung thông báo'}</label>
            <textarea rows="3" required className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl py-4 px-5 outline-none font-bold focus:border-primary transition-all text-slate-700 dark:text-slate-200" value={data.content} onChange={e => setData({...data, content: e.target.value})} />
          </div>
          
          {type === 'meeting' && (
            <>
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Thời gian bắt đầu</label>
                  <input required type="datetime-local" className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl py-4 px-5 outline-none font-bold focus:border-primary transition-all text-slate-700 dark:text-slate-200" value={data.start_time && !isNaN(new Date(data.start_time).getTime()) ? new Date(new Date(data.start_time).getTime() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 16) : ''} onChange={e => setData({...data, start_time: e.target.value})} />
                </div>
                
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Hình thức</label>
                  <div className="flex gap-2 p-1 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-100 dark:border-slate-700">
                    <button type="button" onClick={() => setData({...data, is_online: false})} className={`flex-1 py-3 rounded-xl font-black text-[10px] transition-all ${!data.is_online ? 'bg-white dark:bg-slate-700 shadow-sm text-primary' : 'text-slate-400'}`}>OFFLINE</button>
                    <button type="button" onClick={() => setData({...data, is_online: true})} className={`flex-1 py-3 rounded-xl font-black text-[10px] transition-all ${data.is_online ? 'bg-white dark:bg-slate-700 shadow-sm text-sky-500' : 'text-slate-400'}`}>ONLINE</button>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Địa điểm / Link họp</label>
                <input required className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl py-4 px-5 outline-none font-bold focus:border-primary transition-all text-slate-700 dark:text-slate-200" placeholder={data.is_online ? "Link Google Meet / Zoom" : "Vd: Phòng họp lớn, Tầng 3"} value={data.location} onChange={e => setData({...data, location: e.target.value})} />
              </div>
            </>
          )}

          <div className="space-y-4">
            <div className="flex justify-between items-center"><label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Phòng ban nhận thông tin</label><button type="button" onClick={() => setData({...data, department_ids: depts.map(d => d.id)})} className="text-[10px] font-black text-primary uppercase underline">Chọn tất cả</button></div>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {depts.map(d => (
                <button type="button" key={d.id} onClick={() => handleToggleDept(d.id)} className={`px-3 py-2.5 rounded-xl text-[10px] font-black border transition-all ${data.department_ids.includes(d.id) ? 'bg-primary text-white border-primary shadow-md shadow-primary/20' : 'bg-white dark:bg-slate-800 border-slate-100 dark:border-slate-700 text-slate-400 hover:border-slate-300 dark:hover:border-slate-500'}`}>{d.name}</button>
              ))}
            </div>
          </div>

          <button className={`w-full py-5 text-white rounded-full font-black shadow-xl uppercase text-xs tracking-[0.2em] mt-4 hover:scale-[1.02] transition-all ${type === 'meeting' ? 'brand-gradient' : 'bg-amber-500'}`}>
            {isEdit ? "CẬP NHẬT THÔNG TIN" : (type === 'meeting' ? "KÍCH HOẠT LỊCH HỌP & THÔNG BÁO" : "PHÁT HÀNH THÔNG BÁO NGAY")}
          </button>
        </form>
      </motion.div>
    </div>
  );
};

const DetailModal = ({ item, type, onClose, depts }) => {
  if (!item) return null;
  const getDeptNames = (ids) => {
    const list = Array.isArray(ids) ? ids : JSON.parse(ids || '[]');
    return list.map(id => depts.find(d => d.id === id)?.name || id).filter(Boolean);
  };
  
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/60 backdrop-blur-md p-4">
      <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="bg-surface-container-lowest w-full max-w-xl rounded-[3rem] p-10 shadow-2xl relative overflow-y-auto max-h-[85vh] border border-border/50">
        <button onClick={onClose} className="absolute top-8 right-8 w-10 h-10 rounded-full bg-slate-50 dark:bg-slate-800 flex items-center justify-center text-slate-400 hover:text-red-500 transition-all"><Icon name="close" /></button>
        
        <div className="flex items-center gap-4 mb-8">
          <div className={`w-16 h-16 rounded-2xl flex items-center justify-center ${type === 'meeting' ? 'bg-primary/10 text-primary' : 'bg-amber-500/10 text-amber-500'}`}>
            <Icon name={type === 'meeting' ? (item.is_online ? "videocam" : "meeting_room") : "campaign"} fill={1} className="text-3xl" />
          </div>
          <div>
            <span className={`px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest ${type === 'meeting' ? 'bg-primary/10 text-primary' : 'bg-amber-500/10 text-amber-500'}`}>{type === 'meeting' ? 'Lịch họp' : 'Thông báo'}</span>
            <h3 className="text-2xl font-black text-on-surface mt-1 leading-tight">{item.title}</h3>
          </div>
        </div>

        <div className="space-y-6">
          <div className="p-6 bg-slate-50 dark:bg-slate-800/50 rounded-3xl border border-slate-100/50 dark:border-slate-700/50">
            <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed font-medium whitespace-pre-wrap">{item.content}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-2xl border border-slate-100/50">
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Thời gian</p>
              <p className="text-xs font-black text-on-surface">{new Date(item.start_time || item.created_at).toLocaleString('vi-VN')}</p>
            </div>
            {type === 'meeting' && (
              <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-2xl border border-slate-100/50">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Địa điểm</p>
                <p className="text-xs font-black text-on-surface truncate">{item.location}</p>
              </div>
            )}
          </div>

          <div className="space-y-3">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Người nhận tin</p>
            <div className="flex flex-wrap gap-2">
              {getDeptNames(item.department_ids).length === 0 ? (
                <span className="px-4 py-2 bg-primary/10 text-primary rounded-xl text-[10px] font-black uppercase">Tất cả phòng ban</span>
              ) : (
                getDeptNames(item.department_ids).map((name, i) => (
                  <span key={i} className="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-500 rounded-xl text-[10px] font-black uppercase">{name}</span>
                ))
              )}
            </div>
          </div>
        </div>

        <button onClick={onClose} className="w-full py-5 bg-on-surface text-surface-container-lowest rounded-full font-black text-xs uppercase tracking-widest mt-10 hover:opacity-90 transition-all">Đóng cửa sổ</button>
      </motion.div>
    </div>
  );
};

const MeetingsView = ({ meetings = [], notifications = [], depts = [], onRefresh }) => {
  const [activeSubTab, setActiveSubTab] = useState('meeting'); // meeting, notification
  const [showModal, setShowModal] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [modalType, setModalType] = useState('meeting');
  const [editingItem, setEditingItem] = useState(null);
  const getLocalDate = (date) => {
    if (!date) return "";
    const d = new Date(date);
    if (isNaN(d.getTime())) return "";
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const [selectedDate, setSelectedDate] = useState(getLocalDate(new Date()));
  const [showOptions, setShowOptions] = useState(false);
  const [viewMode, setViewMode] = useState('daily'); // daily, history

  const handleDelete = async (id, itemType = 'meeting') => {
    const label = itemType === 'meeting' ? 'cuộc họp' : 'thông báo';
    if (!window.confirm(`Bạn có chắc chắn muốn xóa ${label} này?`)) return;
    try {
      const endpoint = itemType === 'meeting' ? 'meetings' : 'notifications';
      await axios.delete(`${API_URL}/${endpoint}/${id}`);
      if (onRefresh) onRefresh();
      else window.location.reload();
    } catch (err) { 
      console.error(err);
      alert(`❌ Lỗi khi xóa ${label}: ${err.response?.data?.error || err.message}`); 
    }
  };

  const getDeptNames = (ids) => {
    const list = Array.isArray(ids) ? ids : JSON.parse(ids || '[]');
    return list.map(id => depts.find(d => d.id === id)?.name || id).filter(Boolean);
  };

  const filterByDate = (list) => list.filter(item => {
    try {
      const dateStr = item.start_time || item.created_at;
      if (!dateStr) return false;
      return getLocalDate(dateStr) === selectedDate;
    } catch (e) { return false; }
  });

  const dailyMeetings = filterByDate(meetings).sort((a, b) => new Date(b.start_time || b.created_at) - new Date(a.start_time || a.created_at));
  const dailyNotifications = filterByDate(notifications).sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  const filteredItems = activeSubTab === 'meeting' ? dailyMeetings : dailyNotifications;

  const allHistory = [...meetings.map(m => ({...m, type: 'meeting'})), ...notifications.map(n => ({...n, type: 'notification'}))]
    .sort((a, b) => new Date(b.start_time || b.created_at) - new Date(a.start_time || a.created_at));

  if (viewMode === 'history') {
    return (
      <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <div className="flex items-center justify-between">
          <button onClick={() => setViewMode('daily')} className="flex items-center gap-2 text-slate-500 hover:text-primary transition-colors font-black text-xs uppercase tracking-widest">
            <Icon name="arrow_back" /> Quay lại quản lý
          </button>
          <h2 className="text-2xl font-black text-on-surface">Toàn bộ lịch sử nội dung</h2>
        </div>

        <div className="bg-surface-container-lowest rounded-[3rem] border border-border overflow-hidden shadow-sm">
          <div className="p-8 border-b border-border bg-slate-50/50 dark:bg-slate-800/50 flex justify-between items-center">
             <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Danh sách tổng hợp ({allHistory.length})</p>
             <div className="flex gap-4">
                <div className="flex items-center gap-2"><div className="w-2 h-2 rounded-full bg-primary"></div><span className="text-[9px] font-black uppercase text-slate-500">Lịch họp</span></div>
                <div className="flex items-center gap-2"><div className="w-2 h-2 rounded-full bg-amber-500"></div><span className="text-[9px] font-black uppercase text-slate-500">Thông báo</span></div>
             </div>
          </div>
          
          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {allHistory.map(item => (
              <div key={`${item.type}-${item.id}`} onClick={() => { setSelectedItem(item); setActiveSubTab(item.type); setShowDetail(true); }} className="p-8 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all cursor-pointer flex items-center gap-6 group">
                <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shrink-0 group-hover:scale-110 transition-transform ${item.type === 'meeting' ? 'bg-primary/10 text-primary' : 'bg-amber-500/10 text-amber-500'}`}>
                   <Icon name={item.type === 'meeting' ? (item.is_online ? "videocam" : "meeting_room") : "campaign"} fill={1} className="text-2xl" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-1">
                    <h4 className="font-black text-slate-800 dark:text-slate-100 group-hover:text-primary transition-colors">{item.title}</h4>
                    <span className={`px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-widest ${item.type === 'meeting' ? 'bg-primary/10 text-primary' : 'bg-amber-500/10 text-amber-500'}`}>{item.type === 'meeting' ? 'Họp' : 'Thông báo'}</span>
                  </div>
                  <p className="text-xs text-slate-500 font-medium line-clamp-1 italic">"{item.content}"</p>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-[11px] font-black text-slate-800 dark:text-slate-200 uppercase tracking-tighter">{new Date(item.start_time || item.created_at).toLocaleDateString('vi-VN')}</p>
                  <p className="text-[9px] font-black text-slate-400 uppercase">{new Date(item.start_time || item.created_at).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</p>
                </div>
                <Icon name="chevron_right" className="text-slate-300 group-hover:translate-x-1 transition-transform" />
              </div>
            ))}
          </div>
        </div>
        {showDetail && <DetailModal item={selectedItem} type={activeSubTab} depts={depts} onClose={() => setShowDetail(false)} />}
      </div>
    );
  }

  return (
    <div className="space-y-8 pb-20">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <h2 className="text-4xl font-extrabold tracking-tight text-on-surface">Lịch họp & Sự kiện</h2>
          <p className="text-slate-500 mt-1 font-medium italic">Điều phối các buổi họp phòng ban và trực tuyến.</p>
        </div>
        <div className="relative">
          <button 
            onClick={() => setShowOptions(!showOptions)}
            className="flex items-center gap-2 brand-gradient text-white px-8 py-4 rounded-full font-black shadow-lg hover:scale-105 active:scale-95 transition-all text-xs tracking-widest uppercase"
          >
            <Icon name="add" /> TẠO NỘI DUNG MỚI <Icon name={showOptions ? "expand_less" : "expand_more"} />
          </button>
          
          <AnimatePresence>
            {showOptions && (
              <motion.div 
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                className="absolute top-full mt-3 right-0 w-64 bg-surface-container-lowest rounded-3xl shadow-2xl border border-border p-2 z-50 overflow-hidden"
              >
                <button 
                  onClick={() => { setModalType('meeting'); setEditingItem(null); setShowModal(true); setShowOptions(false); }}
                  className="w-full flex items-center gap-4 px-4 py-4 hover:bg-primary/5 rounded-2xl transition-all group text-left"
                >
                  <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center group-hover:bg-primary group-hover:text-white transition-all"><Icon name="groups" fill={1} /></div>
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-on-surface">Lịch họp mới</p>
                    <p className="text-[9px] text-on-surface-variant font-medium italic mt-0.5">Đặt lịch họp phòng ban</p>
                  </div>
                </button>
                <button 
                  onClick={() => { setModalType('notification'); setEditingItem(null); setShowModal(true); setShowOptions(false); }}
                  className="w-full flex items-center gap-4 px-4 py-4 hover:bg-amber-500/5 rounded-2xl transition-all group text-left"
                >
                  <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-500 flex items-center justify-center group-hover:bg-amber-500 group-hover:text-white transition-all"><Icon name="campaign" fill={1} /></div>
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-on-surface">Thông báo mới</p>
                    <p className="text-[9px] text-on-surface-variant font-medium italic mt-0.5">Gửi thông báo quan trọng</p>
                  </div>
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      <div className="flex gap-4 p-1 bg-surface-container-low rounded-2xl w-fit">
        <button 
          onClick={() => setActiveSubTab('meeting')}
          className={`px-8 py-3 rounded-xl text-xs font-black transition-all ${activeSubTab === 'meeting' ? 'bg-primary text-white shadow-lg' : 'text-on-surface-variant hover:bg-surface-container'}`}
        >
          LỊCH HỌP ({dailyMeetings.length})
        </button>
        <button 
          onClick={() => setActiveSubTab('notification')}
          className={`px-8 py-3 rounded-xl text-xs font-black transition-all ${activeSubTab === 'notification' ? 'bg-amber-500 text-white shadow-lg' : 'text-on-surface-variant hover:bg-surface-container'}`}
        >
          THÔNG BÁO ({dailyNotifications.length})
        </button>
      </div>

      {/* Date Filter Bar */}
      <div className="bg-surface-container-lowest p-4 rounded-[2rem] shadow-sm border border-border flex items-center gap-4 transition-colors">
        <div className="flex items-center gap-2 px-6 border-r border-slate-100 dark:border-slate-800 shrink-0">
          <Icon name="calendar_today" className="text-primary" />
          <input type="date" className="font-black text-sm outline-none bg-transparent cursor-pointer text-slate-700 dark:text-slate-200" value={selectedDate} onChange={e => setSelectedDate(e.target.value)} />
        </div>
        <div className="flex gap-2 px-2 overflow-x-auto no-scrollbar">
          {[-1, 0, 1, 2, 3].map(offset => {
             const d = new Date(); d.setDate(d.getDate() + offset);
             const iso = getLocalDate(d);
             const isSelected = iso === selectedDate;
             return (
               <button key={offset} onClick={() => setSelectedDate(iso)} className={`px-5 py-2 rounded-2xl text-[10px] font-black transition-all shrink-0 ${isSelected ? 'bg-primary text-white shadow-md shadow-primary/20' : 'bg-slate-50 text-slate-400 hover:bg-slate-100'}`}>
                 {offset === 0 ? "HÔM NAY" : d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' })}
               </button>
             );
          })}
        </div>
        <button onClick={() => setViewMode('history')} className="text-[10px] font-black text-primary uppercase underline ml-auto px-4 shrink-0 hover:text-primary/70 transition-all">Xem chi tiết</button>
      </div>

      {filteredItems.length === 0 ? (
        <div className="py-20 flex flex-col items-center justify-center bg-surface-container-lowest rounded-[3rem] border border-dashed border-border transition-colors">
           <div className="w-20 h-20 rounded-full bg-slate-50 dark:bg-slate-800 flex items-center justify-center mb-4 text-slate-200 dark:text-slate-700"><Icon name="event_busy" className="text-4xl" /></div>
           <p className="text-slate-400 font-bold italic">Không có {activeSubTab === 'meeting' ? 'cuộc họp' : 'thông báo'} nào trong ngày đã chọn.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {filteredItems.map(item => (
            <motion.div onClick={() => { setSelectedItem(item); setShowDetail(true); }} layout initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} key={item.id} className={`group bg-surface-container-lowest p-8 rounded-[2.5rem] shadow-sm border border-border hover:shadow-xl transition-all relative overflow-hidden flex flex-col h-full cursor-pointer ${activeSubTab === 'meeting' ? 'hover:border-primary/20' : 'hover:border-amber-500/20'}`}>
              {activeSubTab === 'meeting' && (
                <div className={`absolute top-0 right-0 px-6 py-2 rounded-bl-3xl text-[9px] font-black uppercase tracking-widest z-10 ${item.is_online ? 'bg-sky-500 text-white shadow-lg shadow-sky-500/20' : 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/20'}`}>
                  {item.is_online ? 'Online' : 'Offline'}
                </div>
              )}
              
              <div className="flex items-start gap-4 mb-6">
                 <div className={`w-14 h-14 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform ${activeSubTab === 'meeting' ? 'bg-primary/10 text-primary' : 'bg-amber-500/10 text-amber-500'}`}>
                    <Icon name={activeSubTab === 'meeting' ? (item.is_online ? "videocam" : "meeting_room") : "campaign"} fill={1} className="text-2xl" />
                 </div>
                 <div className="flex-1">
                    <h4 className={`text-lg font-black leading-tight transition-colors ${activeSubTab === 'meeting' ? 'text-slate-800 dark:text-slate-100 group-hover:text-primary' : 'text-slate-800 dark:text-slate-100 group-hover:text-amber-500'}`}>{item.title}</h4>
                    <p className={`text-[11px] font-black mt-1 uppercase tracking-tighter ${activeSubTab === 'meeting' ? 'text-primary' : 'text-amber-500'}`}>
                      {new Date(item.start_time || item.created_at).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} • {new Date(item.start_time || item.created_at).toLocaleDateString('vi-VN')}
                    </p>
                 </div>
              </div>

              <div className="bg-slate-50 dark:bg-slate-800 p-5 rounded-2xl mb-6 flex-1 border border-slate-100/50 dark:border-slate-700/50">
                <p className="text-xs text-slate-500 leading-relaxed font-medium line-clamp-4">"{item.content}"</p>
              </div>

              <div className="space-y-4 mb-6">
                {activeSubTab === 'meeting' && (
                  <div className="flex items-center gap-3 text-slate-500">
                    <div className="w-6 h-6 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center"><Icon name="place" className="text-[14px]" /></div>
                    <span className="text-[11px] font-black truncate max-w-[200px]">{item.location}</span>
                  </div>
                )}
                <div className="flex flex-wrap gap-1.5 items-center">
                  <div className="w-6 h-6 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center mr-1"><Icon name="groups" className="text-[14px] text-slate-400" /></div>
                  {getDeptNames(item.department_ids).length === 0 ? (
                    <span className="px-2.5 py-1 bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 rounded-lg text-[9px] font-black uppercase tracking-tighter whitespace-nowrap">Tất cả phòng ban</span>
                  ) : (
                    getDeptNames(item.department_ids).map((name, i) => (
                      <span key={i} className="px-2.5 py-1 bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 rounded-lg text-[9px] font-black uppercase tracking-tighter whitespace-nowrap">{name}</span>
                    ))
                  )}
                </div>
              </div>

              <div className="flex gap-2 pt-4 border-t border-slate-50 dark:border-slate-800" onClick={e => e.stopPropagation()}>
                <button onClick={() => { setEditingItem(item); setModalType(activeSubTab); setShowModal(true); }} className="flex-1 py-3 bg-slate-50 dark:bg-slate-800 text-slate-600 dark:text-slate-400 rounded-xl font-black text-[10px] hover:bg-slate-200 transition-all uppercase tracking-widest border border-slate-100 dark:border-slate-700">Sửa</button>
                <button onClick={() => handleDelete(item.id, activeSubTab)} className="flex-[1.5] py-3 bg-red-50 dark:bg-red-900/20 text-red-500 rounded-xl font-black text-[10px] hover:bg-red-500 hover:text-white transition-all uppercase tracking-widest border border-red-100 dark:border-red-900/30">Xóa</button>
                {activeSubTab === 'meeting' && item.is_online && <button className="flex-1 py-3 bg-sky-50 dark:bg-sky-900/20 text-sky-600 rounded-xl font-black text-[10px] border border-sky-100 dark:border-sky-900/30 hover:bg-sky-500 hover:text-white transition-all uppercase tracking-widest">Link họp</button>}
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {showModal && <MeetingModal depts={depts} initialData={editingItem} defaultType={modalType} onClose={() => setShowModal(false)} />}
      {showDetail && <DetailModal item={selectedItem} type={activeSubTab} depts={depts} onClose={() => setShowDetail(false)} />}
    </div>
  );
};

export default MeetingsView;
