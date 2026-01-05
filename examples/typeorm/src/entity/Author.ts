import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
} from "typeorm";
import { Post } from "./Post";

@Entity("authors")
export class Author {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;

  @Column({ unique: true })
  email!: string;

  @Column({ nullable: true })
  bio?: string;

  @OneToMany(() => Post, (post) => post.author)
  posts!: Post[];

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

