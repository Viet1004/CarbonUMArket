import { create, IPFSHTTPClient } from "ipfs-http-client";
import { IFile } from "./ifile.interface";
import { Buffer } from 'buffer';
// import dotenv from "dotenv";
// dotenv.config();
// here we handle the ipfs functionality. 

const projectId = '2X2jdBLpkgz4hngBBn4fxdbL4zG';
const projectSecret = '918e9e85f4f31ee93eab8c39e84f9c94';
const auth = 'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64');

export class AppStorage {

    ipfs: IPFSHTTPClient;
    untar: any;

    constructor() {
        this.ipfs = create({
            host: 'ipfs.infura.io',
            port: 5001,
            protocol: 'https',
            headers: {
                authorization: auth
            }
        });
        // this.initialize();
    }

    // private async initialize() {
    //     if(typeof window === "undefined") return;
    //     this.untar = await require("js-untar");
    // }

    async upload(file: IFile) {
        if(!file || !file.buffer) throw 'file not provided';
        if(!this.ipfs) throw 'ipfs not initialized';
        const blob = new Blob([file.buffer], { type: file.type });
        const result = await this.ipfs.add(blob);
        console.log(`Path to result ${result.path}`);
        return result;
    }
}