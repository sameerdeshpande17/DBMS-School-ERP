import {redirect} from "next/navigation";import {getSession} from "@/lib/auth";import TeacherDashboard from "@/components/teacher-dashboard";
export default async function Page(){const user=await getSession();if(!user)redirect("/teacher-login");if(user.role!=="TEACHER")redirect("/");return <TeacherDashboard/>;}
