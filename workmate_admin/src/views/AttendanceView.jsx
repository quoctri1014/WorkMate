import React, { useState } from 'react';
import axios from 'axios';
import { Icon, API_URL } from '../components/Common';

const AttendanceView = ({ attendance = [], onRefresh }) => {
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await axios.put(`${API_URL}/attendance/${editing.id}`, {
        check_in: editing.check_in,
        check_out: editing.check_out === '--:--:--' ? null : editing.check_out,
        date: editing.date
      });
      setEditing(null);
      onRefresh();
    } catch (e) {
      alert('Lỗi khi lưu: ' + e.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-8">
      <h2 className="text-3xl font-extrabold tracking-tight">Nhật ký Chấm công</h2>
      <div className="bg-surface-container-lowest rounded-[2rem] p-8 shadow-sm border border-white dark:border-slate-800 overflow-hidden transition-colors">
        <table className="w-full text-left">
          <thead>
            <tr className="text-[11px] font-extrabold text-on-surface-variant uppercase tracking-wider border-b border-surface-container-low">
              <th className="pb-4 pl-4">Nhân viên</th>
              <th className="pb-4 text-center">Giờ vào</th>
              <th className="pb-4 text-center">Giờ ra</th>
              <th className="pb-4">Phương thức</th>
              <th className="pb-4 text-right pr-4">Trạng thái</th>
              <th className="pb-4 text-center">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container-low/40">
            {attendance.map(a => (
              <tr key={a.id} className="hover:bg-surface-container-low/20 transition-colors">
                <td className="py-5 pl-4 font-bold text-slate-800 dark:text-slate-100">{a.employee_name}</td>
                <td className="py-5 text-center font-mono font-bold text-primary">{a.check_in}</td>
                <td className="py-5 text-center font-mono font-bold text-amber-500">{a.check_out || '--:--:--'}</td>
                <td className="py-5"><div className="flex items-center gap-2"><Icon name={a.method === 'WiFi' ? 'wifi' : 'location_on'} className="text-sky-500" /><span className="text-xs font-semibold text-slate-600 dark:text-slate-300">{a.method}</span></div></td>
                <td className="py-5 text-right pr-4">
                  <span className={`px-3 py-1 ${a.check_out ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' : 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400'} rounded-full text-[11px] font-bold`}>
                    {a.check_out ? 'Hoàn tất' : 'Đang làm'}
                  </span>
                </td>
                <td className="py-5 text-center">
                  <button 
                    onClick={() => setEditing({ ...a })}
                    className="p-2 hover:bg-primary/10 text-primary rounded-lg transition-colors"
                  >
                    <Icon name="edit" className="!text-[18px]" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Edit Modal */}
      {editing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-[2.5rem] w-full max-w-md p-10 shadow-2xl border border-white/20">
            <h3 className="text-2xl font-black mb-6 tracking-tight">Chỉnh sửa giờ công</h3>
            <p className="text-sm text-slate-500 mb-8 font-medium italic">Thay đổi giờ công cho {editing.employee_name} ngày {editing.date}</p>
            
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
    </div>
  );
};

export default AttendanceView;
