import { type } from "@testing-library/user-event/dist/type";

export interface IFile {
    buffer: Buffer,
    type: string,
    name: string,
}