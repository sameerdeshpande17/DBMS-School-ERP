import { NextRequest, NextResponse } from "next/server";
import type { ResultSetHeader } from "mysql2";
import { z } from "zod";
import { db } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const runtime = "nodejs";

const updateSchema = z.object({
  firstName: z.string().trim().min(1).max(60).optional(),
  lastName: z.string().trim().min(1).max(60).optional(),
  email: z.email().nullable().optional().or(z.literal("")),
  phone: z.string().max(20).nullable().optional(),
  address: z.string().max(500).nullable().optional(),
  classId: z.number().int().positive().optional(),
  status: z.enum(["ACTIVE", "INACTIVE", "GRADUATED", "TRANSFERRED"]).optional(),
}).refine((data) => Object.keys(data).length > 0);

export async function PATCH(request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });
  if (user.role !== "ADMIN") return NextResponse.json({ message: "Only administrators can update student records." }, { status: 403 });

  const { id } = await context.params;
  if (!/^\d+$/.test(id) || Number(id) < 1) return NextResponse.json({ message: "Invalid student ID." }, { status: 400 });
  const parsed = updateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ message: "Invalid update details." }, { status: 400 });

  const columns: Record<string, string> = {
    firstName: "first_name", lastName: "last_name", email: "email",
    phone: "phone", address: "address", classId: "class_id", status: "status",
  };
  const entries = Object.entries(parsed.data);
  const assignments = entries.map(([key]) => `${columns[key]} = ?`).join(", ");
  const values = entries.map(([key, value]) => key === "email" && value === "" ? null : value);
  try {
    const [result] = await db.execute<ResultSetHeader>(
      `UPDATE student SET ${assignments} WHERE student_id = ?`,
      [...values, Number(id)]
    );
    if (!result.affectedRows) return NextResponse.json({ message: "Student not found." }, { status: 404 });
    return NextResponse.json({ message: "Student updated successfully." });
  } catch {
    return NextResponse.json({ message: "Unable to update student record. Check the class and email values." }, { status: 400 });
  }
}

export async function DELETE(_request: NextRequest, context: { params: Promise<{ id: string }> }) {
  const user = await getSession();
  if (!user) return NextResponse.json({ message: "Authentication required." }, { status: 401 });
  if (user.role !== "ADMIN") return NextResponse.json({ message: "Only administrators can deactivate student records." }, { status: 403 });

  const { id } = await context.params;
  if (!/^\d+$/.test(id) || Number(id) < 1) return NextResponse.json({ message: "Invalid student ID." }, { status: 400 });
  const [result] = await db.execute<ResultSetHeader>(
    "UPDATE student SET status = 'INACTIVE' WHERE student_id = ? AND status = 'ACTIVE'",
    [Number(id)]
  );
  if (!result.affectedRows) return NextResponse.json({ message: "Active student not found." }, { status: 404 });
  return NextResponse.json({ message: "Student deactivated. The record has been retained for academic history." });
}
