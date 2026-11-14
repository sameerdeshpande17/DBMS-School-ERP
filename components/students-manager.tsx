"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import Link from "next/link";

type Student = {
  student_id: number;
  admission_no: string;
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: string;
  email: string | null;
  phone: string | null;
  class_id: number;
  class_name: string;
  section: string;
  admission_date: string;
  status: string;
};

type ClassOption = { class_id: number; class_name: string; section: string };
type Role = "ADMIN" | "TEACHER" | "STUDENT";

export default function StudentsManager({ role }: { role: Role }) {
  const [students, setStudents] = useState<Student[]>([]);
  const [classes, setClasses] = useState<ClassOption[]>([]);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [accountStudent, setAccountStudent] = useState<number | null>(null);
  const [accountExists, setAccountExists] = useState(false);
  const [accountBusy, setAccountBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await fetch("/api/students");
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || "Unable to load students.");
      setStudents(data.students);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Unable to load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
    if (role === "ADMIN") {
      fetch("/api/classes")
        .then(async (response) => response.ok ? response.json() : { classes: [] })
        .then((data) => setClasses(data.classes || []))
        .catch(() => setClasses([]));
    }
  }, [load, role]);

  async function createStudent(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError("");
    setMessage("");
    const form = new FormData(event.currentTarget);
    const payload = {
      admissionNo: String(form.get("admissionNo")),
      firstName: String(form.get("firstName")),
      lastName: String(form.get("lastName")),
      dateOfBirth: String(form.get("dateOfBirth")),
      gender: String(form.get("gender")),
      email: String(form.get("email") || ""),
      phone: String(form.get("phone") || ""),
      address: String(form.get("address") || ""),
      classId: Number(form.get("classId")),
      admissionDate: String(form.get("admissionDate")),
      status: "ACTIVE",
    };
    try {
      const response = await fetch("/api/students", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || "Unable to create student.");
      event.currentTarget.reset();
      setMessage("Student record created successfully.");
      await load();
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Unable to create student.");
    } finally {
      setSaving(false);
    }
  }

  async function openAccount(studentId: number) {
    setError(""); setMessage(""); setAccountStudent(studentId); setAccountExists(false);
    try { const response = await fetch(`/api/students/${studentId}/account`); const data = await response.json(); if (!response.ok) throw new Error(data.message || "Unable to check account."); setAccountExists(Boolean(data.account)); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Unable to check account."); }
  }

  async function saveAccount(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!accountStudent) return; setAccountBusy(true); setError(""); setMessage("");
    const form = new FormData(event.currentTarget); const password = String(form.get("accountPassword") || "");
    const payload = accountExists ? { password } : { username: String(form.get("accountUsername") || ""), password };
    try { const response = await fetch(`/api/students/${accountStudent}/account`, { method: accountExists ? "PATCH" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "Unable to save account."); setMessage(data.message); setAccountStudent(null); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "Unable to save account."); }
    finally { setAccountBusy(false); }
  }

  async function deactivateStudent(id: number) {
    if (!window.confirm("Deactivate this student? The academic record will be retained.")) return;
    const response = await fetch(`/api/students/${id}`, { method: "DELETE" });
    const data = await response.json();
    if (!response.ok) setError(data.message || "Unable to deactivate student.");
    else { setMessage(data.message); await load(); }
  }

  return (
    <main className="dashboard">
      <header className="topbar">
        <div><span className="eyebrow">SCHOOL MANAGEMENT</span><h1>Students</h1></div>
        <Link className="health-link" href="/">← Dashboard</Link>
      </header>
      <section className="welcome"><div><span className="eyebrow">STUDENT MANAGEMENT</span><h2>{role === "STUDENT" ? "My profile" : "Student directory"}</h2><p>{role === "ADMIN" ? "Manage admissions and student records." : role === "TEACHER" ? "Students in your assigned classes." : "Your registered student information."}</p></div></section>
      {error && <p className="error-message">{error}</p>}
      {message && <p className="success-message">{message}</p>}
      {role === "ADMIN" && (
        <section className="content-section form-panel">
          <h2>Admit a student</h2>
          <form className="student-form" onSubmit={createStudent}>
            <label>Admission number<input name="admissionNo" required maxLength={30}/></label>
            <label>First name<input name="firstName" required maxLength={60}/></label>
            <label>Last name<input name="lastName" required maxLength={60}/></label>
            <label>Date of birth<input name="dateOfBirth" type="date" required/></label>
            <label>Gender<select name="gender" required><option value="UNDISCLOSED">Undisclosed</option><option value="FEMALE">Female</option><option value="MALE">Male</option><option value="OTHER">Other</option></select></label>
            <label>Class<select name="classId" required defaultValue=""><option value="" disabled>Select class</option>{classes.map((item) => <option key={item.class_id} value={item.class_id}>{item.class_name} - {item.section}</option>)}</select></label>
            <label>Admission date<input name="admissionDate" type="date" required/></label>
            <label>Email<input name="email" type="email" maxLength={120}/></label>
            <label>Phone<input name="phone" maxLength={20}/></label>
            <label className="wide-field">Address<textarea name="address" rows={2} maxLength={500}/></label>
            <button className="login-submit" disabled={saving || classes.length === 0}>{saving ? "Saving..." : "Create student"}</button>
            {classes.length === 0 && <p className="muted">Create a class before admitting students.</p>}
          </form>
        </section>
      )}
      {role === "ADMIN" && accountStudent !== null && <section className="content-section form-panel"><div className="section-heading"><h2>{accountExists ? "Reset student password" : "Create student login"}</h2><button className="secondary-button" onClick={() => setAccountStudent(null)}>Close</button></div><form className="student-form" onSubmit={saveAccount}>{!accountExists && <label>Username<input name="accountUsername" minLength={3} maxLength={60} pattern="[A-Za-z0-9_.-]+" required /></label>}<label>{accountExists ? "New password" : "Initial password"}<input name="accountPassword" type="password" minLength={12} maxLength={256} autoComplete="new-password" required /></label><p className="muted">Use at least 12 characters. Share the username and initial password with the student securely.</p><button className="login-submit" disabled={accountBusy}>{accountBusy ? "Saving..." : accountExists ? "Reset password" : "Create login account"}</button></form></section>}
      <section className="content-section form-panel">
        <div className="section-heading"><h2>{role === "STUDENT" ? "My details" : "Student records"}</h2><button className="secondary-button" onClick={() => void load()}>Refresh</button></div>
        {loading ? <p className="muted">Loading student records…</p> : students.length === 0 ? <p className="muted">No student records are available for this account.</p> : (
          <div className="table-wrap"><table className="data-table">
            <thead><tr><th>Admission no.</th><th>Name</th><th>Class</th><th>Email</th><th>Status</th>{role === "ADMIN" && <th>Actions</th>}</tr></thead>
            <tbody>{students.map((student) => <tr key={student.student_id}>
              <td>{student.admission_no}</td><td>{student.first_name} {student.last_name}</td>
              <td>{student.class_name} - {student.section}</td><td>{student.email || "—"}</td>
              <td><span className="status-pill">{student.status}</span></td>
              {role === "ADMIN" && <td><button className="text-button" onClick={() => void openAccount(student.student_id)} disabled={student.status !== "ACTIVE"}>Login account</button><span> · </span><button className="text-button" onClick={() => void deactivateStudent(student.student_id)} disabled={student.status !== "ACTIVE"}>Deactivate</button></td>}
            </tr>)}</tbody>
          </table></div>
        )}
      </section>
    </main>
  );
}
