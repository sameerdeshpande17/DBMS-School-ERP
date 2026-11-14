import {redirect} from "next/navigation";
import {getSession} from "@/lib/auth";
import ModuleManager from "@/components/module-manager";
export default async function Page(){const user=await getSession();if(!user)redirect("/login");return <ModuleManager kind="attendance" role={user.role}/>;}
