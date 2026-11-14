"use client";

import { useEffect, useState } from "react";

type DashboardData = {
  counts: { students: number; teachers: number; classes: number; subjects: number };
  notices: { notice_id: number; title: string; audience: string; published_at: string | null }[];
  user: { username: string; role: "ADMIN" | "TEACHER" | "STUDENT" };
};

const modules = [
  ["Students", "Admissions, student profiles and class allocation", "/students"],
  ["Teachers", "Teacher directory and class assignments", "/teachers"],
  ["Classes & Subjects", "Academic structure and subject mapping", "/classes"],
  ["Attendance", "Daily attendance and attendance summaries", "/attendance"],
  ["Examinations", "Exams, marks and academic performance", "/exams"],
  ["Fee Payments", "Payment records and fee summaries", "/fees"],
  ["Notices", "School announcements and communication", "/notices"],
];

export default function DashboardOverview() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [error, setError] = useState("");
  const [currentUser, setCurrentUser] = useState<DashboardData["user"] | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then(async (response) => {
        if (!response.ok) throw new Error("Dashboard data could not be loaded.");
        return (await response.json()) as DashboardData;
      })
      .then((result) => { setData(result); setCurrentUser(result.user); })
      .catch((reason: Error) => setError(reason.message));
  }, []);

  const stats = [
    ["Active students", data?.counts.students],
    ["Active teachers", data?.counts.teachers],
    ["Classes", data?.counts.classes],
    ["Subjects", data?.counts.subjects],
  ];

  return (
    <main className="dashboard">
      <header className="topbar">
        <div><span className="eyebrow">SCHOOL MANAGEMENT</span><h1>School ERP</h1></div>
        <div className="account-actions">
          {currentUser && <span className="account-label">{currentUser.username} · {currentUser.role}</span>}
          <span className="database-status">MySQL connected</span>
          <button className="secondary-button" onClick={async () => { await fetch("/api/auth/logout", { method: "POST" }); window.location.href = "/login"; }}>Sign out</button>
        </div>
      </header>

      <section className="welcome">
        <div><span className="eyebrow">OVERVIEW</span><h2>Dashboard</h2><p>Academic operations at a glance.</p></div>
        <a className="health-link" href="/api/health">Database health ↗</a>
      </section>

      {error && <p className="error-message">{error}</p>}

      <section className="stats-grid" aria-label="School statistics">
        {stats.map(([label, value]) => (
          <article className="stat-card" key={label as string}>
            <span>{label}</span><strong>{value === undefined ? "—" : value}</strong>
          </article>
        ))}
      </section>

      <section className="content-section">
        <div className="section-heading"><div><span className="eyebrow">WORKSPACE</span><h2>ERP modules</h2></div></div>
        <div className="module-grid">
          {modules.map(([name, description, href], index) => (
            <a className="module-card" href={href} key={name}>
              <span className="module-number">{String(index + 1).padStart(2, "0")}</span>
              <h3>{name}</h3><p>{description}</p><span className="module-arrow">Open module ↗</span>
            </a>
          ))}
        </div>
      </section>

      <section className="content-section notices-section">
        <div className="section-heading"><div><span className="eyebrow">COMMUNICATION</span><h2>Recent notices</h2></div></div>
        {!data && !error && <p className="muted">Loading notices…</p>}
        {data?.notices.length === 0 && <p className="muted">No published notices yet.</p>}
        {data?.notices.map((notice) => (
          <article className="notice-row" key={notice.notice_id}>
            <div><strong>{notice.title}</strong><span>{notice.audience}</span></div>
            <time>{notice.published_at ? new Date(notice.published_at).toLocaleDateString() : "Recently published"}</time>
          </article>
        ))}
      </section>
      <footer>School ERP · MySQL 8.4 primary database · Redis Stack secondary store</footer>
    </main>
  );
}
