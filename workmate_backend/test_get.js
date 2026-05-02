async function test() {
  try {
    const res = await fetch('http://localhost:5000/api/attendance?date=2026-05-05');
    const data = await res.json();
    console.log("Filtered date:", data);
  } catch (err) {
    console.log("ERROR:", err.message);
  }
}
test();
