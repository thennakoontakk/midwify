import {
    MidwifeData,
    getAllMidwives,
    registerMidwife,
    updateMidwife,
    deleteMidwife,
    getMidwife,
} from "../services/midwifeService";
import { showToast, openModal, closeModal } from "../main";

let midwives: MidwifeData[] = [];
let filteredMidwives: MidwifeData[] = [];
let searchTerm = "";

/**
 * Render the Midwives management page
 */
export function renderMidwives(): string {
    return `
    <div class="midwives-page">
      <!-- Header Section -->
      <div class="page-header">
        <div class="header-left">
          <h3>Midwives Management</h3>
          <p>Register and manage Public Health Midwives (PHMs)</p>
        </div>
        <button class="btn btn-primary" id="btn-add-midwife">
          <span class="material-icons-round">person_add</span>
          <span>Register Midwife</span>
        </button>
      </div>

      <!-- Search & Filter Bar -->
      <div class="filter-bar">
        <div class="search-box">
          <span class="material-icons-round">search</span>
          <input type="text" placeholder="Search by name, NIC, registration no..." id="midwife-search" />
        </div>
        <div class="filter-chips">
          <button class="chip active" data-filter="all">All</button>
          <button class="chip" data-filter="active">Active</button>
          <button class="chip" data-filter="inactive">Inactive</button>
        </div>
      </div>

      <!-- Midwives Table -->
      <div class="table-container">
        <div class="table-loading" id="table-loading">
          <div class="spinner"></div>
          <p>Loading midwives...</p>
        </div>
        <table class="data-table" id="midwives-table" style="display:none;">
          <thead>
            <tr>
              <th>Name</th>
              <th>Registration No.</th>
              <th>NIC</th>
              <th>Assigned Area</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody id="midwives-tbody">
          </tbody>
        </table>
        <div class="empty-state" id="empty-state" style="display:none;">
          <span class="material-icons-round">group_off</span>
          <h4>No midwives found</h4>
          <p>Click "Register Midwife" to add a new midwife.</p>
        </div>
      </div>
    </div>
  `;
}

/**
 * Initialize midwives page event listeners
 */
export function initMidwivesPage() {
    const addBtn = document.getElementById("btn-add-midwife");
    const searchInput = document.getElementById("midwife-search") as HTMLInputElement;
    const filterChips = document.querySelectorAll(".filter-chips .chip");

    addBtn?.addEventListener("click", () => openRegistrationModal());

    searchInput?.addEventListener("input", (e) => {
        searchTerm = (e.target as HTMLInputElement).value.toLowerCase();
        applyFilters();
    });

    filterChips.forEach((chip) => {
        chip.addEventListener("click", () => {
            filterChips.forEach((c) => c.classList.remove("active"));
            chip.classList.add("active");
            applyFilters();
        });
    });

    loadMidwives();
}

/**
 * Load all midwives from Firestore
 */
async function loadMidwives() {
    const loading = document.getElementById("table-loading");
    const table = document.getElementById("midwives-table");
    const empty = document.getElementById("empty-state");

    try {
        midwives = await getAllMidwives();
        filteredMidwives = [...midwives];

        if (loading) loading.style.display = "none";

        if (midwives.length === 0) {
            if (empty) empty.style.display = "flex";
            if (table) table.style.display = "none";
        } else {
            if (table) table.style.display = "table";
            if (empty) empty.style.display = "none";
            renderTable();
        }
    } catch (error) {
        console.error("Error loading midwives:", error);
        if (loading) loading.style.display = "none";
        showToast("Failed to load midwives", "error");
    }
}

/**
 * Apply search and filter
 */
function applyFilters() {
    const activeFilter = document.querySelector(".filter-chips .chip.active")?.getAttribute("data-filter") || "all";

    filteredMidwives = midwives.filter((m) => {
        const matchesSearch =
            !searchTerm ||
            m.fullName.toLowerCase().includes(searchTerm) ||
            m.nicNumber.toLowerCase().includes(searchTerm) ||
            m.registrationNumber.toLowerCase().includes(searchTerm) ||
            m.assignedArea.toLowerCase().includes(searchTerm) ||
            m.email.toLowerCase().includes(searchTerm);

        const matchesFilter = activeFilter === "all" || m.status === activeFilter;

        return matchesSearch && matchesFilter;
    });

    const table = document.getElementById("midwives-table");
    const empty = document.getElementById("empty-state");

    if (filteredMidwives.length === 0) {
        if (table) table.style.display = "none";
        if (empty) empty.style.display = "flex";
    } else {
        if (table) table.style.display = "table";
        if (empty) empty.style.display = "none";
    }

    renderTable();
}

/**
 * Render the table body
 */
function renderTable() {
    const tbody = document.getElementById("midwives-tbody");
    if (!tbody) return;

    tbody.innerHTML = filteredMidwives
        .map(
            (m) => `
    <tr>
      <td>
        <div class="cell-name">
          <div class="avatar-sm">${m.fullName.charAt(0).toUpperCase()}</div>
          <div>
            <strong>${m.fullName}</strong>
            <span class="cell-email">${m.email}</span>
          </div>
        </div>
      </td>
      <td><span class="mono">${m.registrationNumber}</span></td>
      <td><span class="mono">${m.nicNumber}</span></td>
      <td>${m.assignedArea}</td>
      <td>
        <span class="badge badge-${m.status}">${m.status}</span>
      </td>
      <td>
        <div class="action-btns">
          <button class="btn-icon" title="View" onclick="window.__viewMidwife('${m.uid}')">
            <span class="material-icons-round">visibility</span>
          </button>
          <button class="btn-icon" title="Edit" onclick="window.__editMidwife('${m.uid}')">
            <span class="material-icons-round">edit</span>
          </button>
          <button class="btn-icon btn-danger" title="Delete" onclick="window.__deleteMidwife('${m.uid}', '${m.fullName.replace(/'/g, "\\'")}')">
            <span class="material-icons-round">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `
        )
        .join("");
}

/**
 * Registration form modal
 */
function getFormHTML(data?: MidwifeData, isEdit = false): string {
    return `
    <form id="midwife-form" class="midwife-form">
      <div class="form-grid">
        <div class="form-group full-width">
          <label>Full Name (with initials)</label>
          <input type="text" name="fullName" placeholder="e.g. H.M. Kumari Perera" value="${data?.fullName || ""}" required />
        </div>
        <div class="form-group">
          <label>NIC Number</label>
          <input type="text" name="nicNumber" placeholder="e.g. 199512345678" value="${data?.nicNumber || ""}" required />
        </div>
        <div class="form-group">
          <label>Registration Number (CMCC/SLMC)</label>
          <input type="text" name="registrationNumber" placeholder="e.g. MW/2024/001" value="${data?.registrationNumber || ""}" required />
        </div>
        <div class="form-group">
          <label>Email Address</label>
          <input type="email" name="email" placeholder="e.g. kumari@example.com" value="${data?.email || ""}" ${isEdit ? "disabled" : "required"} />
        </div>
        ${!isEdit
            ? `<div class="form-group">
          <label>Password</label>
          <input type="password" name="password" placeholder="Min. 6 characters" minlength="6" required />
        </div>`
            : ""
        }
        <div class="form-group">
          <label>Phone Number</label>
          <input type="tel" name="phone" placeholder="e.g. 071-1234567" value="${data?.phone || ""}" required />
        </div>
        <div class="form-group">
          <label>Date of Birth</label>
          <input type="date" name="dateOfBirth" value="${data?.dateOfBirth || ""}" required />
        </div>
        <div class="form-group">
          <label>Assigned MOH Area</label>
          <input type="text" name="assignedArea" placeholder="e.g. Kaduwela MOH Area" value="${data?.assignedArea || ""}" required />
        </div>
        <div class="form-group">
          <label>Qualification</label>
          <input type="text" name="qualification" placeholder="e.g. Diploma in Midwifery" value="${data?.qualification || ""}" required />
        </div>
        <div class="form-group">
          <label>Status</label>
          <select name="status">
            <option value="active" ${data?.status === "active" || !data ? "selected" : ""}>Active</option>
            <option value="inactive" ${data?.status === "inactive" ? "selected" : ""}>Inactive</option>
          </select>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" class="btn btn-secondary" onclick="document.getElementById('modal-close').click()">Cancel</button>
        <button type="submit" class="btn btn-primary">
          <span class="material-icons-round">${isEdit ? "save" : "person_add"}</span>
          <span>${isEdit ? "Update Midwife" : "Register Midwife"}</span>
        </button>
      </div>
    </form>
  `;
}

/**
 * Open registration modal
 */
function openRegistrationModal() {
    openModal("Register New Midwife", getFormHTML());

    const form = document.getElementById("midwife-form") as HTMLFormElement;
    form?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const formData = new FormData(form);
        const submitBtn = form.querySelector('button[type="submit"]') as HTMLButtonElement;

        const data: MidwifeData = {
            fullName: formData.get("fullName") as string,
            nicNumber: formData.get("nicNumber") as string,
            email: formData.get("email") as string,
            phone: formData.get("phone") as string,
            registrationNumber: formData.get("registrationNumber") as string,
            dateOfBirth: formData.get("dateOfBirth") as string,
            assignedArea: formData.get("assignedArea") as string,
            qualification: formData.get("qualification") as string,
            status: formData.get("status") as "active" | "inactive",
        };

        const password = formData.get("password") as string;

        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<div class="spinner-sm"></div> Registering...';

            await registerMidwife(data, password);
            showToast(`${data.fullName} registered successfully!`, "success");
            closeModal();
            loadMidwives();
        } catch (error: any) {
            console.error("Registration error:", error);
            let message = "Failed to register midwife";
            if (error.code === "auth/email-already-in-use") {
                message = "This email is already registered";
            } else if (error.code === "auth/weak-password") {
                message = "Password must be at least 6 characters";
            } else if (error.code === "auth/invalid-email") {
                message = "Invalid email address";
            }
            showToast(message, "error");
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<span class="material-icons-round">person_add</span><span>Register Midwife</span>';
        }
    });
}

/**
 * View midwife details
 */
(window as any).__viewMidwife = async (uid: string) => {
    const m = midwives.find((mw) => mw.uid === uid);
    if (!m) return;

    const createdDate = m.createdAt?.toDate?.()
        ? m.createdAt.toDate().toLocaleDateString()
        : "N/A";

    openModal(
        "Midwife Details",
        `
    <div class="detail-view">
      <div class="detail-header">
        <div class="avatar-lg">${m.fullName.charAt(0).toUpperCase()}</div>
        <div>
          <h3>${m.fullName}</h3>
          <span class="badge badge-${m.status}">${m.status}</span>
        </div>
      </div>
      <div class="detail-grid">
        <div class="detail-item">
          <label>Email</label>
          <span>${m.email}</span>
        </div>
        <div class="detail-item">
          <label>Phone</label>
          <span>${m.phone}</span>
        </div>
        <div class="detail-item">
          <label>NIC Number</label>
          <span>${m.nicNumber}</span>
        </div>
        <div class="detail-item">
          <label>Registration No.</label>
          <span>${m.registrationNumber}</span>
        </div>
        <div class="detail-item">
          <label>Date of Birth</label>
          <span>${m.dateOfBirth}</span>
        </div>
        <div class="detail-item">
          <label>Assigned MOH Area</label>
          <span>${m.assignedArea}</span>
        </div>
        <div class="detail-item">
          <label>Qualification</label>
          <span>${m.qualification}</span>
        </div>
        <div class="detail-item">
          <label>Registered On</label>
          <span>${createdDate}</span>
        </div>
      </div>
    </div>
  `
    );
};

/**
 * Edit midwife
 */
(window as any).__editMidwife = async (uid: string) => {
    const m = midwives.find((mw) => mw.uid === uid);
    if (!m) return;

    openModal("Edit Midwife", getFormHTML(m, true));

    const form = document.getElementById("midwife-form") as HTMLFormElement;
    form?.addEventListener("submit", async (e) => {
        e.preventDefault();
        const formData = new FormData(form);
        const submitBtn = form.querySelector('button[type="submit"]') as HTMLButtonElement;

        const data: Partial<MidwifeData> = {
            fullName: formData.get("fullName") as string,
            nicNumber: formData.get("nicNumber") as string,
            phone: formData.get("phone") as string,
            registrationNumber: formData.get("registrationNumber") as string,
            dateOfBirth: formData.get("dateOfBirth") as string,
            assignedArea: formData.get("assignedArea") as string,
            qualification: formData.get("qualification") as string,
            status: formData.get("status") as "active" | "inactive",
        };

        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<div class="spinner-sm"></div> Updating...';

            await updateMidwife(uid, data);
            showToast(`${data.fullName} updated successfully!`, "success");
            closeModal();
            loadMidwives();
        } catch (error) {
            console.error("Update error:", error);
            showToast("Failed to update midwife", "error");
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<span class="material-icons-round">save</span><span>Update Midwife</span>';
        }
    });
};

/**
 * Delete midwife
 */
(window as any).__deleteMidwife = async (uid: string, name: string) => {
    openModal(
        "Confirm Delete",
        `
    <div class="confirm-dialog">
      <div class="confirm-icon">
        <span class="material-icons-round">warning</span>
      </div>
      <p>Are you sure you want to delete <strong>${name}</strong>?</p>
      <p class="text-muted">This will remove the midwife from the system. The Firebase Auth account will remain but can be removed from Firebase Console.</p>
      <div class="form-actions">
        <button class="btn btn-secondary" onclick="document.getElementById('modal-close').click()">Cancel</button>
        <button class="btn btn-danger-fill" id="confirm-delete-btn">
          <span class="material-icons-round">delete</span>
          <span>Delete</span>
        </button>
      </div>
    </div>
  `
    );

    document.getElementById("confirm-delete-btn")?.addEventListener("click", async () => {
        const btn = document.getElementById("confirm-delete-btn") as HTMLButtonElement;
        try {
            btn.disabled = true;
            btn.innerHTML = '<div class="spinner-sm"></div> Deleting...';

            await deleteMidwife(uid);
            showToast(`${name} deleted successfully`, "success");
            closeModal();
            loadMidwives();
        } catch (error) {
            console.error("Delete error:", error);
            showToast("Failed to delete midwife", "error");
            btn.disabled = false;
            btn.innerHTML = '<span class="material-icons-round">delete</span><span>Delete</span>';
        }
    });
};
