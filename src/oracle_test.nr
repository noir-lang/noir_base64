use crate::encoder::{
    Base64EncodeBE as BASE64_ENCODER, Base64EncodeBENoPad as BASE64_NO_PAD_ENCODER,
    Base64EncodeBEUrlSafe as BASE64_URL_SAFE_ENCODER,
    Base64EncodeBEUrlSafeWithPad as BASE64_URL_SAFE_WITH_PAD_ENCODER,
};

use crate::decoder::{
    Base64DecodeBE as BASE64_DECODER, Base64DecodeBENoPad as BASE64_NO_PAD_DECODER,
    Base64DecodeBEUrlSafe as BASE64_URL_SAFE_DECODER,
    Base64DecodeBEUrlSafeWithPad as BASE64_URL_SAFE_WITH_PAD_DECODER,
};

// Oracle function for standard base64 encoding (calls Node.js server)
#[oracle(base64_encode_standard)]
unconstrained fn node_base64_encode_standard(input: [u8; 20]) -> [u8; 28] {}

// Oracle function for standard no-pad base64 encoding (calls Node.js server)
#[oracle(base64_encode_standard_no_pad)]
unconstrained fn node_base64_encode_standard_no_pad(input: [u8; 20]) -> [u8; 27] {}

// Oracle function for URL-safe base64 encoding (calls Node.js server)
#[oracle(base64_encode_url_safe)]
unconstrained fn node_base64_encode_url_safe(input: [u8; 20]) -> [u8; 27] {}

// Oracle function for URL-safe base64 encoding with padding (calls Node.js server)
#[oracle(base64_encode_url_safe_with_pad)]
unconstrained fn node_base64_encode_url_safe_with_pad(input: [u8; 20]) -> [u8; 28] {}

// Wrapper functions to call the oracles
unconstrained fn get_node_standard_encode(input: [u8; 20]) -> [u8; 28] {
    node_base64_encode_standard(input)
}

unconstrained fn get_node_no_pad_encode(input: [u8; 20]) -> [u8; 27] {
    node_base64_encode_standard_no_pad(input)
}

unconstrained fn get_node_url_safe_encode(input: [u8; 20]) -> [u8; 27] {
    node_base64_encode_url_safe(input)
}

unconstrained fn get_node_url_safe_with_pad_encode(input: [u8; 20]) -> [u8; 28] {
    node_base64_encode_url_safe_with_pad(input)
}

// Unconstrained function to call oracles
unconstrained fn test_oracle_standard(input: [u8; 20]) -> bool {
    let noir_standard = BASE64_ENCODER::encode(input);
    let node_standard = get_node_standard_encode(input);
    noir_standard == node_standard
}

unconstrained fn test_oracle_no_pad(input: [u8; 20]) -> bool {
    let noir_no_pad = BASE64_NO_PAD_ENCODER::encode(input);
    let node_no_pad = get_node_no_pad_encode(input);
    noir_no_pad == node_no_pad
}

unconstrained fn test_oracle_url_safe(input: [u8; 20]) -> bool {
    let noir_url_safe = BASE64_URL_SAFE_ENCODER::encode(input);
    let node_url_safe = get_node_url_safe_encode(input);
    noir_url_safe == node_url_safe
}

unconstrained fn test_oracle_url_safe_with_pad(input: [u8; 20]) -> bool {
    let noir_url_safe_with_pad = BASE64_URL_SAFE_WITH_PAD_ENCODER::encode(input);
    let node_url_safe_with_pad = get_node_url_safe_with_pad_encode(input);
    noir_url_safe_with_pad == node_url_safe_with_pad
}

#[test]
unconstrained fn test_oracle_standard_encoding(input: [u8; 20]) {
    let result = test_oracle_standard(input);
    assert(result, "Standard encoding oracle test failed");
    let result = test_oracle_no_pad(input);
    assert(result, "No-pad encoding oracle test failed");
}

#[test]
unconstrained fn test_oracle_url_safe_encoding(input: [u8; 20]) {
    let result = test_oracle_url_safe(input);
    assert(result, "URL-safe encoding oracle test failed");
    let result = test_oracle_url_safe_with_pad(input);
    assert(result, "URL-safe with padding encoding oracle test failed");
}

#[test]
fn test_standard_decoding(input: [u8; 20]) {
    let noir_encoded = BASE64_ENCODER::encode(input);
    let noir_decoded = BASE64_DECODER::decode(noir_encoded);
    assert(noir_decoded == input, "Standard round-trip test failed");
    let node_encoded = BASE64_NO_PAD_ENCODER::encode(input);
    let noir_decoded = BASE64_NO_PAD_DECODER::decode(node_encoded);
    assert(noir_decoded == input, "Standard no-pad round-trip test failed");
}

#[test]
fn test_url_safe_decoding(input: [u8; 20]) {
    let node_encoded = BASE64_URL_SAFE_ENCODER::encode(input);
    let noir_decoded = BASE64_URL_SAFE_DECODER::decode(node_encoded);
    assert(noir_decoded == input, "URL-safe round-trip test failed");
    let node_encoded = BASE64_URL_SAFE_WITH_PAD_ENCODER::encode(input);
    let noir_decoded = BASE64_URL_SAFE_WITH_PAD_DECODER::decode(node_encoded);
    assert(noir_decoded == input, "URL-safe with padding round-trip test failed");
}
