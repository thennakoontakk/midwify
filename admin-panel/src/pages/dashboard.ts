/**
 * Dashboard page — blank placeholder for now
 */
export function renderDashboard(): string {
    return `
    <div class="dashboard-page">
      <div class="welcome-card">
        <div class="welcome-icon">
          <span class="material-icons-round">waving_hand</span>
        </div>
        <h2>Welcome to Midwify Admin</h2>
        <p>Manage your Public Health Midwives from here. Use the sidebar to navigate.</p>
        <div class="stats-hint">
          <div class="hint-card">
            <span class="material-icons-round">group</span>
            <span>Go to <strong>Midwives</strong> to manage records</span>
          </div>
        </div>
      </div>
    </div>
  `;
}
