import React, { useState, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
//, { useState, useRef } from 'react';
import axios from 'axios';
import { Icon, API_URL } from '../components/Common';

const AttendanceView = ({ attendance = [], onRefresh, selectedDate, onDateChange }) => {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [showExportModal, setShowExportModal] = useState(false);
  const [exportMonth, setExportMonth] = useState(() => {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  });
  const dateInputRef = useRef(null);

  const formatDateDisplay = (dateStr) => {
    if (!dateStr) return '---';
    try {
      const [y, m, d] = dateStr.split('-');
      return `${d}/${m}/${y}`;
    } catch (e) { return dateStr; }
  };

  // Tạo danh sách các ngày để hiển thị thanh chọn ngày
  const getDates = () => {
    const dates = [];
    const today = new Date();
    for (let i = -3; i <= 3; i++) {
      const d = new Date();
      d.setDate(today.getDate() + i);
      
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const full = `${year}-${month}-${day}`;

      dates.push({
        full: full,
        day: day,
        month: month,
        isToday: d.toDateString() === today.toDateString()
      });
    }
    return dates;
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!editing || !editing.id) {
      alert("Lỗi: Không xác định được ID bản ghi!");
      return;
    }
    
    setSaving(true);
    try {
      console.log(`🚀 Đang cập nhật attendance ID: ${editing.id}`, editing);
      const res = await axios.put(`${API_URL}/attendance/${editing.id}`, {
        check_in: editing.check_in,
        check_out: editing.check_out === '--:--:--' ? null : editing.check_out,
        date: editing.date
      });
      
      if (res.data.success) {
        setEditing(null);
        if (onRefresh) onRefresh({ date: selectedDate });
      } else {
        alert('Lỗi: ' + (res.data.error || 'Không rõ nguyên nhân'));
      }
    } catch (err) {
      console.error('❌ Lỗi handleSave:', err);
      alert('Lỗi khi lưu: ' + (err.response?.data?.error || err.message));
    } finally {
      setSaving(false);
    }
  };

  const handleExport = () => {
    const exportUrl = `${API_URL}/attendance/export?month=${exportMonth}`;
    window.open(exportUrl, '_blank');
    setShowExportModal(false);
  };

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <h2 className="text-3xl font-extrabold tracking-tight">Nhật ký Chấm công</h2>
        <button 
          onClick={() => setShowExportModal(true)}
          className="flex items-center gap-2 px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white rounded-2xl font-black text-sm transition-all shadow-lg shadow-emerald-500/20 active:scale-95"
        >
          <Icon name="download" className="!text-[20px]" />
          XUẤT BÁO CÁO EXCEL
        </button>
      </div>

      {/* Date Selection Bar */}
      <div className="relative group">
        <div className="flex flex-col lg:flex-row lg:items-center gap-4 bg-white dark:bg-slate-900 p-2 rounded-[2rem] shadow-sm border border-white dark:border-slate-800 transition-all hover:border-primary/30">
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1 px-2 flex-1 relative z-10">
            {getDates().map(d => (
              <button
                key={d.full}
                onClick={(e) => {
                  e.stopPropagation();
                  onDateChange(d.full);
                }}
                className={`flex flex-col items-center justify-center min-w-[70px] py-3 rounded-2xl transition-all relative z-30 ${
                  selectedDate === d.full
                  ? 'bg-primary text-white shadow-lg shadow-primary/25 font-black scale-105'
                  : 'hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 font-bold'
                }`}
              >
                <span className="text-[9px] uppercase tracking-wider mb-1">
                  {d.isToday ? 'Hôm nay' : `${d.day}-${d.month}`}
                </span>
                <span className="text-lg leading-none">{d.day}</span>
              </button>
            ))}
          </div>
          
          <div className="h-10 w-px bg-slate-200 dark:bg-slate-800 mx-2 hidden md:block" />
          
          <div 
            onClick={() => dateInputRef.current?.showPicker()}
            className="flex items-center gap-3 px-6 py-2 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50 rounded-2xl transition-all relative z-10 shrink-0"
          >
            <Icon name="calendar_today" className="text-primary !text-[20px]" />
            <div className="flex flex-col">
              <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">Ngày đang xem</span>
              <span className="font-black text-sm text-slate-700 dark:text-slate-200">
                {formatDateDisplay(selectedDate)}
              </span>
            </div>
            
            <input 
              ref={dateInputRef}
              type="date" 
              value={selectedDate}
              onChange={(e) => onDateChange(e.target.value)}
              className="absolute opacity-0 pointer-events-none w-0 h-0"
            />
          </div>
        </div>
      </div>

      <div className="bg-surface-container-lowest rounded-[2rem] p-4 sm:p-8 shadow-sm border border-white dark:border-slate-800 overflow-hidden transition-colors">
        <div className="overflow-x-auto w-full">
          <table className="w-full text-left border-collapse min-w-[800px]">
          <thead>
            <tr className="text-[11px] font-extrabold text-on-surface-variant uppercase tracking-wider border-b border-surface-container-low">
              <th className="pb-4 pl-4">Nhân viên</th>
              <th className="pb-4 text-center">Ngày</th>
              <th className="pb-4 text-center">Giờ vào</th>
              <th className="pb-4 text-center">Giờ ra</th>
              <th className="pb-4">Phương thức</th>
              <th className="pb-4 text-right pr-4">Trạng thái</th>
              <th className="pb-4 text-center">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container-low/40">
            {attendance.length > 0 ? attendance.map(a => (
              <tr key={a.id} className="hover:bg-surface-container-low/20 transition-colors group">
                <td className="py-5 pl-4 font-bold text-slate-800 dark:text-slate-100">{a.employee_name}</td>
                <td className="py-5 text-center text-xs font-black text-slate-500 uppercase tracking-tighter">
                  {a.date ? formatDateDisplay(a.date.split('T')[0]) : '---'}
                </td>
                <td className="py-5 text-center font-mono font-bold text-primary">{a.check_in}</td>
                <td className="py-5 text-center font-mono font-bold text-amber-500">{a.check_out || '--:--:--'}</td>
                <td className="py-5">
                  <div className="flex items-center gap-2">
                    <Icon name={a.method === 'WiFi' ? 'wifi' : 'location_on'} className="text-sky-500 !text-[16px]" />
                    <span className="text-xs font-semibold text-slate-600 dark:text-slate-300">{a.method}</span>
                  </div>
                </td>
                                <td className="py-5 text-right pr-4">
                  <span className={`px-3 py-1 ${
                    a.check_out 
                      ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' 
                      : a.is_forgot_penalty
                        ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                        : a.is_forgot_checkout
                          ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400'
                          : 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400'
                  } rounded-full text-[11px] font-bold`}>
                    {a.check_out 
                      ? t('attendance_completed', 'Hoàn tất') 
                      : a.is_forgot_penalty
                        ? t('forgot_checkout_penalty', 'Quên check out (Phạt)')
                        : a.is_forgot_checkout
                          ? t('forgot_checkout', 'Quên check out')
                          : t('working', 'Đang làm')
                    }
                  </span>
                </td>
                <td className="py-5 text-center">
                  <button 
                    onClick={() => {
                      console.log("✏️ Editing attendance:", a);
                      setEditing({ ...a });
                    }}
                    className="p-2 hover:bg-primary/10 text-primary rounded-xl transition-all opacity-0 group-hover:opacity-100"
                  >
                    <Icon name="edit" className="!text-[18px]" />
                  </button>
                </td>
              </tr>
            )) : (
              <tr>
                <td colSpan="7" className="py-20 text-center text-slate-400 font-medium italic">Không có dữ liệu chấm công cho ngày này</td>
              </tr>
            )}
          </tbody>
        </table>
        </div>
      </div>

      {/* Edit Modal */}
      {editing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-[2.5rem] w-full max-w-md p-6 md:p-10 shadow-2xl border border-white/20">
            <h3 className="text-2xl font-black mb-2 tracking-tight">Chỉnh sửa giờ công</h3>
            <p className="text-sm text-slate-500 mb-8 font-medium italic">
              ID: {editing.id} | {editing.employee_name} ngày {editing.date}
            </p>
            
            <form onSubmit={handleSave} className="space-y-6">
              <div>
                <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Giờ vào (HH:mm:ss)</label>
                <input 
                  type="text" 
                  value={editing.check_in} 
                  onChange={e => setEditing({...editing, check_in: e.target.value})}
                  className="w-full mt-2 bg-slate-50 dark:bg-slate-800/50 border-none rounded-2xl px-6 py-4 font-mono font-bold text-primary focus:ring-2 focus:ring-primary/20 transition-all outline-none"
                />
              </div>
              
              <div>
                <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-1">Giờ ra (HH:mm:ss)</label>
                <input 
                  type="text" 
                  value={editing.check_out || ''} 
                  placeholder="--:--:--"
                  onChange={e => setEditing({...editing, check_out: e.target.value})}
                  className="w-full mt-2 bg-slate-50 dark:bg-slate-800/50 border-none rounded-2xl px-6 py-4 font-mono font-bold text-amber-500 focus:ring-2 focus:ring-amber-500/20 transition-all outline-none"
                />
              </div>

              <div className="flex gap-4 pt-4">
                <button 
                  type="button"
                  onClick={() => setEditing(null)}
                  className="flex-1 py-4 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 rounded-2xl font-bold text-sm hover:bg-slate-200 transition-all"
                >
                  Hủy
                </button>
                <button 
                  type="submit"
                  disabled={saving}
                  className="flex-1 py-4 brand-gradient text-white rounded-2xl font-black text-sm shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
                >
                  {saving ? 'Đang lưu...' : 'Lưu thay đổi'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Export Modal */}
      {showExportModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-[2.5rem] w-full max-w-md p-6 md:p-10 shadow-2xl border border-white/20 transition-colors">
            <h3 className="text-2xl font-black mb-6 tracking-tight">Xuất báo cáo tháng</h3>
            <p className="text-sm text-slate-500 mb-8 font-medium">Chọn tháng bạn muốn kết xuất dữ liệu Excel</p>
            
            <div className="space-y-6">
              <input 
                type="month" 
                value={exportMonth}
                onChange={(e) => setExportMonth(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800/50 border-none rounded-2xl px-6 py-4 font-bold text-slate-700 dark:text-slate-200 focus:ring-2 focus:ring-emerald-500/20 transition-all outline-none"
              />

              <div className="flex gap-4 pt-4">
                <button 
                  onClick={() => setShowExportModal(false)}
                  className="flex-1 py-4 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 rounded-2xl font-bold text-sm hover:bg-slate-200 transition-all"
                >
                  Hủy
                </button>
                <button 
                  onClick={handleExport}
                  className="flex-1 py-4 bg-emerald-500 text-white rounded-2xl font-black text-sm shadow-lg shadow-emerald-500/20 hover:scale-[1.02] active:scale-[0.98] transition-all"
                >
                  TẢI FILE EXCEL
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceView;
