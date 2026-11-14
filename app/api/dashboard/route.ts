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
      const [students] = await connection.query<CountRow[]>("SELECT COUNT(*) AS total FROM student WHERE status = 'ACTIVE'");
      const [teachers] = await connection.query<CountRow[]>("SELECT COUNT(*) AS total FROM teacher WHERE status = 'ACTIVE'");
      const [classes] = await connection.query<CountRow[]>("SELECT COUNT(*) AS total FROM class");
      const [subjects] = await connection.query<CountRow[]>("SELECT COUNT(*) AS total FROM subject");
      const [notices] = await connection.query<NoticeRow[]>(
        "SELECT notice_id, title, audience, published_at FROM notice WHERE status = 'PUBLISHED' AND (expires_at IS NULL OR expires_at >= NOW()) ORDER BY published_at DESC LIMIT 5"
      );
      return NextResponse.json({
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
