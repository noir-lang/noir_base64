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

// Main function to test both implementations
unconstrained fn main(input: [u8; 20]) {
    // Get Noir implementation results
    let noir_standard = BASE64_ENCODER::encode(input);
    let noir_no_pad = BASE64_NO_PAD_ENCODER::encode(input);

    // Get Rust implementation results via oracle
    let rust_standard = get_rust_standard_encode(input);
    let rust_no_pad = get_rust_no_pad_encode(input);

    // Compare results - they should be equal
    assert(noir_standard == rust_standard, "Standard encoding mismatch");
    assert(noir_no_pad == rust_no_pad, "No-pad encoding mismatch");
}

// Unconstrained function to safely call oracles
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
fn test_oracle_standard_encoding() {
    let input = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    let result = unsafe { test_oracle_standard(input) };
    assert(result, "Standard encoding oracle test failed");
}

#[test]
fn test_oracle_no_pad_encoding() {
    let input = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
    let result = unsafe { test_oracle_no_pad(input) };
    assert(result, "No-pad encoding oracle test failed");
}

#[test]
fn test_oracle_random_data() {
    let input = [255, 128, 64, 32, 16, 8, 4, 2, 1, 0, 255, 128, 64, 32, 16, 8, 4, 2, 1, 0];
    let result = unsafe { test_oracle_standard(input) };
    assert(result, "Random data standard encoding oracle test failed");
    let result2 = unsafe { test_oracle_no_pad(input) };
    assert(result2, "Random data no-pad encoding oracle test failed");
}
