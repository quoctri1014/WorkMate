import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Icon, API_URL } from '../components/Common';

const SettingsView = ({ config, onRefresh }) => {
  const [showGuide, setShowGuide] = useState(false);
  const [data, setData] = useState({
    company_name: 'WorkMate HQ',
    safe_lat: 10.7946,
    safe_lng: 106.7218,
    safe_wifi_ssid: 'WorkMate_Office_5G',
    safe_wifi_bssid: 'e8:94:f6:7d:a2:c1',
    radius_meters: 100,
    work_start_time: '08:00',
    work_end_time: '17:00',
    break_start_time: '12:00',
    break_end_time: '13:00'
  });

  useEffect(() => {
    if (config && Object.keys(config).length > 0) {
      setData(prev => ({ ...prev, ...config }));
    }
  }, [config]);

  const handleGetCurrentLocation = () => {
    if (!navigator.geolocation) return alert("Trình duyệt không hỗ trợ định vị!");
    navigator.geolocation.getCurrentPosition((pos) => {
      setData({ ...data, safe_lat: pos.coords.latitude, safe_lng: pos.coords.longitude });
      alert("✅ Đã lấy tọa độ hiện tại!");
    }, (err) => {
      alert("❌ Không thể lấy vị trí. Vui lòng cấp quyền cho trình duyệt hoặc nhập thủ công.");
    });
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API_URL}/company/config`, data);
      alert("✅ Đã cập nhật cấu hình hệ thống thành công! Dữ liệu đã được đồng bộ tới tất cả thiết bị.");
      onRefresh();
    } catch (err) { 
      console.error(err);
      alert("❌ Lỗi khi lưu cấu hình! Vui lòng kiểm tra kết nối Server."); 
    }
  };

  return (
    <div className="max-w-5xl mx-auto space-y-12 relative">
      {/* Header Section */}
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-5xl font-black tracking-tighter text-slate-900 dark:text-white">Cài đặt Hệ thống</h2>
          <p className="text-slate-500 mt-2 font-medium text-lg italic opacity-70">Cấu hình Vùng an toàn và tham số chấm công lõi.</p>
        </div>
        <div className="flex items-center gap-4">
          <button 
            onClick={() => setShowGuide(true)}
            className="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center hover:bg-primary hover:text-white transition-all shadow-lg shadow-primary/10 group"
          >
            <Icon name="info" className="group-hover:rotate-12 transition-transform" />
          </button>
          <div className="flex items-center gap-3 px-6 py-3 bg-emerald-500/10 text-emerald-500 rounded-2xl text-[10px] font-black tracking-widest uppercase border border-emerald-500/20 shadow-lg shadow-emerald-500/5">
             <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div> HỆ THỐNG ĐANG HOẠT ĐỘNG
          </div>
        </div>
      </div>

      {/* Guide Modal */}
      <AnimatePresence>
        {showGuide && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowGuide(false)}
              className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-2xl bg-white dark:bg-slate-900 rounded-[3rem] shadow-2xl overflow-hidden border border-slate-200 dark:border-slate-800"
            >
              <div className="brand-gradient h-3 w-full" />
              <div className="p-10 space-y-8 max-h-[80vh] overflow-y-auto no-scrollbar">
                <div className="flex justify-between items-center">
                  <h3 className="text-3xl font-black tracking-tighter">Hướng dẫn Cấu hình</h3>
                  <button onClick={() => setShowGuide(false)} className="w-10 h-10 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center justify-center transition-colors">
                    <Icon name="close" />
                  </button>
                </div>

                <div className="space-y-6 text-sm leading-relaxed text-slate-600 dark:text-slate-400 font-medium">
                  <section className="space-y-3">
                    <h4 className="text-primary font-black uppercase tracking-widest text-xs flex items-center gap-2">
                      <Icon name="schedule" className="!text-lg" /> 1. Quy định Giờ giấc & OT
                    </h4>
                    <ul className="list-disc pl-5 space-y-2">
                      <li><b className="text-slate-900 dark:text-white">Giờ vào/ra:</b> Dùng để xác định đi muộn/về sớm. Giờ công hành chính chỉ được tính trong khung giờ này.</li>
                      <li><b className="text-slate-900 dark:text-white">Giờ nghỉ trưa:</b> Hệ thống tự động trừ khoảng thời gian này nếu nhân viên làm việc xuyên trưa.</li>
                      <li><b className="text-slate-900 dark:text-white">Chế độ OT:</b> Chỉ khi có đơn OT được duyệt, hệ thống mới tính thêm giờ sau giờ tan sở. Số giờ OT tối đa bằng số giờ đã phê duyệt.</li>
                    </ul>
                  </section>

                  <section className="space-y-3">
                    <h4 className="text-amber-500 font-black uppercase tracking-widest text-xs flex items-center gap-2">
                      <Icon name="location_on" className="!text-lg" /> 2. Vùng an toàn (Safe Zone)
                    </h4>
                    <ul className="list-disc pl-5 space-y-2">
                      <li><b className="text-slate-900 dark:text-white">GPS (Vĩ độ/Kinh độ):</b> Tọa độ trung tâm của văn phòng. Nhân viên phải đứng trong bán kính cho phép mới có thể chấm công.</li>
                      <li><b className="text-slate-900 dark:text-white">Bán kính:</b> Khoảng cách tối đa (mét) tính từ tâm tọa độ.</li>
                    </ul>
                  </section>

                  <section className="space-y-3">
                    <h4 className="text-blue-500 font-black uppercase tracking-widest text-xs flex items-center gap-2">
                      <Icon name="wifi" className="!text-lg" /> 3. Mạng WiFi & BSSID
                    </h4>
                    <div className="bg-slate-50 dark:bg-slate-800/50 p-6 rounded-3xl space-y-4 border border-slate-100 dark:border-slate-800">
                      <p><b className="text-slate-900 dark:text-white">BSSID (Mã MAC Router):</b> Là địa chỉ vật lý duy nhất của thiết bị phát WiFi. Đây là chốt chặn bảo mật quan trọng nhất.</p>
                      
                      <div className="space-y-3 pt-2">
                        <p className="text-[10px] font-black uppercase tracking-widest text-primary">Cách lấy mã BSSID:</p>
                        <div className="grid grid-cols-1 gap-3">
                          <div className="flex gap-3 items-start">
                            <div className="w-20 h-6 rounded-lg bg-slate-200 dark:bg-slate-700 flex items-center justify-center shrink-0 font-bold text-[9px] uppercase tracking-wider">Windows</div>
                            <p className="text-xs">Mở <code className="bg-slate-200 dark:bg-slate-700 px-1.5 py-0.5 rounded">CMD</code>, gõ: <code className="text-primary font-bold">netsh wlan show interfaces</code> và tìm dòng "BSSID".</p>
                          </div>
                          <div className="flex gap-3 items-start">
                            <div className="w-20 h-6 rounded-lg bg-slate-200 dark:bg-slate-700 flex items-center justify-center shrink-0 font-bold text-[9px] uppercase tracking-wider">MacOS</div>
                            <p className="text-xs">Giữ phím <code className="bg-slate-200 dark:bg-slate-700 px-1.5 py-0.5 rounded">Option</code> và click vào biểu tượng WiFi trên thanh menu.</p>
                          </div>
                          <div className="flex gap-3 items-start">
                            <div className="w-20 h-6 rounded-lg bg-slate-200 dark:bg-slate-700 flex items-center justify-center shrink-0 font-bold text-[9px] uppercase tracking-wider">Mobile</div>
                            <p className="text-xs">Dùng ứng dụng <b className="text-slate-900 dark:text-white">WiFi Analyzer</b> (Android) hoặc xem trong cài đặt chi tiết mạng (iOS).</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </section>
                </div>

                <div className="pt-6 border-t border-slate-100 dark:border-slate-800">
                  <button 
                    onClick={() => setShowGuide(false)}
                    className="w-full py-4 bg-slate-900 dark:bg-white text-white dark:text-slate-900 rounded-2xl font-black tracking-widest text-xs uppercase hover:opacity-90 transition-opacity"
                  >
                    ĐÃ HIỂU
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <div className="bg-white dark:bg-slate-900 rounded-[3.5rem] shadow-2xl border border-slate-200 dark:border-slate-800 overflow-hidden relative transition-colors">
        <div className="brand-gradient h-4"></div>
        <form onSubmit={handleSave} className="p-10 space-y-10">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
            {/* Cài đặt chung */}
            <div className="col-span-2">
               <h3 className="text-[11px] font-black text-primary uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                 <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Icon name="business" className="!text-[18px]" /></div> Thông tin doanh nghiệp
               </h3>
               <div className="space-y-3">
                 <label className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Tên tổ chức / Công ty</label>
                 <input className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-6 px-8 outline-none font-black text-xl text-slate-900 dark:text-white transition-all" value={data.company_name} onChange={e => setData({...data, company_name: e.target.value})} />
               </div>
            </div>

            {/* Quy định giờ làm việc */}
            <div className="col-span-2">
               <h3 className="text-[11px] font-black text-amber-500 uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                 <div className="w-8 h-8 rounded-xl bg-amber-500/10 flex items-center justify-center"><Icon name="schedule" className="!text-[18px]" /></div> Quy định giờ làm việc & Nghỉ trưa
               </h3>
               <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                  <div className="space-y-3">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.1em] ml-4">Giờ vào làm</label>
                    <input type="time" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-amber-500/20 rounded-[1.2rem] py-4 px-6 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.work_start_time} onChange={e => setData({...data, work_start_time: e.target.value})} />
                  </div>
                  <div className="space-y-3">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.1em] ml-4">Giờ tan sở</label>
                    <input type="time" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-amber-500/20 rounded-[1.2rem] py-4 px-6 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.work_end_time} onChange={e => setData({...data, work_end_time: e.target.value})} />
                  </div>
                  <div className="space-y-3">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.1em] ml-4">Bắt đầu nghỉ</label>
                    <input type="time" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-amber-500/20 rounded-[1.2rem] py-4 px-6 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.break_start_time} onChange={e => setData({...data, break_start_time: e.target.value})} />
                  </div>
                  <div className="space-y-3">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.1em] ml-4">Kết thúc nghỉ</label>
                    <input type="time" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-amber-500/20 rounded-[1.2rem] py-4 px-6 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.break_end_time} onChange={e => setData({...data, break_end_time: e.target.value})} />
                  </div>
               </div>
            </div>

            {/* Vị trí GPS */}
            <div className="col-span-2 md:col-span-1 space-y-10">
              <h3 className="text-[11px] font-black text-primary uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Icon name="location_on" className="!text-[18px]" /></div> Tọa độ Safe Zone
              </h3>
              <div className="space-y-6">
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Vĩ độ (Latitude)</label>
                   <input type="number" step="any" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.safe_lat} onChange={e => setData({...data, safe_lat: parseFloat(e.target.value)})} />
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Kinh độ (Longitude)</label>
                   <input type="number" step="any" className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-slate-900 dark:text-white transition-all" value={data.safe_lng} onChange={e => setData({...data, safe_lng: parseFloat(e.target.value)})} />
                 </div>
                 <button type="button" onClick={handleGetCurrentLocation} className="w-full py-4 bg-primary/10 text-primary rounded-[1.2rem] font-black text-xs flex items-center justify-center gap-3 hover:bg-primary/20 active:scale-95 transition-all uppercase tracking-widest">
                   <Icon name="my_location" className="!text-[20px]" /> LẤY TỌA ĐỘ HIỆN TẠI
                 </button>
              </div>
            </div>

            {/* WiFi & Bán kính */}
            <div className="col-span-2 md:col-span-1 space-y-10">
              <h3 className="text-[11px] font-black text-primary uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Icon name="wifi_tethering" className="!text-[18px]" /></div> Mạng & Phạm vi
              </h3>
              <div className="space-y-6">
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Tên WiFi bắt buộc (SSID)</label>
                   <input className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-slate-900 dark:text-white transition-all placeholder:text-slate-400/30" placeholder="Vd: WorkMate_Office" value={data.safe_wifi_ssid} onChange={e => setData({...data, safe_wifi_ssid: e.target.value})} />
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-primary uppercase tracking-[0.2em] ml-4">Mã định danh WiFi (BSSID)</label>
                   <input className="w-full bg-primary/5 border-2 border-primary/30 border-dashed rounded-[1.5rem] py-5 px-8 outline-none font-mono font-black text-primary text-lg" placeholder="Vd: e8:94:f6:7d:a2:c1" value={data.safe_wifi_bssid} onChange={e => setData({...data, safe_wifi_bssid: e.target.value})} />
                   <p className="text-[10px] text-slate-400 italic ml-4 font-medium">* Mã MAC Router (giúp chống giả mạo vị trí).</p>
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Bán kính cho phép: <span className="text-primary font-black">{data.radius_meters}m</span></label>
                   <input type="range" min="50" max="1000" step="50" className="w-full h-3 bg-slate-50 dark:bg-slate-800 rounded-full appearance-none cursor-pointer accent-primary" value={data.radius_meters} onChange={e => setData({...data, radius_meters: parseInt(e.target.value)})} />
                 </div>
              </div>
            </div>
          </div>

          <div className="pt-10 border-t border-slate-100 dark:border-slate-800">
            <button className="w-full py-6 brand-gradient text-white rounded-full font-black shadow-2xl shadow-primary/20 uppercase tracking-[0.4em] text-sm hover:scale-[1.02] active:scale-95 transition-all">
              XÁC NHẬN CẬP NHẬT CẤU HÌNH
            </button>
          </div>
        </form>
      </div>

      <div className="bg-amber-500/5 border-2 border-amber-500/20 rounded-[2.5rem] p-8 flex gap-6 items-start">
        <div className="w-12 h-12 rounded-2xl bg-amber-500/10 flex items-center justify-center text-amber-500 shrink-0"><Icon name="warning" fill={1} /></div>
        <div className="text-sm text-slate-500 font-medium leading-relaxed">
          <p className="font-black mb-2 uppercase tracking-widest text-amber-500">Lưu ý bảo mật quan trọng:</p>
          <p>Khi bạn thiết lập mã **BSSID**, hệ thống sẽ thực hiện đối soát mã phần cứng của thiết bị phát WiFi. Nhân viên sẽ **không thể** thực hiện chấm công từ xa ngay cả khi họ thay đổi tên WiFi tại nhà giống với tên WiFi của công ty.</p>
        </div>
      </div>
    </div>
  );
};

export default SettingsView;
