import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from "typeorm";
import { Author } from "./Author";
import { Comment } from "./Comment";

@Entity("posts")
export class Post {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  title!: string;

  @Column({ type: "text" })
  content!: string;

  @Column({ default: "draft" })
  status!: string;

  @Column({ name: "author_id" })
  authorId!: number;

  @ManyToOne(() => Author, (author) => author.posts)
  @JoinColumn({ name: "author_id" })
  author!: Author;

  @OneToMany(() => Comment, (comment) => comment.post)
  comments!: Comment[];

  @Column({ name: "published_at", nullable: true })
  publishedAt?: Date;

  @Column({
    name: "published_at_ethiopian",
    type: "timestamp",
    generatedType: "STORED",
    asExpression: "to_ethiopian_timestamp(published_at)",
    nullable: true,
  })
  publishedAtEthiopian?: Date;

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

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt!: Date;

  @Column({
    name: "updated_at_ethiopian",
    type: "timestamp",
    generatedType: "STORED",
    asExpression: "to_ethiopian_timestamp(updated_at)",
    nullable: true,
  })
  updatedAtEthiopian?: Date;
}

