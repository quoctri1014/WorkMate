import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';
import { io } from "socket.io-client";

const socket = io("http://localhost:5000");

const ChatView = ({ adminUser }) => {
  const [conversations, setConversations] = useState([]);
  const [activeChat, setActiveChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const chatEndRef = useRef(null);

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
      if (activeChat && msg.sender_id === activeChat.id) {
        setMessages(prev => [...prev, msg]);
      }
    });
    return () => socket.off(`receive_message_admin`);
  }, [activeChat]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSelectChat = (chat) => {
    setActiveChat(chat);
    fetchMessages(chat.id);
  };

  const handleSend = () => {
    if (!input.trim() || !activeChat) return;
    const msgData = {
      sender_id: adminUser.id,
      receiver_id: activeChat.id,
      message: input,
      is_ai: false
    };
    socket.emit('send_message', msgData);
    setInput('');
  };

  return (
    <div className="h-[calc(100vh-160px)] flex gap-6 overflow-hidden">
      {/* List Conversations */}
      <div className="w-80 bg-white dark:bg-slate-900 rounded-[2rem] border border-slate-100 dark:border-slate-800 flex flex-col shadow-sm">
        <div className="p-6 border-b border-slate-50 dark:border-slate-800">
          <h3 className="text-xl font-black text-slate-900 dark:text-white tracking-tight">Hỗ trợ trực tuyến</h3>
          <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Hộp thư hỗ trợ nhân viên</p>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-2 no-scrollbar">
          {conversations.map(c => (
            <button 
              key={c.id} 
              onClick={() => handleSelectChat(c)}
              className={`w-full p-4 rounded-2xl flex items-center gap-4 transition-all ${activeChat?.id === c.id ? 'bg-primary text-white shadow-lg shadow-primary/20 scale-[1.02]' : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400'}`}
            >
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-black text-lg ${activeChat?.id === c.id ? 'bg-white/20' : 'bg-slate-100 dark:bg-slate-800'}`}>
                {c.name?.[0]}
              </div>
              <div className="text-left flex-1 min-w-0">
                <p className={`font-black text-sm truncate ${activeChat?.id === c.id ? 'text-white' : 'text-slate-900 dark:text-white'}`}>{c.name}</p>
                <p className={`text-[10px] truncate opacity-70 ${activeChat?.id === c.id ? 'text-white' : 'text-slate-500'}`}>{c.last_message}</p>
              </div>
            </button>
          ))}
          {conversations.length === 0 && (
            <div className="text-center py-10 opacity-30">
               <Icon name="chat_bubble_outline" className="!text-4xl mb-2" />
               <p className="text-xs font-bold uppercase tracking-widest">Trống</p>
            </div>
          )}
        </div>
      </div>

      {/* Chat Box */}
      <div className="flex-1 bg-white dark:bg-slate-900 rounded-[2rem] border border-slate-100 dark:border-slate-800 flex flex-col shadow-sm relative overflow-hidden">
        {activeChat ? (
          <>
            <div className="p-6 border-b border-slate-50 dark:border-slate-800 flex items-center justify-between bg-white/50 dark:bg-slate-900/50 backdrop-blur-md z-10">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl brand-gradient text-white flex items-center justify-center font-black text-lg shadow-lg shadow-primary/10">
                  {activeChat.name?.[0]}
                </div>
                <div>
                  <h4 className="text-lg font-black text-slate-900 dark:text-white leading-none">{activeChat.name}</h4>
                  <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Đang hoạt động</p>
                </div>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-8 space-y-6 no-scrollbar bg-slate-50/30 dark:bg-slate-950/30">
              {messages.map((m, i) => {
                const isMe = m.sender_id === adminUser.id;
                return (
                  <motion.div 
                    initial={{ opacity: 0, y: 10, scale: 0.95 }} 
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    key={m.id} 
                    className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`max-w-[70%] p-4 rounded-[1.5rem] shadow-sm ${isMe ? 'bg-primary text-white rounded-tr-none' : m.is_ai ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-900 dark:text-amber-100 border border-amber-200 dark:border-amber-800 rounded-tl-none' : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-100 dark:border-slate-700 rounded-tl-none'}`}>
                      {m.is_ai && <p className="text-[9px] font-black uppercase tracking-widest mb-1 opacity-50 flex items-center gap-1"><Icon name="smart_toy" className="!text-[12px]" /> AI Assistant</p>}
                      <p className="text-sm font-medium leading-relaxed">{m.message}</p>
                      <p className={`text-[9px] mt-2 opacity-50 font-bold ${isMe ? 'text-white' : 'text-slate-400'}`}>
                        {new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </motion.div>
                );
              })}
              <div ref={chatEndRef} />
            </div>

            <div className="p-6 bg-white dark:bg-slate-900 border-t border-slate-50 dark:border-slate-800">
              <div className="flex gap-4">
                <input 
                  value={input} 
                  onChange={e => setInput(e.target.value)}
                  onKeyPress={e => e.key === 'Enter' && handleSend()}
                  placeholder="Nhập tin nhắn phản hồi..." 
                  className="flex-1 bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-2xl px-6 py-4 outline-none font-bold text-slate-700 dark:text-white transition-all"
                />
                <button onClick={handleSend} className="w-14 h-14 brand-gradient text-white rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-105 active:scale-95 transition-all">
                  <Icon name="send" className="!text-2xl" />
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center opacity-20 select-none">
            <Icon name="chat" className="!text-9xl mb-4" />
            <p className="text-xl font-black uppercase tracking-[0.2em]">Chọn cuộc hội thoại</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ChatView;
