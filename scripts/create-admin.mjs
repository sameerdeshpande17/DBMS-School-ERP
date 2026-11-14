import mysql from "mysql2/promise";
import { createInterface } from "node:readline";
import { emitKeypressEvents } from "node:readline";
import { randomBytes, scryptSync } from "node:crypto";

function readHidden(prompt) {
  return new Promise((resolve) => {
    const input = process.stdin;
    const output = process.stdout;
    output.write(prompt);
    emitKeypressEvents(input);
    input.resume();
    if (input.isTTY) input.setRawMode(true);
    let value = "";
    const onKey = (character, key) => {
      if (key?.name === "return") {
        input.off("keypress", onKey);
        if (input.isTTY) input.setRawMode(false);
        output.write("\n");
        resolve(value);
      } else if (key?.name === "backspace") {
        value = value.slice(0, -1);
      } else if (key?.name === "c" && key.ctrl) {
        process.exit(1);
      } else if (!key?.ctrl && !key?.meta && character) {
        value += character;
      }
    };
    input.on("keypress", onKey);
  });
}

const username = process.env.ADMIN_USERNAME || (await new Promise((resolve) => {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  rl.question("Admin username: ", (answer) => { rl.close(); resolve(answer.trim()); });
}));

if (!/^[A-Za-z0-9_.-]{3,60}$/.test(username)) {
  console.error("Username must be 3-60 characters: letters, numbers, dot, underscore or hyphen.");
  process.exit(1);
}

const password = await readHidden("Admin password (minimum 12 characters): ");
if (password.length < 12) {
  console.error("Password must contain at least 12 characters.");
  process.exit(1);
}
const confirmation = await readHidden("Confirm password: ");
if (password !== confirmation) {
  console.error("Passwords do not match.");
  process.exit(1);
}

const salt = randomBytes(16).toString("hex");
const passwordHash = `scrypt$${salt}$${scryptSync(password, salt, 64).toString("hex")}`;

const connection = await mysql.createConnection({
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3307),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "school_erp",
});

try {
  await connection.execute(
    "INSERT INTO app_user (username, password_hash, role) VALUES (?, ?, 'ADMIN')",
    [username, passwordHash]
  );
  console.log(`Admin account "${username}" created successfully.`);
} catch (error) {
  if (error?.code === "ER_DUP_ENTRY") {
    console.error("That username already exists. Choose another username.");
  } else {
    console.error("Could not create admin account:", error.message);
  }
  process.exitCode = 1;
} finally {
  await connection.end();
}
