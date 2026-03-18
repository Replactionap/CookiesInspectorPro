"use strict";

let allCookies = [];
let currentFilter = "all";
let currentHostname = "";

// ─── Init ────────────────────────────────────────────────────────
async function init() {
  try {
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    const url = new URL(tab.url);
    currentHostname = url.hostname;

    document.getElementById("currentUrl").textContent = `🌐 URL: ${currentHostname}`;

    const { version } = browser.runtime.getManifest();
    document.getElementById("versionBadge").textContent = `v${version}`;

    // browser.cookies.getAll with domain returns ALL cookies, including httpOnly and secure
    allCookies = await browser.cookies.getAll({ domain: currentHostname });

    updateStats();
    renderPreview();
  } catch (err) {
    setStatus("Error: " + err.message, true);
  }
}

// ─── Filtering ────────────────────────────────────────────────────
function getFiltered() {
  switch (currentFilter) {
    case "httponly": return allCookies.filter(c => c.httpOnly);
    case "secure":   return allCookies.filter(c => c.secure);
    case "both":     return allCookies.filter(c => c.httpOnly && c.secure);
    default:         return allCookies;
  }
}

// ─── Stats ────────────────────────────────────────────────────────
function updateStats() {
  const total    = allCookies.length;
  const httpOnly = allCookies.filter(c => c.httpOnly).length;
  const secure   = allCookies.filter(c => c.secure).length;
  const both     = allCookies.filter(c => c.httpOnly && c.secure).length;

  document.getElementById("stats").innerHTML = `
    <span class="badge badge-total">Total: ${total}</span>
    <span class="badge badge-http">HttpOnly: ${httpOnly}</span>
    <span class="badge badge-secure">Secure: ${secure}</span>
    <span class="badge badge-both">Both: ${both}</span>
  `;
}

// ─── JSON format ──────────────────────────────────────────────────
function cookiesToJson(cookies) {
  const formatted = cookies.map(c => ({
    name:           c.name,
    value:          c.value,
    domain:         c.domain,
    path:           c.path,
    secure:         c.secure,
    httpOnly:       c.httpOnly,
    sameSite:       c.sameSite,
    expirationDate: c.expirationDate ?? null,
    hostOnly:       c.hostOnly,
    session:        c.session,
    storeId:        c.storeId
  }));

  return JSON.stringify(formatted, null, 2);
}

// ─── Preview ──────────────────────────────────────────────────────
function renderPreview() {
  const filtered = getFiltered();
  document.getElementById("preview").value = cookiesToJson(filtered);
}

// ─── Toast notification ───────────────────────────────────────────
function showToast(message, type = "success", duration = 3000) {
  const container = document.getElementById("toast-container");

  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;

  const icon = type === "success" ? "✅" : "⚠️";
  toast.innerHTML = `<span class="toast-icon">${icon}</span><span>${message}</span>`;

  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add("hide");
    toast.addEventListener("animationend", () => toast.remove(), { once: true });
  }, duration);
}

// ─── Download JSON ────────────────────────────────────────────────
document.getElementById("btnExport").addEventListener("click", () => {
  const filtered = getFiltered();
  const json     = cookiesToJson(filtered);
  const blob     = new Blob([json], { type: "application/json" });
  const url      = URL.createObjectURL(blob);

  const filename = `cookies_${currentHostname}_${currentFilter}_${Date.now()}.json`;

  const a = document.createElement("a");
  a.href     = url;
  a.download = filename;
  a.click();

  URL.revokeObjectURL(url);
  showToast(`Saved: ${filtered.length} cookies → ${filename}`);
});

// ─── Copy ─────────────────────────────────────────────────────────
document.getElementById("btnCopy").addEventListener("click", async () => {
  const filtered = getFiltered();
  const json     = cookiesToJson(filtered);

  try {
    await navigator.clipboard.writeText(json);
    showToast(`Copied ${filtered.length} cookies to clipboard`);
  } catch {
    // fallback for Firefox
    const ta = document.getElementById("preview");
    ta.select();
    document.execCommand("copy");
    showToast(`Copied ${filtered.length} cookies (fallback)`);
  }
});

// ─── Filter toggles ───────────────────────────────────────────────
document.querySelectorAll(".filter-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    currentFilter = btn.dataset.filter;
    renderPreview();
    setStatus("");
  });
});

// ─── Status bar ───────────────────────────────────────────────────
function setStatus(msg, isError = false) {
  const el = document.getElementById("status");
  el.textContent = msg;
  el.className   = "status" + (isError ? " error" : "");
}

// ─── Start ───────────────────────────────────────────────────────
init();