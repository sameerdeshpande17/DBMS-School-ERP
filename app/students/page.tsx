import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import StudentsManager from "@/components/students-manager";

export default async function StudentsPage() {
  const user = await getSession();
  if (!user) redirect("/login");
  return <StudentsManager role={user.role} />;
}
