(() => {
  const cfg = window.WEBSITE_CONFIG || window.ADMIN_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey || !window.supabase?.createClient) {
    return;
  }

  const supabase = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);

  async function rpc(name, params = {}) {
    const { data, error } = await supabase.rpc(name, params);
    if (error) {
      throw error;
    }
    return data;
  }

  async function insert(table, payload) {
    const { error } = await supabase.from(table).insert(payload);
    if (error) {
      throw error;
    }
  }

  function withSubmitState(form, isLoading) {
    const button = form?.querySelector('button[type="submit"]');
    if (!button) {
      return;
    }
    button.disabled = isLoading;
    if (isLoading) {
      button.dataset.originalText = button.textContent || "Submit";
      button.textContent = "Please wait...";
    } else if (button.dataset.originalText) {
      button.textContent = button.dataset.originalText;
      delete button.dataset.originalText;
    }
  }

  function readValue(id) {
    return (document.getElementById(id)?.value || "").trim();
  }

  function bindContactForm() {
    const form = document.querySelector('form[data-form="contact"]') ||
      (document.getElementById("name") && document.getElementById("email") && document.getElementById("message")
        ? document.getElementById("message").closest("form")
        : null);

    if (!form || form.dataset.backendBound === "true") {
      return;
    }

    form.dataset.backendBound = "true";
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      withSubmitState(form, true);

      try {
        const subject = readValue("subject");
        const rawMessage = readValue("message");
        const message = subject ? `[${subject}] ${rawMessage}` : rawMessage;

        await insert("contact_messages", {
          full_name: readValue("name"),
          email: readValue("email"),
          phone: readValue("phone"),
          message
        });

        form.reset();
        alert("Thank you. Your message has been sent.");
      } catch (error) {
        alert(`Unable to send message: ${error.message || "Unknown error"}`);
      } finally {
        withSubmitState(form, false);
      }
    });
  }

  function normalizeAgeRange(age) {
    const parsed = Number(age);
    if (!Number.isFinite(parsed)) {
      return "";
    }
    if (parsed <= 2) return "0-2";
    if (parsed <= 5) return "3-5";
    if (parsed <= 8) return "6-8";
    return "9+";
  }

  function mapChildGender(gender) {
    const value = String(gender || "").toLowerCase();
    if (value === "boy") return "male";
    if (value === "girl") return "female";
    return "any";
  }

  function resolveImage(imageUrl) {
    const value = String(imageUrl || "").trim();
    if (!value) {
      return "img/cld1.jpg";
    }
    if (/^https?:\/\//i.test(value)) {
      return value;
    }
    const { data } = supabase.storage.from("children-photos").getPublicUrl(value);
    return data?.publicUrl || "img/cld1.jpg";
  }

  async function loadChildrenIntoAdoptCards() {
    const container = document.querySelector(".adopt-container");
    if (!container || !document.getElementById("adoptionForm")) {
      return;
    }

    try {
      const rows = await rpc("app_get_public_children");
      if (!Array.isArray(rows) || rows.length === 0) {
        return;
      }

      const cardsHtml = rows.slice(0, 12).map((child) => {
        const name = String(child.name || "Child");
        const age = Number(child.age || 0);
        const story = String(child.story || "");
        const shortStory = story.length > 90 ? `${story.slice(0, 87)}...` : story;
        return `
          <div class="adopt-card">
            <img src="${resolveImage(child.image_url)}" alt="${name}">
            <h3>${name}, ${age} Years</h3>
            <p>${shortStory}</p>
            <button class="adopt-btn" data-child-name="${name}" data-child-age="${age}" data-child-gender="${String(child.gender || "other")}">Adopt Now</button>
          </div>
        `;
      }).join("");

      container.innerHTML = cardsHtml;
    } catch (error) {
      console.error("Unable to load children", error);
    }
  }

  function bindAdoptButtons() {
    const adoptionFormRoot = document.getElementById("adoptionForm");
    if (!adoptionFormRoot) {
      return;
    }

    document.querySelectorAll(".adopt-btn").forEach((button) => {
      if (button.dataset.bound === "true") {
        return;
      }
      button.dataset.bound = "true";

      button.addEventListener("click", () => {
        const childName = button.dataset.childName || "this child";
        const childAge = button.dataset.childAge || "";
        const childGender = button.dataset.childGender || "other";

        sessionStorage.setItem("selectedChild", childName);

        if (childAge) {
          const ageRange = normalizeAgeRange(childAge);
          if (ageRange) {
            const childAgeInput = document.getElementById("childAge");
            if (childAgeInput) {
              childAgeInput.value = ageRange;
            }
          }
        }

        const childGenderInput = document.getElementById("childGender");
        if (childGenderInput) {
          childGenderInput.value = mapChildGender(childGender);
        }

        const heading = adoptionFormRoot.querySelector("h1");
        if (heading) {
          heading.textContent = `Adoption Application Form for ${childName}`;
        }

        adoptionFormRoot.scrollIntoView({ behavior: "smooth" });
      });
    });
  }

  function bindAdoptionForm() {
    const form = document.querySelector("#adoptionForm form");
    if (!form || form.dataset.backendBound === "true") {
      return;
    }

    form.dataset.backendBound = "true";
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      withSubmitState(form, true);

      try {
        const firstName = readValue("firstName");
        const lastName = readValue("lastName");
        const fullName = `${firstName} ${lastName}`.trim();
        const childrenCount = Number.parseInt(readValue("children"), 10);

        await insert("adoption_applications", {
          full_name: fullName,
          first_name: firstName,
          last_name: lastName,
          date_of_birth: readValue("dob") || null,
          marital_status: readValue("maritalStatus") || null,
          address_street: readValue("address"),
          city: readValue("city"),
          state: readValue("state"),
          zip_code: readValue("zipCode"),
          phone: readValue("phone"),
          email: readValue("email"),
          employer: readValue("employer"),
          occupation: readValue("occupation"),
          annual_income: readValue("annualIncome"),
          preferred_age_range: readValue("childAge") || null,
          preferred_gender: readValue("childGender") || null,
          number_of_family_members: Number.parseInt(readValue("familyMembers"), 10) || 0,
          number_of_children: Number.isFinite(childrenCount) ? childrenCount : 0,
          has_children: Number.isFinite(childrenCount) ? childrenCount > 0 : false,
          family_background: readValue("familyBackground"),
          residence_type: readValue("residenceType") || null,
          ownership_status: readValue("ownership") || null,
          health_insurance_provider: readValue("healthInsurance"),
          overall_health_status: readValue("healthStatus") || null,
          reference1_name: readValue("reference1Name"),
          reference1_phone: readValue("reference1Phone"),
          reference1_email: readValue("reference1Email"),
          consent_background_check: !!document.getElementById("backgroundCheck")?.checked,
          agree_home_visits: !!document.getElementById("homeVisit")?.checked,
          previous_adoption_experience: readValue("experience"),
          motivation_for_adoption: readValue("motivation"),
          reason: readValue("motivation")
        });

        form.reset();
        alert("Application submitted successfully. Our team will contact you soon.");
        window.scrollTo({ top: 0, behavior: "smooth" });
      } catch (error) {
        alert(`Unable to submit adoption application: ${error.message || "Unknown error"}`);
      } finally {
        withSubmitState(form, false);
      }
    });
  }

  function bindAppointmentForms() {
    const forms = Array.from(document.querySelectorAll("form")).filter((form) => {
      return form.querySelector("#gname") && form.querySelector("#gmail") && form.querySelector("#message");
    });

    forms.forEach((form) => {
      if (form.dataset.backendBound === "true") {
        return;
      }
      form.dataset.backendBound = "true";

      form.addEventListener("submit", async (event) => {
        event.preventDefault();
        withSubmitState(form, true);

        try {
          const guardianName = form.querySelector("#gname")?.value?.trim() || "";
          const guardianEmail = form.querySelector("#gmail")?.value?.trim() || "";
          const childName = form.querySelector("#cname")?.value?.trim() || "";
          const childAge = form.querySelector("#cage")?.value?.trim() || "";
          const phone = form.querySelector("#phone")?.value?.trim() || "";
          const address = form.querySelector("#address")?.value?.trim() || "";
          const note = form.querySelector("#message")?.value?.trim() || "";

          const messageParts = [
            "Appointment request from website.",
            childName ? `Child: ${childName}` : "",
            childAge ? `Child age: ${childAge}` : "",
            address ? `Address: ${address}` : "",
            note ? `Note: ${note}` : ""
          ].filter(Boolean);

          await insert("contact_messages", {
            full_name: guardianName,
            email: guardianEmail,
            phone,
            message: messageParts.join(" | ")
          });

          form.reset();
          alert("Appointment request submitted successfully.");
        } catch (error) {
          alert(`Unable to submit appointment: ${error.message || "Unknown error"}`);
        } finally {
          withSubmitState(form, false);
        }
      });
    });
  }

  async function init() {
    await loadChildrenIntoAdoptCards();
    bindAdoptButtons();
    bindAdoptionForm();
    bindContactForm();
    bindAppointmentForms();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
