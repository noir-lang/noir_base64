# noir_base64

A Base64 encoding/decoding library written in Noir which can encode arbitrary byte arrays into Base64 and decode Base64-encoded byte arrays (e.g. `"SGVsbG8gV29ybGQ=".as_bytes()`).

## Noir Version Compatibility

This library is tested with all Noir stable releases from v0.36.0.

## Usage
### Configuration
Start by selecting the encoder or decoder for your configuration. These are defined separately so that only one lookup table will be instantiated at a time, since many cases will require either an encoder or a decoder but not both.

RFC 4648 specifies multiple alphabets, including the [standard Base 64 Alphabet](https://datatracker.ietf.org/doc/html/rfc4648#section-4) known as `base64` and the ["URL and Filename Safe Alphabet"](https://datatracker.ietf.org/doc/html/rfc4648#section-5) known as `base64url`. It also specifies that [padding](https://datatracker.ietf.org/doc/html/rfc4648#section-3.2) should be required in the general case but can be explicitly omitted as an option.

Available encoder configurations:
- `BASE64_ENCODER`: uses the standard alphabet (base64) and adds padding.
- `BASE64_NO_PAD_ENCODER`: uses the standard alphabet (base64), but omits padding.
- `BASE64_URL_ENCODER`: uses the "URL and Filename Safe Alphabet" (base64url) and omits padding, which is common for `base64url` when the length is implicitly known, as in this case.
- `BASE64_URL_WITH_PAD_ENCODER`: uses the "URL and Filename Safe Alphabet" (base64url) and adds padding.

Available decoder configurations:
- `BASE64_DECODER`: uses the standard alphabet (base64) and expects correct padding.
- `BASE64_NO_PAD_DECODER`: uses the standard alphabet (base64), but expects all padding characters to have been stripped, which is common for `base64url` when the length is implicitly known, as in this case. A padding character encountered during decoding will trigger an error.
- `BASE64_URL_DECODER`: uses the "URL and Filename Safe Alphabet" (base64url), but expects all padding characters to have been stripped. A padding character encountered during decoding will trigger an error.
- `BASE64_URL_WITH_PAD_DECODER`: uses the "URL and Filename Safe Alphabet" (base64url) and expects correct padding.

### `fn encode`
Takes an arbitrary byte array as input, encodes it in Base64 according to the alphabet and padding rules specified by the configuration, then encodes each Base64 character into UTF-8 to return a byte array representing the Base64 encoding.

```
// bytes: [u8; N]
let base64 = BASE64_ENCODER::encode(bytes);
```

### `fn decode`
Takes a utf-8 byte array that encodes a Base64 string and attempts to decoded it into bytes according to the provided configuration specifying the alphabet and padding rules.

```
// base64: [u8; N]
let bytes = BASE64_DECODER::decode(base64);
```

## Example usage
(see tests in `lib.nr` for more examples)

```
fn encode_and_decode() {
    let input: str<88> = "The quick brown fox jumps over the lazy dog, while 42 ravens perch atop a rusty mailbox.";
    let base64_encoded = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZywgd2hpbGUgNDIgcmF2ZW5zIHBlcmNoIGF0b3AgYSBydXN0eSBtYWlsYm94Lg==";

    let encoded:[u8; 120] = noir_base64::BASE64_ENCODER::encode(input.as_bytes());
    assert(encoded == base64_encoded.as_bytes());

    let decoded: [u8; 88] = noir_base64::BASE64_DECODER::decode(encoded);
    assert(decoded == input.as_bytes());
}
```


## Costs

All of the benchmarks below are for the [Barretenberg proving backend](https://github.com/AztecProtocol/aztec-packages/tree/master/barretenberg). 

After the initial setup cost it is often cheaper to decode than to encode, as shown by the numbers below where the encode/decode were run over the same pairs of unencoded and base64-encoded text.

| UTF-8 Length | Base64 Length | # times | # Gates to Encode | # Gates to Decode |
| ------------ | ------------- | ------- | ----------------- | ----------------- |
| 12           | 16            | 1       | 2946              | 1065              |
| 12           | 16            | 2       | 3057              | 1114              |
| 12           | 16            | 3       | 3166              | 1163              |
| 610          | 816           | 1       | 7349              | 8062              |
| 610          | 816           | 2       | 10993             | 9181              |
| 610          | 816           | 3       | 14597             | 10239             |

### `encode`
Costs are equivalent for all encoder configurations. 

- encoding an array of 12 bytes into 16 base64 characters requires ~110 gates plus an initial setup cost of ~2836 gates. (Gate counts for encoding the same array 1, 2, and 3 were 2946, 3057, 3166 respectively.)
- encoding an array of 610 input bytes requires ~3625 gates plus an initial setup cost of ~3700 gates. (Gate counts for encoding the same array 1, 2, 3, 4 times were 7349, 10993, 14597, and 18200 respectively.)

### `decode`
Decoding padded inputs costs 1-2 gates more than decoding unpadded inputs. Since the difference is marginal, the numbers below are only for the padded case.

- decoding an array of 16 base64 characters bytes into 12 bytes requires ~49 gates plus an initial setup cost of ~1016 gates. (Gate counts for encoding the same array 1, 2, and 3 times were 1065, 1114, and 1163 respectively.)
- decoding an array of 816 base64 characters (including padding) into 610 input bytes requires ~1060 gates plus an initial setup cost of ~7000 gates. (Gate counts for decoding the same array 1, 2, 3, 4 times were 8062, 9181, 10239, and 11298 respectively.)