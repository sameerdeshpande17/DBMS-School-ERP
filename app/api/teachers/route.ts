import { NextRequest, NextResponse } from "next/server";
import type { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { db } from "@/lib/db";
import { getSession } from "@/lib/auth";
export const runtime = "nodejs";
export const dynamic = "force-dynamic";
interface TeacherRow extends RowDataPacket { teacher_id:number; employee_no:string; first_name:string; last_name:string; email:string; phone:string|null; hire_date:string; status:string; }
const schema=z.object({employeeNo:z.string().trim().min(1).max(20),firstName:z.string().trim().min(1).max(60),lastName:z.string().trim().min(1).max(60),email:z.email().max(120),phone:z.string().max(20).optional(),hireDate:z.iso.date(),status:z.enum(["ACTIVE","INACTIVE"]).default("ACTIVE")});
export async function GET(){
 const u=await getSession(); if(!u)return NextResponse.json({message:"Authentication required."},{status:401}); if(u.role==="STUDENT")return NextResponse.json({message:"Access denied."},{status:403});
 try { const [rows]=await db.execute<TeacherRow[]>(`SELECT teacher_id,employee_no,first_name,last_name,email,phone,hire_date,status FROM teacher ${u.role==="TEACHER"?"WHERE teacher_id = ?":""} ORDER BY last_name,first_name`,u.role==="TEACHER"?[u.teacherId]:[]); return NextResponse.json({teachers:rows}); } catch{return NextResponse.json({message:"Unable to load teachers."},{status:503});}
}
export async function POST(req:NextRequest){
 const u=await getSession(); if(!u)return NextResponse.json({message:"Authentication required."},{status:401}); if(u.role!=="ADMIN")return NextResponse.json({message:"Admin access required."},{status:403});
 const p=schema.safeParse(await req.json().catch(()=>null)); if(!p.success)return NextResponse.json({message:"Invalid teacher details.",errors:p.error.flatten()},{status:400});
 try{const d=p.data;const [r]=await db.execute<ResultSetHeader>("INSERT INTO teacher(employee_no,first_name,last_name,email,phone,hire_date,status) VALUES(?,?,?,?,?,?,?)",[d.employeeNo,d.firstName,d.lastName,d.email,d.phone||null,d.hireDate,d.status]);return NextResponse.json({teacherId:r.insertId},{status:201});}
 catch(e){if((e as {code?:string}).code==="ER_DUP_ENTRY")return NextResponse.json({message:"Employee number or email already exists."},{status:409});return NextResponse.json({message:"Unable to create teacher."},{status:503});}
}
