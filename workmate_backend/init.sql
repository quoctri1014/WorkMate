-- 1. Tạo bảng Phòng ban
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    positions JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tạo bảng Nhân viên
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    department_id INTEGER REFERENCES departments(id),
    department_name VARCHAR(255),
    position VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tạo bảng Chấm công
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    employee_name VARCHAR(255),
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_out_time TIMESTAMP,
    check_in_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tạo bảng Phê duyệt (Đơn từ)
CREATE TABLE approvals (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    name VARCHAR(255),
    type VARCHAR(100),
    reason TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tạo bảng Lịch họp
CREATE TABLE meetings (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    date DATE,
    time TIME,
    link TEXT,
    depts JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
