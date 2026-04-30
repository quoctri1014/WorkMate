import React, { useState } from 'react';
import axios from 'axios';
import { motion } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';

const LoginView = ({ onLogin }) => {
  const [e, setE] = useState(''); const [p, setP] = useState('');
  const submit = async () => {
    try {
      const res = await axios.post(`${API_URL}/auth/login`, { email: e, password: p });
      onLogin(res.data.user);
    } catch (err) { alert("Sai tài khoản hoặc mật khẩu!"); }
  };
  return (
    <div className="h-screen w-full flex items-center justify-center bg-surface transition-colors duration-500 overflow-hidden relative">
      {/* Background Decorative Elements */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-primary/5 blur-[120px]"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-blue-500/5 blur-[120px]"></div>

      <motion.div 
        initial={{ scale: 0.95, opacity: 0, y: 20 }} 
        animate={{ scale: 1, opacity: 1, y: 0 }} 
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="bg-surface-container-lowest p-12 rounded-[3.5rem] shadow-2xl w-[450px] border border-border text-center relative z-10"
      >
        <div className="w-24 h-24 brand-gradient rounded-[2rem] flex items-center justify-center mx-auto text-white shadow-2xl shadow-primary/30 mb-10 group hover:rotate-6 transition-transform">
          <Icon name="shield_person" fill={1} className="text-5xl" />
        </div>
        
        <div className="mb-10">
          <h2 className="text-4xl font-black text-on-surface tracking-tighter mb-2">WorkMate</h2>
          <p className="text-on-surface-variant font-medium text-sm tracking-widest uppercase italic">Quản trị hệ thống Core</p>
        </div>

        <div className="space-y-4 text-left">
          <div className="space-y-1">
            <p className="ml-5 text-[10px] font-black text-on-surface-variant uppercase tracking-widest">Tài khoản quản trị</p>
            <input 
              className="w-full bg-surface-container-low border-2 border-transparent rounded-[1.5rem] py-4 px-6 outline-none focus:border-primary/30 focus:bg-surface-container-lowest transition-all text-on-surface font-bold text-sm" 
              placeholder="admin@workmate.com" 
              value={e} 
              onChange={val => setE(val.target.value)} 
            />
          </div>
          
          <div className="space-y-1">
            <p className="ml-5 text-[10px] font-black text-on-surface-variant uppercase tracking-widest">Mật khẩu bảo mật</p>
            <input 
              className="w-full bg-surface-container-low border-2 border-transparent rounded-[1.5rem] py-4 px-6 outline-none focus:border-primary/30 focus:bg-surface-container-lowest transition-all text-on-surface font-bold text-sm" 
              type="password" 
              placeholder="••••••••" 
              value={p} 
              onChange={val => setP(val.target.value)} 
            />
          </div>

          <button 
            onClick={submit} 
            className="w-full py-5 brand-gradient text-white rounded-full font-black shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all uppercase text-xs tracking-[0.2em] mt-8"
          >
            XÁC THỰC VÀO HỆ THỐNG
          </button>
        </div>
        
        <p className="mt-10 text-[10px] text-on-surface-variant/50 font-medium italic">© 2026 WorkMate Ecosystem. All rights reserved.</p>
      </motion.div>
    </div>
  );
};

export default LoginView;
