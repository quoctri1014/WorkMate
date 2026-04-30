import React from 'react';
import { Icon } from '../components/Common';

const AttendanceView = ({ attendance = [] }) => (
  <div className="space-y-8">
    <h2 className="text-3xl font-extrabold tracking-tight">Nhật ký Chấm công</h2>
    <div className="bg-surface-container-lowest rounded-[2rem] p-8 shadow-sm border border-white dark:border-slate-800 overflow-hidden transition-colors">
      <table className="w-full text-left">
        <thead>
          <tr className="text-[11px] font-extrabold text-on-surface-variant uppercase tracking-wider border-b border-surface-container-low">
            <th className="pb-4 pl-4">Nhân viên</th>
            <th className="pb-4 text-center">Giờ vào</th>
            <th className="pb-4">Phương thức</th>
            <th className="pb-4 text-right pr-4">Trạng thái</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-surface-container-low/40">
          {attendance.map(a => (
            <tr key={a.id} className="hover:bg-surface-container-low/20 transition-colors">
            <td className="py-5 pl-4 font-bold text-slate-800 dark:text-slate-100">{a.employee_name}</td>
              <td className="py-5 text-center font-mono font-bold text-primary">{a.check_in}</td>
              <td className="py-5"><div className="flex items-center gap-2"><Icon name={a.method === 'WiFi' ? 'wifi' : 'location_on'} className="text-sky-500" /><span className="text-xs font-semibold text-slate-600 dark:text-slate-300">{a.method}</span></div></td>
              <td className="py-5 text-right pr-4"><span className="px-3 py-1 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 rounded-full text-[11px] font-bold">Hợp lệ</span></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

export default AttendanceView;
