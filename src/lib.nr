//! Base64 Encoder and Decoder
//!
//! Encodings use the alphabets and padding rules specified in RFC-4648
//! (https://datatracker.ietf.org/doc/html/rfc4648):
//!
//! A 65-character subset of US-ASCII is used, enabling 6 bits to be represented per printable
//! character. (The extra 65th character, "=", is used to signify a special processing function.)
//!
//! The encoding process represents 24-bit groups of input bits as output strings of 4 encoded
//! characters. Proceeding from left to right, a 24-bit input group is formed by concatenating 3
//! 8-bit input groups. These 24 bits are then treated as 4 concatenated 6-bit groups, each of which
//! is translated into a single character in the base 64 alphabet.
//!
//! Each 6-bit group is used as an index into an array of 64 printable characters. The character
//! referenced by the index is placed in the output string.

mod encoder;
mod benchmarks;
mod tables;
mod boundary_check;
pub use encoder::{
    Base64EncodeBE as BASE64_ENCODER, Base64EncodeBENoPad as BASE64_NO_PAD_ENCODER,
    Base64EncodeBEUrlSafe as BASE64_URL_ENCODER,
    Base64EncodeBEUrlSafeWithPad as BASE64_URL_WITH_PAD_ENCODER,
};

mod decoder;
pub use decoder::{
    Base64DecodeBE as BASE64_DECODER, Base64DecodeBENoPad as BASE64_NO_PAD_DECODER,
    Base64DecodeBEUrlSafe as BASE64_URL_DECODER,
    Base64DecodeBEUrlSafeWithPad as BASE64_URL_WITH_PAD_DECODER,
};

pub(crate) mod defaults {
    pub(crate) global BASE64_PADDING_CHAR: u8 = 61;
    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // we pack 40 base64 values into a field element and convert into 30 bytes
    pub(crate) global BASE64_ELEMENTS_PER_CHUNK: u32 = 40;
    pub(crate) global BYTES_PER_CHUNK: u32 = 30;
    // when converting between ASCII and Base64 via lookup tables, an invalid result is -2^32
    pub(crate) global INVALID_VALUE: u8 = 255;
    pub(crate) global INVALID_DECODE_VALUE: Field = 0 - 0x100000000;
}

#[test]
fn encode_and_decode() {
    let input: str<88> =
        "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg==";

    let encoded: [u8; 120] = BASE64_ENCODER::encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = BASE64_DECODER::decode(encoded);
    assert(decoded == input.as_bytes());
}

#[test]
fn encode_and_decode_no_pad() {
    let input: str<88> =
        "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded: str<118> = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg";

    let encoded: [u8; 118] = BASE64_NO_PAD_ENCODER::encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = BASE64_NO_PAD_DECODER::decode(encoded);
    assert(decoded == input.as_bytes());
}
