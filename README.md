# noir_base64

A library to encode ASCII into Base64 and decode Base64 into ASCII

# Usage

### `fn base64_encode`
Takees an input byte array of ASCII characters and produces an output byte array of base64-encoded characters. The 6-bit base64 characters are packed into a concatenated byte array (e.g. 4 bytes of ASCII produce 3 bytes of encoded Base64)

### `fn base64_decode`
Takes an input byte array of packed base64 characters and produces an output byte array of ASCII characters (e.g. 3 input bytes of base64 produces 4 output bytes of ASCII)

### `fn base64_encode_elements`
Takes an input byte array of ASCII characters and produces an output byte array of base64-encoded characters. Data is not packed i.e. each output array element maps to a 6-bit base64 character

### `fn base64_decode_elements`
Takes an input byte array of base64 characters and produces an output byte array of ASCII characters. Input data is not packed i.e. each input element maps to a 6-bit base64 character

### Example usage
(see tests in `lib.nr` for more examples)

```
use dep::noir_base64;
fn encode() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    // Translated directly to ASCII
    let input: [u8; 44] = [
        71, 120, 77, 108, 103,
        119, 76, 105, 121, 112,
        110, 86, 114, 69, 50,
        67, 48, 83, 102, 52,
        121, 122, 104, 99, 87,
        84, 107, 65, 104, 83,
        90, 53, 43, 87, 69,
        82, 104, 75, 104, 88,
        116, 108, 85, 61
    ];

    // will produce packed byte array of base64 chars:
    /*
    [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ]
    */
    let result: [u8; 32] = noir_base64::base64_encode(input);
}
```

# Costs

`base64_encode_elements` will encode an array of 44 ASCII bytes in ~470 gates, plus a ~256 gate cost to initialize an encoding lookup table (the initialization cost is incurred once regardless of the number of decodings)

