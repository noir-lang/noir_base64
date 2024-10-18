mod encoder;
pub use encoder::ENCODER as BASE64_ENCODER;

mod decoder;
pub use decoder::DECODER as BASE64_DECODER;

#[test]
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded: str<118> = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg";

    let encoded:[u8; 118] = BASE64_ENCODER.encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = BASE64_DECODER.decode(encoded);
    assert(decoded == input.as_bytes());
}
