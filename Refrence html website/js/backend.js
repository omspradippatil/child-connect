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

  function bindMentorForm() {
    const form = document.getElementById("mentorApplyForm");
    if (!form || form.dataset.backendBound === "true") {
      return;
    }

    form.dataset.backendBound = "true";
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      withSubmitState(form, true);

      try {
        const fullName = (form.querySelector('input[name="full_name"]')?.value || "").trim();
        const email = (form.querySelector('input[name="email"]')?.value || "").trim();
        const phone = (form.querySelector('input[name="phone"]')?.value || "").trim();
        const skills = (form.querySelector('input[name="skills"]')?.value || "").trim();
        const availability = (form.querySelector('select[name="availability"]')?.value || "").trim();
        const motivation = (form.querySelector('textarea[name="motivation"]')?.value || "").trim();

        await insert("mentor_applications", {
          full_name: fullName,
          email,
          phone,
          skills,
          availability,
          motivation
        });

        form.reset();
        alert("Mentor application submitted successfully.");
      } catch (error) {
        alert(`Unable to submit mentor application: ${error.message || "Unknown error"}`);
      } finally {
        withSubmitState(form, false);
      }
    });
  }

  async function loadProgramsGrid() {
    const grid = document.getElementById("programsGrid");
    if (!grid) {
      return;
    }

    const iconMap = {
      palette: "fa-palette",
      sports: "fa-running",
      people: "fa-users",
      book: "fa-book-open",
      run: "fa-heartbeat",
      music: "fa-music",
      school: "fa-school"
    };

    try {
      const rows = await rpc("app_get_public_programs");
      if (!Array.isArray(rows) || rows.length === 0) {
        return;
      }

      grid.innerHTML = rows.map((program) => {
        const title = String(program.title || "Program");
        const description = String(program.description || "");
        const iconKey = String(program.icon_key || "school").toLowerCase();
        const iconClass = iconMap[iconKey] || "fa-school";
        const color = String(program.color_hex || "#4FA8D5");

        return `
          <div class="col-lg-4 col-md-6 wow fadeInUp" data-wow-delay="0.1s">
            <div class="classes-item">
              <div class="bg-light rounded-circle w-75 mx-auto p-3 d-flex align-items-center justify-content-center" style="min-height: 190px;">
                <i class="fas ${iconClass} fa-3x" style="color: ${color};"></i>
              </div>
              <div class="bg-light rounded p-4 pt-5 mt-n5">
                <a class="d-block text-center h3 mt-3 mb-4">${title}</a>
                <p class="text-center mb-4">${description}</p>
              </div>
            </div>
          </div>
        `;
      }).join("");
    } catch (error) {
      console.error("Unable to load programs", error);
    }
  }

  function formatDate(dateLike) {
    const date = new Date(dateLike || "");
    if (Number.isNaN(date.getTime())) {
      return "";
    }
    return date.toLocaleDateString();
  }

  async function loadParentFeedbackGrid() {
    const grid = document.getElementById("feedbackGrid");
    if (!grid) {
      return;
    }

    try {
      const token = localStorage.getItem("website_session_token") || "";
      const rows = await rpc("app_get_parent_feedback", { p_session_token: token });
      if (!Array.isArray(rows) || rows.length === 0) {
        return;
      }

      grid.innerHTML = rows.slice(0, 6).map((item) => {
        const parentNames = String(item.parent_names || "Parent");
        const storyTitle = String(item.story_title || "Family Story");
        const storyBody = String(item.story_body || "");
        const childName = String(item.child_name || "");
        const summary = storyBody.length > 170 ? `${storyBody.slice(0, 167)}...` : storyBody;
        const createdAt = formatDate(item.created_at);

        return `
          <div class="col-lg-4 col-md-6 wow fadeInUp" data-wow-delay="0.1s">
            <div class="team-item position-relative">
              <div class="team-text" style="position: static; opacity: 1; transform: none; padding: 24px; min-height: 280px;">
                <h3>${parentNames}</h3>
                <p><strong>${storyTitle}</strong></p>
                <p>${summary}</p>
                <p style="font-size: 13px; margin-bottom: 0;">${childName ? `Child: ${childName} | ` : ""}${createdAt}</p>
              </div>
            </div>
          </div>
        `;
      }).join("");
    } catch (error) {
      console.error("Unable to load parent feedback", error);
    }
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
    const form = document.querySelector('form[data-form="adoption-application"]') || document.querySelector("#adoptionForm form");
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
    const markedForms = Array.from(document.querySelectorAll('form[data-form="appointment"]'));
    const forms = markedForms.length > 0
      ? markedForms
      : Array.from(document.querySelectorAll("form")).filter((form) => {
      return form.querySelector("#gname") && form.querySelector("#gmail") && form.querySelector("#message") && !form.querySelector("#reason");
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

  function bindAdoptionInquiryForms() {
    const markedForms = Array.from(document.querySelectorAll('form[data-form="adoption-inquiry"]'));
    const forms = markedForms.length > 0
      ? markedForms
      : Array.from(document.querySelectorAll("form")).filter((form) => {
      return form.querySelector("#gname") && form.querySelector("#gmail") && form.querySelector("#reason");
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
          const fullName = form.querySelector("#gname")?.value?.trim() || "";
          const email = form.querySelector("#gmail")?.value?.trim() || "";
          const preferredChildName = form.querySelector("#cname")?.value?.trim() || "";
          const preferredAge = form.querySelector("#cage")?.value?.trim() || "";
          const reason = form.querySelector("#reason")?.value?.trim() || "";
          const extraMessage = form.querySelector("#message")?.value?.trim() || "";
          const agreed = !!form.querySelector("#agree")?.checked;

          if (!agreed) {
            throw new Error("Please agree to the adoption guidelines and terms.");
          }

          const combinedReason = [reason, extraMessage].filter(Boolean).join(". ");
          if (combinedReason.length < 20) {
            throw new Error("Please provide a more detailed reason (at least 20 characters).");
          }

          await insert("adoption_applications", {
            full_name: fullName,
            email,
            preferred_age_range: preferredAge || null,
            preferred_gender: "any",
            reason: combinedReason,
            motivation_for_adoption: combinedReason,
            family_background: preferredChildName ? `Preferred child: ${preferredChildName}` : null
          });

          form.reset();
          alert("Adoption inquiry submitted successfully.");
        } catch (error) {
          alert(`Unable to submit adoption inquiry: ${error.message || "Unknown error"}`);
        } finally {
          withSubmitState(form, false);
        }
      });
    });
  }

  async function init() {
    await loadChildrenIntoAdoptCards();
    await loadProgramsGrid();
    await loadParentFeedbackGrid();
    bindAdoptButtons();
    bindAdoptionForm();
    bindContactForm();
    bindMentorForm();
    bindAdoptionInquiryForms();
    bindAppointmentForms();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
