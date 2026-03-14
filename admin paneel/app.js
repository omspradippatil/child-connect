(() => {
  const cfg = window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) {
    alert("Configure admin paneel/config.js with Supabase URL and anon key.");
    return;
  }

  const supabase = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  const tokenKey = "admin_session_token";

  // ── DOM refs ──────────────────────────────────────────────
  const authView      = document.getElementById("authView");
  const appView       = document.getElementById("appView");
  const authError     = document.getElementById("authError");
  const loginForm     = document.getElementById("loginForm");
  const logoutBtn     = document.getElementById("logoutBtn");
  const stats         = document.getElementById("stats");
  const childrenList  = document.getElementById("childrenList");
  const programsList  = document.getElementById("programsList");
  const adoptionList  = document.getElementById("adoptionList");
  const volunteerList = document.getElementById("volunteerList");
  const donorList     = document.getElementById("donorList");
  const contactList   = document.getElementById("contactList");
  const addChildBtn   = document.getElementById("addChildBtn");
  const addProgramBtn = document.getElementById("addProgramBtn");
  const addTeamMemberBtn = document.getElementById("addTeamMemberBtn");
  const teamList      = document.getElementById("teamList");
  const chatThreads   = document.getElementById("chatThreads");
  const chatMessages  = document.getElementById("chatMessages");
  const chatSendForm  = document.getElementById("chatSendForm");
  const chatInput     = document.getElementById("chatInput");
  const activeChatTitle = document.getElementById("activeChatTitle");
  const editorDialog  = document.getElementById("editorDialog");
  const editorForm    = document.getElementById("editorForm");
  const darkToggle    = document.getElementById("darkToggle");
  const sidebarAvatar = document.getElementById("sidebarAvatar");
  const sidebarName   = document.getElementById("sidebarName");
  const sidebarRole   = document.getElementById("sidebarRole");
  const childSearch   = document.getElementById("childSearch");
  const programSearch = document.getElementById("programSearch");
  const activityFeed  = document.getElementById("activityFeed");
  const quickStats    = document.getElementById("quickStats");
  const requestSummary = document.getElementById("requestSummary");

  const navButtons = Array.from(document.querySelectorAll(".nav-btn[data-tab]"));
  const tabs       = Array.from(document.querySelectorAll(".tab"));

  let sessionToken  = localStorage.getItem(tokenKey) || "";
  let currentUser   = null;
  let activeThreadId = "";
  let allChildren   = [];
  let allPrograms   = [];
  let allRequests   = { adoptions: [], mentors: [], volunteers: [], donors: [], contacts: [] };
  let activeRequestFilter = "all";

  // ═══════════════════════════════════
  //  TOAST SYSTEM
  // ═══════════════════════════════════
  const toastContainer = document.getElementById("toast-container");

  function showToast(message, type = "info", duration = 3500) {
    const icons = { success: "✅", error: "❌", info: "ℹ️", warn: "⚠️" };
    const toast = document.createElement("div");
    toast.className = `toast ${type}`;
    toast.innerHTML = `<span class="toast-icon">${icons[type] || "ℹ️"}</span><span>${escapeHtml(message)}</span>`;
    toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.classList.add("out");
      toast.addEventListener("animationend", () => toast.remove());
    }, duration);
  }

  // ═══════════════════════════════════
  //  DARK MODE
  // ═══════════════════════════════════
  const htmlEl = document.documentElement;
  const savedTheme = localStorage.getItem("admin_theme") || "light";
  htmlEl.setAttribute("data-theme", savedTheme);

  darkToggle.addEventListener("click", () => {
    const isDark = htmlEl.getAttribute("data-theme") === "dark";
    const next = isDark ? "light" : "dark";
    htmlEl.setAttribute("data-theme", next);
    localStorage.setItem("admin_theme", next);
  });
  darkToggle.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") darkToggle.click(); });

  // ═══════════════════════════════════
  //  UTILITIES
  // ═══════════════════════════════════
  function escapeHtml(v) {
    return String(v ?? "")
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;").replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function formatDate(ts) {
    if (!ts) return "";
    const d = new Date(ts);
    return isNaN(d.getTime()) ? "" : d.toLocaleString();
  }

  function timeAgo(ts) {
    if (!ts) return "";
    const diff = (Date.now() - new Date(ts)) / 1000;
    if (diff < 60)   return "just now";
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  }

  function badgeClass(status) {
    const map = {
      active: "badge-active", inactive: "badge-inactive",
      submitted: "badge-submitted", new: "badge-new",
      pending: "badge-pending", screening: "badge-screening",
      in_review: "badge-in_review", shortlisted: "badge-shortlisted",
      approved: "badge-approved", resolved: "badge-resolved",
      rejected: "badge-rejected", admin: "badge-admin", mentor: "badge-mentor"
    };
    return map[(status || "").toLowerCase()] || "badge-inactive";
  }

  function badge(label) {
    if (!label) return "";
    return `<span class="badge ${badgeClass(label)}">${escapeHtml(label)}</span>`;
  }

  function initials(name) {
    if (!name) return "?";
    const parts = name.trim().split(/\s+/);
    return (parts[0][0] + (parts[1]?.[0] || "")).toUpperCase();
  }

  function avatarColor(name) {
    const colors = ["#e04e39","#2563eb","#16a34a","#d97706","#7c3aed","#0d9488","#db2777","#0891b2"];
    let h = 0;
    for (const c of (name || "")) h = (h * 31 + c.charCodeAt(0)) % colors.length;
    return colors[Math.abs(h)];
  }

  function resolveChildImageUrl(rawValue) {
    const raw = String(rawValue || "").trim();
    if (!raw) return "";

    if (/^https?:\/\//i.test(raw)) {
      return raw;
    }

    if (raw.startsWith("/storage/v1/object/")) {
      return `${cfg.supabaseUrl}${raw}`;
    }

    const { data } = supabase.storage.from("children-photos").getPublicUrl(raw);
    return data?.publicUrl || "";
  }

  const donorKeywords = [
    "donor", "donate", "donation", "contribute", "contribution",
    "sponsor", "sponsorship", "fund", "funding", "support"
  ];

  function isDonorContact(row) {
    const blob = `${row?.message || ""} ${row?.subject || ""} ${row?._notes || ""}`.toLowerCase();
    return donorKeywords.some((key) => blob.includes(key));
  }

  // ═══════════════════════════════════
  //  CSV EXPORT
  // ═══════════════════════════════════
  function toCSV(rows, cols) {
    const header = cols.map(c => `"${c.label}"`).join(",");
    const body = rows.map(r => cols.map(c => `"${String(r[c.key] ?? "").replace(/"/g, '""')}"`).join(",")).join("\n");
    return header + "\n" + body;
  }

  function downloadCSV(csv, filename) {
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = filename; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    showToast(`Exported ${filename}`, "success");
  }

  document.getElementById("exportChildrenBtn")?.addEventListener("click", () => {
    if (!allChildren.length) { showToast("No children to export", "warn"); return; }
    downloadCSV(toCSV(allChildren, [
      { label: "Name", key: "name" }, { label: "Age", key: "age" },
      { label: "Gender", key: "gender" }, { label: "Location", key: "location" },
      { label: "Story", key: "story" }, { label: "Active", key: "is_active" }
    ]), "children.csv");
  });

  document.getElementById("exportRequestsBtn")?.addEventListener("click", () => {
    const all = [
      ...allRequests.adoptions.map(r => ({ ...r, _type: "adoption" })),
      ...allRequests.volunteers.map(r => ({ ...r, _type: "volunteer" })),
      ...allRequests.donors.map(r => ({ ...r, _type: "donor" })),
      ...allRequests.contacts.map(r => ({ ...r, _type: "contact" }))
    ];
    if (!all.length) { showToast("No requests to export", "warn"); return; }
    downloadCSV(toCSV(all, [
      { label: "Type", key: "_type" }, { label: "Name", key: "full_name" },
      { label: "Email", key: "email" }, { label: "Status", key: "status" },
      { label: "Created", key: "created_at" }
    ]), "requests.csv");
  });

  document.getElementById("exportOverviewBtn")?.addEventListener("click", () => {
    const rows = [
      { metric: "Children", value: allChildren.length },
      { metric: "Active Children", value: allChildren.filter(c => c.is_active).length },
      { metric: "Programs", value: allPrograms.length },
      { metric: "Adoption Requests", value: allRequests.adoptions.length },
      { metric: "Volunteer Applications", value: allRequests.volunteers.length },
      { metric: "Donor Leads", value: allRequests.donors.length },
      { metric: "Contact Messages", value: allRequests.contacts.length },
    ];
    downloadCSV(toCSV(rows, [{ label: "Metric", key: "metric" }, { label: "Value", key: "value" }]), "overview.csv");
  });

  // ═══════════════════════════════════
  //  AUTH / NAVIGATION
  // ═══════════════════════════════════
  function showAuth() { authView.classList.remove("hidden"); appView.classList.add("hidden"); }
  function showApp()  { authView.classList.add("hidden");    appView.classList.remove("hidden"); }

  function setActiveTab(name) {
    navButtons.forEach(btn => btn.classList.toggle("active", btn.dataset.tab === name));
    tabs.forEach(tab => tab.classList.toggle("active", tab.id === name));
  }

  function isAdmin()  { return (currentUser?.role || "").toLowerCase() === "admin"; }
  function isMentor() { return (currentUser?.role || "").toLowerCase() === "mentor"; }

  function updateSidebarUser() {
    if (!currentUser) return;
    const name = currentUser.full_name || currentUser.email || "User";
    const role = currentUser.role || "";
    sidebarName.textContent = name;
    sidebarRole.textContent = role;
    sidebarAvatar.textContent = initials(name);
    sidebarAvatar.style.background = avatarColor(name);
  }

  function applyRolePermissions() {
    const mentorOnly = isMentor();
    navButtons.forEach((btn) => {
      const tab = btn.dataset.tab;
      if (!tab) return;
      if (mentorOnly) btn.classList.toggle("hidden", tab !== "mentorChat");
      else btn.classList.remove("hidden");
    });

    [addChildBtn, addProgramBtn, addTeamMemberBtn].forEach(b => b?.classList.toggle("hidden", mentorOnly));
    ["overview","children","programs","requests","team"].forEach(id => {
      document.getElementById(id)?.classList.toggle("hidden", mentorOnly);
    });
    document.getElementById("mentorChat")?.classList.remove("hidden");
    setActiveTab(mentorOnly ? "mentorChat" : "overview");
  }

  async function rpc(name, params = {}) {
    const { data, error } = await supabase.rpc(name, params);
    if (error) throw error;
    return data;
  }

  function setToken(token) {
    sessionToken = token || "";
    if (sessionToken) localStorage.setItem(tokenKey, sessionToken);
    else localStorage.removeItem(tokenKey);
  }

  async function signIn(email, password) {
    const data = await rpc("app_sign_in", { p_email: email.trim(), p_password: password });
    const token = data?.session_token;
    const user  = data?.user;
    if (!token || !user) throw new Error("Invalid login response");
    const role = (user.role || "").toLowerCase();
    if (role !== "admin" && role !== "mentor") throw new Error("Only admin or mentor accounts can access this panel.");
    currentUser = user;
    setToken(token);
  }

  async function signOut() {
    if (sessionToken) {
      try { await rpc("app_sign_out", { p_session_token: sessionToken }); } catch (_) {}
    }
    currentUser = null; activeThreadId = "";
    setToken("");
    showAuth();
    showToast("Signed out successfully", "info");
  }

  // ═══════════════════════════════════
  //  OVERVIEW / DASHBOARD
  // ═══════════════════════════════════
  async function loadOverview() {
    const data = await rpc("app_admin_dashboard_snapshot", { p_session_token: sessionToken });

    const pendingAdoptions = (allRequests.adoptions || []).filter(r =>
      r.status === "submitted" || r.status === "shortlisted" || r.status === "in_review"
    ).length;
    const pendingVolunteers = (allRequests.volunteers || []).filter(r =>
      r.status === "submitted" || r.status === "screening" || r.status === "in_review"
    ).length;
    const pendingLeads = (allRequests.donors || []).filter(r =>
      r.status === "new" || r.status === "in_review"
    ).length;

    const cards = [
      { label: "Adoption Requests", value: allRequests.adoptions.length, tab: "requests", icon: "🏠", cls: "stat-blue"   },
      { label: "Volunteer Applications", value: allRequests.volunteers.length, tab: "requests", icon: "🤝", cls: "stat-green" },
      { label: "Donor Leads", value: allRequests.donors.length, tab: "requests", icon: "💝", cls: "stat-purple" },
      { label: "Contact Messages", value: allRequests.contacts.length, tab: "requests", icon: "✉️", cls: "stat-orange" },
      { label: "Children",         value: allChildren.length,       tab: "children", icon: "👧", cls: "stat-purple" },
      { label: "Programs",         value: allPrograms.length,       tab: "programs", icon: "📚", cls: "stat-teal"   },
      { label: "Pending Reviews", value: pendingAdoptions + pendingVolunteers + pendingLeads, tab: "requests", icon: "⏳", cls: "stat-red" }
    ];

    stats.innerHTML = cards.map(card => `
      <div class="stat clickable ${card.cls}" data-tab="${card.tab}" title="View ${card.label}">
        <div class="stat-icon">${card.icon}</div>
        <div class="stat-body">
          <div class="num">${card.value}</div>
          <div class="label">${escapeHtml(card.label)}</div>
        </div>
      </div>`).join("");

    stats.querySelectorAll(".stat.clickable[data-tab]").forEach(el =>
      el.addEventListener("click", () => setActiveTab(el.dataset.tab))
    );

    renderActivityFeed(data);
    renderQuickStats(data);
  }

  function renderActivityFeed(data) {
    const items = [];
    const addItems = (arr, type, icon, colorClass) => {
      (arr || []).slice(0, 3).forEach(r => {
        items.push({ text: `${type}: <strong>${escapeHtml(r.full_name || r.name || "")}</strong> — ${escapeHtml(r.status || "")}`, icon, color: colorClass, ts: r.created_at || r.updated_at });
      });
    };
    addItems(allRequests.adoptions,  "Adoption",                "🏠", "orange");
    addItems(allRequests.volunteers, "Volunteer Application",    "🤝", "blue");
    addItems(allRequests.donors,     "Donor Lead",              "💝", "red");
    addItems(allRequests.contacts,   "Contact Message",         "✉️", "green");

    items.sort((a, b) => new Date(b.ts) - new Date(a.ts));

    if (!items.length) {
      activityFeed.innerHTML = `<div class="empty-state"><div class="empty-state-icon">🕊️</div>No recent activity</div>`;
      return;
    }

    activityFeed.innerHTML = items.slice(0, 6).map(item => `
      <div class="activity-item">
        <div class="activity-dot ${item.color}"></div>
        <div>
          <div class="activity-text">${item.text}</div>
          <div class="activity-time">${timeAgo(item.ts)}</div>
        </div>
      </div>`).join("");
  }

  function renderQuickStats(data) {
    const active  = allChildren.filter(c => c.is_active).length;
    const activeP = allPrograms.filter(p => p.is_active).length;
    quickStats.innerHTML = `
      <div class="qs-item"><span>Active Children</span><span class="qs-val" style="color:var(--success)">${active}</span></div>
      <div class="qs-item"><span>Active Programs</span><span class="qs-val" style="color:var(--info)">${activeP}</span></div>
      <div class="qs-item"><span>Adoption Pending</span><span class="qs-val" style="color:var(--warn)">${(allRequests.adoptions || []).filter(r => r.status === "submitted" || r.status === "shortlisted").length}</span></div>
      <div class="qs-item"><span>Volunteer Pending</span><span class="qs-val" style="color:var(--warn)">${(allRequests.volunteers || []).filter(r => r.status === "submitted" || r.status === "screening").length}</span></div>
      <div class="qs-item"><span>Donor Leads</span><span class="qs-val" style="color:var(--accent)">${allRequests.donors.length}</span></div>
    `;
  }

  // ═══════════════════════════════════
  //  CHILDREN
  // ═══════════════════════════════════
  function renderChildren(list) {
    if (!list.length) {
      childrenList.innerHTML = `<div class="empty-state"><div class="empty-state-icon">👶</div>No children found</div>`;
      return;
    }
    childrenList.innerHTML = list.map(row => {
      const resolvedImageUrl = resolveChildImageUrl(row.image_url);
      const img = resolvedImageUrl
        ? `<img class="child-card-img" src="${escapeHtml(resolvedImageUrl)}" alt="${escapeHtml(row.name)}" loading="lazy" />`
        : `<div class="child-avatar" style="background:${escapeHtml(row.avatar_color_hex || "#FFD8B4")}">👦</div>`;
      return `
        <div class="child-card">
          ${img}
          <div class="child-card-name">${escapeHtml(row.name)} ${badge(row.is_active ? "active" : "inactive")}</div>
          <div class="child-card-meta">Age ${escapeHtml(String(row.age))} · ${escapeHtml(row.location)}</div>
          <div class="muted" style="font-size:12px;margin-bottom:10px">${escapeHtml((row.story || "").slice(0, 80))}${row.story?.length > 80 ? "…" : ""}</div>
          <div class="item-actions">
            <button class="ghost" data-edit-child='${JSON.stringify(row)}'>✏️ Edit</button>
            <button class="danger" data-delete-child="${row.id}">🗑 Delete</button>
          </div>
        </div>`;
    }).join("");
    wireContentActions();
  }

  async function loadContent() {
    const data = await rpc("app_admin_list_content", { p_session_token: sessionToken });
    allChildren = Array.isArray(data.children) ? data.children : [];
    allPrograms = Array.isArray(data.programs) ? data.programs : [];

    renderChildren(allChildren);
    renderPrograms(allPrograms);
  }

  // ── Search children
  childSearch?.addEventListener("input", () => {
    const q = (childSearch.value || "").toLowerCase();
    renderChildren(q ? allChildren.filter(c =>
      (c.name || "").toLowerCase().includes(q) || (c.location || "").toLowerCase().includes(q)
    ) : allChildren);
  });

  // ═══════════════════════════════════
  //  PROGRAMS
  // ═══════════════════════════════════
  function renderPrograms(list) {
    if (!list.length) {
      programsList.innerHTML = `<div class="empty-state"><div class="empty-state-icon">📚</div>No programs found</div>`;
      return;
    }
    programsList.innerHTML = list.map(row => {
      const subtitle = row.description;
      const actions = `
        <button class="ghost" data-edit-program='${JSON.stringify(row)}'>✏️ Edit</button>
        <button class="danger" data-delete-program="${row.id}">🗑 Delete</button>
      `;
      return buildItem(row.title, subtitle, actions, row.is_active ? "active" : "inactive");
    }).join("");
    wireContentActions();
  }

  programSearch?.addEventListener("input", () => {
    const q = (programSearch.value || "").toLowerCase();
    renderPrograms(q ? allPrograms.filter(p =>
      (p.title || "").toLowerCase().includes(q) || (p.description || "").toLowerCase().includes(q)
    ) : allPrograms);
  });

  // ═══════════════════════════════════
  //  REQUESTS
  // ═══════════════════════════════════
  async function loadRequests() {
    const data = await rpc("app_admin_list_requests", { p_session_token: sessionToken });
    const adoptions = data.adoptions || [];
    const mentors = data.mentors || [];
    const contacts = data.contacts || [];

    allRequests.adoptions = adoptions;
    allRequests.mentors = mentors;
    allRequests.volunteers = mentors;
    allRequests.donors = contacts.filter(isDonorContact);
    allRequests.contacts = contacts.filter((row) => !isDonorContact(row));

    applyRequestFilter(activeRequestFilter);
  }

  function applyRequestFilter(filter) {
    activeRequestFilter = filter;

    if (requestSummary) {
      requestSummary.innerHTML = `
        <div class="request-chip"><span>🏠 Adoption</span><strong>${allRequests.adoptions.length}</strong></div>
        <div class="request-chip"><span>🤝 Volunteer</span><strong>${allRequests.volunteers.length}</strong></div>
        <div class="request-chip"><span>💝 Donor Leads</span><strong>${allRequests.donors.length}</strong></div>
        <div class="request-chip"><span>✉️ Contact</span><strong>${allRequests.contacts.length}</strong></div>
      `;
    }

    const filterFn = r => filter === "all" || r.status === filter ||
      (filter === "pending" && (r.status === "submitted" || r.status === "screening" || r.status === "in_review" || r.status === "new"));

    renderRequestList(adoptionList, allRequests.adoptions.filter(filterFn), "adoption", ["submitted","shortlisted","approved","rejected"]);
    renderRequestList(volunteerList, allRequests.volunteers.filter(filterFn), "volunteer", ["submitted","screening","approved","rejected"], "mentor");
    renderRequestList(donorList, allRequests.donors.filter(filterFn), "donor", ["new","in_review","resolved"], "contact");
    renderRequestList(contactList, allRequests.contacts.filter(filterFn), "contact", ["new","in_review","resolved"]);
  }

  document.getElementById("requestFilterTabs")?.querySelectorAll(".filter-tab").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".filter-tab").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      applyRequestFilter(btn.dataset.filter);
    });
  });

  function renderRequestList(container, rows, type, statuses, requestType = type) {
    if (!container) {
      return;
    }

    if (!rows.length) {
      container.innerHTML = `<div class="empty-state" style="padding:20px"><div class="empty-state-icon">📭</div>No ${type} requests</div>`;
      return;
    }

    container.innerHTML = rows.map(row => {
      const options = statuses.map(s => `<option value="${s}" ${row.status === s ? "selected" : ""}>${s}</option>`).join("");
      const detailId = `detail-${type}-${row.id}`;

      // Build detail fields
      const detailRows = Object.entries(row)
        .filter(([k]) => !["id","status","full_name","email"].includes(k))
        .map(([k, v]) => v ? `<div class="request-field"><strong>${escapeHtml(k.replace(/_/g," "))}</strong>${escapeHtml(String(v))}</div>` : "")
        .join("");

      const actions = `
        <select data-request-id="${row.id}" data-request-type="${requestType}">${options}</select>
        <button data-save-request="${row.id}" data-request-type="${requestType}" class="ghost">💾 Save</button>
        <button data-delete-request="${row.id}" data-request-type="${requestType}" class="danger">🗑 Delete</button>
        <button class="expand-btn" data-expand="${detailId}">🔍 Details</button>
      `;
      const detail = `
        <div class="request-detail" id="${detailId}">
          ${detailRows}
          <strong>Internal Notes</strong>
          <textarea class="request-notes" placeholder="Add notes…" data-notes-id="${row.id}" data-notes-type="${type}">${escapeHtml(row._notes || "")}</textarea>
        </div>
      `;
      return buildItem(row.full_name, row.email || row.status, actions, row.status) + detail;
    }).join("");

    // Wire expand buttons
    container.querySelectorAll("[data-expand]").forEach(btn => {
      btn.addEventListener("click", () => {
        const el = document.getElementById(btn.dataset.expand);
        if (!el) return;
        el.classList.toggle("open");
        btn.textContent = el.classList.contains("open") ? "✖ Close" : "🔍 Details";
      });
    });

    // Wire save buttons
    container.querySelectorAll("[data-save-request]").forEach(btn => {
      btn.addEventListener("click", async () => {
        const id = btn.getAttribute("data-save-request");
        const reqType = btn.getAttribute("data-request-type");
        const select = container.querySelector(`[data-request-id="${id}"][data-request-type="${reqType}"]`);
        const status = select.value;
        try {
          await rpc("app_admin_update_request_status", {
            p_session_token: sessionToken,
            p_request_type: reqType, p_id: id, p_status: status
          });
          showToast(`Status updated to "${status}"`, "success");
          await loadOverview();
          await loadRequests();
        } catch (err) {
          showToast(err.message || "Failed to update status", "error");
        }
      });
    });

    // Wire delete buttons
    container.querySelectorAll("[data-delete-request]").forEach(btn => {
      btn.addEventListener("click", async () => {
        const id = btn.getAttribute("data-delete-request");
        const reqType = btn.getAttribute("data-request-type");
        if (!confirm("Delete this request record? This cannot be undone.")) return;
        try {
          await rpc("app_admin_delete_request", {
            p_session_token: sessionToken,
            p_request_type: reqType,
            p_id: id
          });
          showToast("Request record deleted", "success");
          await loadOverview();
          await loadRequests();
        } catch (err) {
          showToast(err.message || "Delete failed", "error");
        }
      });
    });
  }

  // ═══════════════════════════════════
  //  TEAM
  // ═══════════════════════════════════
  async function loadTeamUsers() {
    if (!isAdmin()) {
      teamList.innerHTML = '<div class="muted">Team management is only available for admins.</div>';
      return;
    }
    const rows = await rpc("app_admin_list_team_users", { p_session_token: sessionToken });
    const items = Array.isArray(rows) ? rows : [];

    if (!items.length) {
      teamList.innerHTML = `<div class="empty-state"><div class="empty-state-icon">👥</div>No team members yet</div>`;
      return;
    }

    teamList.innerHTML = items.map(row => {
      const color = avatarColor(row.full_name);
      const inits = initials(row.full_name);
      const statusBadge = row.is_active ? badge("active") : badge("inactive");
      const roleBadge = badge(row.role);
      return `
        <div class="item">
          <div class="team-item-row">
            <div class="team-avatar" style="background:${color}">${inits}</div>
            <div style="flex:1">
              <div class="item-title">${escapeHtml(row.full_name)} ${roleBadge}</div>
              <div class="item-sub">${escapeHtml(row.email)} ${statusBadge}</div>
            </div>
          </div>
        </div>`;
    }).join("");
  }

  // ═══════════════════════════════════
  //  CHAT
  // ═══════════════════════════════════
  async function loadChatThreads() {
    const rows  = await rpc("app_admin_list_chat_threads", { p_session_token: sessionToken });
    const items = Array.isArray(rows) ? rows : [];

    chatThreads.innerHTML = items.map(row => {
      const subtitle = `${row.user_email} | ${row.status}`;
      const preview  = row.last_message ? `<div class="muted">${escapeHtml(row.last_message)}</div>` : "";
      const activeClass = row.id === activeThreadId ? " active" : "";
      return `
        <div class="item thread-item${activeClass}" data-thread-id="${row.id}">
          <div><strong>${escapeHtml(row.user_name || "Unknown User")}</strong></div>
          <div class="muted">${escapeHtml(subtitle)}</div>
          ${preview}
          <div class="muted">${timeAgo(row.last_message_at || row.updated_at)}</div>
        </div>`;
    }).join("");

    chatThreads.querySelectorAll("[data-thread-id]").forEach(item => {
      item.addEventListener("click", async () => {
        activeThreadId = item.getAttribute("data-thread-id") || "";
        await loadChatThreads();
        await loadChatMessages();
      });
    });

    if (!activeThreadId && items.length > 0) {
      activeThreadId = items[0].id;
      await loadChatThreads();
      await loadChatMessages();
    }
  }

  async function loadChatMessages() {
    if (!activeThreadId) {
      activeChatTitle.textContent = "Select a thread";
      chatMessages.innerHTML = '<div class="muted" style="padding:10px">Choose a user thread to view messages.</div>';
      return;
    }
    const rows  = await rpc("app_admin_list_chat_messages", { p_session_token: sessionToken, p_thread_id: activeThreadId });
    const items = Array.isArray(rows) ? rows : [];

    activeChatTitle.textContent = `Thread: ${activeThreadId.slice(0, 8)}…`;
    chatMessages.innerHTML = items.map(row => {
      const role = (row.sender_role || "").toLowerCase();
      const mine = role === "admin" || role === "mentor";
      return `
        <div class="chat-bubble ${mine ? "mine" : "theirs"}">
          <div>${escapeHtml(row.message_text || "")}</div>
          <span class="chat-meta">${escapeHtml(role || "user")} · ${timeAgo(row.created_at)}</span>
        </div>`;
    }).join("");

    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  // ═══════════════════════════════════
  //  ITEM BUILDER
  // ═══════════════════════════════════
  function buildItem(title, subtitle, actionsHtml, badgeLabel) {
    return `
      <div class="item">
        <div class="item-head">
          <div>
            <div class="item-title">${escapeHtml(title)}</div>
            <div class="item-sub">${escapeHtml(subtitle || "")}</div>
          </div>
          ${badge(badgeLabel)}
        </div>
        <div class="item-actions">${actionsHtml || ""}</div>
      </div>`;
  }

  // ═══════════════════════════════════
  //  DIALOG / FORMS
  // ═══════════════════════════════════
  function openDialog(fields, onSubmit, title) {
    editorForm.innerHTML = `
      <div class="dialog-head">
        <div class="dialog-title">${escapeHtml(title)}</div>
        <button type="button" class="dialog-close-btn" data-dialog-close aria-label="Close dialog">✕</button>
      </div>
    ` + fields + `
      <div class="item-actions" style="justify-content:flex-end;margin-top:8px">
        <button value="cancel" formmethod="dialog" class="ghost">Cancel</button>
        <button id="saveEditorBtn" type="submit">Save Changes</button>
      </div>`;

    wireDialogCloseControls();

    editorForm.onsubmit = async (e) => {
      e.preventDefault();
      const btn = document.getElementById("saveEditorBtn");
      if (btn) { btn.disabled = true; btn.textContent = "Saving…"; }
      try {
        await onSubmit(new FormData(editorForm));
        editorDialog.close();
        await loadAllData();
        showToast("Saved successfully!", "success");
      } catch (err) {
        showToast(err.message || "Save failed", "error");
        if (btn) { btn.disabled = false; btn.textContent = "Save Changes"; }
      }
    };

    editorDialog.showModal();
    // Wire photo upload if the form contains the upload zone
    setTimeout(() => wirePhotoUpload(), 0);
  }

  function wireDialogCloseControls() {
    editorForm.querySelectorAll("[data-dialog-close]").forEach((btn) => {
      btn.addEventListener("click", () => editorDialog.close());
    });
  }

  function childFields(row = {}) {
    const checked = (row.is_active ?? true) ? "checked" : "";
    const existingImageUrl = resolveChildImageUrl(row.image_url);
    const existingImg = existingImageUrl ? `<img src="${escapeHtml(existingImageUrl)}" class="upload-preview-img" id="uploadPreviewImg" />` : `<div class="upload-preview-placeholder" id="uploadPreviewImg">👶</div>`;
    return `
      <input name="id" value="${escapeHtml(row.id || "")}" type="hidden" />
      <input name="image_url" value="${escapeHtml(row.image_url || "")}" type="hidden" id="imageUrlHidden" />

      <!-- Photo Upload Zone -->
      <div class="upload-zone" id="photoUploadZone" title="Click or drag a photo here">
        <div class="upload-zone-preview" id="uploadPreview">
          ${existingImg}
        </div>
        <div class="upload-zone-body">
          <div class="upload-zone-icon">📷</div>
          <div class="upload-zone-label">Click to upload photo</div>
          <div class="upload-zone-sub">or drag & drop · JPG, PNG, WEBP · max 5 MB</div>
          <input type="file" id="photoFileInput" accept="image/jpeg,image/png,image/webp,image/gif" class="upload-file-input" />
        </div>
        <div class="upload-progress" id="uploadProgress" style="display:none">
          <div class="upload-progress-bar" id="uploadProgressBar"></div>
        </div>
        <div class="upload-status" id="uploadStatus"></div>
      </div>
      <div style="font-size:12px;color:var(--text-muted);margin-top:-6px">Or paste a URL instead:</div>
      <input id="imageUrlManual" placeholder="https://... (optional, overrides upload)" value="${escapeHtml(row.image_url || "")}" />

      <input name="name" placeholder="Name" value="${escapeHtml(row.name || "")}" required />
      <input name="age" placeholder="Age" type="number" min="1" max="18" value="${escapeHtml(row.age || 5)}" required />
      <input name="location" placeholder="Location" value="${escapeHtml(row.location || "")}" required />
      <textarea name="story" placeholder="Story" required>${escapeHtml(row.story || "")}</textarea>
      <textarea name="interests" placeholder="Activities / What child likes to do" required>${escapeHtml(row.interests || "")}</textarea>
      <select name="gender">
        <option value="boy" ${(row.gender || "") === "boy" ? "selected" : ""}>Boy</option>
        <option value="girl" ${(row.gender || "") === "girl" ? "selected" : ""}>Girl</option>
        <option value="other" ${(row.gender || "") === "other" ? "selected" : ""}>Other</option>
      </select>
      <input name="avatar_color_hex" placeholder="Avatar fallback colour e.g. #FFD8B4" value="${escapeHtml(row.avatar_color_hex || "#FFD8B4")}" />
      <input name="display_order" placeholder="Display order" type="number" min="0" value="${escapeHtml(row.display_order || 0)}" />
      <label class="toggle-label">
        <input name="is_active" type="checkbox" class="toggle-input" ${checked} />
        <span class="toggle-track"><span class="toggle-thumb"></span></span>
        <span class="toggle-text">Active</span>
      </label>
    `;
  }

  // Wire up upload zone immediately after it is injected into the DOM
  function wirePhotoUpload() {
    const zone      = document.getElementById("photoUploadZone");
    const fileInput = document.getElementById("photoFileInput");
    const preview   = document.getElementById("uploadPreview");
    const hidden    = document.getElementById("imageUrlHidden");
    const manual    = document.getElementById("imageUrlManual");
    const status    = document.getElementById("uploadStatus");
    const progress  = document.getElementById("uploadProgress");
    const bar       = document.getElementById("uploadProgressBar");
    if (!zone || !fileInput) return;

    // Sync manual URL → hidden field
    manual.addEventListener("input", () => {
      hidden.value = manual.value.trim();
      if (manual.value.trim()) {
        preview.innerHTML = `<img src="${escapeHtml(manual.value.trim())}" class="upload-preview-img" />`;
      }
    });

    // Click zone → trigger file picker
    zone.addEventListener("click", (e) => { if (e.target !== fileInput) fileInput.click(); });

    // Drag & Drop
    zone.addEventListener("dragover",  (e) => { e.preventDefault(); zone.classList.add("drag-over"); });
    zone.addEventListener("dragleave", ()  => zone.classList.remove("drag-over"));
    zone.addEventListener("drop", (e) => {
      e.preventDefault();
      zone.classList.remove("drag-over");
      const file = e.dataTransfer.files[0];
      if (file) handlePhotoFile(file);
    });

    fileInput.addEventListener("change", () => {
      if (fileInput.files[0]) handlePhotoFile(fileInput.files[0]);
    });

    async function handlePhotoFile(file) {
      if (!file.type.startsWith("image/")) { showToast("Please select an image file", "warn"); return; }
      if (file.size > 5 * 1024 * 1024)    { showToast("File too large (max 5 MB)", "warn"); return; }

      // Local preview immediately
      const localUrl = URL.createObjectURL(file);
      preview.innerHTML = `<img src="${localUrl}" class="upload-preview-img" />`;
      status.textContent = "Uploading…";
      status.className   = "upload-status uploading";
      progress.style.display = "block";
      bar.style.width = "0%";

      // Animate progress bar (fake smooth progress until upload resolves)
      let pct = 0;
      const tick = setInterval(() => { pct = Math.min(pct + 6, 85); bar.style.width = pct + "%"; }, 200);

      try {
        const ext      = file.name.split(".").pop().toLowerCase() || "jpg";
        const safeName = `child_${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
        const { data, error } = await supabase.storage
          .from("children-photos")
          .upload(safeName, file, { cacheControl: "3600", upsert: false, contentType: file.type });

        clearInterval(tick);
        bar.style.width = "100%";

        if (error) throw error;

        const uploadedPath = data.path;
        const { data: urlData } = supabase.storage.from("children-photos").getPublicUrl(uploadedPath);
        const publicUrl = urlData.publicUrl;

        // Persist storage object path in DB so URLs can be regenerated reliably.
        hidden.value = uploadedPath;
        manual.value = uploadedPath;
        status.textContent = "✅ Photo uploaded!";
        status.className   = "upload-status done";
        URL.revokeObjectURL(localUrl);
        preview.innerHTML = `<img src="${escapeHtml(publicUrl)}" class="upload-preview-img" />`;
      } catch (err) {
        clearInterval(tick);
        bar.style.width = "0%";
        status.textContent = "❌ " + (err.message || "Upload failed");
        status.className   = "upload-status failed";
        showToast(err.message || "Photo upload failed", "error");
      } finally {
        setTimeout(() => { progress.style.display = "none"; }, 800);
      }
    }
  }

  function programFields(row = {}) {
    const checked = (row.is_active ?? true) ? "checked" : "";
    return `
      <input name="id" value="${escapeHtml(row.id || "")}" type="hidden" />
      <input name="title" placeholder="Title" value="${escapeHtml(row.title || "")}" required />
      <textarea name="description" placeholder="Description" required>${escapeHtml(row.description || "")}</textarea>
      <input name="icon_key" placeholder="school/palette/people/book/music/run" value="${escapeHtml(row.icon_key || "school")}" />
      <input name="image_url" placeholder="https://..." value="${escapeHtml(row.image_url || "")}" />
      <input name="color_hex" placeholder="#4FA8D5" value="${escapeHtml(row.color_hex || "#4FA8D5")}" />
      <input name="display_order" placeholder="Display order" type="number" min="0" value="${escapeHtml(row.display_order || 0)}" />
      <label class="toggle-label">
        <input name="is_active" type="checkbox" class="toggle-input" ${checked} />
        <span class="toggle-track"><span class="toggle-thumb"></span></span>
        <span class="toggle-text">Active</span>
      </label>
    `;
  }

  async function saveChild(fd) {
    // Prefer the manual URL field if the user typed one, otherwise use the hidden (uploaded) URL
    const manualUrl  = (document.getElementById("imageUrlManual")?.value || "").trim();
    const uploadedUrl = (document.getElementById("imageUrlHidden")?.value || "").trim();
    const finalUrl   = manualUrl || uploadedUrl || fd.get("image_url") || "";
    await rpc("app_admin_upsert_child", {
      p_session_token: sessionToken,
      p_id: fd.get("id") || null,
      p_name: fd.get("name"),
      p_age: Number(fd.get("age")),
      p_location: fd.get("location"),
      p_story: fd.get("story"),
      p_interests: fd.get("interests"),
      p_image_url: finalUrl,
      p_gender: fd.get("gender"),
      p_avatar_color_hex: fd.get("avatar_color_hex"),
      p_is_active: fd.get("is_active") === "on",
      p_display_order: Number(fd.get("display_order") || 0)
    });
  }

  async function saveProgram(fd) {
    await rpc("app_admin_upsert_program", {
      p_session_token: sessionToken,
      p_id: fd.get("id") || null,
      p_title: fd.get("title"),
      p_description: fd.get("description"),
      p_icon_key: fd.get("icon_key"),
      p_image_url: fd.get("image_url"),
      p_color_hex: fd.get("color_hex"),
      p_is_active: fd.get("is_active") === "on",
      p_display_order: Number(fd.get("display_order") || 0)
    });
  }

  function wireContentActions() {
    childrenList.querySelectorAll("[data-edit-child]").forEach(btn => {
      btn.addEventListener("click", () => {
        const row = JSON.parse(btn.getAttribute("data-edit-child"));
        openDialog(childFields(row), saveChild, "Edit Child");
      });
    });

    childrenList.querySelectorAll("[data-delete-child]").forEach(btn => {
      btn.addEventListener("click", async () => {
        if (!confirm("Delete this child profile? This cannot be undone.")) return;
        try {
          await rpc("app_admin_delete_child", { p_session_token: sessionToken, p_id: btn.getAttribute("data-delete-child") });
          showToast("Child profile deleted", "success");
          await loadAllData();
        } catch (err) { showToast(err.message || "Delete failed", "error"); }
      });
    });

    programsList.querySelectorAll("[data-edit-program]").forEach(btn => {
      btn.addEventListener("click", () => {
        const row = JSON.parse(btn.getAttribute("data-edit-program"));
        openDialog(programFields(row), saveProgram, "Edit Program");
      });
    });

    programsList.querySelectorAll("[data-delete-program]").forEach(btn => {
      btn.addEventListener("click", async () => {
        if (!confirm("Delete this program?")) return;
        try {
          await rpc("app_admin_delete_program", { p_session_token: sessionToken, p_id: btn.getAttribute("data-delete-program") });
          showToast("Program deleted", "success");
          await loadAllData();
        } catch (err) { showToast(err.message || "Delete failed", "error"); }
      });
    });
  }

  // ═══════════════════════════════════
  //  TEAM DIALOG
  // ═══════════════════════════════════
  function openTeamMemberDialog() {
    if (!isAdmin()) { showToast("Only admins can add team members.", "warn"); return; }

    const fields = `
      <div class="dialog-head">
        <div class="dialog-title">Add Admin / Mentor</div>
        <button type="button" class="dialog-close-btn" data-dialog-close aria-label="Close dialog">✕</button>
      </div>
      <input name="full_name" placeholder="Full name" required />
      <input name="email" type="email" placeholder="Email" required />
      <input name="password" type="password" placeholder="Temporary password" minlength="6" required />
      <select name="role" required>
        <option value="mentor">Mentor</option>
        <option value="admin">Admin</option>
      </select>
      <label class="toggle-label">
        <input name="is_active" type="checkbox" class="toggle-input" checked />
        <span class="toggle-track"><span class="toggle-thumb"></span></span>
        <span class="toggle-text">Active</span>
      </label>
      <div class="item-actions" style="justify-content:flex-end;margin-top:8px">
        <button value="cancel" formmethod="dialog" class="ghost">Cancel</button>
        <button type="submit">Create Member</button>
      </div>
    `;

    editorForm.innerHTML = fields;
    wireDialogCloseControls();
    editorForm.onsubmit = async (e) => {
      e.preventDefault();
      const fd = new FormData(editorForm);
      try {
        await rpc("app_admin_create_user", {
          p_session_token: sessionToken,
          p_full_name: fd.get("full_name"),
          p_email: fd.get("email"),
          p_password: fd.get("password"),
          p_role: fd.get("role"),
          p_is_active: fd.get("is_active") === "on"
        });
        editorDialog.close();
        showToast("Team member created!", "success");
        await loadTeamUsers();
      } catch (err) {
        showToast(err.message || "Unable to create team member", "error");
      }
    };
    editorDialog.showModal();
  }

  // Allow closing dialog by clicking outside the dialog box.
  editorDialog?.addEventListener("click", (e) => {
    if (e.target === editorDialog) {
      editorDialog.close();
    }
  });

  // ═══════════════════════════════════
  //  LOAD ALL
  // ═══════════════════════════════════
  async function loadAllData() {
    if (isMentor()) {
      await Promise.all([loadChatThreads()]);
      return;
    }
    // Load content first so counts are available for overview
    await loadContent();
    await loadRequests();
    await Promise.all([loadOverview(), loadTeamUsers(), loadChatThreads()]);
  }

  // ═══════════════════════════════════
  //  EVENT WIRING
  // ═══════════════════════════════════
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    authError.textContent = "";
    const btn = e.target.querySelector("button[type=submit]");
    if (btn) { btn.disabled = true; btn.textContent = "Signing in…"; }
    try {
      await signIn(document.getElementById("email").value, document.getElementById("password").value);
      showApp();
      updateSidebarUser();
      applyRolePermissions();
      await loadAllData();
      showToast(`Welcome back, ${currentUser?.full_name || currentUser?.email}!`, "success");
    } catch (err) {
      authError.textContent = err.message || "Sign in failed";
    } finally {
      if (btn) { btn.disabled = false; btn.textContent = "Sign In"; }
    }
  });

  logoutBtn.addEventListener("click", signOut);
  addChildBtn.addEventListener("click", () => openDialog(childFields(), saveChild, "Add Child"));
  addProgramBtn.addEventListener("click", () => openDialog(programFields(), saveProgram, "Add Program"));
  if (addTeamMemberBtn) addTeamMemberBtn.addEventListener("click", openTeamMemberDialog);

  if (chatSendForm) {
    chatSendForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      if (!activeThreadId) { showToast("Select a thread first.", "warn"); return; }
      const text = (chatInput.value || "").trim();
      if (!text) return;
      try {
        await rpc("app_admin_send_chat_message", { p_session_token: sessionToken, p_thread_id: activeThreadId, p_message_text: text });
        chatInput.value = "";
        await loadChatMessages();
        await loadChatThreads();
      } catch (err) {
        showToast(err.message || "Failed to send message", "error");
      }
    });
  }

  navButtons.forEach(btn => btn.addEventListener("click", () => setActiveTab(btn.dataset.tab)));

  // ═══════════════════════════════════
  //  BOOT
  // ═══════════════════════════════════
  (async () => {
    if (!sessionToken) { showAuth(); return; }
    try {
      const user = await rpc("app_get_session_user", { p_session_token: sessionToken });
      currentUser = user;
      const role = (currentUser?.role || "").toLowerCase();
      if (role !== "admin" && role !== "mentor") throw new Error("Not authorized");
      showApp();
      updateSidebarUser();
      applyRolePermissions();
      await loadAllData();
    } catch (_) {
      currentUser = null;
      setToken("");
      showAuth();
    }
  })();
})();
