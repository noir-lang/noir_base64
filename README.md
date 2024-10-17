# noir_base64

A Base64 encoding/decoding library written in Noir which can encode arbitrary byte arrays into Base64 and decode Base64-encoded byte arrays (e.g. `"SGVsbG8gV29ybGQ=".as_bytes()`).

# Usage

### `fn base64_encode`
Takes an arbitrary byte array as input, unpacks it into Base64 values, then encodes each Base64 value into an ASCII character according to the [standard Base64 alphabet](https://datatracker.ietf.org/doc/html/rfc4648#section-4), to return a byte array representing the Base64 encoding. The encoded result is *not padded*, so padding must be handled separately.

### `fn base64_decode`
Takes an ASCII byte array that encodes a Base64 string and decodes it into bytes. Input data is expected to be unpadded, so padding characters will cause decoding to fail.

### `fn base64_encode_elements`
Takes an input byte array of ASCII characters and produces an output byte array of base64-encoded characters. Data is not packed i.e. each output array element maps to a 6-bit base64 character.

### `fn base64_decode_elements`
Takes an input byte array of base64 characters and produces an output byte array of ASCII characters. Input data is not packed i.e. each input element maps to a 6-bit base64 character. Input data is expected not to contain padding characters. Padding characters will cause decoding to fail.

### Example usage
(see tests in `lib.nr` for more examples)

```
use dep::noir_base64;
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded: str<118> = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg";

    let encoded:[u8; 118] = noir_base64::base64_encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = noir_base64::base64_decode(encoded);
    assert(decoded == input.as_bytes());
}
```

# Costs

- `base64_encode` will encode an array of 88 bytes in ~1182 gates, plus a ~64 gate cost to initialize the encoding lookup table (the initialization cost is incurred once regardless of the number of encodings).
- `base64_decode` will decode an array of 118 bytes in ~2150 gates, plus a ~256 gate cost to initialize the decoding lookup table (the initialization cost is incurred once regardless of the number of decodings).
