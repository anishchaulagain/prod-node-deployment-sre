import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Post } from "../entities/Post";

export class PostController {
    private postRepository = AppDataSource.getRepository(Post);

    getAll = async (req: Request, res: Response): Promise<void> => {
        const posts = await this.postRepository.find();
        res.json(posts);
    };

    getOne = async (req: Request, res: Response): Promise<void> => {
        const id = parseInt(req.params.id as string);
        const result = await this.postRepository.findOneBy({ id });
        if (result) {
            res.json(result);
        } else {
            res.status(404).send("Post not found");
        }
    };

    create = async (req: Request, res: Response): Promise<void> => {
        const post = this.postRepository.create(req.body);
        const result = await this.postRepository.save(post);
        res.status(201).json(result);
    };

    update = async (req: Request, res: Response): Promise<void> => {
        const id = parseInt(req.params.id as string);
        const post = await this.postRepository.findOneBy({ id });
        if (post) {
            this.postRepository.merge(post, req.body);
            const result = await this.postRepository.save(post);
            res.json(result);
        } else {
            res.status(404).send("Post not found");
        }
    };

    delete = async (req: Request, res: Response): Promise<void> => {
        const id = parseInt(req.params.id as string);
        const result = await this.postRepository.delete(id);
        if (result.affected === 1) {
            res.status(204).send();
        } else {
            res.status(404).send("Post not found");
        }
    };
}
