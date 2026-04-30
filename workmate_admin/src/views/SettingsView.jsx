import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Icon, API_URL } from '../components/Common';

const SettingsView = ({ config, onRefresh }) => {
  const [data, setData] = useState({
    company_name: 'WorkMate HQ',
    safe_lat: 10.7946,
    safe_lng: 106.7218,
    safe_wifi_ssid: 'WorkMate_Office_5G',
    safe_wifi_bssid: 'e8:94:f6:7d:a2:c1',
    radius_meters: 100
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
    <div className="max-w-5xl mx-auto space-y-12">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-5xl font-black tracking-tighter text-on-surface">Cài đặt Hệ thống</h2>
          <p className="text-on-surface-variant mt-2 font-medium text-lg italic">Cấu hình Vùng an toàn và tham số chấm công lõi.</p>
        </div>
        <div className="flex items-center gap-3 px-6 py-3 bg-emerald-500/10 text-emerald-500 rounded-2xl text-[10px] font-black tracking-widest uppercase border border-emerald-500/20 shadow-lg shadow-emerald-500/5">
           <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div> HỆ THỐNG ĐANG HOẠT ĐỘNG
        </div>
      </div>

      <div className="bg-surface-container-lowest rounded-[3.5rem] shadow-2xl border border-border overflow-hidden relative">
        <div className="brand-gradient h-4"></div>
        <form onSubmit={handleSave} className="p-10 space-y-10">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
            {/* Cài đặt chung */}
            <div className="col-span-2">
               <h3 className="text-[11px] font-black text-primary uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                 <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Icon name="business" className="!text-[18px]" /></div> Thông tin doanh nghiệp
               </h3>
               <div className="space-y-3">
                 <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-4">Tên tổ chức / Công ty</label>
                 <input className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-6 px-8 outline-none font-black text-xl text-on-surface transition-all" value={data.company_name} onChange={e => setData({...data, company_name: e.target.value})} />
               </div>
            </div>

            {/* Vị trí GPS */}
            <div className="col-span-2 md:col-span-1 space-y-10">
              <h3 className="text-[11px] font-black text-primary uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Icon name="location_on" className="!text-[18px]" /></div> Tọa độ Safe Zone
              </h3>
              <div className="space-y-6">
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-4">Vĩ độ (Latitude)</label>
                   <input type="number" step="any" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-on-surface transition-all" value={data.safe_lat} onChange={e => setData({...data, safe_lat: parseFloat(e.target.value)})} />
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-4">Kinh độ (Longitude)</label>
                   <input type="number" step="any" className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-on-surface transition-all" value={data.safe_lng} onChange={e => setData({...data, safe_lng: parseFloat(e.target.value)})} />
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
                   <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-4">Tên WiFi bắt buộc (SSID)</label>
                   <input className="w-full bg-surface-container-low border-2 border-transparent focus:border-primary/20 rounded-[1.5rem] py-5 px-8 outline-none font-black text-on-surface transition-all placeholder:text-on-surface-variant/30" placeholder="Vd: WorkMate_Office" value={data.safe_wifi_ssid} onChange={e => setData({...data, safe_wifi_ssid: e.target.value})} />
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-primary uppercase tracking-[0.2em] ml-4">Mã định danh WiFi (BSSID)</label>
                   <input className="w-full bg-primary/5 border-2 border-primary/30 border-dashed rounded-[1.5rem] py-5 px-8 outline-none font-mono font-black text-primary text-lg" placeholder="Vd: e8:94:f6:7d:a2:c1" value={data.safe_wifi_bssid} onChange={e => setData({...data, safe_wifi_bssid: e.target.value})} />
                   <p className="text-[10px] text-on-surface-variant/50 italic ml-4 font-medium">* Mã MAC Router (giúp chống giả mạo vị trí).</p>
                 </div>
                 <div className="space-y-3">
                   <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-[0.2em] ml-4">Bán kính cho phép: <span className="text-primary font-black">{data.radius_meters}m</span></label>
                   <input type="range" min="50" max="1000" step="50" className="w-full h-3 bg-surface-container-low rounded-full appearance-none cursor-pointer accent-primary" value={data.radius_meters} onChange={e => setData({...data, radius_meters: parseInt(e.target.value)})} />
                 </div>
              </div>
            </div>
          </div>

          <div className="pt-10 border-t border-border">
            <button className="w-full py-6 brand-gradient text-white rounded-full font-black shadow-2xl shadow-primary/20 uppercase tracking-[0.4em] text-sm hover:scale-[1.02] active:scale-95 transition-all">
              XÁC NHẬN CẬP NHẬT CẤU HÌNH
            </button>
          </div>
        </form>
      </div>

      <div className="bg-amber-500/5 border-2 border-amber-500/20 rounded-[2.5rem] p-8 flex gap-6 items-start">
        <div className="w-12 h-12 rounded-2xl bg-amber-500/10 flex items-center justify-center text-amber-500 shrink-0"><Icon name="warning" fill={1} /></div>
        <div className="text-sm text-on-surface-variant font-medium leading-relaxed">
          <p className="font-black mb-2 uppercase tracking-widest text-amber-500">Lưu ý bảo mật quan trọng:</p>
          <p>Khi bạn thiết lập mã **BSSID**, hệ thống sẽ thực hiện đối soát mã phần cứng của thiết bị phát WiFi. Nhân viên sẽ **không thể** thực hiện chấm công từ xa ngay cả khi họ thay đổi tên WiFi tại nhà giống với tên WiFi của công ty.</p>
        </div>
      </div>
    </div>
  );
};

export default SettingsView;
