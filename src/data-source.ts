import "reflect-metadata";
import { DataSource } from "typeorm";
import { Post } from "./entities/Post";
import "dotenv/config";

export const AppDataSource = new DataSource({
    type: process.env.DB_TYPE as any,
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    synchronize: true,
    logging: false,
    entities: [Post],
    migrations: [],
    subscribers: [],
});
