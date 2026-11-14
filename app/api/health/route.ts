import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const connection = await db.getConnection();
    try {
      const [rows] = await connection.query<
        Array<{ database_name: string; mysql_version: string }>
      >("SELECT DATABASE() AS database_name, VERSION() AS mysql_version");
      return NextResponse.json({
        status: "ok",
        database: rows[0]?.database_name ?? null,
        mysqlVersion: rows[0]?.mysql_version ?? null,
      });
    } finally {
      connection.release();
    }
  } catch {
    return NextResponse.json(
      {
        status: "error",
        message: "Unable to connect to the configured MySQL database.",
      },
      { status: 503 }
    );
  }
}
