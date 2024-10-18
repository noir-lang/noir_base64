mod encoder;
pub use encoder::{STANDARD as BASE64_ENCODER_STANDARD, STANDARD_NO_PAD as BASE64_ENCODER_STANDARD_NO_PAD};

mod decoder;
pub use decoder::{STANDARD as BASE64_DECODER_STANDARD, STANDARD_NO_PAD as BASE64_DECODER_STANDARD_NO_PAD};

pub(crate) mod defaults {
    pub(crate) global BASE64_PADDING_CHAR: u8 = 61;
}

#[test]
fn encode_and_decode_no_pad() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded: str<118> = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg";

    let encoded:[u8; 118] = BASE64_ENCODER_STANDARD_NO_PAD.encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = BASE64_DECODER.decode(encoded);
    assert(decoded == input.as_bytes());
}
