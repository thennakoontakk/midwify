import "./style.css";
import { renderDashboard, initDashboard } from "./pages/dashboard";
import { renderMidwives, initMidwivesPage } from "./pages/midwives";

// Router state
let currentPage = "dashboard";

/**
 * Navigate to a page
 */
function navigateTo(page: string) {
  currentPage = page;
  const container = document.getElementById("page-container");
  const pageTitle = document.getElementById("page-title");

  // Update nav active state
  document.querySelectorAll(".nav-item").forEach((item) => {
    item.classList.toggle("active", item.getAttribute("data-page") === page);
  });

  if (!container) return;

  switch (page) {
    case "dashboard":
      container.innerHTML = renderDashboard();
      if (pageTitle) pageTitle.textContent = "Dashboard";
      initDashboard();
      break;
    case "midwives":
      container.innerHTML = renderMidwives();
      if (pageTitle) pageTitle.textContent = "Midwives";
      initMidwivesPage();
      break;
    default:
      container.innerHTML = renderDashboard();
      if (pageTitle) pageTitle.textContent = "Dashboard";
      initDashboard();
  }

  // Close mobile sidebar
  document.getElementById("sidebar")?.classList.remove("open");
}

/**
 * Show toast notification
 */
export function showToast(
  message: string,
  type: "success" | "error" | "info" = "info"
) {
  const container = document.getElementById("toast-container");
  if (!container) return;

  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;

  const icons: Record<string, string> = {
    success: "check_circle",
    error: "error",
    info: "info",
  };

  toast.innerHTML = `
    <span class="material-icons-round">${icons[type]}</span>
    <span>${message}</span>
  `;

  container.appendChild(toast);

  // Animate in
  requestAnimationFrame(() => toast.classList.add("show"));

  // Auto remove
  setTimeout(() => {
    toast.classList.remove("show");
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

/**
 * Open modal
 */
export function openModal(title: string, bodyHTML: string) {
  const overlay = document.getElementById("modal-overlay");
  const modalTitle = document.getElementById("modal-title");
  const modalBody = document.getElementById("modal-body");

  if (modalTitle) modalTitle.textContent = title;
  if (modalBody) modalBody.innerHTML = bodyHTML;
  overlay?.classList.add("active");
  document.body.style.overflow = "hidden";
}

/**
 * Close modal
 */
export function closeModal() {
  const overlay = document.getElementById("modal-overlay");
  overlay?.classList.remove("active");
  document.body.style.overflow = "";
}

/**
 * Initialize app
 */
function init() {
  // Navigation
  document.querySelectorAll(".nav-item").forEach((item) => {
    item.addEventListener("click", (e) => {
      e.preventDefault();
      const page = item.getAttribute("data-page");
      if (page) navigateTo(page);
    });
  });

  // Hash routing
  function handleHash() {
    const hash = window.location.hash.replace("#", "") || "dashboard";
    navigateTo(hash);
  }
  window.addEventListener("hashchange", handleHash);

  // Mobile menu toggle
  document.getElementById("menu-toggle")?.addEventListener("click", () => {
    document.getElementById("sidebar")?.classList.toggle("open");
  });

  // Modal close
  document.getElementById("modal-close")?.addEventListener("click", closeModal);
  document.getElementById("modal-overlay")?.addEventListener("click", (e) => {
    if ((e.target as HTMLElement).id === "modal-overlay") closeModal();
  });

  // Escape key closes modal
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeModal();
  });

  // Initial page
  handleHash();
}

// Boot — ES modules are deferred, DOM is ready by now
init();
