(() => {
  const cfg = window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) {
    alert("Configure admin paneel/config.js with Supabase URL and anon key.");
    return;
  }

  const supabase = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  const tokenKey = "admin_session_token";

  const authView = document.getElementById("authView");
  const appView = document.getElementById("appView");
  const authError = document.getElementById("authError");

  const loginForm = document.getElementById("loginForm");
  const logoutBtn = document.getElementById("logoutBtn");

  const stats = document.getElementById("stats");
  const childrenList = document.getElementById("childrenList");
  const programsList = document.getElementById("programsList");
  const adoptionList = document.getElementById("adoptionList");
  const mentorList = document.getElementById("mentorList");
  const contactList = document.getElementById("contactList");

  const addChildBtn = document.getElementById("addChildBtn");
  const addProgramBtn = document.getElementById("addProgramBtn");

  const editorDialog = document.getElementById("editorDialog");
  const editorForm = document.getElementById("editorForm");

  const navButtons = Array.from(document.querySelectorAll(".nav-btn[data-tab]"));
  const tabs = Array.from(document.querySelectorAll(".tab"));

  let sessionToken = localStorage.getItem(tokenKey) || "";

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function showAuth() {
    authView.classList.remove("hidden");
    appView.classList.add("hidden");
  }

  function showApp() {
    authView.classList.add("hidden");
    appView.classList.remove("hidden");
  }

  function setActiveTab(name) {
    navButtons.forEach((btn) => btn.classList.toggle("active", btn.dataset.tab === name));
    tabs.forEach((tab) => tab.classList.toggle("active", tab.id === name));
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
    const user = data?.user;
    if (!token || !user) throw new Error("Invalid login response");
    if ((user.role || "").toLowerCase() !== "admin") {
      throw new Error("This account is not admin.");
    }
    setToken(token);
  }

  async function signOut() {
    if (sessionToken) {
      try {
        await rpc("app_sign_out", { p_session_token: sessionToken });
      } catch (_) {}
    }
    setToken("");
    showAuth();
  }

  async function loadOverview() {
    const data = await rpc("app_admin_dashboard_snapshot", { p_session_token: sessionToken });
    const cards = [
      { label: "Contact Messages", value: data.contact_count || 0 },
      { label: "Adoption Requests", value: data.adoption_count || 0 },
      { label: "Mentor Requests", value: data.mentor_count || 0 }
    ];
    stats.innerHTML = cards
      .map((card) => `<div class="stat"><div class="num">${card.value}</div><div>${escapeHtml(card.label)}</div></div>`)
      .join("");
  }

  function buildItem(title, subtitle, actionsHtml, badge) {
    return `
      <div class="item">
        <div class="item-head">
          <div>
            <div><strong>${escapeHtml(title)}</strong></div>
            <div class="muted">${escapeHtml(subtitle || "")}</div>
          </div>
          ${badge ? `<span class="badge">${escapeHtml(badge)}</span>` : ""}
        </div>
        <div class="item-actions">${actionsHtml || ""}</div>
      </div>
    `;
  }

  async function loadContent() {
    const data = await rpc("app_admin_list_content", { p_session_token: sessionToken });
    const children = Array.isArray(data.children) ? data.children : [];
    const programs = Array.isArray(data.programs) ? data.programs : [];

    childrenList.innerHTML = children
      .map((row) => {
        const title = `${row.name} (${row.age})`;
        const subtitle = `${row.location} - ${row.story}`;
        const badge = row.is_active ? "active" : "inactive";
        const actions = `
          <button class="ghost" data-edit-child='${JSON.stringify(row)}'>Edit</button>
          <button class="danger" data-delete-child="${row.id}">Delete</button>
        `;
        return buildItem(title, subtitle, actions, badge);
      })
      .join("");

    programsList.innerHTML = programs
      .map((row) => {
        const actions = `
          <button class="ghost" data-edit-program='${JSON.stringify(row)}'>Edit</button>
          <button class="danger" data-delete-program="${row.id}">Delete</button>
        `;
        return buildItem(row.title, row.description, actions, row.is_active ? "active" : "inactive");
      })
      .join("");

    wireContentActions();
  }

  async function loadRequests() {
    const data = await rpc("app_admin_list_requests", { p_session_token: sessionToken });

    renderRequestList(adoptionList, data.adoptions || [], "adoption", ["submitted", "shortlisted", "approved", "rejected"]);
    renderRequestList(mentorList, data.mentors || [], "mentor", ["submitted", "screening", "approved", "rejected"]);
    renderRequestList(contactList, data.contacts || [], "contact", ["new", "in_review", "resolved"]);
  }

  function renderRequestList(container, rows, type, statuses) {
    container.innerHTML = rows
      .map((row) => {
        const options = statuses.map((s) => `<option value="${s}" ${row.status === s ? "selected" : ""}>${s}</option>`).join("");
        const actions = `
          <select data-request-id="${row.id}" data-request-type="${type}">${options}</select>
          <button data-save-request="${row.id}" data-request-type="${type}" class="ghost">Save</button>
        `;
        return buildItem(row.full_name, row.email || row.status, actions, row.status);
      })
      .join("");

    container.querySelectorAll("[data-save-request]").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const id = btn.getAttribute("data-save-request");
        const reqType = btn.getAttribute("data-request-type");
        const select = container.querySelector(`[data-request-id="${id}"][data-request-type="${reqType}"]`);
        const status = select.value;
        try {
          await rpc("app_admin_update_request_status", {
            p_session_token: sessionToken,
            p_request_type: reqType,
            p_id: id,
            p_status: status
          });
          await loadOverview();
          await loadRequests();
        } catch (err) {
          alert(err.message || "Failed to update status");
        }
      });
    });
  }

  function openDialog(fields, onSubmit, title) {
    editorForm.innerHTML = `<h3>${escapeHtml(title)}</h3>` + fields + `
      <div class="item-actions">
        <button value="cancel" formmethod="dialog" class="ghost">Cancel</button>
        <button id="saveEditorBtn" type="submit">Save</button>
      </div>
    `;

    editorForm.onsubmit = async (e) => {
      e.preventDefault();
      try {
        await onSubmit(new FormData(editorForm));
        editorDialog.close();
        await loadAllData();
      } catch (err) {
        alert(err.message || "Save failed");
      }
    };

    editorDialog.showModal();
  }

  function childFields(row = {}) {
    return `
      <input name="id" value="${escapeHtml(row.id || "")}" type="hidden" />
      <input name="name" placeholder="Name" value="${escapeHtml(row.name || "")}" required />
      <input name="age" placeholder="Age" type="number" min="1" max="18" value="${escapeHtml(row.age || 5)}" required />
      <input name="location" placeholder="Location" value="${escapeHtml(row.location || "")}" required />
      <textarea name="story" placeholder="Story" required>${escapeHtml(row.story || "")}</textarea>
      <select name="gender">
        <option value="boy" ${(row.gender || "") === "boy" ? "selected" : ""}>Boy</option>
        <option value="girl" ${(row.gender || "") === "girl" ? "selected" : ""}>Girl</option>
        <option value="other" ${(row.gender || "") === "other" ? "selected" : ""}>Other</option>
      </select>
      <input name="avatar_color_hex" placeholder="#FFD8B4" value="${escapeHtml(row.avatar_color_hex || "#FFD8B4")}" />
      <label><input name="is_active" type="checkbox" ${(row.is_active ?? true) ? "checked" : ""}/> Active</label>
      <input name="display_order" type="number" value="${escapeHtml(row.display_order || 0)}" />
    `;
  }

  function programFields(row = {}) {
    return `
      <input name="id" value="${escapeHtml(row.id || "")}" type="hidden" />
      <input name="title" placeholder="Title" value="${escapeHtml(row.title || "")}" required />
      <textarea name="description" placeholder="Description" required>${escapeHtml(row.description || "")}</textarea>
      <input name="icon_key" placeholder="school/palette/people/book/music/run" value="${escapeHtml(row.icon_key || "school")}" />
      <input name="color_hex" placeholder="#4FA8D5" value="${escapeHtml(row.color_hex || "#4FA8D5")}" />
      <label><input name="is_active" type="checkbox" ${(row.is_active ?? true) ? "checked" : ""}/> Active</label>
      <input name="display_order" type="number" value="${escapeHtml(row.display_order || 0)}" />
    `;
  }

  async function saveChild(fd) {
    await rpc("app_admin_upsert_child", {
      p_session_token: sessionToken,
      p_id: fd.get("id") || null,
      p_name: fd.get("name"),
      p_age: Number(fd.get("age")),
      p_location: fd.get("location"),
      p_story: fd.get("story"),
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
      p_color_hex: fd.get("color_hex"),
      p_is_active: fd.get("is_active") === "on",
      p_display_order: Number(fd.get("display_order") || 0)
    });
  }

  function wireContentActions() {
    childrenList.querySelectorAll("[data-edit-child]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const row = JSON.parse(btn.getAttribute("data-edit-child"));
        openDialog(childFields(row), saveChild, "Edit Child");
      });
    });

    childrenList.querySelectorAll("[data-delete-child]").forEach((btn) => {
      btn.addEventListener("click", async () => {
        if (!confirm("Delete this child profile?")) return;
        await rpc("app_admin_delete_child", {
          p_session_token: sessionToken,
          p_id: btn.getAttribute("data-delete-child")
        });
        await loadAllData();
      });
    });

    programsList.querySelectorAll("[data-edit-program]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const row = JSON.parse(btn.getAttribute("data-edit-program"));
        openDialog(programFields(row), saveProgram, "Edit Program");
      });
    });

    programsList.querySelectorAll("[data-delete-program]").forEach((btn) => {
      btn.addEventListener("click", async () => {
        if (!confirm("Delete this program?")) return;
        await rpc("app_admin_delete_program", {
          p_session_token: sessionToken,
          p_id: btn.getAttribute("data-delete-program")
        });
        await loadAllData();
      });
    });
  }

  async function loadAllData() {
    await Promise.all([loadOverview(), loadContent(), loadRequests()]);
  }

  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    authError.textContent = "";
    try {
      const email = document.getElementById("email").value;
      const password = document.getElementById("password").value;
      await signIn(email, password);
      showApp();
      await loadAllData();
    } catch (err) {
      authError.textContent = err.message || "Sign in failed";
    }
  });

  logoutBtn.addEventListener("click", signOut);

  addChildBtn.addEventListener("click", () => {
    openDialog(childFields(), saveChild, "Add Child");
  });

  addProgramBtn.addEventListener("click", () => {
    openDialog(programFields(), saveProgram, "Add Program");
  });

  navButtons.forEach((btn) => {
    btn.addEventListener("click", () => setActiveTab(btn.dataset.tab));
  });

  (async () => {
    if (!sessionToken) {
      showAuth();
      return;
    }

    try {
      await rpc("app_get_session_user", { p_session_token: sessionToken });
      showApp();
      await loadAllData();
    } catch (_) {
      setToken("");
      showAuth();
    }
  })();
})();
