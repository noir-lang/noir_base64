import { JSONRPCServer } from "json-rpc-2.0";
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import { createHash } from "crypto";

const app = express();
app.use(cors());
app.use(bodyParser.json());

const server = new JSONRPCServer();

// Direct base64 encoding functions
function base64EncodeStandard(data) {
    const buffer = Buffer.from(data);
    return buffer.toString('base64');
}

function base64EncodeStandardNoPad(data) {
    const buffer = Buffer.from(data);
    return buffer.toString('base64').replace(/=/g, '');
}

// Add the oracle method for base64 encoding
server.addMethod("resolve_foreign_call", async (params) => {
    console.log("Received foreign call:", JSON.stringify(params, null, 2));
    
    if (!params[0] || !params[0].function) {
        throw new Error("Invalid foreign call parameters");
    }

    const functionName = params[0].function;
    const inputs = params[0].inputs[0]; // First input array

    try {
        let result;
        
        // Convert hex strings back to bytes
        const data = inputs.map(hex => parseInt(hex, 16));
        
        switch (functionName) {
            case "base64_encode_standard":
                result = base64EncodeStandard(data);
                break;
                
            case "base64_encode_standard_no_pad":
                result = base64EncodeStandardNoPad(data);
                break;
                
            default:
                throw new Error(`Unknown function: ${functionName}`);
        }

        // Convert the result string back to array of hex values
        const resultBytes = Array.from(Buffer.from(result, 'utf8')).map(b => b.toString(16).padStart(2, '0'));
        
        console.log(`Function: ${functionName}, Input: ${data.length} bytes, Output: ${result}`);
        
        return { values: [resultBytes] };
    } catch (error) {
        console.error("Error in foreign call:", error);
        throw error;
    }
});

app.post("/", (req, res) => {
    const jsonRPCRequest = req.body;
    server.receive(jsonRPCRequest).then((jsonRPCResponse) => {
        if (jsonRPCResponse) {
            res.json(jsonRPCResponse);
        } else {
            res.sendStatus(204);
        }
    }).catch((error) => {
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

const PORT = 5556;
app.listen(PORT, () => {
    console.log(`Direct JSON RPC Server running on port ${PORT}`);
    console.log("Available methods:");
    console.log("- base64_encode_standard");
    console.log("- base64_encode_standard_no_pad");
});
