use super::defaults::{BASE64_ELEMENTS_PER_CHUNK, BASE64_PADDING_CHAR, BYTES_PER_CHUNK};

pub global STANDARD: Base64DecodeBE = Base64DecodeBE::new(true);
pub global STANDARD_NO_PAD: Base64DecodeBE = Base64DecodeBE::new(false);
pub global URL_SAFE: Base64DecodeBE = Base64DecodeBE::base64url(false);
pub global URL_SAFE_WITH_PAD: Base64DecodeBE = Base64DecodeBE::base64url(true);

global INVALID_VALUE: u8 = 255;
struct Base64DecodeBE {
    // for some reason, if the lookup table is not defined in a struct, access costs are expensive and ROM tables aren't being used :/
    table: [u8; 256],
    pad: bool,
}
impl Base64DecodeBE {
    /// Creates a new decoder that uses the standard Base64 Alphabet (base64) specified in RFC 4648
    /// https://datatracker.ietf.org/doc/html/rfc4648#section-4
    fn new(pad: bool) -> Self {
        Base64DecodeBE {
            table: [
                // 0-42
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                62, // 43
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE, // 44-46
                63, // 47
                52,
                53,
                54,
                55,
                56,
                57,
                58,
                59,
                60,
                61, // 48-57
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE, // 58-64
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23,
                24,
                25, // 65-90 (A-Z)
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE, // 91-96
                26,
                27,
                28,
                29,
                30,
                31,
                32,
                33,
                34,
                35,
                36,
                37,
                38,
                39,
                40,
                41,
                42,
                43,
                44,
                45,
                46,
                47,
                48,
                49,
                50,
                51, // 97-122 (a-z)
                // 123-255
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
            ],
            pad,
        }
    }

    // Creates a new decoder that uses the URL and Filename Safe Alphabet specified in RFC 4648
    // https://datatracker.ietf.org/doc/html/rfc4648#section-5
    fn base64url(pad: bool) -> Self {
        Base64DecodeBE {
            table: [
                // 0-44 (no mapping)
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                62, // 45 (-)
                INVALID_VALUE,
                INVALID_VALUE, // 46-47 (no mapping)
                52,
                53,
                54,
                55,
                56,
                57,
                58,
                59,
                60,
                61, // 48-57 (0-9)
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE, // 58-64 (no mapping)
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23,
                24,
                25, // 65-90 (A-Z)
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE, // 91-94 (no mapping)
                63, // 95 (_)
                INVALID_VALUE, // 96 (no mapping)
                26,
                27,
                28,
                29,
                30,
                31,
                32,
                33,
                34,
                35,
                36,
                37,
                38,
                39,
                40,
                41,
                42,
                43,
                44,
                45,
                46,
                47,
                48,
                49,
                50,
                51, // 97-122 (a-z)
                // 123-255
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
                INVALID_VALUE,
            ],
            pad,
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }

    /**
    * @brief Take an array of ASCII values and convert into *packed* byte array of base64 values
    *        Each Base64 value is 6 bits. This method will produce a byte array where data is concatenated so that there are no sparse bits
    *        (e.g. encoding 4 ASCII values produces 24 bits of Base64 data = 3 bytes of output data)
    **/
    pub fn decode<let InputElements: u32, let OutputBytes: u32>(
        self,
        input: [u8; InputElements],
    ) -> [u8; OutputBytes] {
        let rem = OutputBytes % 3;
        // Calculate the number of padding characters and the length of the input without padding
        let num_padding_chars = if rem == 1 {
            2
        } else if rem == 2 {
            1
        } else {
            0
        };

        // Assert that the output length & input length are correct
        // Every 3 output chars will be encoded as 4 base64 input chars
        let encoded_length = (OutputBytes + 2) / 3 * 4; // ceil(input * 4 / 3)
        if self.pad {
            assert(
                encoded_length == InputElements,
                f"DecodeError: invalid input length for specified output length. Expected {encoded_length} input elements, but got {InputElements}.",
            );
            // enforce Base64 padding is valid
            if num_padding_chars == 2 {
                let offset = InputElements - 1;
                assert(
                    input[offset] == BASE64_PADDING_CHAR,
                    f"DecodeError: expected padding at offset {offset}.",
                );
                let offset = InputElements - 2;
                assert(
                    input[offset] == BASE64_PADDING_CHAR,
                    f"DecodeError: expected padding at offset {offset}.",
                );
            } else if num_padding_chars == 1 {
                let offset = InputElements - 1;
                assert(
                    input[InputElements - 1] == BASE64_PADDING_CHAR,
                    f"DecodeError: expected padding at offset {offset}.",
                );
            }
        } else {
            let expected = encoded_length - num_padding_chars;
            assert(
                encoded_length - num_padding_chars == InputElements,
                f"DecodeError: invalid input length for specified output length. Expected {expected} input elements, but got {InputElements}.",
            );
        }

        let mut result: [u8; OutputBytes] = [0; OutputBytes];
        let num_chunks = (InputElements / BASE64_ELEMENTS_PER_CHUNK)
            + (InputElements % BASE64_ELEMENTS_PER_CHUNK != 0) as u32;

        if num_chunks > 0 {
            let final_chunk = num_chunks - 1;

            for i in 0..final_chunk {
                let mut slice: Field = 0;
                for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                    slice *= 64;
                    let offset = i * BASE64_ELEMENTS_PER_CHUNK + j;
                    let input_byte = input[offset];
                    let decoded = self.get(input_byte as Field);
                    assert(
                        decoded != INVALID_VALUE,
                        f"DecodeError: invalid symbol {input_byte}, offset {offset}.",
                    );
                    slice += decoded as Field;
                }
                let slice_bytes: [u8; 30] = slice.to_be_bytes();
                for j in 0..BYTES_PER_CHUNK {
                    result[i * BYTES_PER_CHUNK + j] = slice_bytes[j];
                }
            }

            // process the final chunk, which may contain padding
            let base64_offset: u32 = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
            let byte_offset = final_chunk * BYTES_PER_CHUNK;
            let base64_elements_in_final_chunk = if self.pad {
                InputElements - base64_offset - num_padding_chars
            } else {
                InputElements - base64_offset
            };

            // pack the base64 values into the field element
            let mut slice: Field = 0;
            for j in 0..base64_elements_in_final_chunk {
                slice *= 64;
                let offset = base64_offset + j;
                let input_byte = input[offset];
                let decoded = self.get(input_byte as Field);
                assert(
                    decoded != INVALID_VALUE,
                    f"DecodeError: invalid symbol {input_byte}, offset {offset}.",
                );
                slice += decoded as Field;
            }
            for _ in base64_elements_in_final_chunk..BASE64_ELEMENTS_PER_CHUNK {
                slice *= 64;
            }

            // TODO: check is it cheaper to use a constant value in `to_be_bytes` or can we use `bytes_in_final_chunk`?
            // extract the bytes from the Field element
            let slice_bytes: [u8; 30] = slice.to_be_bytes();
            let num_bytes_in_final_chunk = OutputBytes - byte_offset;
            for i in 0..num_bytes_in_final_chunk {
                result[byte_offset + i] = slice_bytes[i];
            }
        }

        result
    }

    /// Take a `BoundedVec` input containing up to `MAX_INPUT_LEN` bytes of base64-encoded
    /// data and decode the first `input.len()` bytes.
    pub fn decode_var<let MAX_INPUT_LEN: u32, let MAX_OUTPUT_LEN: u32>(
        self,
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, MAX_OUTPUT_LEN> {
        // calculate the number of padding characters from the input data
        let num_padding_chars = if self.pad & input.len() > 0 {
            assert(
                input.len() % 4 == 0,
                "DecodeError: the input length of padded base64 data should be a multiple of 4.",
            );
            let last_char = input.get(input.len() - 1);
            if last_char != BASE64_PADDING_CHAR {
                0
            } else if input.get(input.len() - 2) == BASE64_PADDING_CHAR {
                2
            } else {
                1
            }
        } else {
            0
        };

        let unpadded_input_len = input.len() - num_padding_chars;
        let decoded_length = unpadded_input_len * 3 / 4;
        assert(
            MAX_INPUT_LEN >= (MAX_OUTPUT_LEN + 2) / 3 * 4,
            "maximum input length is too short for the specified maximum output length",
        );

        let mut result: BoundedVec<u8, MAX_OUTPUT_LEN> = BoundedVec::new();

        let max_chunks = MAX_INPUT_LEN / BASE64_ELEMENTS_PER_CHUNK
            + (MAX_INPUT_LEN % BASE64_ELEMENTS_PER_CHUNK != 0) as u32;
        let num_chunks = (input.len() / BASE64_ELEMENTS_PER_CHUNK)
            + (input.len() % BASE64_ELEMENTS_PER_CHUNK != 0) as u32;

        if num_chunks > 0 {
            let final_chunk = num_chunks - 1;

            for i in 0..max_chunks {
                if (i < final_chunk) {
                    let mut slice: Field = 0;
                    for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                        slice *= 64;
                        let offset = i * BASE64_ELEMENTS_PER_CHUNK + j;
                        let input_byte = input.get_unchecked(offset);
                        let decoded = self.get(input_byte as Field);
                        assert(
                            decoded != INVALID_VALUE,
                            f"DecodeError: invalid symbol {input_byte}, offset {offset}.",
                        );
                        slice += decoded as Field;
                    }
                    let slice_bytes: [u8; 30] = slice.to_be_bytes();
                    for j in 0..BYTES_PER_CHUNK {
                        result.push(slice_bytes[j]);
                    }
                }
            }

            // process the final chunk, which may contain padding
            let base64_offset: u32 = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
            let byte_offset = final_chunk * BYTES_PER_CHUNK;
            let base64_elements_in_final_chunk = if self.pad {
                input.len() - base64_offset - num_padding_chars
            } else {
                input.len() - base64_offset
            };

            // pack the base64 values into the field element
            let mut slice: Field = 0;
            for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                slice *= 64;
                if (j < base64_elements_in_final_chunk) {
                    let offset = base64_offset + j;
                    let input_byte = input.get_unchecked(offset);
                    let decoded = self.get(input_byte as Field);
                    assert(
                        decoded != INVALID_VALUE,
                        f"DecodeError: invalid symbol {input_byte}, offset {offset}.",
                    );
                    slice += decoded as Field;
                }
            }

            // extract the bytes from the Field element
            let slice_bytes: [u8; 30] = slice.to_be_bytes();
            let num_bytes_in_final_chunk = decoded_length - byte_offset;
            for i in 0..BYTES_PER_CHUNK {
                if (i < num_bytes_in_final_chunk) {
                    result.push(slice_bytes[i]);
                }
            }
        }

        result
    }
}

#[test]
fn test_decode_empty() {
    let input: [u8; 0] = [];
    let expected: [u8; 0] = [];
    let result = STANDARD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_padding() {
    // f
    let input: [u8; 4] = [90, 103, 61, 61];
    let expected: [u8; 1] = [102];
    let result = STANDARD.decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 4] = [90, 109, 56, 61];
    let expected: [u8; 2] = [102, 111];
    let result = STANDARD.decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = STANDARD.decode(input);

    assert(result == expected);
}

#[test]
fn test_decode_standard_no_pad() {
    // f
    let input: [u8; 2] = [90, 103];
    let expected: [u8; 1] = [102];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 3] = [90, 109, 56];
    let expected: [u8; 2] = [102, 111];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = STANDARD_NO_PAD.decode(input);

    assert(result == expected);
}

#[test]
fn test_decode_max_byte() {
    let expected: [u8; 1] = [255];

    let input: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    let result: [u8; 1] = STANDARD.decode(input);
    assert(result == expected);

    let input: [u8; 2] = [47, 119]; // "/w"
    let result: [u8; 1] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);

    let input: [u8; 4] = [95, 119, 61, 61]; // "_w=="
    let result: [u8; 1] = URL_SAFE_WITH_PAD.decode(input);
    assert(result == expected);

    let input: [u8; 2] = [95, 119]; // "_w"
    let result: [u8; 1] = URL_SAFE.decode(input);
    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 255, offset 0")]
fn test_decode_invalid() {
    let input: [u8; 2] = [255, 255];
    let _: [u8; 1] = STANDARD_NO_PAD.decode(input);
}

#[test(should_fail_with = "DecodeError: invalid input length for specified output length. Expected 3 input elements, but got 4.")]
fn test_decode_standard_no_pad_fail_with_padding() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_standard() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = STANDARD.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 95, offset 0")]
fn test_decode_underscore_with_standard() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let _: [u8; 2] = STANDARD.decode(input);
}

#[test]
fn test_decode_url_safe_with_pad() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE_WITH_PAD.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 47, offset 0")]
fn test_decode_slash_with_url_safe() {
    // test decoding / and +
    let input: [u8; 3] = [47, 43, 65];
    let _: [u8; 2] = URL_SAFE.decode(input);
}

#[test]
fn test_decode_url_safe() {
    // test decoding _ and -
    let input: [u8; 3] = [95, 45, 65];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE.decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid input length for specified output length. Expected 3 input elements, but got 4.")]
fn test_decode_url_safe_no_pad_fail_with_padding() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = URL_SAFE.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_ascii() {
    // base64: SGVsbG8gV29ybGQh
    let input: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];
    // "Hello World!"
    let expected: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];

    // all configurations should decode the same way
    let result: [u8; 12] = STANDARD.decode(input);
    assert(result == expected);
    let result: [u8; 12] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 12] = URL_SAFE_WITH_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 12] = URL_SAFE.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_utf8() {
    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let input: [u8; 36] = [
        52, 52, 71, 84, 52, 52, 75, 84, 52, 52, 71, 114, 52, 52, 71, 104, 52, 52, 71, 118, 52, 52,
        67, 66, 53, 76, 105, 87, 53, 53, 87, 77, 55, 55, 121, 66,
    ];
    // non-ascii utf-8: "Hello, World!" in Japanese
    let expected: [u8; 27] = [
        227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 129, 175, 227, 128, 129,
        228, 184, 150, 231, 149, 140, 239, 188, 129,
    ];

    // all configurations should decode the same way
    let result: [u8; 27] = STANDARD.decode(input);
    assert(result == expected);
    let result: [u8; 27] = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 27] = URL_SAFE_WITH_PAD.decode(input);
    assert(result == expected);
    let result: [u8; 27] = URL_SAFE.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_multi_chunks() {
    // "The quick brown fox jumps over the lazy dog."
    let expected: [u8; 44] = [
        84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32,
        106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121,
        32, 100, 111, 103, 46,
    ];

    let input: [u8; 60] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52, 61,
    ];
    let result: [u8; 44] = STANDARD.decode(input);
    assert(result == expected);

    let input: [u8; 59] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ];
    let result = STANDARD_NO_PAD.decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_with_padding() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    // Translated directly to ASCII
    let input: [u8; 44] = [
        71, 120, 77, 108, 103, 119, 76, 105, 121, 112, 110, 86, 114, 69, 50, 67, 48, 83, 102, 52,
        121, 122, 104, 99, 87, 84, 107, 65, 104, 83, 90, 53, 43, 87, 69, 82, 104, 75, 104, 88, 116,
        108, 85, 61,
    ];

    let result: [u8; 32] = STANDARD.decode(input);
    let expected: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172, 77, 130, 209, 39, 248, 203, 56, 92, 89, 57, 0,
        133, 38, 121, 249, 97, 17, 132, 168, 87, 182, 85,
    ];
    assert(result == expected);
}

#[test]
fn test_decode_var_empty() {
    let input: BoundedVec<u8, 0> = BoundedVec::new();
    let expected: BoundedVec<u8, 0> = BoundedVec::new();
    let result = STANDARD.decode_var(input);
    assert(result == expected);
}

#[test]
fn test_decode_var_padding() {
    // f
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103, 61, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let result = STANDARD.decode_var(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let result = STANDARD.decode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 8> = BoundedVec::from_array([90, 109, 57, 118]);
    let expected: BoundedVec<u8, 6> = BoundedVec::from_array([102, 111, 111]);
    let result = STANDARD.decode_var(input);

    assert(result == expected);
}

#[test]
fn test_decode_var_standard_no_pad() {
    // f
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let result = STANDARD_NO_PAD.decode_var(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let result = STANDARD_NO_PAD.decode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let result = STANDARD_NO_PAD.decode_var(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 61, offset 3")]
fn test_decode_var_no_pad_fail_with_padding() {
    // test decoding / and +
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([47, 43, 65, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([255, 224]);
    let result = STANDARD_NO_PAD.decode_var(input);
    assert(result == expected);
}

#[test]
fn test_decode_var() {
    // base64: "SGVsbG8sIFdvcmxkIQ=="
    let input: BoundedVec<u8, 24> = BoundedVec::from_array([
        83, 71, 86, 115, 98, 71, 56, 115, 73, 70, 100, 118, 99, 109, 120, 107, 73, 81, 61, 61,
    ]);
    // base64: "SGVsbG8sIFdvcmxkIQ"
    let input_no_pad: BoundedVec<u8, 24> = BoundedVec::from_array([
        83, 71, 86, 115, 98, 71, 56, 115, 73, 70, 100, 118, 99, 109, 120, 107, 73, 81,
    ]);
    // "Hello, World!"
    let expected: BoundedVec<u8, 16> =
        BoundedVec::from_array([72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]);

    // all configurations should decode the same way
    let result = STANDARD.decode_var(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.decode_var(input_no_pad);
    assert(result == expected);
    let result = URL_SAFE_WITH_PAD.decode_var(input);
    assert(result == expected);
    let result = URL_SAFE.decode_var(input_no_pad);
    assert(result == expected);
}

#[test]
fn test_decode_var_multi_chunks() {
    // base64: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="
    let input: BoundedVec<u8, 64> = BoundedVec::from_array([
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52, 61,
    ]);
    // base64: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="
    let input_no_pad: BoundedVec<u8, 64> = BoundedVec::from_array([
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ]);
    // "The quick brown fox jumps over the lazy dog."
    let expected: BoundedVec<u8, 48> = BoundedVec::from_array([
        84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32,
        106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121,
        32, 100, 111, 103, 46,
    ]);

    // all configurations should give the same encoding
    let result = STANDARD.decode_var(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.decode_var(input_no_pad);
    assert(result == expected);
    let result = URL_SAFE_WITH_PAD.decode_var(input);
    assert(result == expected);
    let result = URL_SAFE.decode_var(input_no_pad);
    assert(result == expected);
}
