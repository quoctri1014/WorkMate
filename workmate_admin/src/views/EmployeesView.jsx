import React, { useState } from 'react';
import axios from 'axios';
import { motion } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';

const formatDateForInput = (dateStr) => {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const formatDateDisplay = (dateStr) => {
  if (!dateStr) return 'Chưa cập nhật';
  const d = new Date(dateStr);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
};

export const EmployeeModal = ({ employee, depts = [], onClose, onRefresh }) => {
  const emp = employee;
  const [data, setData] = useState(employee ? { 
    ...employee, 
    join_date: formatDateForInput(employee.join_date),
    birthday: formatDateForInput(employee.birthday)
  } : { name: '', email: '', phone: '', department_id: depts[0]?.id || '', position: '', join_date: formatDateForInput(new Date()), birthday: '', password: '' });
  
  const [result, setResult] = useState(null);
  const [banks, setBanks] = useState([]);

  React.useEffect(() => {
    if (employee) {
      axios.get(`${API_URL}/employees/${employee.id}/banks`)
        .then(res => setBanks(res.data))
        .catch(err => console.error(err));
    }
  }, [employee]);

  const selectedDept = depts.find(d => d.id === parseInt(data.department_id));
  const positions = selectedDept ? (Array.isArray(selectedDept.positions) ? selectedDept.positions : JSON.parse(selectedDept.positions || '[]')) : [];

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      if (employee) {
        await axios.put(`${API_URL}/employees/${employee.id}`, data);
        alert("✅ Cập nhật hồ sơ thành công!");
        onRefresh(); onClose();
      } else {
        const res = await axios.post(`${API_URL}/employees`, data);
        setResult(res.data);
      }
    } catch (err) { 
      const msg = err.response?.data?.error || "Lỗi không xác định khi lưu thông tin!";
      alert(`❌ Lỗi: ${msg}`); 
    }
  };

  if (result) return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <div className="bg-surface-container-lowest w-full max-w-md rounded-[3rem] p-10 shadow-2xl text-center border border-border">
        <div className="w-24 h-24 bg-emerald-500/10 text-emerald-500 rounded-full flex items-center justify-center mx-auto mb-8 shadow-inner">
          <Icon name="check_circle" fill={1} className="text-5xl" />
        </div>
        <h2 className="text-3xl font-black text-on-surface mb-2 tracking-tight">Thành công!</h2>
        <p className="text-sm text-on-surface-variant mb-10 font-medium">Hồ sơ nhân sự mới đã được kích hoạt.</p>
        <div className="bg-surface-container-low p-8 rounded-[2.5rem] space-y-6 mb-10 border border-border text-left relative overflow-hidden">
           <div className="absolute top-0 right-0 w-20 h-20 bg-primary/5 rounded-full -mr-10 -mt-10"></div>
           <div><span className="text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em] block mb-2">Mã nhân viên</span><span className="font-mono font-black text-primary text-2xl tracking-wider">{result.employee_code}</span></div>
           <div className="h-px bg-border"></div>
           <div><span className="text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em] block mb-2">Mật khẩu tạm</span><span className="font-mono font-black text-emerald-600 text-2xl tracking-wider">{result.password}</span></div>
        </div>
        <button onClick={() => { onRefresh(); onClose(); }} className="w-full py-6 brand-gradient text-white rounded-full font-black shadow-xl uppercase tracking-[0.3em] text-sm hover:scale-[1.02] active:scale-95 transition-all">HOÀN TẤT VÀ ĐÓNG</button>
      </div>
    </div>
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 text-left">
      <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="bg-surface-container-lowest w-full max-w-4xl rounded-[3.5rem] p-12 shadow-2xl relative transition-colors overflow-y-auto max-h-[90vh]">
        <button onClick={onClose} className="absolute top-12 right-12 text-on-surface-variant hover:rotate-90 transition-all duration-500"><Icon name="close" /></button>
        
        <div className="flex items-center gap-6 mb-12">
          <div className="w-20 h-20 rounded-3xl brand-gradient flex items-center justify-center text-white shadow-2xl shadow-primary/20">
            <Icon name={emp ? "how_to_reg" : "person_add"} fill={1} className="!text-4xl" />
          </div>
          <div>
            <h2 className="text-4xl font-black text-on-surface tracking-tighter leading-none mb-2">{emp ? 'Chỉnh sửa hồ sơ' : 'Thêm nhân sự mới'}</h2>
            <p className="text-on-surface-variant font-medium text-sm italic">{emp ? `Mã nhân viên: ${emp.employee_code}` : 'Hệ thống sẽ tự động cấp mã và mật khẩu đăng nhập.'}</p>
          </div>
        </div>

        <form onSubmit={handleSave} className="space-y-10">
           <div className="grid grid-cols-2 gap-x-12 gap-y-8">
              <div className="space-y-3">
                <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Thông tin định danh</label>
                <div className="space-y-4">
                  <div className="relative group">
                    <Icon name="person" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" />
                    <input required placeholder="Họ và tên nhân viên" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface transition-all" value={data.name} onChange={e => setData({...data, name: e.target.value})} />
                  </div>
                  <div className="relative group">
                    <Icon name="mail" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" />
                    <input required type="email" placeholder="Email công việc" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface transition-all" value={data.email} onChange={e => setData({...data, email: e.target.value})} />
                  </div>
                  <div className="relative group">
                    <Icon name="call" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" />
                    <input required type="tel" placeholder="Số điện thoại liên hệ" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface transition-all" value={data.phone} onChange={e => setData({...data, phone: e.target.value})} />
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Vị trí & Phòng ban</label>
                <div className="space-y-4">
                  <div className="relative group">
                    <Icon name="corporate_fare" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <select className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface appearance-none transition-all" value={data.department_id} onChange={e => setData({...data, department_id: e.target.value, position: ''})}>
                       <option value="">Chọn phòng ban</option>
                       {depts.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                    </select>
                  </div>
                  <div className="relative group">
                    <Icon name="badge" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <select disabled={!data.department_id} className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface appearance-none disabled:opacity-50 transition-all" value={data.position} onChange={e => setData({...data, position: e.target.value})}>
                       <option value="">Chọn chức danh chuyên môn</option>
                       {positions.map((p, i) => <option key={i} value={p}>{p}</option>)}
                    </select>
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Thời gian & Liên hệ</label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="relative group">
                    <input type="date" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 px-6 outline-none font-bold text-on-surface transition-all" value={data.join_date} onChange={e => setData({...data, join_date: e.target.value})} title="Ngày vào làm" />
                  </div>
                  <div className="relative group">
                    <input type="date" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 px-6 outline-none font-bold text-on-surface transition-all" value={data.birthday} onChange={e => setData({...data, birthday: e.target.value})} title="Ngày sinh" />
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Bảo mật hệ thống</label>
                <div className="relative group">
                  <Icon name="lock" className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors" />
                  <input required={!emp} type="password" placeholder={emp ? "Nhập để thay đổi mật khẩu" : "Mật khẩu đăng nhập"} className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 pl-14 pr-6 outline-none font-bold text-on-surface transition-all" value={data.password} onChange={e => setData({...data, password: e.target.value})} />
                </div>
              </div>
           </div>

           {emp && banks.length > 0 && (
             <div className="pt-8 border-t border-border">
                <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2 mb-4 block">Tài khoản thanh toán ({banks.length})</label>
                <div className="grid grid-cols-2 gap-4">
                  {banks.map(b => (
                    <div key={b.id} className="bg-surface-container-low p-5 rounded-[2rem] flex items-center justify-between border border-border group hover:border-primary/30 transition-all">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-white dark:bg-slate-900 flex items-center justify-center text-primary shadow-sm group-hover:scale-110 transition-transform"><Icon name="account_balance" /></div>
                        <div>
                          <p className="text-sm font-black text-on-surface">{b.bank_name}</p>
                          <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-widest">{b.account_holder}</p>
                        </div>
                      </div>
                      <p className="font-mono font-black text-on-surface text-sm">{b.account_number}</p>
                    </div>
                  ))}
                </div>
             </div>
           )}

           <div className="pt-10">
             <button className="w-full py-7 brand-gradient text-white rounded-full font-black shadow-2xl shadow-primary/30 uppercase tracking-[0.4em] text-sm hover:scale-[1.02] active:scale-95 transition-all">
               XÁC NHẬN VÀ LƯU HỒ SƠ
             </button>
           </div>
        </form>
      </motion.div>
    </div>
  );
};

const EmployeesView = ({ employees = [], depts = [], onRefresh, onlineUsers = [] }) => {
  const [editing, setEditing] = useState(null);
  const [showAdd, setShowAdd] = useState(false);

  const handleDelete = async (id) => {
    if (!window.confirm("Bạn có chắc muốn xóa nhân viên này khỏi hệ thống?")) return;
    try {
      await axios.delete(`${API_URL}/employees/${id}`);
      onRefresh();
    } catch (err) { alert("Lỗi khi xóa nhân viên!"); }
  };

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-end mb-4">
        <div>
          <h2 className="text-4xl font-black tracking-tighter text-on-surface">Đội ngũ nhân sự</h2>
          <p className="text-on-surface-variant mt-1 font-medium italic">Quản lý và điều phối nguồn lực WorkMate.</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 brand-gradient text-white px-8 py-4 rounded-full font-black shadow-xl shadow-primary/20 hover:scale-105 active:scale-95 transition-all text-xs tracking-widest uppercase">
          <Icon name="person_add" fill={1} /> THÊM NHÂN SỰ MỚI
        </button>
      </div>
      <div className="bg-surface-container-lowest rounded-[3rem] shadow-sm overflow-hidden border border-border transition-colors">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-surface-container-low/30 border-b border-border">
              <th className="px-10 py-6 text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em]">Hồ sơ nhân viên</th>
              <th className="px-6 py-6 text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em]">Mã định danh</th>
              <th className="px-6 py-6 text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em]">Vị trí nghiệp vụ</th>
              <th className="px-6 py-6 text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em]">Phòng ban</th>
              <th className="px-10 py-6 text-[10px] font-black text-on-surface-variant uppercase tracking-[0.2em] text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {employees.map(e => (
              <tr key={e.id} className="hover:bg-primary/5 transition-all group">
                <td className="px-10 py-5">
                  <div className="flex items-center gap-4">
                    <div className="relative">
                      {e.avatar_url ? (
                        <img src={e.avatar_url.startsWith('http') ? e.avatar_url : `http://localhost:5000${e.avatar_url}`} className="w-12 h-12 rounded-2xl object-cover shadow-sm" alt={e.name} />
                      ) : (
                        <div className="w-12 h-12 rounded-2xl bg-primary-light flex items-center justify-center text-primary font-black text-lg shadow-inner">{e.name?.[0]}</div>
                      )}
                      <div className={`absolute -bottom-1 -right-1 w-4 h-4 border-2 border-surface rounded-full transition-colors duration-500 ${onlineUsers.includes(Number(e.id)) ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]' : 'bg-slate-400'}`}></div>
                    </div>
                    <div><p className="text-sm font-black text-on-surface mb-0.5">{e.name}</p><p className="text-[10px] font-bold text-on-surface-variant italic">{e.email}</p></div>
                  </div>
                </td>
                <td className="px-6 py-5"><span className="font-mono font-black text-primary text-xs bg-primary/5 px-3 py-1.5 rounded-lg border border-primary/10 tracking-wider">{e.employee_code}</span></td>
                <td className="px-6 py-5 text-[11px] font-black text-on-surface-variant uppercase tracking-widest">{e.position}</td>
                <td className="px-6 py-5 text-[11px] font-black text-on-surface uppercase tracking-widest">{e.department_name}</td>
                <td className="px-10 py-5 text-right">
                  <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-all scale-90 group-hover:scale-100">
                    <button onClick={() => setEditing(e)} className="p-2.5 text-primary hover:bg-primary/10 rounded-xl transition-all" title="Chỉnh sửa"><Icon name="edit" /></button>
                    <button onClick={() => handleDelete(e.id)} className="p-2.5 text-error hover:bg-error/10 rounded-xl transition-all" title="Xóa hồ sơ"><Icon name="delete" /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {(showAdd || editing) && (
        <EmployeeModal 
          employee={editing} 
          depts={depts} 
          onRefresh={onRefresh} 
          onClose={() => { setShowAdd(false); setEditing(null); }} 
        />
      )}
    </div>
  );
};

export default EmployeesView;
