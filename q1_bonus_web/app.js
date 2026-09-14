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

// --- Assets list (with optional filters) ---

document.getElementById("load-assets").addEventListener("click", () => loadAssets());

document.getElementById("apply-filter").addEventListener("click", () => {
    loadAssets(true);
});

document.getElementById("clear-filter").addEventListener("click", () => {
    document.getElementById("filter-institution").value = "";
    document.getElementById("filter-site").value = "";
    loadAssets();
});

async function loadAssets(useFilters = false) {
    const status = document.getElementById("assets-status");
    const tbody = document.getElementById("assets-tbody");
    status.textContent = "Loading...";
    tbody.innerHTML = "";

    // Build URL with optional filters
    let url = `${API_BASE}/assets`;
    if (useFilters) {
        const inst = document.getElementById("filter-institution").value.trim();
        const site = document.getElementById("filter-site").value.trim();
        const params = new URLSearchParams();
        if (inst) params.set("institution", inst);
        if (site) params.set("site", site);
        const qs = params.toString();
        if (qs) url += `?${qs}`;
    }

    try {
        const res = await fetch(url);
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
}

// escape untrusted text before injecting into the DOM :)
function escapeHtml(str) {
    if (str == null) return "";
    return String(str)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
}

// --- Asset detail ---

let currentAssetTag = null;

// Make table rows clickable.
document.getElementById("assets-tbody").addEventListener("click", (e) => {
    const tr = e.target.closest("tr");
    if (!tr) return;
    const tag = tr.children[0].textContent;
    openAssetDetail(tag);
});

document.getElementById("close-detail").addEventListener("click", () => {
    document.getElementById("detail-panel").hidden = true;
    currentAssetTag = null;
});

async function openAssetDetail(tag) {
    currentAssetTag = tag;
    const panel = document.getElementById("detail-panel");
    panel.hidden = false;
    document.getElementById("detail-title").textContent = `Asset: ${tag}`;

    try {
        const res = await fetch(`${API_BASE}/assets/${encodeURIComponent(tag)}`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const a = await res.json();
        renderAssetDetail(a);
    } catch (err) {
        document.getElementById("detail-meta").innerHTML = `<p class="status">Error: ${escapeHtml(err.message)}</p>`;
    }
}

function renderAssetDetail(a) {
    // Meta
    const meta = document.getElementById("detail-meta");
    meta.innerHTML = `
        <dl>
            <dt>Name</dt><dd>${escapeHtml(a.name)}</dd>
            <dt>Description</dt><dd>${escapeHtml(a.description)}</dd>
            <dt>Institution</dt><dd>${escapeHtml(a.institution)}</dd>
            <dt>Site</dt><dd>${escapeHtml(a.site)}</dd>
            <dt>Status</dt><dd><span class="badge status-${escapeHtml(a.status)}">${escapeHtml(a.status)}</span></dd>
            <dt>Date Acquired</dt><dd>${escapeHtml(a.dateAcquired)}</dd>
        </dl>
    `;

    // Schedules
    const sList = document.getElementById("schedule-list");
    sList.innerHTML = "";
    if (!a.schedules || a.schedules.length === 0) {
        sList.innerHTML = "<li><em>No schedules.</em></li>";
    } else {
        for (const s of a.schedules) {
            const li = document.createElement("li");
            li.innerHTML = `
                <span>
                    <strong>${escapeHtml(s.scheduleId)}</strong> —
                    ${escapeHtml(s.scheduleType)} —
                    ${escapeHtml(s.dueDate)} —
                    ${escapeHtml(s.details)}
                </span>
                <button data-schedule-id="${escapeHtml(s.scheduleId)}">Delete</button>
            `;
            sList.appendChild(li);
        }
        sList.querySelectorAll("button").forEach(btn => {
            btn.addEventListener("click", () => deleteSchedule(currentAssetTag, btn.dataset.scheduleId));
        });
    }

    // Components
    const cList = document.getElementById("component-list");
    cList.innerHTML = "";
    if (!a.components || a.components.length === 0) {
        cList.innerHTML = "<li><em>No components.</em></li>";
    } else {
        for (const c of a.components) {
            const li = document.createElement("li");
            li.innerHTML = `<span><strong>${escapeHtml(c.compId)}</strong> — ${escapeHtml(c.name)} — ${escapeHtml(c.description)}</span>`;
            cList.appendChild(li);
        }
    }

    // Work Orders
    const wList = document.getElementById("workorder-list");
    wList.innerHTML = "";
    if (!a.workOrders || a.workOrders.length === 0) {
        wList.innerHTML = "<li><em>No work orders.</em></li>";
    } else {
        for (const w of a.workOrders) {
            const li = document.createElement("li");
            li.innerHTML = `<span><strong>${escapeHtml(w.orderId)}</strong> — ${escapeHtml(w.status)} — ${escapeHtml(w.description)}</span>`;
            wList.appendChild(li);
        }
    }
}

// AAtions: loan, return, schedule CRUD 

document.getElementById("btn-loan-out").addEventListener("click", () => changeStatus("LOANED_OUT"));
document.getElementById("btn-return").addEventListener("click", () => changeStatus("AVAILABLE"));

async function changeStatus(newStatus) {
    if (!currentAssetTag) return;
    try {
        const getRes = await fetch(`${API_BASE}/assets/${encodeURIComponent(currentAssetTag)}`);
        if (!getRes.ok) throw new Error(`HTTP ${getRes.status}`);
        const asset = await getRes.json();
        asset.status = newStatus;

        const putRes = await fetch(`${API_BASE}/assets/${encodeURIComponent(currentAssetTag)}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(asset)
        });
        if (!putRes.ok) throw new Error(`HTTP ${putRes.status}`);
        await openAssetDetail(currentAssetTag);
        await refreshAssetsTable();
    } catch (err) {
        alert(`Failed to update status: ${err.message}`);
    }
}

document.getElementById("schedule-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    if (!currentAssetTag) return;
    const schedule = {
        scheduleId: document.getElementById("sched-id").value.trim(),
        dueDate: document.getElementById("sched-due").value,
        scheduleType: document.getElementById("sched-type").value,
        details: document.getElementById("sched-details").value.trim()
    };
    try {
        const res = await fetch(`${API_BASE}/assets/${encodeURIComponent(currentAssetTag)}/schedules`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(schedule)
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        e.target.reset();
        await openAssetDetail(currentAssetTag);
    } catch (err) {
        alert(`Failed to add schedule: ${err.message}`);
    }
});

async function deleteSchedule(assetTag, scheduleId) {
    if (!confirm(`Delete schedule ${scheduleId}?`)) return;
    try {
        const res = await fetch(`${API_BASE}/assets/${encodeURIComponent(assetTag)}/schedules/${encodeURIComponent(scheduleId)}`, {
            method: "DELETE"
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        await openAssetDetail(assetTag);
    } catch (err) {
        alert(`Failed to delete schedule: ${err.message}`);
    }
}

// Extracted from Chunck 2 so actions can refresh the table too.
async function refreshAssetsTable() {
    await loadAssets();
}

// Overdue dashboard 

document.getElementById("load-overdue").addEventListener("click", async () => {
    const status = document.getElementById("overdue-status");
    const list = document.getElementById("overdue-list");
    status.textContent = "Loading...";
    list.innerHTML = "";

    let url = `${API_BASE}/assets/overdue`;
    const dateInput = document.getElementById("overdue-date").value;
    if (dateInput) {
        url += `?currentDate=${encodeURIComponent(dateInput)}`;
    }

    try {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const items = await res.json();
        if (!Array.isArray(items) || items.length === 0) {
            status.textContent = "No overdue assets.";
            return;
        }
        for (const item of items) {
            const li = document.createElement("li");
            const schedules = (item.schedules || [])
                .map(s => `<div class="overdue-meta">${escapeHtml(s.scheduleId)} — ${escapeHtml(s.scheduleType)} — due ${escapeHtml(s.dueDate)} — ${escapeHtml(s.details)}</div>`)
                .join("");
            li.innerHTML = `
                <div class="overdue-tag">${escapeHtml(item.assetTag)} — ${escapeHtml(item.name)}</div>
                <div class="overdue-meta">${escapeHtml(item.institution)} · ${escapeHtml(item.site)}</div>
                ${schedules}
            `;
            list.appendChild(li);
        }
        status.textContent = `${items.length} overdue asset(s).`;
    } catch (err) {
        status.textContent = `Error: ${err.message}`;
    }
});

document.getElementById("clear-overdue").addEventListener("click", () => {
    document.getElementById("overdue-date").value = "";
    document.getElementById("overdue-status").textContent = "";
    document.getElementById("overdue-list").innerHTML = "";
});