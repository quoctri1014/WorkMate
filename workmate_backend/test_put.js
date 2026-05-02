async function test() {
  try {
    const res = await fetch('http://localhost:5000/api/attendance/3', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        check_in: '16:21:54',
        check_out: '17:22:33',
        date: '2026-05-02'
      })
    });
    const text = await res.text();
    console.log(res.status, text);
  } catch (err) {
    console.log("ERROR:", err.message);
  }
}
test();
