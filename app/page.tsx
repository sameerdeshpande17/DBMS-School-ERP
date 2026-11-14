import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import DashboardOverview from "@/components/dashboard-overview";

export default async function Home() {
  const user = await getSession();
  if (!user) redirect("/login");
  return <DashboardOverview />;
}
