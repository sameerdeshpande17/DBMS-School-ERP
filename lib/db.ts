import mysql from "mysql2/promise";

const globalForMysql = globalThis as unknown as {
  mysqlPool?: mysql.Pool;
};

function createPool(): mysql.Pool {
  const databaseUrl = process.env.DATABASE_URL;

  if (databaseUrl) {
    return mysql.createPool(databaseUrl);
  }

  return mysql.createPool({
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT || 3307),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || "school_erp",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });
}

export const db = globalForMysql.mysqlPool ?? createPool();

if (process.env.NODE_ENV !== "production") {
  globalForMysql.mysqlPool = db;
}
