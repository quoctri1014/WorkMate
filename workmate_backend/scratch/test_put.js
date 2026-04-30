const axios = require('axios');

async function testPut() {
  try {
    const id = 7;
    const data = {
      name: "Nguyễn Văn C",
      email: "quoctri101405@gmail.com",
      phone: "0123456789",
      department_id: 1,
      position: "Lập trình viên Fullstack",
      join_date: "2026-04-23",
      birthday: "2005-10-04"
    };
    
    console.log('--- Đang thử gửi lệnh PUT ---');
    const res = await axios.put(`http://localhost:5000/api/employees/${id}`, data);
    console.log('Phản hồi từ server:', JSON.stringify(res.data, null, 2));
  } catch (err) {
    console.error('❌ Lỗi:', err.response?.data || err.message);
  }
}

testPut();
