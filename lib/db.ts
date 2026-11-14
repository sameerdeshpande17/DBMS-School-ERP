import mysql from "mysql2/promise";

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error("DATABASE_URL is not configured. Create .env.local from .env.example.");
}

const globalForMysql = globalThis as unknown as {
  mysqlPool?: mysql.Pool;
};

export const db =
  globalForMysql.mysqlPool ??
  mysql.createPool(databaseUrl);

if (process.env.NODE_ENV !== "production") {
  globalForMysql.mysqlPool = db;
}
