import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { getSession } from "@/lib/auth";
import type { RowDataPacket } from "mysql2";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface CountRow extends RowDataPacket { total: number; }
interface NoticeRow extends RowDataPacket {
  notice_id: number;
  title: string;
  audience: string;
  published_at: string | null;
}

export async function GET() {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });
  try {
    const connection = await db.getConnection();
    try {
      let studentsQuery = "SELECT COUNT(*) AS total FROM student WHERE status = 'ACTIVE'";
      const studentParams: number[] = [];
      let teachersQuery = "SELECT COUNT(*) AS total FROM teacher WHERE status = 'ACTIVE'";
      const teacherParams: number[] = [];
      let classesQuery = "SELECT COUNT(*) AS total FROM class";
      const classParams: number[] = [];

      if (user.role === "TEACHER") {
        if (!user.teacherId) return NextResponse.json({ message: "Teacher profile is not linked." }, { status: 403 });
        studentsQuery += " AND class_id IN (SELECT class_id FROM class WHERE class_teacher_id = ? UNION SELECT class_id FROM class_subject WHERE teacher_id = ?)";
        studentParams.push(user.teacherId, user.teacherId);
        teachersQuery += " AND teacher_id = ?";
        teacherParams.push(user.teacherId);
        classesQuery += " WHERE class_teacher_id = ? OR class_id IN (SELECT class_id FROM class_subject WHERE teacher_id = ?)";
        classParams.push(user.teacherId, user.teacherId);
      } else if (user.role === "STUDENT") {
        if (!user.studentId) return NextResponse.json({ message: "Student profile is not linked." }, { status: 403 });
        studentsQuery += " AND student_id = ?";
        studentParams.push(user.studentId);
        teachersQuery = "SELECT COUNT(DISTINCT teacher_id) AS total FROM class_subject WHERE class_id = (SELECT class_id FROM student WHERE student_id = ?)";
        teacherParams.push(user.studentId);
        classesQuery += " WHERE class_id = (SELECT class_id FROM student WHERE student_id = ?)";
        classParams.push(user.studentId);
      }

      const [students] = await connection.execute<CountRow[]>(studentsQuery, studentParams);
      const [teachers] = await connection.execute<CountRow[]>(teachersQuery, teacherParams);
      const [classes] = await connection.execute<CountRow[]>(classesQuery, classParams);
      const [subjects] = await connection.query<CountRow[]>("SELECT COUNT(*) AS total FROM subject");
      const [notices] = await connection.execute<NoticeRow[]>(
        user.role === "ADMIN"
          ? "SELECT notice_id, title, audience, published_at FROM notice WHERE status IN ('DRAFT','PUBLISHED') ORDER BY COALESCE(published_at,'9999-12-31') DESC LIMIT 5"
          : "SELECT notice_id, title, audience, published_at FROM notice WHERE status = 'PUBLISHED' AND (audience = 'ALL' OR audience = ?) AND (expires_at IS NULL OR expires_at >= NOW()) ORDER BY published_at DESC LIMIT 5",
        user.role === "ADMIN" ? [] : [user.role]
      );
      return NextResponse.json({
        user: { username: user.username, role: user.role },
        counts: {
          students: Number(students[0]?.total ?? 0),
          teachers: Number(teachers[0]?.total ?? 0),
          classes: Number(classes[0]?.total ?? 0),
          subjects: Number(subjects[0]?.total ?? 0),
        },
        notices,
      });
    } finally {
      connection.release();
    }
  } catch {
    return NextResponse.json({ message: "Unable to load dashboard data from MySQL." }, { status: 503 });
  }
}
