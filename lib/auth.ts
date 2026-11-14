import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";

export const SESSION_COOKIE = "school_erp_session";
export type UserRole = "ADMIN" | "TEACHER" | "STUDENT";

export interface SessionUser {
  userId: number;
  username: string;
  role: UserRole;
  teacherId: number | null;
  studentId: number | null;
}

function getSecret(): Uint8Array {
  const secret = process.env.SESSION_SECRET;
  if (!secret || Buffer.byteLength(secret) < 32) {
    throw new Error("SESSION_SECRET must be set to at least 32 bytes.");
  }
  return new TextEncoder().encode(secret);
}

export async function createSession(user: SessionUser): Promise<string> {
  return new SignJWT({
    username: user.username,
    role: user.role,
    teacherId: user.teacherId,
    studentId: user.studentId,
  })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(String(user.userId))
    .setIssuedAt()
    .setExpirationTime("8h")
    .sign(getSecret());
}

export async function getSession(): Promise<SessionUser | null> {
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!token) return null;

  try {
    const { payload } = await jwtVerify(token, getSecret());
    if (
      typeof payload.sub !== "string" ||
      typeof payload.username !== "string" ||
      !["ADMIN", "TEACHER", "STUDENT"].includes(String(payload.role))
    ) return null;

    return {
      userId: Number(payload.sub),
      username: payload.username,
      role: payload.role as UserRole,
      teacherId: typeof payload.teacherId === "number" ? payload.teacherId : null,
      studentId: typeof payload.studentId === "number" ? payload.studentId : null,
    };
  } catch {
    return null;
  }
}

export async function requireRole(roles: UserRole[]): Promise<SessionUser | null> {
  const user = await getSession();
  return user && roles.includes(user.role) ? user : null;
}
