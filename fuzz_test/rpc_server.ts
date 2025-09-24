import { JSONRPCServer } from "json-rpc-2.0";
import express, { Request, Response } from "express";
import bodyParser from "body-parser";
import cors from "cors";
import { createHash } from "crypto";

const app = express();
app.use(cors());
app.use(bodyParser.json());

const server = new JSONRPCServer();

// Direct base64 encoding functions
function base64EncodeStandard(data: number[]): string {
    const buffer = Buffer.from(data);
    return buffer.toString('base64');
}

function base64EncodeStandardNoPad(data: number[]): string {
    const buffer = Buffer.from(data);
    return buffer.toString('base64').replace(/=/g, '');
}

function base64EncodeUrlSafe(data: number[]): string {
    const buffer = Buffer.from(data);
    return buffer.toString('base64url');
}

function base64EncodeUrlSafeWithPad(data: number[]): string {
    // convert to standard Base64
  const base64 = Buffer.from(data).toString("base64");

  // make it URL-safe by replacing + and /
  const base64Url = base64.replace(/\+/g, "-").replace(/\//g, "_");
  return base64Url;
}


// Type definitions for the foreign call parameters
interface ForeignCallParams {
    function: string;
    inputs: number[][];
}

interface ForeignCallRequest {
    [0]: ForeignCallParams;
}

interface ForeignCallResponse {
    values: string[][];
}

// Add the oracle method for base64 encoding
server.addMethod("resolve_foreign_call", async (params: ForeignCallRequest): Promise<ForeignCallResponse> => {
    
    if (!params[0] || !params[0].function) {
        throw new Error("Invalid foreign call parameters");
    }

    const functionName = params[0].function;
    const inputs = params[0].inputs[0]; // First input array

    try {
        let result: string;
        
        // Convert hex strings back to bytes
        const data: number[] = inputs.map(hex => parseInt(hex.toString(), 16));
        
        switch (functionName) {
            case "base64_encode_standard":
                result = base64EncodeStandard(data);
                break;
                
            case "base64_encode_standard_no_pad":
                result = base64EncodeStandardNoPad(data);
                break;
                
            case "base64_encode_url_safe":
                result = base64EncodeUrlSafe(data);
                break;
                
            case "base64_encode_url_safe_with_pad":
                result = base64EncodeUrlSafeWithPad(data);
                break;
                
                
            default:
                throw new Error(`Unknown function: ${functionName}`);
        }

        // Convert the result string back to array of hex values
        const resultBytes: string[] = Array.from(Buffer.from(result, 'utf8')).map(b => b.toString(16).padStart(2, '0'));
    
        
        return { values: [resultBytes] };
    } catch (error) {
        console.error("Error in foreign call:", error);
        throw error;
    }
});

app.post("/", (req: Request, res: Response) => {
    const jsonRPCRequest = req.body;
    server.receive(jsonRPCRequest).then((jsonRPCResponse) => {
        if (jsonRPCResponse) {
            res.json(jsonRPCResponse);
        } else {
            res.sendStatus(204);
        }
    }).catch((error: Error) => {
        console.error("RPC Error:", error);
        res.status(500).json({
            jsonrpc: "2.0",
            error: {
                code: -32603,
                message: "Internal error",
                data: error.message
            },
            id: jsonRPCRequest.id
        });
    });
});

const PORT: number = parseInt(process.env.RPC_PORT || "8095");
app.listen(PORT, () => {
    console.log(`Direct JSON RPC Server running on port ${PORT}`);
    console.log("Available methods:");
    console.log("- base64_encode_standard");
    console.log("- base64_encode_standard_no_pad");
    console.log("- base64_encode_url_safe");
    console.log("- base64_encode_url_safe_with_pad");
});
