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

// assets list 

document.getElementById("load-assets").addEventListener("click", async () => {
    const status = document.getElementById("assets-status");
    const tbody = document.getElementById("assets-tbody");
    status.textContent = "Loading...";
    tbody.innerHTML = "";
    try {
        const res = await fetch(`${API_BASE}/assets`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const assets = await res.json();
        if (!Array.isArray(assets) || assets.length === 0) {
            status.textContent = "No assets found.";
            return;
        }
        for (const a of assets) {
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>${escapeHtml(a.assetTag)}</td>
                <td>${escapeHtml(a.name)}</td>
                <td>${escapeHtml(a.institution)}</td>
                <td>${escapeHtml(a.site)}</td>
                <td><span class="badge status-${escapeHtml(a.status)}">${escapeHtml(a.status)}</span></td>
            `;
            tbody.appendChild(tr);
        }
        status.textContent = `${assets.length} asset(s) loaded.`;
    } catch (err) {
        status.textContent = `Error: ${err.message}`;
    }
});

// Escape untrusted text before injecting into the DOM.
function escapeHtml(str) {
    if (str == null) return "";
    return String(str)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
}