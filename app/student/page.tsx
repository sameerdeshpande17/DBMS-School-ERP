import {redirect} from "next/navigation";import {getSession} from "@/lib/auth";import StudentDashboard from "@/components/student-dashboard";
export default async function Page(){const user=await getSession();if(!user)redirect("/student-login");if(user.role!=="STUDENT")redirect("/");return <StudentDashboard/>;}
