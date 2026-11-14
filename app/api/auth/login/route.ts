import { NextRequest, NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { z } from "zod";
import { db } from "@/lib/db";
import { createSession, SESSION_COOKIE, type UserRole } from "@/lib/auth";
import { verifyPassword } from "@/lib/password";

export const runtime = "nodejs";

interface UserRow extends RowDataPacket {
  user_id: number;
  username: string;
  password_hash: string;
  role: UserRole;
  teacher_id: number | null;
  student_id: number | null;
  is_active: number;
}

const loginSchema = z.object({
  username: z.string().trim().min(1).max(60),
  password: z.string().min(1).max(256),
});

export async function POST(request: NextRequest) {
  const parsed = loginSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ message: "Enter a valid username and password." }, { status: 400 });
  }

  try {
    const [rows] = await db.execute<UserRow[]>(
      "SELECT user_id, username, password_hash, role, teacher_id, student_id, is_active FROM app_user WHERE username = ? LIMIT 1",
      [parsed.data.username]
    );
    const account = rows[0];

    if (!account || !account.is_active || !(await verifyPassword(parsed.data.password, account.password_hash))) {
      return NextResponse.json({ message: "Invalid username or password." }, { status: 401 });
    }

    const token = await createSession({
      userId: Number(account.user_id),
      username: account.username,
      role: account.role,
      teacherId: account.teacher_id === null ? null : Number(account.teacher_id),
      studentId: account.student_id === null ? null : Number(account.student_id),
    });

    const response = NextResponse.json({
      user: { username: account.username, role: account.role },
    });
    response.cookies.set(SESSION_COOKIE, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 8,
    });
    return response;
  } catch {
    return NextResponse.json({ message: "Unable to sign in. Check server configuration." }, { status: 503 });
  }
}
