(() => {
  const cfg = window.WEBSITE_CONFIG || window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey || !window.supabase?.createClient) {
    return;
  }

  const supabase = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  const state = {
    token: localStorage.getItem("website_session_token") || localStorage.getItem("admin_session_token") || "",
    user: null,
    threadId: "",
    pollTimer: null
  };

  const chatGate = document.getElementById("chatGate");
  const chatPanel = document.getElementById("chatPanel");
  const gateMessage = document.getElementById("gateMessage");
  const chatStatus = document.getElementById("chatStatus");
  const chatMessages = document.getElementById("chatMessages");
  const chatForm = document.getElementById("chatSendForm");
  const chatInput = document.getElementById("chatInput");
  const signInBtn = document.getElementById("goSignIn");
  const goAdminBtn = document.getElementById("goAdminPanel");

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  async function rpc(name, params = {}) {
    const { data, error } = await supabase.rpc(name, params);
    if (error) {
      throw error;
    }
    return data;
  }

  function setStatus(message, isError = false) {
    if (!chatStatus) return;
    chatStatus.textContent = message;
    chatStatus.className = isError ? "chat-status error" : "chat-status";
  }

  function showGate(message) {
    chatGate.classList.remove("hidden");
    chatPanel.classList.add("hidden");
    gateMessage.textContent = message;
  }

  function showChat() {
    chatGate.classList.add("hidden");
    chatPanel.classList.remove("hidden");
  }

  function renderMessages(rows) {
    if (!Array.isArray(rows) || rows.length === 0) {
      chatMessages.innerHTML = '<div class="empty-chat">No messages yet. Start by saying hello.</div>';
      return;
    }

    chatMessages.innerHTML = rows.map((row) => {
      const role = String(row.sender_role || "user");
      const mine = role === "user";
      const cls = mine ? "bubble mine" : "bubble mentor";
      const sender = mine ? "You" : "Mentor Team";
      return `
        <div class="${cls}">
          <div class="bubble-text">${escapeHtml(row.message_text || "")}</div>
          <div class="bubble-meta">${sender}</div>
        </div>
      `;
    }).join("");

    chatMessages.scrollTop = chatMessages.scrollHeight;
  }

  async function loadMessages() {
    if (!state.threadId || !state.token) return;
    try {
      const rows = await rpc("app_user_list_chat_messages", {
        p_session_token: state.token,
        p_thread_id: state.threadId
      });
      renderMessages(rows);
    } catch (error) {
      setStatus(error.message || "Unable to load messages", true);
    }
  }

  async function bootstrapUserChat() {
    const thread = await rpc("app_user_get_or_create_chat_thread", {
      p_session_token: state.token
    });

    const threadId = String(thread?.id || "");
    if (!threadId) {
      throw new Error("Could not create chat thread.");
    }

    state.threadId = threadId;
    await loadMessages();

    if (state.pollTimer) {
      clearInterval(state.pollTimer);
    }
    state.pollTimer = setInterval(loadMessages, 4000);
  }

  async function detectUser() {
    if (!state.token) {
      showGate("Please sign in first to start mentor chat.");
      return;
    }

    try {
      const user = await rpc("app_get_session_user", { p_session_token: state.token });
      state.user = user;
      const role = String(user?.role || "").toLowerCase();

      if (role === "admin" || role === "mentor") {
        showGate("You are signed in as admin/mentor. Use the Admin Panel Mentor Chat to reply to users.");
        goAdminBtn.classList.remove("hidden");
        return;
      }

      showChat();
      setStatus("Connected to mentor support.");
      await bootstrapUserChat();
    } catch (error) {
      showGate("Session invalid or expired. Please sign in again.");
    }
  }

  async function sendMessage(event) {
    event.preventDefault();
    const text = chatInput.value.trim();
    if (!text || !state.threadId) return;

    const submitBtn = chatForm.querySelector('button[type="submit"]');
    submitBtn.disabled = true;

    try {
      await rpc("app_user_send_chat_message", {
        p_session_token: state.token,
        p_thread_id: state.threadId,
        p_message_text: text
      });
      chatInput.value = "";
      await loadMessages();
    } catch (error) {
      setStatus(error.message || "Unable to send message", true);
    } finally {
      submitBtn.disabled = false;
    }
  }

  signInBtn?.addEventListener("click", () => {
    window.location.href = "admin-login.html";
  });

  goAdminBtn?.addEventListener("click", () => {
    window.location.href = "../admin paneel/index.html";
  });

  chatForm?.addEventListener("submit", sendMessage);

  detectUser();
})();
