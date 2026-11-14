import { NextRequest, NextResponse } from "next/server";
import type { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { db } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface StudentRow extends RowDataPacket {
  student_id: number;
  admission_no: string;
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  class_id: number;
  class_name: string;
  section: string;
  admission_date: string;
  status: string;
}

const studentSchema = z.object({
  admissionNo: z.string().trim().min(1).max(30),
  firstName: z.string().trim().min(1).max(60),
  lastName: z.string().trim().min(1).max(60),
  dateOfBirth: z.iso.date(),
  gender: z.enum(["FEMALE", "MALE", "OTHER", "UNDISCLOSED"]),
  email: z.email().nullable().optional().or(z.literal("")),
  phone: z.string().max(20).nullable().optional(),
  address: z.string().max(500).nullable().optional(),
  classId: z.number().int().positive(),
  admissionDate: z.iso.date(),
  status: z.enum(["ACTIVE", "INACTIVE", "GRADUATED", "TRANSFERRED"]).default("ACTIVE"),
});

const selectFields = `s.student_id, s.admission_no, s.first_name, s.last_name,
  s.date_of_birth, s.gender, s.email, s.phone, s.address, s.class_id,
  c.class_name, c.section, s.admission_date, s.status`;

export async function GET() {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });

  try {
    let sql = `SELECT ${selectFields} FROM student s JOIN class c ON c.class_id = s.class_id`;
    const params: number[] = [];

    if (user.role === "STUDENT") {
      if (!user.studentId) return NextResponse.json({ message: "Student profile is not linked." }, { status: 403 });
      sql += " WHERE s.student_id = ?";
      params.push(user.studentId);
    } else if (user.role === "TEACHER") {
      if (!user.teacherId) return NextResponse.json({ message: "Teacher profile is not linked." }, { status: 403 });
      sql += ` WHERE (c.class_teacher_id = ? OR EXISTS (
        SELECT 1 FROM class_subject cs WHERE cs.class_id = s.class_id AND cs.teacher_id = ?
      ))`;
      params.push(user.teacherId, user.teacherId);
    }
    sql += " ORDER BY s.last_name, s.first_name";

    const [rows] = await db.execute<StudentRow[]>(sql, params);
    return NextResponse.json({ students: rows });
  } catch {
    return NextResponse.json({ message: "Unable to retrieve student records." }, { status: 503 });
  }
}

export async function POST(request: NextRequest) {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });
  if (user.role !== "ADMIN") return NextResponse.json({ message: "Only administrators can create student records." }, { status: 403 });

  const parsed = studentSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ message: "Invalid student details.", errors: parsed.error.flatten() }, { status: 400 });

  const data = parsed.data;
  try {
    const [result] = await db.execute<ResultSetHeader>(
      `INSERT INTO student
      (admission_no, first_name, last_name, date_of_birth, gender, email, phone, address, class_id, admission_date, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [data.admissionNo, data.firstName, data.lastName, data.dateOfBirth, data.gender,
       data.email || null, data.phone || null, data.address || null, data.classId, data.admissionDate, data.status]
    );
    return NextResponse.json({ studentId: result.insertId, message: "Student created successfully." }, { status: 201 });
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === "ER_DUP_ENTRY") return NextResponse.json({ message: "Admission number or email already exists." }, { status: 409 });
    if (code === "ER_NO_REFERENCED_ROW_2") return NextResponse.json({ message: "Selected class does not exist." }, { status: 400 });
    return NextResponse.json({ message: "Unable to create student record." }, { status: 503 });
  }
}
