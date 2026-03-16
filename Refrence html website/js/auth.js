(() => {
  const cfg = window.WEBSITE_CONFIG || window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey || !window.supabase?.createClient) {
    return;
  }

  if (window.location.protocol === "file:") {
    alert("Open website through a local server (for example VS Code Live Server). Direct file:// mode can block Supabase requests.");
  }

  const supabase = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);

  function setSessionToken(token) {
    if (!token) {
      return;
    }
    localStorage.setItem("website_session_token", token);
    localStorage.setItem("admin_session_token", token);
  }

  async function rpc(name, params) {
    const { data, error } = await supabase.rpc(name, params);
    if (error) {
      throw error;
    }
    return data;
  }

  function setButtonLoading(button, loading, loadingText) {
    if (!button) return;
    button.disabled = loading;
    if (loading) {
      button.dataset.originalText = button.textContent || "Submit";
      button.textContent = loadingText;
    } else if (button.dataset.originalText) {
      button.textContent = button.dataset.originalText;
      delete button.dataset.originalText;
    }
  }

  function validateEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  }

  const registerForm = document.getElementById("registerForm") || document.querySelector('form[action="register.php"]');
  if (registerForm) {
    registerForm.addEventListener("submit", async (event) => {
      event.preventDefault();

      const fullName = registerForm.querySelector('input[name="name"]')?.value?.trim() || "";
      const email = registerForm.querySelector('input[name="email"]')?.value?.trim() || "";
      const password = registerForm.querySelector('input[name="password"]')?.value || "";
      const confirmPassword = registerForm.querySelector('input[name="confirm_password"]')?.value || "";

      if (fullName.length < 2) {
        alert("Please enter your full name.");
        return;
      }

      if (!validateEmail(email)) {
        alert("Please enter a valid email address.");
        return;
      }

      if (password.length < 6) {
        alert("Password must be at least 6 characters.");
        return;
      }

      if (password !== confirmPassword) {
        alert("Password and confirm password do not match.");
        return;
      }

      const submitButton = registerForm.querySelector('button[type="submit"]');
      setButtonLoading(submitButton, true, "Creating account...");

      try {
        const response = await rpc("app_sign_up", {
          p_full_name: fullName,
          p_email: email,
          p_password: password
        });

        const token = response?.session_token;
        if (token) {
          setSessionToken(token);
        }

        alert("Account created successfully. You are now signed in.");
        window.location.href = "index.html";
      } catch (error) {
        alert(`Registration failed: ${error.message || "Unknown error"}`);
      } finally {
        setButtonLoading(submitButton, false, "");
      }
    });
  }

  const loginForm = document.getElementById("adminLoginForm") || document.querySelector('form[action="admin-login.php"]');
  if (loginForm) {
    loginForm.addEventListener("submit", async (event) => {
      event.preventDefault();

      const email = loginForm.querySelector('input[name="email"]')?.value?.trim() || "";
      const password = loginForm.querySelector('input[name="password"]')?.value || "";

      if (!validateEmail(email)) {
        alert("Please enter a valid email address.");
        return;
      }

      if (password.length < 6) {
        alert("Please enter your password.");
        return;
      }

      const submitButton = loginForm.querySelector('button[type="submit"]');
      setButtonLoading(submitButton, true, "Signing in...");

      try {
        const response = await rpc("app_sign_in", {
          p_email: email,
          p_password: password
        });

        const token = response?.session_token;
        const user = response?.user || {};
        const role = String(user.role || "").toLowerCase();

        if (!token) {
          throw new Error("Session token missing in login response.");
        }

        setSessionToken(token);

        if (role === "admin" || role === "mentor") {
          window.location.href = "../admin paneel/index.html";
          return;
        }

        window.location.href = "index.html";
      } catch (error) {
        alert(`Login failed: ${error.message || "Unknown error"}`);
      } finally {
        setButtonLoading(submitButton, false, "");
      }
    });
  }
})();
