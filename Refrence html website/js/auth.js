(() => {
  const cfg = window.WEBSITE_CONFIG || window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey || !window.supabase?.createClient) {
    return;
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

  const registerForm = document.getElementById("registerForm") || document.querySelector('form[action="register.php"]');
  if (registerForm) {
    registerForm.addEventListener("submit", async (event) => {
      event.preventDefault();

      const fullName = registerForm.querySelector('input[name="name"]')?.value?.trim() || "";
      const email = registerForm.querySelector('input[name="email"]')?.value?.trim() || "";
      const password = registerForm.querySelector('input[name="password"]')?.value || "";
      const confirmPassword = registerForm.querySelector('input[name="confirm_password"]')?.value || "";

      if (password !== confirmPassword) {
        alert("Password and confirm password do not match.");
        return;
      }

      const submitButton = registerForm.querySelector('button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = true;
      }

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

        alert("Registration successful. Your account is created on the same backend as the app.");
        window.location.href = "admin-login.html";
      } catch (error) {
        alert(`Registration failed: ${error.message || "Unknown error"}`);
      } finally {
        if (submitButton) {
          submitButton.disabled = false;
        }
      }
    });
  }

  const loginForm = document.getElementById("adminLoginForm") || document.querySelector('form[action="admin-login.php"]');
  if (loginForm) {
    loginForm.addEventListener("submit", async (event) => {
      event.preventDefault();

      const email = loginForm.querySelector('input[name="email"]')?.value?.trim() || "";
      const password = loginForm.querySelector('input[name="password"]')?.value || "";

      const submitButton = loginForm.querySelector('button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = true;
      }

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

        if (role !== "admin" && role !== "mentor") {
          throw new Error("This panel is only for admin or mentor accounts.");
        }

        setSessionToken(token);
        window.location.href = "../admin paneel/index.html";
      } catch (error) {
        alert(`Login failed: ${error.message || "Unknown error"}`);
      } finally {
        if (submitButton) {
          submitButton.disabled = false;
        }
      }
    });
  }
})();
