import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';
import { io } from "socket.io-client";

const socket = io("https://workmate-backend-k8nk.onrender.com");

const ChatView = ({ adminUser, onlineUsers = [], onNavigate }) => {
  const [conversations, setConversations] = useState([]);
  const [activeChat, setActiveChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isUploading, setIsUploading] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [showConfirmDelete, setShowConfirmDelete] = useState(false);
  const chatEndRef = useRef(null);
  const fileInputRef = useRef(null);

  const fetchConversations = async () => {
    try {
      const res = await axios.get(`${API_URL}/chat/admin/conversations`);
      setConversations(res.data);
    } catch (err) { console.error(err); }
  };

  const fetchMessages = async (userId) => {
    try {
      const res = await axios.get(`${API_URL}/chat/history/${userId}`);
      setMessages(res.data);
    } catch (err) { console.error(err); }
  };

  useEffect(() => {
    fetchConversations();
    socket.on(`receive_message_admin`, (msg) => {
      fetchConversations();
      if (activeChat && (msg.sender_id === activeChat.id || msg.receiver_id === activeChat.id)) {
        setMessages(prev => [...prev, msg]);
      }
    });
    if (adminUser?.id) {
      socket.on(`receive_message_${adminUser.id}`, (msg) => {
        if (activeChat && (msg.receiver_id === activeChat.id || msg.sender_id === activeChat.id)) {
          setMessages(prev => [...prev, msg]);
        }
      });
    }
    return () => {
      socket.off(`receive_message_admin`);
      if (adminUser?.id) socket.off(`receive_message_${adminUser.id}`);
    };
  }, [activeChat]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSelectChat = (chat) => {
    setActiveChat(chat);
    fetchMessages(chat.id);
  };

  const handleSend = (options = {}) => {
    if ((!input.trim() && !options.file_url) || !activeChat) return;
    const msgData = {
      sender_id: adminUser.id,
      receiver_id: activeChat.id,
      message: options.message || input,
      is_ai: false,
      message_type: options.message_type || 'text',
      file_url: options.file_url || null
    };
    socket.emit('send_message', msgData);
    setInput('');
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    setIsUploading(true);
    try {
      const res = await axios.post(`${API_URL}/chat/upload`, formData);
      const { file_url, file_type, file_name } = res.data;
      
      let msgType = 'file';
      if (file_type.startsWith('image/')) msgType = 'image';
      else if (file_type.startsWith('video/')) msgType = 'video';

      handleSend({
        message: file_name,
        message_type: msgType,
        file_url: file_url
      });
    } catch (err) {
      console.error('Lỗi upload:', err);
      alert('Không thể tải tệp lên. Vui lòng thử lại.');
    } finally {
      setIsUploading(false);
      e.target.value = '';
    }
  };

  const handleClearHistory = async () => {
    if (!activeChat) return;
    try {
      await axios.delete(`${API_URL}/chat/history/${activeChat.id}`);
      setMessages([]);
      setShowConfirmDelete(false);
      setIsMenuOpen(false);
      fetchConversations();
    } catch (err) { console.error(err); }
  };

  const handleExportChat = () => {
    if (!activeChat || messages.length === 0) return;
    const content = messages.map(m => {
      const time = new Date(m.created_at).toLocaleString();
      const sender = Number(m.sender_id) === Number(adminUser.id) ? 'Admin' : activeChat.name;
      return `[${time}] ${sender}: ${m.message_type === 'text' ? m.message : `[${m.message_type}] ${m.message}`}`;
    }).join('\n');

    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `chat_history_${activeChat.name}_${new Date().getTime()}.txt`;
    a.click();
    setIsMenuOpen(false);
  };

  const renderMessageContent = (m) => {
    const isMe = Number(m.sender_id) === Number(adminUser.id);
    const serverUrl = 'https://workmate-backend-k8nk.onrender.com';

    if (m.message_type === 'image') {
      return (
        <div className="space-y-2">
          <img 
            src={`${serverUrl}${m.file_url}`} 
            alt="Sent image" 
            className="max-w-full rounded-2xl border border-white/20 shadow-sm cursor-zoom-in hover:opacity-90 transition-opacity"
            onClick={() => window.open(`${serverUrl}${m.file_url}`, '_blank')}
          />
          <p className="text-[10px] opacity-50 italic">{m.message}</p>
        </div>
      );
    }

    if (m.message_type === 'video') {
      return (
        <div className="space-y-2">
          <video controls className="max-w-full rounded-2xl border border-white/20 shadow-sm">
            <source src={`${serverUrl}${m.file_url}`} type="video/mp4" />
            Trình duyệt của bạn không hỗ trợ phát video.
          </video>
          <p className="text-[10px] opacity-50 italic">{m.message}</p>
        </div>
      );
    }

    if (m.message_type === 'file') {
      return (
        <a 
          href={`${serverUrl}${m.file_url}`} 
          target="_blank" 
          rel="noopener noreferrer"
          className={`flex items-center gap-3 p-3 rounded-xl border transition-all hover:scale-[1.02] ${isMe ? 'bg-white/10 border-white/20' : 'bg-surface-container-high border-border'}`}
        >
          <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${isMe ? 'bg-white/20' : 'bg-primary/10 text-primary'}`}>
            <Icon name="description" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold truncate">{m.message}</p>
            <p className="text-[9px] opacity-50 uppercase tracking-widest">Tài liệu</p>
          </div>
          <Icon name="download" className="!text-lg opacity-50" />
        </a>
      );
    }

    return <p className="text-sm font-bold leading-relaxed tracking-tight">{m.message}</p>;
  };

  const isOnline = (id) => {
    return onlineUsers.some(onlineId => Number(onlineId) === Number(id));
  };

  return (
    <div className="h-full flex overflow-hidden p-6 gap-6 select-none relative">
      {/* List Conversations */}
      <div className="w-80 h-full bg-surface-container-lowest rounded-[2.5rem] border border-border flex flex-col shadow-sm overflow-hidden">
        <div className="p-8 border-b border-border/50 bg-surface-container-lowest/50 backdrop-blur-md">
          <h3 className="text-2xl font-black text-on-surface tracking-tighter">Hỗ trợ trực tuyến</h3>
          <p className="text-[10px] text-on-surface-variant font-black uppercase tracking-[0.2em] mt-1.5 opacity-60">Hộp thư hỗ trợ nhân viên</p>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-1.5 custom-scrollbar">
          {conversations.map(c => (
            <button 
              key={c.id} 
              onClick={() => handleSelectChat(c)}
              className={`w-full p-4 rounded-2xl flex items-center gap-4 transition-all duration-300 relative group ${activeChat?.id === c.id ? 'bg-primary/5 shadow-inner' : 'hover:bg-surface-container-low text-on-surface-variant'}`}
            >
              {activeChat?.id === c.id && (
                <motion.div layoutId="active-pill" className="absolute left-0 w-1.5 h-8 bg-primary rounded-r-full shadow-[0_0_12px_rgba(var(--primary-rgb),0.5)]" />
              )}
              <div className="relative">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center font-black text-lg overflow-hidden transition-transform duration-500 ${activeChat?.id === c.id ? 'scale-110 shadow-lg' : 'bg-surface-container-low'}`}>
                  {c.avatar_url ? (
                    <img src={c.avatar_url.startsWith('http') ? c.avatar_url : `https://workmate-backend-k8nk.onrender.com${c.avatar_url}`} className="w-full h-full object-cover" alt={c.name} />
                  ) : (
                    <span className="text-primary opacity-40">{c.name?.[0]}</span>
                  )}
                </div>
                <div className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-surface transition-all duration-500 ${isOnline(c.id) ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]' : 'bg-slate-300'}`} />
              </div>
              <div className="text-left flex-1 min-w-0 ml-1">
                <p className={`font-black text-sm truncate transition-colors ${activeChat?.id === c.id ? 'text-primary' : 'text-on-surface'}`}>{c.name}</p>
                <p className="text-[10px] truncate opacity-50 font-bold mt-0.5">{c.last_message || 'Bắt đầu hội thoại'}</p>
              </div>
            </button>
          ))}
          {conversations.length === 0 && (
            <div className="flex flex-col items-center justify-center py-20 opacity-20 grayscale">
               <Icon name="chat_bubble_outline" className="!text-5xl mb-3" />
               <p className="text-[10px] font-black uppercase tracking-[0.3em]">Hộp thư trống</p>
            </div>
          )}
        </div>
      </div>

      {/* Chat Box */}
      <div className="flex-1 h-full bg-surface-container-lowest rounded-[3rem] border border-border flex flex-col shadow-sm relative overflow-hidden">
        {activeChat ? (
          <>
            <div className="p-8 border-b border-border/50 flex items-center justify-between bg-surface-container-lowest/80 backdrop-blur-xl z-20 shadow-sm shadow-black/5">
              <div className="flex items-center gap-5">
                <div className="w-14 h-14 rounded-2xl brand-gradient text-white flex items-center justify-center font-black text-xl shadow-xl shadow-primary/20 overflow-hidden ring-4 ring-primary/5">
                  {activeChat.avatar_url ? (
                    <img src={activeChat.avatar_url.startsWith('http') ? activeChat.avatar_url : `https://workmate-backend-k8nk.onrender.com${activeChat.avatar_url}`} className="w-full h-full object-cover" alt={activeChat.name} />
                  ) : (
                    activeChat.name?.[0]
                  )}
                </div>
                <div>
                  <h4 className="text-xl font-black text-on-surface tracking-tight leading-none">{activeChat.name}</h4>
                  <div className="flex items-center gap-2 mt-1.5">
                    <div className={`w-2 h-2 rounded-full ${isOnline(activeChat.id) ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'}`} />
                    <p className={`text-[10px] font-black uppercase tracking-widest ${isOnline(activeChat.id) ? 'text-emerald-500' : 'text-on-surface-variant opacity-60'}`}>{isOnline(activeChat.id) ? 'Đang trực tuyến' : 'Ngoại tuyến'}</p>
                    <span className="mx-1 opacity-20">•</span>
                    <p className="text-[10px] font-bold text-on-surface-variant/60 uppercase tracking-widest">{activeChat.department_name}</p>
                  </div>
                </div>
              </div>
              <div className="flex gap-2 relative">
                 <button 
                  onClick={() => setIsMenuOpen(!isMenuOpen)}
                  className={`p-3 rounded-2xl transition-all ${isMenuOpen ? 'bg-primary text-white' : 'hover:bg-surface-container-low text-on-surface-variant'}`}
                 >
                   <Icon name="more_vert" />
                 </button>

                 <AnimatePresence>
                   {isMenuOpen && (
                     <>
                       <div className="fixed inset-0 z-30" onClick={() => setIsMenuOpen(false)} />
                       <motion.div 
                        initial={{ opacity: 0, scale: 0.9, y: -10, x: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0, x: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: -10, x: 10 }}
                        className="absolute right-0 top-14 w-56 bg-white dark:bg-slate-900 rounded-3xl shadow-2xl border border-border p-2 z-40 overflow-hidden"
                       >
                         <button onClick={() => { onNavigate('employees'); setIsMenuOpen(false); }} className="w-full flex items-center gap-3 p-3 rounded-2xl hover:bg-slate-50 dark:hover:bg-slate-800 text-on-surface-variant transition-all">
                            <Icon name="person" className="!text-xl" />
                            <span className="text-xs font-black uppercase tracking-widest">Xem hồ sơ</span>
                         </button>
                         <button onClick={handleExportChat} className="w-full flex items-center gap-3 p-3 rounded-2xl hover:bg-slate-50 dark:hover:bg-slate-800 text-on-surface-variant transition-all">
                            <Icon name="download" className="!text-xl" />
                            <span className="text-xs font-black uppercase tracking-widest">Xuất báo cáo</span>
                         </button>
                         <div className="h-px bg-border my-1 mx-2" />
                         <button onClick={() => { setShowConfirmDelete(true); setIsMenuOpen(false); }} className="w-full flex items-center gap-3 p-3 rounded-2xl hover:bg-rose-50 dark:hover:bg-rose-900/20 text-rose-500 transition-all">
                            <Icon name="delete" className="!text-xl" />
                            <span className="text-xs font-black uppercase tracking-widest">Xóa lịch sử</span>
                         </button>
                       </motion.div>
                     </>
                   )}
                 </AnimatePresence>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-10 space-y-8 custom-scrollbar bg-[radial-gradient(circle_at_top_right,var(--primary-light),transparent_40%)]">
              {messages.map((m, i) => {
                const isMe = Number(m.sender_id) === Number(adminUser.id);
                return (
                  <motion.div 
                    initial={{ opacity: 0, y: 15, scale: 0.9 }} 
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    key={m.id} 
                    className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`max-w-[65%] group`}>
                      <div className={`p-5 rounded-[2rem] shadow-sm relative transition-all duration-300 ${isMe ? 'brand-gradient text-white rounded-tr-none shadow-primary/20' : m.is_ai ? 'bg-amber-50 dark:bg-amber-900/10 text-amber-900 dark:text-amber-100 border border-amber-200/50 rounded-tl-none' : 'bg-surface-container-low text-on-surface border border-border/50 rounded-tl-none'}`}>
                        {m.is_ai && <p className="text-[9px] font-black uppercase tracking-widest mb-2 opacity-50 flex items-center gap-1.5"><Icon name="auto_awesome" className="!text-[12px]" /> AI Assistant</p>}
                        
                        {renderMessageContent(m)}

                      </div>
                      <p className={`text-[9px] mt-2 font-black uppercase tracking-[0.15em] opacity-0 group-hover:opacity-40 transition-opacity ${isMe ? 'text-right' : 'text-left'}`}>
                        {new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </motion.div>
                );
              })}
              <div ref={chatEndRef} />
            </div>

            <div className="p-8 bg-surface-container-lowest/80 backdrop-blur-xl border-t border-border/50">
              <div className="flex gap-4 items-center bg-surface-container-low p-2 rounded-[2rem] border border-border shadow-inner">
                
                <input 
                  type="file" 
                  ref={fileInputRef} 
                  onChange={handleFileUpload} 
                  className="hidden" 
                />
                
                <button 
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isUploading}
                  className={`w-12 h-12 rounded-full flex items-center justify-center transition-all ${isUploading ? 'bg-slate-200 text-slate-400 animate-pulse' : 'hover:bg-surface-container-high text-on-surface-variant'}`}
                >
                  <Icon name={isUploading ? "sync" : "attach_file"} className={isUploading ? "animate-spin" : ""} />
                </button>

                <input 
                  value={input} 
                  onChange={e => setInput(e.target.value)}
                  onKeyPress={e => e.key === 'Enter' && handleSend()}
                  placeholder={isUploading ? "Đang tải tệp lên..." : "Gửi tin nhắn phản hồi..."} 
                  disabled={isUploading}
                  className="flex-1 bg-transparent px-2 py-4 outline-none font-bold text-on-surface text-sm placeholder:opacity-30"
                />
                <button 
                  onClick={() => handleSend()} 
                  disabled={isUploading || (!input.trim())}
                  className={`w-12 h-12 brand-gradient text-white rounded-full flex items-center justify-center shadow-lg shadow-primary/30 hover:scale-105 active:scale-95 transition-all ${isUploading || !input.trim() ? 'opacity-50 grayscale' : ''}`}
                >
                  <Icon name="arrow_upward" className="!text-2xl" fill={1} />
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center relative overflow-hidden">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,var(--primary-light),transparent_70%)] opacity-30" />
            <motion.div initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 1 }} className="relative z-10 flex flex-col items-center">
              <div className="w-40 h-40 rounded-[3rem] bg-surface-container-low flex items-center justify-center text-primary/10 mb-10 shadow-inner">
                <Icon name="forum" className="!text-[100px] rotate-12" fill={1} />
              </div>
              <h3 className="text-3xl font-black text-on-surface tracking-tighter mb-2">Trung tâm điều phối</h3>
              <p className="text-sm font-bold text-on-surface-variant uppercase tracking-[0.3em] opacity-30">Chọn cuộc hội thoại để bắt đầu</p>
            </motion.div>
          </div>
        )}
      </div>

      {/* Confirmation Modal */}
      <AnimatePresence>
        {showConfirmDelete && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-black/40 backdrop-blur-sm">
            <motion.div 
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="w-full max-w-sm bg-white dark:bg-slate-900 rounded-[2.5rem] shadow-2xl p-8 border border-border"
            >
              <div className="w-16 h-16 rounded-2xl bg-rose-50 dark:bg-rose-900/20 text-rose-500 flex items-center justify-center mb-6">
                <Icon name="delete_forever" className="!text-3xl" />
              </div>
              <h3 className="text-2xl font-black text-on-surface tracking-tighter mb-2">Xác nhận xóa?</h3>
              <p className="text-sm text-on-surface-variant opacity-70 mb-8 font-medium leading-relaxed">
                Hành động này sẽ xóa vĩnh viễn toàn bộ lịch sử trò chuyện với <span className="font-black text-on-surface">{activeChat?.name}</span>. Bạn không thể hoàn tác thao tác này.
              </p>
              <div className="flex gap-3">
                <button onClick={() => setShowConfirmDelete(false)} className="flex-1 py-4 rounded-2xl bg-surface-container-low text-on-surface-variant font-black uppercase tracking-widest text-xs transition-all hover:bg-surface-container-high">Hủy</button>
                <button onClick={handleClearHistory} className="flex-1 py-4 rounded-2xl bg-rose-500 text-white font-black uppercase tracking-widest text-xs shadow-lg shadow-rose-500/30 transition-all hover:scale-105 active:scale-95">Xóa ngay</button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default ChatView;
