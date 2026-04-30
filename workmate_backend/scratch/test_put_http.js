const http = require('http');

const data = JSON.stringify({
  name: "Nguyễn Văn C",
  email: "quoctri101405@gmail.com",
  phone: "0123456789",
  department_id: 1,
  position: "Lập trình viên Fullstack",
  join_date: "2026-04-23",
  birthday: "2005-10-04"
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/employees/7',
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Body:', body);
  });
});

req.on('error', (e) => {
  console.error(`❌ Lỗi: ${e.message}`);
});

req.write(data);
req.end();
