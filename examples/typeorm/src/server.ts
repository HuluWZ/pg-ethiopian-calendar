import "reflect-metadata";
import express, { Request, Response } from "express";
import { AppDataSource } from "./data-source";
import { Author } from "./entity/Author";
import { Post } from "./entity/Post";
import { Comment } from "./entity/Comment";

const app = express();
const PORT = process.env.PORT || 3003;

app.use(express.json());

// ============================================================================
// Ethiopian Calendar Endpoints
// ============================================================================

app.get("/ethiopian/today", async (_req: Request, res: Response) => {
  const result = await AppDataSource.query("SELECT to_ethiopian_date() as today");
  res.json({ ethiopianDate: result[0].today });
});

app.get("/ethiopian/convert/:date", async (req: Request, res: Response) => {
  const { date } = req.params;
  try {
    const result = await AppDataSource.query(
      "SELECT to_ethiopian_date($1::timestamp) as ethiopian",
      [date]
    );
    res.json({ gregorian: date, ethiopian: result[0].ethiopian });
  } catch {
    res.status(400).json({ error: "Invalid date format" });
  }
});

// ============================================================================
// Author Endpoints
// ============================================================================

app.get("/authors", async (_req: Request, res: Response) => {
  const authorRepo = AppDataSource.getRepository(Author);
  const authors = await authorRepo.find({ relations: ["posts"] });
  res.json(authors);
});

app.post("/authors", async (req: Request, res: Response) => {
  const { name, email, bio } = req.body;
  const authorRepo = AppDataSource.getRepository(Author);

  const author = authorRepo.create({ name, email, bio });
  await authorRepo.save(author);

  res.status(201).json(author);
});

// ============================================================================
// Post Endpoints
// ============================================================================

app.get("/posts", async (_req: Request, res: Response) => {
  const postRepo = AppDataSource.getRepository(Post);
  const posts = await postRepo.find({
    relations: ["author", "comments"],
    order: { createdAt: "DESC" },
  });
  res.json(posts);
});

app.get("/posts/:id", async (req: Request, res: Response) => {
  const { id } = req.params;
  const postRepo = AppDataSource.getRepository(Post);

  const post = await postRepo.findOne({
    where: { id: parseInt(id) },
    relations: ["author", "comments"],
  });

  if (!post) {
    res.status(404).json({ error: "Post not found" });
    return;
  }

  res.json(post);
});

app.post("/posts", async (req: Request, res: Response) => {
  const { title, content, authorId } = req.body;
  const postRepo = AppDataSource.getRepository(Post);

  const post = postRepo.create({ title, content, authorId, status: "draft" });
  await postRepo.save(post);

  res.status(201).json(post);
});

app.patch("/posts/:id/publish", async (req: Request, res: Response) => {
  const { id } = req.params;
  const postRepo = AppDataSource.getRepository(Post);

  const post = await postRepo.findOneBy({ id: parseInt(id) });
  if (!post) {
    res.status(404).json({ error: "Post not found" });
    return;
  }

  post.status = "published";
  post.publishedAt = new Date();
  await postRepo.save(post);

  // Reload to get computed Ethiopian date
  const updated = await postRepo.findOne({
    where: { id: parseInt(id) },
    relations: ["author"],
  });

  res.json(updated);
});

// ============================================================================
// Comment Endpoints
// ============================================================================

app.get("/posts/:postId/comments", async (req: Request, res: Response) => {
  const { postId } = req.params;
  const commentRepo = AppDataSource.getRepository(Comment);

  const comments = await commentRepo.find({
    where: { postId: parseInt(postId) },
    order: { createdAt: "ASC" },
  });

  res.json(comments);
});

app.post("/posts/:postId/comments", async (req: Request, res: Response) => {
  const { postId } = req.params;
  const { authorName, content } = req.body;
  const commentRepo = AppDataSource.getRepository(Comment);

  const comment = commentRepo.create({
    postId: parseInt(postId),
    authorName,
    content,
  });
  await commentRepo.save(comment);

  res.status(201).json(comment);
});

// ============================================================================
// Query by Ethiopian Date
// ============================================================================

app.get("/posts/published/ethiopian-month/:year/:month", async (req: Request, res: Response) => {
  const { year, month } = req.params;

  const posts = await AppDataSource.query(
    `
    SELECT p.*, a.name as author_name
    FROM posts p
    JOIN authors a ON p.author_id = a.id
    WHERE EXTRACT(YEAR FROM p.published_at_ethiopian) = $1
      AND EXTRACT(MONTH FROM p.published_at_ethiopian) = $2
    ORDER BY p.published_at_ethiopian DESC
    `,
    [year, month]
  );

  res.json(posts);
});

// ============================================================================
// Server
// ============================================================================

AppDataSource.initialize()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`
╔═══════════════════════════════════════════════════════════╗
║     Ethiopian Calendar - TypeORM Demo                     ║
╠═══════════════════════════════════════════════════════════╣
║  Server running on http://localhost:${PORT}                  ║
╠═══════════════════════════════════════════════════════════╣
║  Endpoints:                                               ║
║  • GET  /ethiopian/today          - Current Ethiopian date║
║  • GET  /ethiopian/convert/:date  - Convert to Ethiopian  ║
║  • GET  /authors                  - List authors          ║
║  • POST /authors                  - Create author         ║
║  • GET  /posts                    - List posts            ║
║  • POST /posts                    - Create post           ║
║  • PATCH /posts/:id/publish       - Publish post          ║
║  • GET  /posts/:id/comments       - List comments         ║
║  • POST /posts/:id/comments       - Add comment           ║
║  • GET  /posts/published/ethiopian-month/:y/:m            ║
╚═══════════════════════════════════════════════════════════╝
      `);
    });
  })
  .catch((error) => console.error("Database connection failed:", error));

