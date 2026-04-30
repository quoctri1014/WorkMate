const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function seedSeniority() {
  try {
    const employees = await pool.query('SELECT id, join_date FROM employees');
    
    for (const emp of employees.rows) {
      const joinDate = new Date(emp.join_date);
      const now = new Date();
      const diffTime = Math.abs(now - joinDate);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      const seniorityPoints = diffDays * 100;
      const technicalScore = Math.floor(Math.random() * (95 - 70) + 70);
      const teamworkScore = Math.floor(Math.random() * (95 - 75) + 75);
      const creativityScore = Math.floor(Math.random() * (90 - 65) + 65);
      
      await pool.query(
        'UPDATE employees SET seniority_points = $1, technical_score = $2, teamwork_score = $3, creativity_score = $4 WHERE id = $5',
        [seniorityPoints, technicalScore, teamworkScore, creativityScore, emp.id]
      );
      console.log(`Updated employee ${emp.id}: ${seniorityPoints} pts`);
    }
    console.log('✅ Seeding seniority data completed!');
  } catch (err) {
    console.error('❌ Error seeding seniority data:', err.message);
  } finally {
    await pool.end();
  }
}

seedSeniority();
