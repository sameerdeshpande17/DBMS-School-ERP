import {redirect} from "next/navigation";
import {getSession} from "@/lib/auth";
import ModuleManager from "@/components/module-manager";
export default async function Page(){const user=await getSession();if(!user)redirect("/login");if(user.role==="STUDENT")redirect("/");return <ModuleManager kind="teachers" role={user.role}/>;}
