import Redis from "ioredis";
const globalForRedis = globalThis as unknown as { redisClient?: Redis };
export const redis = globalForRedis.redisClient ?? new Redis(process.env.REDIS_URL ?? "redis://127.0.0.1:6379", { lazyConnect: true, maxRetriesPerRequest: 1 });
if (process.env.NODE_ENV !== "production") globalForRedis.redisClient = redis;
