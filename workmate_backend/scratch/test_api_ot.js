const fetch = require('node-fetch');

async function checkApiOutput() {
  try {
    const res = await fetch('http://localhost:5000/api/statistics/7?period=month');
    const data = await res.json();
    console.log("History items:");
    data.history.slice(0, 3).forEach(h => {
      console.log(`Date: ${h.check_in_time}, ot_hours: ${h.ot_hours}`);
    });
  } catch (err) {
    console.error("Error:", err.message);
  }
}
checkApiOutput();
