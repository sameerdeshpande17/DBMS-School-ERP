import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { db } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface ClassRow extends RowDataPacket {
  class_id: number;
  class_name: string;
  section: string;
  academic_year: string;
}

export async function GET() {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });
  try {
    let sql = "SELECT class_id, class_name, section, academic_year FROM class";
    const params: number[] = [];
    if (user.role === "TEACHER") {
      if (!user.teacherId) return NextResponse.json({ message: "Teacher profile is not linked." }, { status: 403 });
      sql += " WHERE class_teacher_id = ? OR class_id IN (SELECT class_id FROM class_subject WHERE teacher_id = ?)";
      params.push(user.teacherId, user.teacherId);
    } else if (user.role === "STUDENT") {
      if (!user.studentId) return NextResponse.json({ message: "Student profile is not linked." }, { status: 403 });
      sql += " WHERE class_id = (SELECT class_id FROM student WHERE student_id = ?)";
      params.push(user.studentId);
    }
    sql += " ORDER BY class_name, section";
    const [classes] = await db.execute<ClassRow[]>(sql, params);
    return NextResponse.json({ classes });
  } catch {
    return NextResponse.json({ message: "Unable to retrieve classes." }, { status: 503 });
  }
}
