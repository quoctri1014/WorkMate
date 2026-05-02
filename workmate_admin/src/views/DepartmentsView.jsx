import React, { useState } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={onClose} className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm" />
      <motion.div initial={{ scale: 0.9, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }} className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-[3rem] p-10 shadow-2xl relative border border-slate-200 dark:border-slate-800 overflow-hidden">
        <div className="brand-gradient h-3 absolute top-0 left-0 right-0" />
        <button onClick={onClose} className="absolute top-8 right-8 w-10 h-10 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center justify-center transition-all duration-300"><Icon name="close" /></button>
        
        <div className="mb-10">
          <h2 className="text-4xl font-black text-slate-900 dark:text-white tracking-tighter">{dept ? 'Cập nhật phòng ban' : 'Thêm phòng ban mới'}</h2>
          <p className="text-slate-500 font-medium mt-1">Thiết lập bộ nhận diện và chức danh chuyên môn.</p>
        </div>

        <form onSubmit={handleSave} className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
               <div className="md:col-span-2 space-y-3">
                  <label className="text-[11px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.2em] ml-2">Tên phòng ban</label>
                  <input required placeholder="Vd: Phòng Kỹ thuật" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 px-6 outline-none font-bold text-slate-900 dark:text-white transition-all placeholder:text-slate-300" value={data.name} onChange={e => setData({...data, name: e.target.value})} />
               </div>
               <div className="space-y-3">
                  <label className="text-[11px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.2em] ml-2">Mã định danh</label>
                  <input required maxLength="5" placeholder="TECH" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 px-6 outline-none font-black uppercase text-primary transition-all text-center tracking-widest" value={data.code} onChange={e => setData({...data, code: e.target.value.toUpperCase()})} />
               </div>
            </div>

            <div className="space-y-4">
               <label className="text-[11px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.2em] ml-2">Thiết lập các chức danh</label>
               <div className="flex gap-4">
                  <input className="flex-1 bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-2xl py-5 px-6 outline-none font-bold text-slate-900 dark:text-white transition-all" placeholder="Vd: Senior Developer" value={newPos} onChange={e => setNewPos(e.target.value)} onKeyPress={e => e.key === 'Enter' && (e.preventDefault(), handleAddPos())} />
                  <button type="button" onClick={handleAddPos} className="w-16 h-16 brand-gradient text-white rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-105 active:scale-95 transition-all"><Icon name="add" className="!text-3xl" /></button>
               </div>
               <div className="flex flex-wrap gap-2 max-h-48 overflow-y-auto p-1 no-scrollbar">
                  {data.positions.map((p, i) => (
                     <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} key={i} className="flex items-center gap-2 px-5 py-3 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-bold border border-slate-200 dark:border-slate-700 group hover:border-primary/30 transition-all">
                        {p} 
                        <button type="button" onClick={() => handleRemovePos(i)} className="text-slate-400 hover:text-red-500 transition-colors">
                          <Icon name="close" className="!text-[14px]" />
                        </button>
                     </motion.div>
                  ))}
               </div>
            </div>

           <button className="w-full py-5 brand-gradient text-white rounded-3xl font-black shadow-xl shadow-primary/20 uppercase text-xs tracking-[0.3em] mt-6 hover:opacity-90 transition-opacity">XÁC NHẬN LƯU THÔNG TIN</button>
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
    try {
      await axios.delete(`${API_URL}/departments/${id}`);
      onRefresh();
    } catch (err) { alert("Không thể xóa phòng ban đang có nhân viên!"); }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-12">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
        <div>
          <h2 className="text-5xl font-black tracking-tighter text-slate-900 dark:text-white">Cấu trúc Tổ chức</h2>
          <p className="text-slate-500 font-medium text-lg mt-2 italic opacity-80">Quản lý các phòng ban và sơ đồ vị trí chuyên môn.</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="flex items-center gap-3 brand-gradient text-white px-10 py-5 rounded-full font-black shadow-2xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all uppercase tracking-widest text-xs">
          <Icon name="domain_add" className="!text-xl" /> THÊM PHÒNG BAN
        </button>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-10">
        {depts.map(d => {
          const positions = Array.isArray(d.positions) ? d.positions : JSON.parse(d.positions || '[]').filter(p => p);
          return (
            <motion.div 
              layout
              key={d.id} 
              className="bg-white dark:bg-slate-900 rounded-[3rem] shadow-xl border border-slate-100 dark:border-slate-800 p-10 flex flex-col gap-8 relative group hover:shadow-2xl hover:shadow-primary/5 transition-all overflow-hidden"
            >
               {/* Decorative background element */}
               <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full -mr-32 -mt-32 transition-all group-hover:scale-125 duration-700"></div>
               <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-slate-50 dark:bg-slate-800/20 rounded-full transition-all group-hover:translate-x-5 duration-500"></div>

               <div className="flex justify-between items-start relative z-10">
                  <div className="flex items-center gap-8">
                     <div className="w-24 h-24 rounded-[2rem] bg-slate-50 dark:bg-slate-800 flex flex-col items-center justify-center border-2 border-white dark:border-slate-800 shadow-xl transition-transform group-hover:rotate-6 duration-500">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Mã PB</span>
                        <span className="text-2xl font-black text-primary leading-none">{d.code}</span>
                     </div>
                     <div>
                       <h3 className="text-3xl font-black text-slate-900 dark:text-white tracking-tighter leading-tight mb-2 group-hover:text-primary transition-colors">{d.name}</h3>
                       <div className="flex items-center gap-3">
                         <span className="text-xs text-slate-400 font-bold uppercase tracking-widest">ID: {d.id}</span>
                       </div>
                     </div>
                  </div>
                  <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-all translate-y-2 group-hover:translate-y-0">
                     <button onClick={() => setEditing(d)} className="w-12 h-12 flex items-center justify-center text-primary bg-primary/5 hover:bg-primary hover:text-white rounded-2xl transition-all shadow-lg shadow-primary/5"><Icon name="edit" /></button>
                     <button onClick={() => handleDelete(d.id)} className="w-12 h-12 flex items-center justify-center text-red-500 bg-red-500/5 hover:bg-red-500 hover:text-white rounded-2xl transition-all shadow-lg shadow-red-500/5"><Icon name="delete" /></button>
                  </div>
               </div>

               <div className="space-y-6 relative z-10 flex-1">
                  <div className="flex items-center gap-4">
                     <div className="h-px flex-1 bg-slate-100 dark:bg-slate-800"></div>
                     <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.25em]">Cơ cấu nhân sự</p>
                     <div className="h-px flex-1 bg-slate-100 dark:bg-slate-800"></div>
                  </div>
                  <div className="flex flex-wrap gap-2.5">
                     {positions.map((pos, idx) => (
                       <span key={idx} className="px-5 py-3 bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 rounded-2xl text-[11px] font-bold border border-slate-100 dark:border-slate-800 hover:border-primary/20 hover:bg-white dark:hover:bg-slate-800 transition-all cursor-default whitespace-normal break-words max-w-[200px] text-center">
                         {pos}
                       </span>
                     ))}
                     {positions.length === 0 && (
                       <div className="w-full py-6 text-center border-2 border-dashed border-slate-100 dark:border-slate-800 rounded-3xl">
                         <p className="text-xs italic text-slate-400 font-medium">Chưa thiết lập sơ đồ vị trí</p>
                       </div>
                     )}
                  </div>
               </div>
               
               <div className="pt-6 border-t border-slate-50 dark:border-slate-800 flex justify-between items-center relative z-10">
                 <div className="flex items-center gap-2">
                   <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                   <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{positions.length} Vị trí chuyên môn</span>
                 </div>
                 <button onClick={() => setEditing(d)} className="text-[11px] font-black text-primary uppercase tracking-widest flex items-center gap-2 hover:translate-x-1 transition-transform group/btn">
                   CHỈNH SỬA CƠ CẤU <Icon name="arrow_forward" className="!text-lg" />
                 </button>
               </div>
            </motion.div>
          );
        })}
      </div>

      <AnimatePresence>
        {(showAdd || editing) && (
          <AddDeptModal 
            dept={editing} 
            onClose={() => { setShowAdd(false); setEditing(null); }} 
            onRefresh={onRefresh} 
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default DepartmentsView;
