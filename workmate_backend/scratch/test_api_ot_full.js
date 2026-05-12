const fetch = require('node-fetch');

async function checkApiOutput() {
  try {
    const res = await fetch('http://localhost:5000/api/statistics/7?period=month');
    const data = await res.json();
    console.log("First history item:", data.history[0]);
  } catch (err) {
    console.error("Error:", err.message);
  }
}
checkApiOutput();
