import mysql from "mysql2/promise";
const globalForMysql = globalThis as unknown as { mysqlPool?: mysql.Pool };
export const db = globalForMysql.mysqlPool ?? mysql.createPool({ uri: process.env.DATABASE_URL, waitForConnections: true, connectionLimit: 10, queueLimit: 0 });
if (process.env.NODE_ENV !== "production") globalForMysql.mysqlPool = db;
