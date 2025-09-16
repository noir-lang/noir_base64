use crate::encoder::{
    Base64EncodeBE as BASE64_ENCODER, Base64EncodeBENoPad as BASE64_NO_PAD_ENCODER,
};

// Oracle function for standard base64 encoding
#[oracle(base64_encode_standard)]
unconstrained fn rust_base64_encode_standard(input: [u8; 20]) -> [u8; 28] {}

// Oracle function for standard no-pad base64 encoding
#[oracle(base64_encode_standard_no_pad)]
unconstrained fn rust_base64_encode_standard_no_pad(input: [u8; 20]) -> [u8; 27] {}

// Wrapper functions to call the oracles
unconstrained fn get_rust_standard_encode(input: [u8; 20]) -> [u8; 28] {
    rust_base64_encode_standard(input)
}

unconstrained fn get_rust_no_pad_encode(input: [u8; 20]) -> [u8; 27] {
    rust_base64_encode_standard_no_pad(input)
}

// Unconstrained function to call oracles
unconstrained fn test_oracle_standard(input: [u8; 20]) -> bool {
    let noir_standard = BASE64_ENCODER::encode(input);
    let rust_standard = get_rust_standard_encode(input);
    noir_standard == rust_standard
}

unconstrained fn test_oracle_no_pad(input: [u8; 20]) -> bool {
    let noir_no_pad = BASE64_NO_PAD_ENCODER::encode(input);
    let rust_no_pad = get_rust_no_pad_encode(input);
    noir_no_pad == rust_no_pad
}

#[test]
fn test_oracle_standard_encoding(input: [u8; 20]) {
    let result = unsafe { test_oracle_standard(input) };
    assert(result, "Standard encoding oracle test failed");
}

#[test]
fn test_oracle_no_pad_encoding(input: [u8; 20]) {
    let result = unsafe { test_oracle_no_pad(input) };
    assert(result, "No-pad encoding oracle test failed");
}

