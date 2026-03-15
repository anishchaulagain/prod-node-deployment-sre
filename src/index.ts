import "dotenv/config";
import express from "express";
import { AppDataSource } from "./data-source";
import postRoutes from "./routes/postRoutes";
import swaggerUi from "swagger-ui-express";
import swaggerJsdoc from "swagger-jsdoc";

const app = express(); //express app
const port = 8000;

app.use(express.json());

const options = {
    definition: {
        openapi: "3.0.0",
        info: {
            title: "Express API with MySQL and Swagger",
            version: "1.0.0",
            description: "A simple CRUD API application made with Express and documented with Swagger",
        },
        servers: [
            {
                url: "/",
            },
        ],
    },
    apis: ["./src/routes/*.ts"],
};

const specs = swaggerJsdoc(options);
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(specs));

app.use("/posts", postRoutes);

app.get("/health", (_, res) => {
    res.status(200).json({ status: "ok" });
});

AppDataSource.initialize()
    .then(() => {
        console.log("Data Source has been initialized!");
        app.listen(port, () => {
            console.log(`Server is running at http://localhost:${port}`);
            console.log(`Swagger UI is available at http://localhost:${port}/api-docs`);
        });
    })
    .catch((err) => {
        console.error("Error during Data Source initialization", err);
    });
