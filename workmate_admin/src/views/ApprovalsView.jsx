import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Icon, API_URL } from '../components/Common';

const AdminAssignModal = ({ onClose, onRefresh }) => {
  const [departments, setDepartments] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [selectedFilterDept, setSelectedFilterDept] = useState('all');
  const [customType, setCustomType] = useState('');
  const [formData, setFormData] = useState({
    type: 'Làm thêm giờ',
    reason: '',
    from_date: '',
    to_date: '',
    total_hours: 0,
    is_half_day: false,
    assign_type: 'dept', // 'dept' or 'emp'
    department_id: '',
    employee_ids: []
  });

  useEffect(() => {
    fetchDepts();
    fetchEmps();
  }, []);

  const fetchDepts = async () => {
    const res = await axios.get(`${API_URL}/departments`);
    setDepartments(res.data);
  };

  const fetchEmps = async () => {
    const res = await axios.get(`${API_URL}/employees`);
    setEmployees(res.data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (formData.assign_type === 'emp' && formData.employee_ids.length === 0) {
      alert("Vui lòng chọn ít nhất một nhân viên!");
      return;
    }

    const finalType = formData.type === 'Khác' ? customType : formData.type;
    if (!finalType) {
      alert("Vui lòng nhập loại lịch!");
      return;
    }

    try {
      await axios.post(`${API_URL}/approvals/admin-assign`, {
        ...formData,
        type: finalType
      });
      alert("Đã gán lịch thành công!");
      onRefresh();
      onClose();
    } catch (err) {
      alert("Lỗi khi gán lịch: " + (err.response?.data?.error || err.message));
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <div className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-300">
        <div className="px-8 py-6 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-100 dark:border-slate-800 flex justify-between items-center">
          <div>
            <h3 className="text-xl font-black text-slate-800 dark:text-slate-100">Gán lịch OT / Nghỉ mới</h3>
            <p className="text-xs text-slate-500 font-bold uppercase tracking-wider mt-1">Chủ động quản lý thời gian nhân viên</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-full transition-colors">
            <Icon name="close" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-8 space-y-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-3">
              <div>
                <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Loại lịch</label>
                <select 
                  className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                  value={formData.type}
                  onChange={(e) => setFormData({...formData, type: e.target.value})}
                >
                  <option value="Làm thêm giờ">Làm thêm giờ</option>
                  <option value="Nghỉ">Nghỉ</option>
                  <option value="Công tác">Công tác</option>
                  <option value="Khác">Khác...</option>
                </select>
              </div>
              {formData.type === 'Khác' && (
                <div className="animate-in slide-in-from-top-2 duration-300">
                  <input 
                    type="text"
                    placeholder="Nhập loại lịch khác..."
                    className="w-full px-4 py-2 bg-slate-100 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-bold focus:ring-1 ring-primary transition-all"
                    value={customType}
                    onChange={(e) => setCustomType(e.target.value)}
                    required
                  />
                </div>
              )}
            </div>
            <div>
              <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Đối tượng gán</label>
              <select 
                className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                value={formData.assign_type}
                onChange={(e) => setFormData({...formData, assign_type: e.target.value, department_id: '', employee_ids: []})}
              >
                <option value="dept">Theo phòng ban</option>
                <option value="emp">Chọn nhân viên cụ thể</option>
              </select>
            </div>
          </div>

          {formData.assign_type === 'dept' ? (
            <div className="animate-in slide-in-from-top-2 duration-300">
              <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Chọn phòng ban</label>
              <select 
                className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                value={formData.department_id}
                onChange={(e) => setFormData({...formData, department_id: e.target.value})}
                required
              >
                <option value="">-- Chọn phòng ban --</option>
                <option value="all">Tất cả phòng ban (Toàn công ty)</option>
                {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
              </select>
            </div>
          ) : (
            <div className="space-y-4 animate-in slide-in-from-top-2 duration-300">
              <div className="flex items-center gap-4">
                <div className="flex-1">
                  <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Lọc theo phòng ban</label>
                  <select 
                    className="w-full px-4 py-2 bg-slate-50 dark:bg-slate-800 border-none rounded-lg text-xs font-bold focus:ring-1 ring-primary transition-all"
                    value={selectedFilterDept}
                    onChange={(e) => setSelectedFilterDept(e.target.value)}
                  >
                    <option value="all">Tất cả phòng ban</option>
                    {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                </div>
                <div className="pt-5">
                  <span className="text-[10px] font-black text-slate-400 uppercase">Đã chọn: {formData.employee_ids.length}</span>
                </div>
              </div>
              <div>
                <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Chọn nhân viên</label>
                <div className="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto p-4 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-100 dark:border-slate-700 custom-scrollbar">
                  {employees
                    .filter(e => selectedFilterDept === 'all' || e.department_id?.toString() === selectedFilterDept.toString())
                    .map(e => (
                    <label key={e.id} className="flex items-center gap-2 p-2 hover:bg-white dark:hover:bg-slate-700 rounded-xl cursor-pointer transition-all border border-transparent hover:border-slate-100 dark:hover:border-slate-600 group">
                      <input 
                        type="checkbox" 
                        className="rounded-md border-none bg-slate-200 dark:bg-slate-600 text-primary focus:ring-0"
                        checked={formData.employee_ids.includes(e.id)}
                        onChange={(cb) => {
                          const ids = cb.target.checked 
                            ? [...formData.employee_ids, e.id]
                            : formData.employee_ids.filter(id => id !== e.id);
                          setFormData({...formData, employee_ids: ids});
                        }}
                      />
                      <div className="flex flex-col">
                        <span className="text-xs font-bold text-slate-700 dark:text-slate-200 group-hover:text-primary transition-colors">{e.name}</span>
                        <span className="text-[9px] font-black text-slate-400 uppercase tracking-tighter">Mã NV: {e.employee_code}</span>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>
          )}

          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Từ ngày / Giờ bắt đầu</label>
              <input 
                type="datetime-local"
                className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                value={formData.from_date}
                onChange={(e) => setFormData({...formData, from_date: e.target.value})}
                required
              />
            </div>
            <div>
              <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Đến ngày / Giờ kết thúc</label>
              <input 
                type="datetime-local"
                className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                value={formData.to_date}
                onChange={(e) => setFormData({...formData, to_date: e.target.value})}
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Số giờ (nếu là OT)</label>
              <input 
                type="number" step="0.5"
                className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-xl text-sm font-bold focus:ring-2 ring-primary transition-all"
                value={formData.total_hours}
                onChange={(e) => setFormData({...formData, total_hours: e.target.value})}
              />
            </div>
            <div className="flex items-center gap-3 pt-6">
              <input 
                type="checkbox"
                id="is_half_day"
                className="w-5 h-5 rounded-md border-none bg-slate-100 dark:bg-slate-800 text-primary focus:ring-0"
                checked={formData.is_half_day}
                onChange={(e) => setFormData({...formData, is_half_day: e.target.checked})}
              />
              <label htmlFor="is_half_day" className="text-xs font-black uppercase tracking-widest text-slate-500 cursor-pointer">Nghỉ nửa ngày</label>
            </div>
          </div>

          <div>
            <label className="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-2">Lý do / Mô tả công việc</label>
            <textarea 
              className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-none rounded-2xl text-sm font-bold focus:ring-2 ring-primary transition-all min-h-[100px]"
              placeholder="Nhập lý do hoặc nội dung công việc assigned..."
              value={formData.reason}
              onChange={(e) => setFormData({...formData, reason: e.target.value})}
              required
            ></textarea>
          </div>

          <div className="pt-4 flex gap-4">
            <button type="button" onClick={onClose} className="flex-1 py-4 bg-slate-100 dark:bg-slate-800 text-slate-500 font-black uppercase tracking-widest text-[11px] rounded-2xl hover:bg-slate-200 transition-all">Hủy bỏ</button>
            <button type="submit" className="flex-[2] py-4 bg-primary text-white font-black uppercase tracking-widest text-[11px] rounded-2xl shadow-lg shadow-primary/25 hover:scale-[1.02] active:scale-95 transition-all">Xác nhận gán lịch</button>
          </div>
        </form>
      </div>
    </div>
  );
};

const ApprovalsView = ({ approvals = [], onRefresh }) => {
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7)); // YYYY-MM

  const handleAction = async (id, status) => {
    try {
      await axios.put(`${API_URL}/approvals/${id}`, { status });
      if (onRefresh) onRefresh();
    } catch (err) {
      alert("Lỗi khi thực hiện thao tác!");
    }
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '---';
    return new Date(dateStr).toLocaleDateString('vi-VN');
  };

  const filteredApprovals = approvals
    .filter(a => {
      const matchStatus = filterStatus === 'all' || a.status === filterStatus;
      const matchMonth = a.created_at && a.created_at.startsWith(selectedMonth);
      return matchStatus && matchMonth;
    })
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  // Generate last 12 months for the filter
  const monthOptions = [];
  for (let i = 0; i < 12; i++) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    monthOptions.push(d.toISOString().slice(0, 7));
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-3xl font-black tracking-tight text-slate-800 dark:text-slate-100">Phê duyệt yêu cầu</h2>
          <p className="text-slate-500 dark:text-slate-400 mt-1 font-medium">Quản lý và xử lý các đơn báo nghỉ, tăng ca từ nhân viên.</p>
        </div>
        <div className="flex gap-2">
           <button 
             onClick={() => setShowAssignModal(true)}
             className="px-6 py-3 bg-primary text-white rounded-2xl shadow-lg shadow-primary/25 text-xs font-black uppercase tracking-widest flex items-center gap-2 hover:scale-[1.05] transition-all active:scale-95"
           >
             <Icon name="add" className="!text-lg" /> Gán lịch mới
           </button>
           <div className="px-4 py-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-sm text-xs font-bold text-slate-600 dark:text-slate-400 flex items-center gap-2">
             <span className="w-2 h-2 rounded-full bg-orange-400"></span> {approvals.filter(a => a.status === 'pending').length} Chờ duyệt
           </div>
        </div>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex flex-wrap gap-3">
          {[
            { id: 'all', label: 'Tất cả' },
            { id: 'pending', label: 'Chờ duyệt' },
            { id: 'approved', label: 'Đã duyệt' },
            { id: 'rejected', label: 'Từ chối' }
          ].map(s => (
            <button 
              key={s.id}
              onClick={() => setFilterStatus(s.id)}
              className={`px-6 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${
                filterStatus === s.id 
                ? 'bg-slate-800 dark:bg-white text-white dark:text-slate-900 shadow-lg' 
                : 'bg-white dark:bg-slate-900 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 border border-slate-100 dark:border-slate-800'
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-3 px-4 py-2 bg-white dark:bg-slate-800 rounded-2xl border border-slate-100 dark:border-slate-800 shadow-sm">
          <Icon name="calendar_month" className="text-slate-400 !text-lg" />
          <select 
            className="bg-transparent border-none text-xs font-black uppercase tracking-widest text-slate-600 dark:text-slate-300 focus:ring-0 cursor-pointer"
            value={selectedMonth}
            onChange={(e) => setSelectedMonth(e.target.value)}
          >
            {monthOptions.map(m => {
              const [year, month] = m.split('-');
              return (
                <option key={m} value={m} className="dark:bg-slate-900">
                  Tháng {month} / {year}
                </option>
              );
            })}
          </select>
        </div>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-[2rem] shadow-xl shadow-slate-200/50 dark:shadow-none border border-slate-100 dark:border-slate-800 overflow-hidden transition-colors">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50/50 dark:bg-slate-800/50 border-b border-slate-100 dark:border-slate-800">
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest">Nhân viên</th>
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest">Loại yêu cầu</th>
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest">Thời gian</th>
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest">Lý do / Nội dung</th>
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest text-center">Trạng thái</th>
                <th className="px-6 py-5 text-[11px] font-black text-slate-400 uppercase tracking-widest text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50 dark:divide-slate-800">
              {filteredApprovals.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-12 text-center text-slate-400 font-medium">Không có dữ liệu trong tháng {selectedMonth.split('-')[1]} / {selectedMonth.split('-')[0]}</td>
                </tr>
              ) : filteredApprovals.map(a => {
                let attachments = [];
                try {
                  attachments = typeof a.attachment_urls === 'string' ? JSON.parse(a.attachment_urls) : (a.attachment_urls || []);
                } catch (e) { attachments = []; }

                const isOT = a.type === 'Làm thêm giờ';

                return (
                  <tr key={a.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-sky-100 dark:bg-sky-900/30 text-sky-700 dark:text-sky-400 flex items-center justify-center font-black text-sm uppercase border-2 border-white dark:border-slate-800 shadow-sm transition-colors">
                          {a.employee_name?.[0]}
                        </div>
                        <div className="font-bold text-slate-700 dark:text-slate-200 text-sm">{a.employee_name}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 text-[10px] font-black rounded-lg uppercase tracking-widest ${isOT ? 'bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400' : (a.type === 'Nghỉ bệnh' ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400' : 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400')}`}>
                        {a.type}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-bold text-slate-600 dark:text-slate-400">
                        {isOT ? formatDate(a.from_date) : `${formatDate(a.from_date)} - ${formatDate(a.to_date)}`}
                      </div>
                      {isOT && <div className="text-[10px] text-indigo-500 font-black uppercase mt-0.5">Số giờ: {a.total_hours}h</div>}
                      {!isOT && a.is_half_day && <div className="text-[10px] text-orange-500 font-black uppercase mt-0.5">Nghỉ nửa ngày</div>}
                    </td>
                    <td className="px-6 py-4">
                      <div className="max-w-xs">
                        <p className="text-xs text-slate-500 dark:text-slate-400 line-clamp-2 italic">"{a.reason}"</p>
                        {attachments.length > 0 && (
                          <div className="flex gap-1.5 mt-2">
                            {attachments.map((url, idx) => (
                              <a key={idx} href={url.startsWith('http') ? url : `http://localhost:5000${url}`} target="_blank" rel="noreferrer" className="w-8 h-8 rounded-md overflow-hidden border border-slate-200 dark:border-slate-700 hover:scale-110 transition-transform">
                                <img src={url.startsWith('http') ? url : `http://localhost:5000${url}`} className="w-full h-full object-cover" alt="Minh chứng" />
                              </a>
                            ))}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[10px] font-black uppercase tracking-wider ${
                        a.status === 'pending' ? 'bg-amber-50 dark:bg-amber-900/20 text-amber-600' : 
                        a.status === 'approved' ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600' : 'bg-rose-50 dark:bg-rose-900/20 text-rose-600'
                      }`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${
                          a.status === 'pending' ? 'bg-amber-400' : 
                          a.status === 'approved' ? 'bg-emerald-400' : 'bg-rose-400'
                        }`}></span>
                        {a.status === 'pending' ? 'Chờ duyệt' : a.status === 'approved' ? 'Đã duyệt' : 'Từ chối'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      {a.status === 'pending' ? (
                        <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button onClick={() => handleAction(a.id, 'rejected')} className="p-2 text-slate-400 hover:text-error hover:bg-error/10 rounded-lg transition-all" title="Từ chối">
                            <Icon name="close" className="!text-lg" />
                          </button>
                          <button onClick={() => handleAction(a.id, 'approved')} className="p-2 text-white bg-primary hover:bg-primary-dark rounded-lg shadow-md shadow-primary/20 transition-all" title="Phê duyệt">
                            <Icon name="check" className="!text-lg" />
                          </button>
                        </div>
                      ) : (
                        <span className="text-[10px] font-bold text-slate-300 uppercase italic">Xong</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {showAssignModal && (
        <AdminAssignModal 
          onClose={() => setShowAssignModal(false)} 
          onRefresh={onRefresh} 
        />
      )}
    </div>
  );
};

export default ApprovalsView;

