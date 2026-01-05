import "dotenv/config";
import "reflect-metadata";
import { DataSource } from "typeorm";
import { Author } from "./entity/Author";
import { Post } from "./entity/Post";
import { Comment } from "./entity/Comment";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("❌ DATABASE_URL environment variable is required");
  console.error("   Copy env.example to .env and set your connection string");
  process.exit(1);
}

export const AppDataSource = new DataSource({
  type: "postgres",
  url: connectionString,
  synchronize: false,
  logging: false,
  entities: [Author, Post, Comment],
  migrations: ["src/migrations/*.ts"],
});

