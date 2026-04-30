import React, { useState } from 'react';
import axios from 'axios';
import { motion } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';

export const AddDeptModal = ({ dept, onClose, onRefresh }) => {
  const [data, setData] = useState(dept ? { ...dept, positions: (Array.isArray(dept.positions) ? dept.positions : JSON.parse(dept.positions || '[]')) } : { name: '', code: '', positions: [] });
  const [newPos, setNewPos] = useState('');

  const handleAddPos = () => {
    if (!newPos) return;
    setData({ ...data, positions: [...data.positions, newPos] });
    setNewPos('');
  };

  const handleRemovePos = (idx) => {
    const p = [...data.positions];
    p.splice(idx, 1);
    setData({ ...data, positions: p });
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!data.name || !data.code || data.positions.length === 0) {
      alert("Vui lòng nhập đầy đủ thông tin và ít nhất 1 chức danh!");
      return;
    }
    try {
      if (dept) {
        await axios.put(`${API_URL}/departments/${dept.id}`, { ...data, positions: JSON.stringify(data.positions) });
      } else {
        await axios.post(`${API_URL}/departments`, { ...data, positions: JSON.stringify(data.positions) });
      }
      alert("✅ Lưu thông tin phòng ban thành công!");
      onRefresh(); onClose();
    } catch (err) { alert("Lỗi khi lưu phòng ban! Hãy kiểm tra mã phòng có bị trùng không."); }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="bg-surface-container-lowest w-full max-w-2xl rounded-[2.5rem] p-12 shadow-2xl relative border border-border">
        <button onClick={onClose} className="absolute top-10 right-10 text-on-surface-variant hover:rotate-90 transition-all duration-300"><Icon name="close" /></button>
        <h2 className="text-4xl font-black mb-12 text-on-surface tracking-tighter">{dept ? 'Cập nhật phòng ban' : 'Thêm phòng ban mới'}</h2>

        <form onSubmit={handleSave} className="space-y-8 text-left">
            <div className="grid grid-cols-2 gap-8">
               <div className="space-y-3">
                  <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Tên phòng ban</label>
                  <input required placeholder="Vd: Phòng Kỹ thuật" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-6 outline-none font-bold text-on-surface transition-all placeholder:text-on-surface-variant/30" value={data.name} onChange={e => setData({...data, name: e.target.value})} />
               </div>
               <div className="space-y-3">
                  <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Mã phòng (2-3 ký tự)</label>
                  <input required maxLength="3" placeholder="Vd: TECH" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-6 outline-none font-bold uppercase text-on-surface transition-all placeholder:text-on-surface-variant/30" value={data.code} onChange={e => setData({...data, code: e.target.value.toUpperCase()})} />
               </div>
            </div>

            <div className="space-y-4">
               <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-2">Thiết lập các chức danh</label>
               <div className="flex gap-4">
                  <input className="flex-1 bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-6 outline-none font-bold text-on-surface transition-all placeholder:text-on-surface-variant/30" placeholder="Vd: Senior Developer" value={newPos} onChange={e => setNewPos(e.target.value)} onKeyPress={e => e.key === 'Enter' && (e.preventDefault(), handleAddPos())} />
                  <button type="button" onClick={handleAddPos} className="w-16 h-16 brand-gradient text-white rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-110 active:scale-95 transition-all"><Icon name="add" className="!text-3xl" /></button>
               </div>
               <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto p-1 custom-scrollbar">
                  {data.positions.map((p, i) => (
                     <div key={i} className="flex items-center gap-3 px-6 py-3 bg-primary/10 text-primary rounded-2xl text-xs font-black border border-primary/20 group hover:bg-primary/20 transition-all">
                        {p} 
                        <button type="button" onClick={() => handleRemovePos(i)} className="text-on-surface-variant/50 hover:text-error transition-colors">
                          <Icon name="close" className="!text-[16px]" />
                        </button>
                     </div>
                  ))}
               </div>
            </div>

           <button className="w-full py-5 brand-gradient text-white rounded-full font-black shadow-xl uppercase text-sm tracking-[0.2em] mt-4">XÁC NHẬN LƯU THÔNG TIN</button>
        </form>
      </motion.div>
    </div>
  );
};

const DepartmentsView = ({ depts = [], onRefresh }) => {
  const [showAdd, setShowAdd] = useState(false);
  const [editing, setEditing] = useState(null);

  const handleDelete = async (id) => {
    if (!window.confirm("Bạn có chắc muốn xóa phòng ban này? Nhân viên thuộc phòng này sẽ bị ảnh hưởng.")) return;
    await axios.delete(`${API_URL}/departments/${id}`);
    onRefresh();
  };

  return (
    <div className="space-y-10">
      <div className="flex justify-between items-end">
        <div><h2 className="text-4xl font-extrabold tracking-tight">Cấu trúc Tổ chức</h2><p className="text-on-surface-variant mt-1 font-medium">Quản lý các phòng ban và chức danh chuyên môn.</p></div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 brand-gradient text-white px-8 py-4 rounded-full font-black shadow-xl hover:scale-105 transition-all"><Icon name="domain_add" /> THÊM PHÒNG BAN MỚI</button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {depts.map(d => (
          <div key={d.id} className="bg-surface-container-lowest p-8 rounded-[2.5rem] shadow-sm border border-border flex flex-col gap-8 relative group overflow-hidden transition-all hover:shadow-2xl hover:shadow-primary/5 hover:-translate-y-1">
             <div className="absolute top-0 right-0 w-24 h-24 bg-primary/5 rounded-full -mr-12 -mt-12 transition-all group-hover:scale-150"></div>
             
             <div className="flex justify-between items-start relative z-10">
                <div className="flex items-center gap-6">
                   <div className="w-16 h-16 rounded-2xl bg-primary-light flex items-center justify-center text-primary font-black text-2xl shadow-inner transition-colors group-hover:bg-primary group-hover:text-white">{d.code}</div>
                   <div>
                     <h3 className="text-2xl font-black text-on-surface transition-colors leading-none mb-2">{d.name}</h3>
                     <div className="flex items-center gap-2">
                       <span className="px-2 py-0.5 bg-primary/10 text-primary text-[9px] font-black rounded-md uppercase">Mã PB: {d.code}</span>
                       <span className="text-[9px] text-on-surface-variant font-bold uppercase tracking-widest">ID: {d.id}</span>
                     </div>
                   </div>
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all scale-90 group-hover:scale-100">
                   <button onClick={() => setEditing(d)} className="p-2.5 text-primary hover:bg-primary/10 rounded-xl transition-all"><Icon name="edit" /></button>
                   <button onClick={() => handleDelete(d.id)} className="p-2.5 text-error hover:bg-error/10 rounded-xl transition-all"><Icon name="delete" /></button>
                </div>
             </div>

             <div className="space-y-4 relative z-10 flex-1">
                <div className="flex items-center gap-2">
                   <div className="h-px flex-1 bg-border"></div>
                   <p className="text-[9px] font-black text-on-surface-variant uppercase tracking-widest px-2">Nhóm chức danh chuyên môn</p>
                   <div className="h-px flex-1 bg-border"></div>
                </div>
                <div className="flex flex-wrap gap-2">
                   {(Array.isArray(d.positions) ? d.positions : JSON.parse(d.positions || '[]')).map((pos, idx) => (
                     <span key={idx} className="px-4 py-2 bg-surface-container-low text-on-surface-variant rounded-xl text-[10px] font-bold border border-border/50 hover:border-primary/30 transition-all cursor-default">{pos}</span>
                   ))}
                   {(Array.isArray(d.positions) ? d.positions : JSON.parse(d.positions || '[]')).length === 0 && (
                     <div className="w-full py-4 text-center border-2 border-dashed border-border rounded-2xl">
                       <p className="text-[10px] italic text-on-surface-variant font-medium">Chưa thiết lập chức danh chuyên môn</p>
                     </div>
                   )}
                </div>
             </div>
             
             <div className="pt-4 border-t border-border flex justify-between items-center relative z-10">
               <div></div>
               <button onClick={() => setEditing(d)} className="text-[10px] font-black text-primary uppercase tracking-widest flex items-center gap-1 group-hover:underline">Chi tiết phòng ban <Icon name="arrow_forward" className="!text-[12px]" /></button>
             </div>
          </div>
        ))}
      </div>

      {(showAdd || editing) && (
        <AddDeptModal 
          dept={editing} 
          onClose={() => { setShowAdd(false); setEditing(null); }} 
          onRefresh={onRefresh} 
        />
      )}
    </div>
  );
};

export default DepartmentsView;
