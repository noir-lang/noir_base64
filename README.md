# noir_base64

A library to encode ASCII into Base64 and decode Base64 into ASCII.

## Dependencies

- Noir ≥v0.34.0
- Compatible version of a proving backend, eg Barretenberg

Refer to [Noir's docs](https://noir-lang.org/docs/getting_started/installation/) and [Barretenberg's docs](https://github.com/AztecProtocol/aztec-packages/blob/master/barretenberg/cpp/src/barretenberg/bb/readme.md#installation) for installation steps.

## Installation

In your _Nargo.toml_ file, add the version of this library you would like to install under dependency:

```
[dependencies]
noir_base64 = { tag = "v0.2.0", git = "https://github.com/noir-lang/noir_base64" }
```
## Quickstart

The library offers 4 functions; `fn base64_encode`, `fn base64_decode`, `fn base64_encode_elements` & `fn base64_decode_elements`. Find descriptions per method below. 

In this example we take input `"Noir"` represented in ASCII, and encode this into Base64. The result is either "packed" together or given as separate elements. (Refer to the method descriptions below.)

Define the input in ASCII (`"N"` = 78, `"o"`= 111, `"i"`= 105, `"r"`= 114):
```rust
let input: [u8; 4] = [78, 111, 105, 114];
```

Encode either into a concatenated array or each Base64 element in a separate byte; Base64 values only take up 6 bits of space, see full explanation of the conversion + mapping table below.

```rust
// Packed
let result_packed: [u8; 3] = noir_base64::base64_encode(input);
assert(result_packed == [54, 136, 171]);

// In separate elements
let result_elements: [u8; 4] = noir_base64::base64_encode_elements(input);
assert(result_elements == [13, 40, 34, 43]);
```

A larger example:

```rust
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

See more examples in `lib.nr` and the `examples` folder. 

## Conversion explainer

[Base64](https://datatracker.ietf.org/doc/html/rfc4648#section-4) is a 6-bit encoding system (`0` to `63`).

[ASCII](https://www.ascii-code.com/) is a 7-bit character code ( `0` to `127`).

Note that the character set of ASCII is larger than that of Base64. When encoding ASCII into Base64, the special characters that exist in ASCII but not in Base64 are mapped to `0`.

For encoding and decoding the library uses lookup tables. The following table shows the mapping from ASCII <-> Base64. (See for the expanded version below.)

| Character | Decimal in ASCII | Decimal in Base64 |
|:----------------|:-----------------:|:------------------:|
| `+`             | 43               | 62                |
| `/`             | 47               | 63                |
| `0-9`           | 48,..,57          | 52,..,61           |
| `A-Z`           | 65,..,90          | 0,..,25            |
| `a-z`           | 97,..,122         | 26,..,51           |

### Example

For example for input "Noir" in ASCII, we have `"N"` = 78, `"o"`= 111, `"i"`= 105, `"r"`= 114:
```rust
let input_ascii: [u8; 4] = [78, 111, 105, 114];
```

The output in Base64 will be:
- `N` -> 13
- `o` -> 40
- `i` -> 34
- `r` -> 43

Base64 values are 6 bits and this library offers 2 way to output the result; `base64_encode` or `base64_encode_elements`. 

For `base64_encode_elements` each value is stored in a different byte, which in this case results in: `[13, 40, 34, 43]`.
```rust
let result_elements: [u8; 4] = noir_base64::base64_encode_elements(input);
assert(result_elements == [13, 40, 34, 43]);
```

For `base64_encode` concatenate the values and then split them up into bytes. As follows:
1. Rewrite all values to binary:
```
13      |   40    |   34    |   43    <- Decimal representation
001101  | 101000  | 100010  | 101011  <- Binary representation
```
2. Glue together
```
001101101000100010101011
```
3. Split up in chunks of 8 bits
```
00110110 | 10001000 | 10101011
```
4. Convert to decimal: `[54, 136, 171]`

```rust
let result_packed: [u8; 3] = noir_base64::base64_encode(input);
assert(result_packed == [54, 136, 171]);
```

## Methods

### `fn base64_encode`
Takees an input byte array of ASCII characters and produces an output byte array of base64-encoded characters. The 6-bit base64 characters are packed into a concatenated byte array (e.g. 4 bytes of ASCII produce 3 bytes of encoded Base64)

### `fn base64_decode`
Takes an input byte array of packed base64 characters and produces an output byte array of ASCII characters (e.g. 3 input bytes of base64 produces 4 output bytes of ASCII)

### `fn base64_encode_elements`
Takes an input byte array of ASCII characters and produces an output byte array of base64-encoded characters. Data is not packed i.e. each output array element maps to a 6-bit base64 character

### `fn base64_decode_elements`
Takes an input byte array of base64 characters and produces an output byte array of ASCII characters. Input data is not packed i.e. each input element maps to a 6-bit base64 character

## Costs

`base64_encode_elements` will encode an array of 44 ASCII bytes in ~470 gates, plus a ~256 gate cost to initialize an encoding lookup table (the initialization cost is incurred once regardless of the number of decodings)

## Base64 Encoding Table (Extended)

| Character | Decimal in ASCII | Decimal in Base64 |
|:----------|:-----------------|:------------------|
| `+`       | 43               | 62                |
| `/`       | 47               | 63                |
| `0`       | 48               | 52                |
| `1`       | 49               | 53                |
| `2`       | 50               | 54                |
| `3`       | 51               | 55                |
| `4`       | 52               | 56                |
| `5`       | 53               | 57                |
| `6`       | 54               | 58                |
| `7`       | 55               | 59                |
| `8`       | 56               | 60                |
| `9`       | 57               | 61                |
| `A`       | 65               | 0                 |
| `B`       | 66               | 1                 |
| `C`       | 67               | 2                 |
| `D`       | 68               | 3                 |
| `E`       | 69               | 4                 |
| `F`       | 70               | 5                 |
| `G`       | 71               | 6                 |
| `H`       | 72               | 7                 |
| `I`       | 73               | 8                 |
| `J`       | 74               | 9                 |
| `K`       | 75               | 10                |
| `L`       | 76               | 11                |
| `M`       | 77               | 12                |
| `N`       | 78               | 13                |
| `O`       | 79               | 14                |
| `P`       | 80               | 15                |
| `Q`       | 81               | 16                |
| `R`       | 82               | 17                |
| `S`       | 83               | 18                |
| `T`       | 84               | 19                |
| `U`       | 85               | 20                |
| `V`       | 86               | 21                |
| `W`       | 87               | 22                |
| `X`       | 88               | 23                |
| `Y`       | 89               | 24                |
| `Z`       | 90               | 25                |
| `a`       | 97               | 26                |
| `b`       | 98               | 27                |
| `c`       | 99               | 28                |
