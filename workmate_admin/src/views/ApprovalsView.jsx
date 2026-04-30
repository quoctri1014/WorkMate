import React from 'react';
import axios from 'axios';
import { Icon, API_URL } from '../components/Common';

const ApprovalsView = ({ approvals = [] }) => {
  const handleAction = async (id, status) => {
    try {
      await axios.put(`${API_URL}/approvals/${id}`, { status });
    } catch (err) {
      alert("Lỗi khi thực hiện thao tác!");
    }
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '---';
    return new Date(dateStr).toLocaleDateString('vi-VN');
  };
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-3xl font-black tracking-tight text-slate-800 dark:text-slate-100">Phê duyệt yêu cầu</h2>
          <p className="text-slate-500 dark:text-slate-400 mt-1 font-medium">Quản lý và xử lý các đơn báo nghỉ, tăng ca từ nhân viên.</p>
        </div>
        <div className="flex gap-2">
           <div className="px-4 py-2 bg-white border border-slate-200 rounded-xl shadow-sm text-xs font-bold text-slate-600 flex items-center gap-2">
             <span className="w-2 h-2 rounded-full bg-orange-400"></span> {approvals.filter(a => a.status === 'pending').length} Chờ duyệt
           </div>
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
              {approvals.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-12 text-center text-slate-400 font-medium">Chưa có yêu cầu nào cần xử lý</td>
                </tr>
              ) : approvals.map(a => {
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
    </div>
  );
};

export default ApprovalsView;
