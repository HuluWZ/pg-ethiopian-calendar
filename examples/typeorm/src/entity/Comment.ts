import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from "typeorm";
import { Post } from "./Post";

@Entity("comments")
export class Comment {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "author_name" })
  authorName!: string;

  @Column({ type: "text" })
  content!: string;

  @Column({ name: "post_id" })
  postId!: number;

  @ManyToOne(() => Post, (post) => post.comments)
  @JoinColumn({ name: "post_id" })
  post!: Post;

  @CreateDateColumn({ name: "created_at" })
  createdAt!: Date;

  @Column({
    name: "created_at_ethiopian",
    type: "timestamp",
    generatedType: "STORED",
    asExpression: "to_ethiopian_timestamp(created_at)",
    nullable: true,
  })
  createdAtEthiopian?: Date;
}

