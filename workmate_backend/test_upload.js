const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

async function testUpload() {
  try {
    console.log('--- ĐANG KIỂM TRA API UPLOAD ---');
    const form = new FormData();
    // Tạo một file giả để upload
    const testFile = path.join(__dirname, 'test_image.txt');
    fs.writeFileSync(testFile, 'test content');
    
    form.append('file', fs.createReadStream(testFile));

    const response = await axios.post('http://localhost:5000/api/upload', form, {
      headers: form.getHeaders(),
    });

    console.log('✅ Kết quả API:', response.data);
    
    if (response.data.success) {
      console.log('✅ File đã được lưu tại:', path.join(__dirname, response.data.url));
      const checkFile = path.join(__dirname, response.data.url);
      if (fs.existsSync(checkFile)) {
        console.log('✅ XÁC NHẬN: File thực sự tồn tại trên ổ đĩa!');
      } else {
        console.log('❌ LỖI: API báo thành công nhưng file không thấy đâu!');
      }
    }
  } catch (err) {
    console.error('❌ LỖI KHI GỌI API:', err.message);
    if (err.response) {
      console.error('Data:', err.response.data);
    }
  }
}

testUpload();
