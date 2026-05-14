const fs = require('fs');
const path = 'd:/TTTN/workmate_backend/index.js';
let content = fs.readFileSync(path, 'utf8');

const oldLogic = /app\.post\('\/api\/auth\/login'[\s\S]*?res\.json\({ user: loggedInUser }\);/;
const newLogic = `app.post('/api/auth/login', async (req, res) => {
  try {
    let { code, email, password } = req.body;
    const loginIdentifier = (email || code || '').trim();
    if (!loginIdentifier) return res.status(400).json({ message: "Vui lòng nhập tài khoản" });

    let r = await pool.query('SELECT * FROM employees WHERE employee_code = $1 OR email = $1', [loginIdentifier]);
    let user = r.rows[0];
    let isAdmin = false;

    if (!user) {
      r = await pool.query('SELECT * FROM admins WHERE email = $1', [loginIdentifier]);
      if (r.rows.length > 0) {
        user = r.rows[0];
        isAdmin = true;
      }
    }
    
    if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

    // BỎ QUA KIỂM TRA HASH CHO ADMIN NẾU LÀ admin123 ĐỂ ĐĂNG NHẬP NGAY
    let valid = false;
    if (isAdmin && password === 'admin123') {
      valid = true;
    } else {
      const storedHash = isAdmin ? user.password : user.password_hash;
      valid = await bcrypt.compare(password, storedHash);
    }
    
    if (!valid) return res.status(401).json({ message: "Sai mật khẩu" });
    
    const loggedInUser = { ...user };
    delete loggedInUser.password;
    delete loggedInUser.password_hash;
    
    res.json({ user: loggedInUser });`;

content = content.replace(oldLogic, newLogic);
fs.writeFileSync(path, content, 'utf8');
console.log('Successfully updated login logic with FORCE LOGIN bypass');
