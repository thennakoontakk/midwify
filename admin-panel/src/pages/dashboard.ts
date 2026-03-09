/**
 * Dashboard page — Analytics dashboard with Chart.js charts
 * Pulls live data from Firestore midwives + patients collections
 */
import { db, authReady } from "../firebase";
import { collection, getDocs, query, orderBy, limit } from "firebase/firestore";
import {
  Chart,
  BarController,
  BarElement,
  LineController,
  LineElement,
  PointElement,
  DoughnutController,
  PieController,
  ArcElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";

// Register Chart.js components
Chart.register(
  BarController,
  BarElement,
  LineController,
  LineElement,
  PointElement,
  DoughnutController,
  PieController,
  ArcElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend,
  Filler
);

// ── Chart color palette (matches dark theme) ────────────────────────
const COLORS = {
  primary: "#E91E7B",
  primaryLight: "#FF4081",
  success: "#34d399",
  warning: "#fbbf24",
  error: "#f87171",
  info: "#60a5fa",
  purple: "#a78bfa",
  teal: "#2dd4bf",
  orange: "#fb923c",
  lime: "#a3e635",
  rose: "#fb7185",
  sky: "#38bdf8",
  indigo: "#818cf8",
  emerald: "#6ee7b7",
  amber: "#fcd34d",
  cyan: "#22d3ee",
};

const CHART_PALETTE = [
  COLORS.primary,
  COLORS.info,
  COLORS.success,
  COLORS.warning,
  COLORS.purple,
  COLORS.teal,
  COLORS.orange,
  COLORS.rose,
  COLORS.sky,
  COLORS.lime,
  COLORS.indigo,
  COLORS.emerald,
  COLORS.amber,
  COLORS.cyan,
  COLORS.primaryLight,
  COLORS.error,
];

// ── Global Chart.js defaults for dark theme ─────────────────────────
Chart.defaults.color = "#9595a8";
Chart.defaults.borderColor = "rgba(255, 255, 255, 0.06)";
Chart.defaults.font.family = "'Inter', sans-serif";
Chart.defaults.font.size = 11;
Chart.defaults.plugins.legend.labels.usePointStyle = true;
Chart.defaults.plugins.legend.labels.pointStyle = "circle";
Chart.defaults.plugins.legend.labels.padding = 16;

// ── Interfaces ──────────────────────────────────────────────────────
interface MidwifeDoc {
  uid?: string;
  fullName: string;
  assignedArea: string;
  qualification: string;
  status: string;
}

interface PatientDoc {
  fullName: string;
  age: number;
  riskLevel: string;
  gestationalWeeks: number;
  status: string;
  midwifeId: string;
  bloodGroup: string;
  diabetesStatus: string;
  createdAt?: any;
}

// ── Helper: extract district from assignedArea ──────────────────────
function getDistrict(area: string): string {
  if (!area) return "Unknown";
  return area.split(" - ")[0].split(",")[0].trim();
}

// ── Render HTML skeleton ────────────────────────────────────────────
export function renderDashboard(): string {
  return `
    <div class="dashboard-analytics" id="dashboard-analytics">
      <!-- Stat Cards -->
      <div class="dash-stats">
        <div class="stat-card" id="stat-midwives">
          <div class="stat-icon stat-icon-primary">
            <span class="material-icons-round">group</span>
          </div>
          <div class="stat-info">
            <span class="stat-value"><span class="spinner-sm"></span></span>
            <span class="stat-label">Total Midwives</span>
          </div>
        </div>
        <div class="stat-card" id="stat-patients">
          <div class="stat-icon stat-icon-info">
            <span class="material-icons-round">pregnant_woman</span>
          </div>
          <div class="stat-info">
            <span class="stat-value"><span class="spinner-sm"></span></span>
            <span class="stat-label">Total Patients</span>
          </div>
        </div>
        <div class="stat-card" id="stat-high-risk">
          <div class="stat-icon stat-icon-danger">
            <span class="material-icons-round">warning</span>
          </div>
          <div class="stat-info">
            <span class="stat-value"><span class="spinner-sm"></span></span>
            <span class="stat-label">High-Risk Patients</span>
          </div>
        </div>
        <div class="stat-card" id="stat-active">
          <div class="stat-icon stat-icon-success">
            <span class="material-icons-round">check_circle</span>
          </div>
          <div class="stat-info">
            <span class="stat-value"><span class="spinner-sm"></span></span>
            <span class="stat-label">Active Patients</span>
          </div>
        </div>
      </div>

      <!-- Charts Row 1 -->
      <div class="charts-grid">
        <div class="chart-card">
          <div class="chart-header">
            <h4>Midwives by District</h4>
            <span class="chart-badge">Distribution</span>
          </div>
          <div class="chart-body">
            <canvas id="chart-midwives-district"></canvas>
          </div>
        </div>
        <div class="chart-card">
          <div class="chart-header">
            <h4>Patients by District</h4>
            <span class="chart-badge">Distribution</span>
          </div>
          <div class="chart-body">
            <canvas id="chart-patients-district"></canvas>
          </div>
        </div>
      </div>

      <!-- Charts Row 2 -->
      <div class="charts-grid">
        <div class="chart-card">
          <div class="chart-header">
            <h4>Patient Risk Levels</h4>
            <span class="chart-badge">Risk Analysis</span>
          </div>
          <div class="chart-body chart-body-doughnut">
            <canvas id="chart-risk-levels"></canvas>
          </div>
        </div>
        <div class="chart-card">
          <div class="chart-header">
            <h4>Gestational Weeks Distribution</h4>
            <span class="chart-badge">Trimester Breakdown</span>
          </div>
          <div class="chart-body">
            <canvas id="chart-gestational"></canvas>
          </div>
        </div>
      </div>

      <!-- Charts Row 3 -->
      <div class="charts-grid">
        <div class="chart-card">
          <div class="chart-header">
            <h4>Midwife Qualifications</h4>
            <span class="chart-badge">Education</span>
          </div>
          <div class="chart-body chart-body-doughnut">
            <canvas id="chart-qualifications"></canvas>
          </div>
        </div>
        <div class="chart-card">
          <div class="chart-header">
            <h4>Patients Added Over Time</h4>
            <span class="chart-badge">Trend</span>
          </div>
          <div class="chart-body">
            <canvas id="chart-patients-timeline"></canvas>
          </div>
        </div>
      </div>

      <!-- Recent Patients -->
      <div class="chart-card recent-card">
        <div class="chart-header">
          <h4>Recent Patients</h4>
          <span class="chart-badge">Latest Additions</span>
        </div>
        <div class="recent-table-wrap">
          <table class="data-table" id="recent-patients-table">
            <thead>
              <tr>
                <th>Patient</th>
                <th>Risk Level</th>
                <th>Gestational Weeks</th>
                <th>Blood Group</th>
                <th>Assigned Midwife</th>
              </tr>
            </thead>
            <tbody id="recent-patients-body">
              <tr><td colspan="5" class="table-loading"><div class="spinner"></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `;
}

// ── Chart instances (so we can destroy on re-render) ────────────────
let chartInstances: Chart[] = [];

function destroyCharts() {
  chartInstances.forEach((c) => c.destroy());
  chartInstances = [];
}

// ── Initialize dashboard with live data ─────────────────────────────
export async function initDashboard() {
  destroyCharts();

  try {
    // Wait for anonymous auth to complete
    await authReady;

    // Fetch data
    const [midwivesSnap, patientsSnap] = await Promise.all([
      getDocs(collection(db, "midwives")),
      getDocs(collection(db, "patients")),
    ]);

    const midwives: MidwifeDoc[] = midwivesSnap.docs.map(
      (d) => d.data() as MidwifeDoc
    );
    const patients: PatientDoc[] = patientsSnap.docs.map(
      (d) => d.data() as PatientDoc
    );

    // Create a lookup: midwifeId → midwife
    const midwifeMap = new Map<string, MidwifeDoc>();
    midwivesSnap.docs.forEach((d) => {
      midwifeMap.set(d.id, d.data() as MidwifeDoc);
    });

    // ── Update stat cards ───────────────────────────────────────────
    updateStat("stat-midwives", midwives.length);
    updateStat("stat-patients", patients.length);
    updateStat(
      "stat-high-risk",
      patients.filter((p) => p.riskLevel === "high").length
    );
    updateStat(
      "stat-active",
      patients.filter((p) => p.status === "active").length
    );

    // ── 1. Midwives by District (Bar) ───────────────────────────────
    const midwifeDistricts = countBy(midwives, (m) => getDistrict(m.assignedArea));
    createBarChart("chart-midwives-district", midwifeDistricts, "Midwives");

    // ── 2. Patients by District (Bar) ───────────────────────────────
    const patientDistricts = countBy(patients, (p) => {
      const mw = midwifeMap.get(p.midwifeId);
      return mw ? getDistrict(mw.assignedArea) : "Unknown";
    });
    createBarChart("chart-patients-district", patientDistricts, "Patients");

    // ── 3. Risk Levels (Doughnut) ───────────────────────────────────
    const riskCounts = countBy(patients, (p) => capitalize(p.riskLevel || "unknown"));
    createDoughnutChart("chart-risk-levels", riskCounts, [
      COLORS.success,
      COLORS.warning,
      COLORS.error,
      COLORS.info,
    ]);

    // ── 4. Gestational Weeks (Bar histogram) ────────────────────────
    const trimesterData = {
      "1st Trimester (1-12w)": patients.filter(
        (p) => p.gestationalWeeks >= 1 && p.gestationalWeeks <= 12
      ).length,
      "2nd Trimester (13-26w)": patients.filter(
        (p) => p.gestationalWeeks >= 13 && p.gestationalWeeks <= 26
      ).length,
      "3rd Trimester (27-40w)": patients.filter(
        (p) => p.gestationalWeeks >= 27 && p.gestationalWeeks <= 40
      ).length,
    };
    createBarChart("chart-gestational", trimesterData, "Patients", [
      COLORS.info,
      COLORS.purple,
      COLORS.primary,
    ]);

    // ── 5. Midwife Qualifications (Pie) ─────────────────────────────
    const qualCounts = countBy(midwives, (m) => m.qualification || "Unknown");
    createPieChart("chart-qualifications", qualCounts);

    // ── 6. Patients Over Time (Line) ────────────────────────────────
    const timeline = buildTimeline(patients);
    createLineChart("chart-patients-timeline", timeline);

    // ── Recent Patients Table ───────────────────────────────────────
    renderRecentPatients(patients, midwifeMap);
  } catch (err) {
    console.error("Dashboard init error:", err);
  }
}

// ── Utilities ───────────────────────────────────────────────────────
function updateStat(id: string, value: number) {
  const el = document.querySelector(`#${id} .stat-value`);
  if (el) el.textContent = String(value);
}

function countBy<T>(arr: T[], keyFn: (item: T) => string): Record<string, number> {
  const counts: Record<string, number> = {};
  arr.forEach((item) => {
    const key = keyFn(item);
    counts[key] = (counts[key] || 0) + 1;
  });
  return counts;
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function buildTimeline(patients: PatientDoc[]): Record<string, number> {
  const months: Record<string, number> = {};
  const monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  patients.forEach((p) => {
    if (p.createdAt && p.createdAt.toDate) {
      const d = p.createdAt.toDate();
      const key = `${monthNames[d.getMonth()]} ${d.getFullYear()}`;
      months[key] = (months[key] || 0) + 1;
    }
  });

  // Sort by date
  const sorted = Object.entries(months).sort((a, b) => {
    const [mA, yA] = a[0].split(" ");
    const [mB, yB] = b[0].split(" ");
    const dateA = new Date(`${mA} 1, ${yA}`);
    const dateB = new Date(`${mB} 1, ${yB}`);
    return dateA.getTime() - dateB.getTime();
  });

  const result: Record<string, number> = {};
  sorted.forEach(([k, v]) => (result[k] = v));
  return result;
}

// ── Chart Factories ─────────────────────────────────────────────────
function createBarChart(
  canvasId: string,
  data: Record<string, number>,
  label: string,
  colors?: string[]
) {
  const canvas = document.getElementById(canvasId) as HTMLCanvasElement;
  if (!canvas) return;

  const labels = Object.keys(data);
  const values = Object.values(data);
  const bgColors = colors || labels.map((_, i) => CHART_PALETTE[i % CHART_PALETTE.length]);

  const chart = new Chart(canvas, {
    type: "bar",
    data: {
      labels,
      datasets: [
        {
          label,
          data: values,
          backgroundColor: bgColors.map((c) => c + "cc"),
          borderColor: bgColors,
          borderWidth: 1,
          borderRadius: 6,
          borderSkipped: false,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: "#1c1c28",
          titleColor: "#f0f0f5",
          bodyColor: "#9595a8",
          borderColor: "rgba(255,255,255,0.1)",
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: { stepSize: 1 },
          grid: { color: "rgba(255,255,255,0.04)" },
        },
        x: {
          grid: { display: false },
          ticks: { maxRotation: 45, minRotation: 0 },
        },
      },
    },
  });
  chartInstances.push(chart);
}

function createDoughnutChart(
  canvasId: string,
  data: Record<string, number>,
  colors?: string[]
) {
  const canvas = document.getElementById(canvasId) as HTMLCanvasElement;
  if (!canvas) return;

  const labels = Object.keys(data);
  const values = Object.values(data);
  const bgColors = colors || labels.map((_, i) => CHART_PALETTE[i % CHART_PALETTE.length]);

  const chart = new Chart(canvas, {
    type: "doughnut",
    data: {
      labels,
      datasets: [
        {
          data: values,
          backgroundColor: bgColors.map((c) => c + "cc"),
          borderColor: "#16161f",
          borderWidth: 3,
          hoverOffset: 8,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: "62%",
      plugins: {
        legend: {
          position: "bottom",
          labels: { padding: 16, font: { size: 11 } },
        },
        tooltip: {
          backgroundColor: "#1c1c28",
          titleColor: "#f0f0f5",
          bodyColor: "#9595a8",
          borderColor: "rgba(255,255,255,0.1)",
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
        },
      },
    },
  });
  chartInstances.push(chart);
}

function createPieChart(canvasId: string, data: Record<string, number>) {
  const canvas = document.getElementById(canvasId) as HTMLCanvasElement;
  if (!canvas) return;

  const labels = Object.keys(data);
  const values = Object.values(data);

  const chart = new Chart(canvas, {
    type: "pie",
    data: {
      labels,
      datasets: [
        {
          data: values,
          backgroundColor: labels.map(
            (_, i) => CHART_PALETTE[i % CHART_PALETTE.length] + "cc"
          ),
          borderColor: "#16161f",
          borderWidth: 3,
          hoverOffset: 8,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: "bottom",
          labels: { padding: 16, font: { size: 11 } },
        },
        tooltip: {
          backgroundColor: "#1c1c28",
          titleColor: "#f0f0f5",
          bodyColor: "#9595a8",
          borderColor: "rgba(255,255,255,0.1)",
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
        },
      },
    },
  });
  chartInstances.push(chart);
}

function createLineChart(canvasId: string, data: Record<string, number>) {
  const canvas = document.getElementById(canvasId) as HTMLCanvasElement;
  if (!canvas) return;

  const labels = Object.keys(data);
  const values = Object.values(data);

  const chart = new Chart(canvas, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "Patients Added",
          data: values,
          borderColor: COLORS.primary,
          backgroundColor: COLORS.primary + "1a",
          fill: true,
          tension: 0.4,
          pointBackgroundColor: COLORS.primary,
          pointBorderColor: "#16161f",
          pointBorderWidth: 2,
          pointRadius: 5,
          pointHoverRadius: 7,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: "#1c1c28",
          titleColor: "#f0f0f5",
          bodyColor: "#9595a8",
          borderColor: "rgba(255,255,255,0.1)",
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
        },
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: { stepSize: 1 },
          grid: { color: "rgba(255,255,255,0.04)" },
        },
        x: {
          grid: { display: false },
        },
      },
    },
  });
  chartInstances.push(chart);
}

// ── Recent Patients Table ───────────────────────────────────────────
function renderRecentPatients(
  patients: PatientDoc[],
  midwifeMap: Map<string, MidwifeDoc>
) {
  const tbody = document.getElementById("recent-patients-body");
  if (!tbody) return;

  // Sort by createdAt descending, take top 5
  const sorted = [...patients]
    .sort((a, b) => {
      const tA = a.createdAt?.toMillis?.() || 0;
      const tB = b.createdAt?.toMillis?.() || 0;
      return tB - tA;
    })
    .slice(0, 5);

  if (sorted.length === 0) {
    tbody.innerHTML = `
      <tr><td colspan="5" class="empty-state">
        <span class="material-icons-round">person_off</span>
        <h4>No patients yet</h4>
      </td></tr>`;
    return;
  }

  const riskBadgeClass = (risk: string) => {
    switch (risk) {
      case "high":
        return "badge-risk-high";
      case "medium":
        return "badge-risk-medium";
      default:
        return "badge-risk-low";
    }
  };

  tbody.innerHTML = sorted
    .map((p) => {
      const mw = midwifeMap.get(p.midwifeId);
      const initials = p.fullName
        .split(" ")
        .map((w) => w[0])
        .join("")
        .substring(0, 2)
        .toUpperCase();

      return `
        <tr>
          <td>
            <div class="cell-name">
              <div class="avatar-sm">${initials}</div>
              <div>
                <strong>${p.fullName}</strong>
                <span class="cell-email">Age: ${p.age}</span>
              </div>
            </div>
          </td>
          <td><span class="badge ${riskBadgeClass(p.riskLevel)}">${capitalize(p.riskLevel)}</span></td>
          <td><span class="mono">${p.gestationalWeeks}w</span></td>
          <td><span class="mono">${p.bloodGroup || "N/A"}</span></td>
          <td>${mw ? mw.fullName : "—"}</td>
        </tr>
      `;
    })
    .join("");
}
