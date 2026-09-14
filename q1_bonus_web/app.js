const API_BASE = "http://localhost:9090";

document.getElementById("check-health").addEventListener("click", async () => {
    const out = document.getElementById("health-output");
    out.textContent = "Checking...";
    try {
        const res = await fetch(`${API_BASE}/health`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        out.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
        out.textContent = `Error: ${err.message}`;
    }
});