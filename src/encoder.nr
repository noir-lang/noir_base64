use super::defaults::{BASE64_ELEMENTS_PER_CHUNK, BASE64_PADDING_CHAR, BYTES_PER_CHUNK};

pub global STANDARD: Base64EncodeBE = Base64EncodeBE::new(true);
pub global STANDARD_NO_PAD: Base64EncodeBE = Base64EncodeBE::new(false);
pub global URL_SAFE: Base64EncodeBE = Base64EncodeBE::base64url(false);
pub global URL_SAFE_WITH_PAD: Base64EncodeBE = Base64EncodeBE::base64url(true);

global CONVERT_MODULO3_TO_PADDING_BYTES: [u32; 3] = [0, 2, 1];
global PAD_1: [Field; 3] = [0, 1, 1];
global PAD_2: [Field; 3] = [0, 1, 0];

struct Base64EncodeBE {
    // for some reason, if the lookup table is not defined in a struct, access costs are expensive and ROM tables aren't being used :/
    table: [u8; 64],
    pad: bool,
}

impl Base64EncodeBE {
    /// Creates a new encoder that uses the standard Base64 Alphabet (base64) specified in RFC 4648
    /// (https://datatracker.ietf.org/doc/html/rfc4648#section-4)
    fn new(pad: bool) -> Self {
        Base64EncodeBE {
            // The alphabet values here are standard UTF-8 (and ASCII) byte encodings, so the index
            // in the table is the 6-bit Base64 value, and the value at that index is the UTF-8
            // encoding of that value.
            table: [
                65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
                86, 87, 88, 89, 90, // 0-25 (A-Z)
                97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113,
                114, 115, 116, 117, 118, 119, 120, 121, 122, // 26-51 (a-z)
                48, 49, 50, 51, 52, 53, 54, 55, 56, 57, // 0-9
                43, // +
                47, // /
            ],
            pad,
        }
    }

    // Creates a new encoder that uses the URL and Filename Safe Alphabet specified in RFC 4648
    // https://datatracker.ietf.org/doc/html/rfc4648#section-5
    fn base64url(pad: bool) -> Self {
        Base64EncodeBE {
            table: [
                65, 66, 67, 68, 69, 70, 71, 72, // A, B, C, D, E, F, G, H
                73, 74, 75, 76, 77, 78, 79, 80, // I, J, K, L, M, N, O, P
                81, 82, 83, 84, 85, 86, 87, 88, // Q, R, S, T, U, V, W, X
                89, 90, 97, 98, 99, 100, 101, 102, // Y, Z, a, b, c, d, e, f
                103, 104, 105, 106, 107, 108, 109, 110, // g, h, i, j, k, l, m, n
                111, 112, 113, 114, 115, 116, 117, 118, // o, p, q, r, s, t, u, v
                119, 120, 121, 122, 48, 49, 50, 51, // w, x, y, z, 0, 1, 2, 3
                52, 53, 54, 55, 56, 57, 45, 95, // 4, 5, 6, 7, 8, 9, -, _
            ],
            pad,
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }

    /**
    * @brief Take an array of ASCII values and convert into base64 values
    **/
    fn encode_elements<let InputElements: u32>(
        self,
        input: [u8; InputElements],
    ) -> [u8; InputElements] {
        let mut result: [u8; InputElements] = [0; InputElements];

        for i in 0..InputElements {
            result[i] = self.get(input[i] as Field);
        }
        result
    }

    pub fn encode_var_no_pad<let MAX_INPUT_LEN: u32>(
        self,
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2)) + (((MAX_INPUT_LEN % 3) / 2))> {
        // let num_padding_chars: _ = (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2);

        // let mut r: [u8; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2)] =
        //     [0; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2)];
        // r
        let mut raw = self.encode_no_pad(input.storage());

        let real_length = input.len();
        let encoded_length = ((real_length * 8) + 5) / 6;

        let r: BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2)) + (((MAX_INPUT_LEN % 3) / 2))> =
            BoundedVec::from_parts(raw, encoded_length);
        r
    }

    pub fn encode_var<let MAX_INPUT_LEN: u32>(
        self,
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 3) + (((MAX_INPUT_LEN % 3) / 2) * 2)> {
        // let num_padding_chars: _ = (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2);

        // let mut r: [u8; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2)] =
        //     [0; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2)];
        // r
        let output_length =
            ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 2) + ((MAX_INPUT_LEN % 3) / 2);
        let mut raw = self.encode(input.storage());

        let real_length = input.len();
        let real_length_mod_3 = real_length % 3;
        let encoded_length = ((real_length * 8) + 5) / 6;

        let length_check1 = (encoded_length < output_length) as Field;
        let length_check2 = ((encoded_length + 1) < output_length) as Field;
        let pad1_null_index = encoded_length as Field * length_check1;
        let pad2_null_index = (encoded_length as Field + 1) * length_check2;
        let pad1_null_char = raw[pad1_null_index] as Field;
        let pad2_null_char = raw[pad2_null_index] as Field;
        let has_byte1_padding = PAD_1[real_length_mod_3];
        let has_byte2_padding = PAD_2[real_length_mod_3];

        let first_potential_padding_byte =
            (BASE64_PADDING_CHAR as Field - pad1_null_char) * has_byte1_padding + pad1_null_char;
        let second_potential_padding_byte =
            (BASE64_PADDING_CHAR as Field - pad2_null_char) * has_byte2_padding + pad2_null_char;

        raw[pad1_null_index] = first_potential_padding_byte as u8;
        raw[pad2_null_index] = second_potential_padding_byte as u8;

        let final_length = encoded_length + CONVERT_MODULO3_TO_PADDING_BYTES[real_length_mod_3];
        println(
            f"length = {real_length}, max_input = {MAX_INPUT_LEN} final length = {final_length}, max output = {output_length}",
        );
        let r: BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 3) + (((MAX_INPUT_LEN % 3) / 2) * 2)> =
            BoundedVec::from_parts(raw, final_length);
        r
    }
    /**
    * @brief Take an array of packed base64 encoded bytes and convert into ASCII
    **/
    pub fn encode<let InputBytes: u32>(
        self,
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2)] {
        // Calculate the number of padding characters and the length of the output without padding

        // input bytes modulo 3 . e.g.

        // input = 5 implies 1 padding char = 40 bits of data = 6 base64 vals + 2 bits
        // 1 is padding so we have 5 base64 vals
        let rem = InputBytes % 3;
        let num_padding_chars = if rem == 1 {
            2
        } else if rem == 2 {
            1
        } else {
            0
        };
        let OutputElements =
            ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2);
        let non_padded_output_length = OutputElements - num_padding_chars;

        let mut result: [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2)] = [
            0; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2)
        ];

        let num_chunks =
            (InputBytes / BYTES_PER_CHUNK) + (InputBytes % BYTES_PER_CHUNK != 0) as u32;

        if num_chunks > 0 {
            let final_chunk = num_chunks - 1;

            for i in 0..final_chunk {
                // pack the bytes into the field element
                let mut slice: Field = 0;
                for j in 0..BYTES_PER_CHUNK {
                    slice *= 256;
                    slice += input[i * BYTES_PER_CHUNK + j] as Field;
                }

                // extract the 6-bit values from the Field element
                let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
                for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                    result[i * BASE64_ELEMENTS_PER_CHUNK + j] = slice_base64_chunks[j];
                }
            }

            // process the final chunk, which may require padding
            let byte_offset = final_chunk * BYTES_PER_CHUNK;
            let base64_offset = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
            let bytes_in_final_chunk = InputBytes - byte_offset;
            let num_elements_in_final_chunk = OutputElements - base64_offset;

            // pack the bytes into the field element
            let mut slice: Field = 0;
            for j in 0..bytes_in_final_chunk {
                slice *= 256;
                slice += input[(num_chunks - 1) * BYTES_PER_CHUNK + j] as Field;
            }
            for _ in bytes_in_final_chunk..BYTES_PER_CHUNK {
                slice *= 256;
            }

            // TODO: check is it cheaper to use a constant value in `to_be_bytes` or can we use `bytes_in_final_chunk`?
            // extract the 6-bit values from the Field element
            let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
            for i in 0..num_elements_in_final_chunk {
                // If padding is enabled, we can skip setting the last `non_padded_output_length` chars
                //    if (!self.pad | base64_offset + i < non_padded_output_length) {
                result[base64_offset + i] = slice_base64_chunks[i];
                //    }
            }

            result = self.encode_elements(result);

            //     if self.pad {
            // handle padding
            let rem = InputBytes % 3;
            if (rem == 1) {
                result[OutputElements - 1] = BASE64_PADDING_CHAR;
                result[OutputElements - 2] = BASE64_PADDING_CHAR;
            } else if (rem == 2) {
                result[OutputElements - 1] = BASE64_PADDING_CHAR;
            }
            //   }
        }
        result
    }

    pub fn encode_no_pad<let InputBytes: u32>(
        self,
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2)) + (((InputBytes % 3) / 2))] {
        // Calculate the number of padding characters and the length of the output without padding

        // input bytes modulo 3 . e.g.

        // input = 5 implies 1 padding char = 40 bits of data = 6 base64 vals + 2 bits
        // 1 is padding so we have 5 base64 vals

        let OutputElements =
            ((InputBytes * 8) / 6) + ((InputBytes % 3) % 2) + ((InputBytes % 3) / 2);
        let non_padded_output_length = OutputElements;

        // Assert that the output length is correct
        // Every 3 chars will be encoded as 4 base64 chars
        // let encoded_length = (InputBytes + 2) / 3 * 4; // ceil(input * 4 / 3)
        // assert(
        //     encoded_length == OutputElements,
        //     f"EncodeError: invalid output length. Expected {encoded_length} output elements, but got {OutputElements}.",
        // );

        let mut result: [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2)) + (((InputBytes % 3) / 2))] =
            [0; ((InputBytes * 8) / 6) + ((InputBytes % 3) % 2) + ((InputBytes % 3) / 2)];

        let num_chunks =
            (InputBytes / BYTES_PER_CHUNK) + (InputBytes % BYTES_PER_CHUNK != 0) as u32;

        if num_chunks > 0 {
            let final_chunk = num_chunks - 1;

            for i in 0..final_chunk {
                // pack the bytes into the field element
                let mut slice: Field = 0;
                for j in 0..BYTES_PER_CHUNK {
                    slice *= 256;
                    slice += input[i * BYTES_PER_CHUNK + j] as Field;
                }

                // extract the 6-bit values from the Field element
                let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
                for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                    result[i * BASE64_ELEMENTS_PER_CHUNK + j] = slice_base64_chunks[j];
                }
            }

            // process the final chunk, which may require padding
            let byte_offset = final_chunk * BYTES_PER_CHUNK;
            let base64_offset = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
            let bytes_in_final_chunk = InputBytes - byte_offset;
            let num_elements_in_final_chunk = OutputElements - base64_offset;

            // pack the bytes into the field element
            let mut slice: Field = 0;
            for j in 0..bytes_in_final_chunk {
                slice *= 256;
                slice += input[(num_chunks - 1) * BYTES_PER_CHUNK + j] as Field;
            }
            for _ in bytes_in_final_chunk..BYTES_PER_CHUNK {
                slice *= 256;
            }

            // TODO: check is it cheaper to use a constant value in `to_be_bytes` or can we use `bytes_in_final_chunk`?
            // extract the 6-bit values from the Field element
            let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
            for i in 0..num_elements_in_final_chunk {
                // If padding is enabled, we can skip setting the last `non_padded_output_length` chars
                if (!self.pad | base64_offset + i < non_padded_output_length) {
                    result[base64_offset + i] = slice_base64_chunks[i];
                }
            }

            result = self.encode_elements(result);
        }
        result
    }
    // /// Take a `BoundedVec` input containing up to `MAX_INPUT_LEN` bytes of data and encode the
    // /// first `input.len()` bytes into Base64.
    // pub fn encode_var<let MAX_INPUT_LEN: u32, let MAX_OUTPUT_LEN: u32>(
    //     self,
    //     input: BoundedVec<u8, MAX_INPUT_LEN>,
    // ) -> BoundedVec<u8, MAX_OUTPUT_LEN> {
    //     // Calculate the number of padding characters and the length of the output without padding
    //     let rem = input.len() % 3;
    //     let num_padding_chars = if rem == 1 {
    //         2
    //     } else if rem == 2 {
    //         1
    //     } else {
    //         0
    //     };
    //     // Every 3 chars will be encoded as 4 base64 chars
    //     let encoded_length = (input.len() + 2) / 3 * 4; // ceil(input * 4 / 3)
    //     let non_padded_output_length = encoded_length - num_padding_chars;
    //     assert(
    //         MAX_OUTPUT_LEN >= (MAX_INPUT_LEN + 2) / 3 * 4,
    //         "maximum output length is too short for the specified maximum input length",
    //     );
    //     let mut result: BoundedVec<u8, MAX_OUTPUT_LEN> = BoundedVec::new();
    //     let max_chunks =
    //         MAX_INPUT_LEN / BYTES_PER_CHUNK + (MAX_INPUT_LEN % BYTES_PER_CHUNK != 0) as u32;
    //     let num_chunks =
    //         (input.len() / BYTES_PER_CHUNK) + (input.len() % BYTES_PER_CHUNK != 0) as u32;
    //     if num_chunks > 0 {
    //         let final_chunk = num_chunks - 1;
    //         for i in 0..max_chunks {
    //             if (i < final_chunk) {
    //                 // pack the bytes into the field element
    //                 let mut slice: Field = 0;
    //                 for j in 0..BYTES_PER_CHUNK {
    //                     slice *= 256;
    //                     slice += input.get_unchecked(i * BYTES_PER_CHUNK + j) as Field;
    //                 }
    //                 // extract the 6-bit values from the Field element
    //                 let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
    //                 for j in 0..BASE64_ELEMENTS_PER_CHUNK {
    //                     let base64 = self.get(slice_base64_chunks[j] as Field);
    //                     result.push(base64);
    //                 }
    //             }
    //         }
    //         // process the final chunk, which may require padding
    //         let byte_offset = final_chunk * BYTES_PER_CHUNK;
    //         let base64_offset = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
    //         let bytes_in_final_chunk = input.len() - byte_offset;
    //         let num_elements_in_final_chunk = encoded_length - base64_offset;
    //         // pack the bytes into the field element
    //         let mut slice: Field = 0;
    //         for j in 0..BYTES_PER_CHUNK {
    //             slice *= 256;
    //             if (j < bytes_in_final_chunk) {
    //                 slice += input.get_unchecked((num_chunks - 1) * BYTES_PER_CHUNK + j) as Field;
    //             }
    //         }
    //         // extract the 6-bit values from the Field element
    //         let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64);
    //         for i in 0..40 {
    //             if (i < num_elements_in_final_chunk & base64_offset + i < non_padded_output_length) {
    //                 let base64 = self.get(slice_base64_chunks[i] as Field);
    //                 result.push(base64);
    //             }
    //         }
    //         if self.pad {
    //             // handle padding
    //             let rem = input.len() % 3;
    //             if (rem == 1) {
    //                 result.push(BASE64_PADDING_CHAR);
    //                 result.push(BASE64_PADDING_CHAR);
    //             } else if (rem == 2) {
    //                 result.push(BASE64_PADDING_CHAR);
    //             }
    //         }
    //     }
    //     result
    // }
}

// === TESTS ======================================================================================

#[test]
fn test_encode_elements() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    // Translated directly to ASCII (with the = padding character stripped)
    let ascii_expected: [u8; 43] = [
        71, 120, 77, 108, 103, 119, 76, 105, 121, 112, 110, 86, 114, 69, 50, 67, 48, 83, 102, 52,
        121, 122, 104, 99, 87, 84, 107, 65, 104, 83, 90, 53, 43, 87, 69, 82, 104, 75, 104, 88, 116,
        108, 85,
    ];

    let input: [u8; 43] = [
        6, 49, 12, 37, 32, 48, 11, 34, 50, 41, 39, 21, 43, 4, 54, 2, 52, 18, 31, 56, 50, 51, 33, 28,
        22, 19, 36, 0, 33, 18, 25, 57, 62, 22, 4, 17, 33, 10, 33, 23, 45, 37, 20,
    ];

    let ascii_result = STANDARD.encode_elements(input);

    assert(ascii_result == ascii_expected);
}

#[test]
fn test_encode_empty() {
    let input: [u8; 0] = [];
    let result = STANDARD.encode(input);
    let expected: [u8; 0] = [];

    assert(result == expected);
}

#[test]
fn test_encode_padding() {
    // f
    let input: [u8; 1] = [102];
    let expected: [u8; 4] = [90, 103, 61, 61];
    let result = STANDARD.encode(input);

    assert(result == expected);

    // fo
    let input: [u8; 2] = [102, 111];
    let expected: [u8; 4] = [90, 109, 56, 61];
    let result = STANDARD.encode(input);

    assert(result == expected);

    // foo
    let input: [u8; 3] = [102, 111, 111];
    let expected: [u8; 4] = [90, 109, 57, 118];
    let result = STANDARD.encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_standard_no_pad() {
    // f
    let input: [u8; 1] = [102];
    let expected: [u8; 2] = [90, 103];
    let result = STANDARD_NO_PAD.encode_no_pad(input);

    assert(result == expected);

    // fo
    let input: [u8; 2] = [102, 111];
    let expected: [u8; 3] = [90, 109, 56];
    let result = STANDARD_NO_PAD.encode_no_pad(input);

    assert(result == expected);

    // foo
    let input: [u8; 3] = [102, 111, 111];
    let expected: [u8; 4] = [90, 109, 57, 118];
    let result = STANDARD_NO_PAD.encode_no_pad(input);

    assert(result == expected);
}

#[test]
fn test_encode_max_byte() {
    let input: [u8; 1] = [255];

    let result: [u8; 4] = STANDARD.encode(input);
    let expected: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    assert(result == expected);

    let result: [u8; 2] = STANDARD_NO_PAD.encode_no_pad(input);
    let expected: [u8; 2] = [47, 119]; // "/w"
    assert(result == expected);

    let result: [u8; 4] = URL_SAFE_WITH_PAD.encode(input);
    let expected: [u8; 4] = [95, 119, 61, 61]; // "_w=="
    assert(result == expected);

    let result: [u8; 2] = URL_SAFE.encode_no_pad(input);
    let expected: [u8; 2] = [95, 119]; // "_w"
    assert(result == expected);
}

#[test]
fn test_encode_ascii() {
    // "Hello World!"
    let input: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];
    // base64: SGVsbG8gV29ybGQh
    let expected: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];

    // all configurations should give the same encoding
    let result = STANDARD.encode(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.encode(input);
    assert(result == expected);
    let result = URL_SAFE_WITH_PAD.encode(input);
    assert(result == expected);
    let result = URL_SAFE.encode(input);
    assert(result == expected);
}

#[test]
fn test_encode_utf8() {
    // non-ascii utf-8: "Hello, World!" in Japanese
    let input: [u8; 27] = [
        227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 129, 175, 227, 128, 129,
        228, 184, 150, 231, 149, 140, 239, 188, 129,
    ];
    // base64: 44GT44KT44Gr44Gh44Gv44CB5LiW55WM77yB
    let expected: [u8; 36] = [
        52, 52, 71, 84, 52, 52, 75, 84, 52, 52, 71, 114, 52, 52, 71, 104, 52, 52, 71, 118, 52, 52,
        67, 66, 53, 76, 105, 87, 53, 53, 87, 77, 55, 55, 121, 66,
    ];

    // all configurations should give the same encoding
    let result = STANDARD.encode(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.encode(input);
    assert(result == expected);
    let result = URL_SAFE_WITH_PAD.encode(input);
    assert(result == expected);
    let result = URL_SAFE.encode(input);
    assert(result == expected);
}

#[test]
fn test_encode_multi_chunks() {
    // "The quick brown fox jumps over the lazy dog."
    let input: [u8; 44] = [
        84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32,
        106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121,
        32, 100, 111, 103, 46,
    ];

    let expected: [u8; 60] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52, 61,
    ];
    let result = STANDARD.encode(input);
    assert(result == expected);

    let expected: [u8; 59] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ];
    let result = STANDARD_NO_PAD.encode_no_pad(input);
    assert(result == expected);
}

#[test]
fn test_encode_standard() {
    // test encoding to / and +
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 4] = [47, 43, 65, 61];
    let result: [u8; 4] = STANDARD.encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_url_safe_with_pad() {
    // test encoding to _ and -
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 4] = [95, 45, 65, 61];
    let result: [u8; 4] = URL_SAFE_WITH_PAD.encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_url_safe() {
    // test encoding to _ and -
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 3] = [95, 45, 65];
    let result: [u8; 3] = URL_SAFE.encode_no_pad(input);
    assert(result == expected);
}

#[test]
fn test_encode() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU
    // Translated directly to ASCII (with padding byte character stripped)
    let expected: [u8; 43] = [
        71, 120, 77, 108, 103, 119, 76, 105, 121, 112, 110, 86, 114, 69, 50, 67, 48, 83, 102, 52,
        121, 122, 104, 99, 87, 84, 107, 65, 104, 83, 90, 53, 43, 87, 69, 82, 104, 75, 104, 88, 116,
        108, 85,
    ];

    let input: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172, 77, 130, 209, 39, 248, 203, 56, 92, 89, 57, 0,
        133, 38, 121, 249, 97, 17, 132, 168, 87, 182, 85,
    ];

    let result = STANDARD_NO_PAD.encode_no_pad(input);
    assert(result == expected);
}

#[test]
fn test_base64_encode_slash() {
    let input: [u8; 1] = [63]; // '/' in Base64
    let result: [u8; 1] = STANDARD_NO_PAD.encode_elements(input);

    // Should map to '/' in ASCII, which is 47
    assert(result[0] == 47);
}

#[test]
fn test_encode_var_empty() {
    let input: BoundedVec<u8, 3> = BoundedVec::new();
    let result = STANDARD.encode_var(input);
    let expected: BoundedVec<u8, 4> = BoundedVec::new();

    assert(result == expected);
}

#[test]
fn test_encode_var_padding() {
    // f
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103, 61, 61]);
    let result = STANDARD.encode_var(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56, 61]);
    let result = STANDARD.encode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let result = STANDARD.encode_var(input);

    assert(result == expected);
}

#[test]
fn test_encode_var_standard_no_pad() {
    // f
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103]);
    let result = STANDARD_NO_PAD.encode_var_no_pad(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56]);
    let result = STANDARD_NO_PAD.encode_var_no_pad(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let result = STANDARD_NO_PAD.encode_var_no_pad(input);

    assert(result == expected);
}

#[test]
fn test_encode_var() {
    // "Hello, World!"
    let input: BoundedVec<u8, 16> =
        BoundedVec::from_array([72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]);
    // base64: "SGVsbG8sIFdvcmxkIQ=="
    let expected: BoundedVec<u8, 24> = BoundedVec::from_array([
        83, 71, 86, 115, 98, 71, 56, 115, 73, 70, 100, 118, 99, 109, 120, 107, 73, 81, 61, 61,
    ]);
    // base64: "SGVsbG8sIFdvcmxkIQ"
    let expected_no_pad: BoundedVec<u8, 22> = BoundedVec::from_array([
        83, 71, 86, 115, 98, 71, 56, 115, 73, 70, 100, 118, 99, 109, 120, 107, 73, 81,
    ]);

    // all configurations should give the same encoding
    let result = STANDARD.encode_var(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.encode_var_no_pad(input);
    assert(result == expected_no_pad);
    let result = URL_SAFE_WITH_PAD.encode_var(input);
    assert(result == expected);
    let result = URL_SAFE.encode_var_no_pad(input);
    assert(result == expected_no_pad);
}

#[test]
fn test_encode_var_multi_chunks() {
    // "The quick brown fox jumps over the lazy dog."
    let input: BoundedVec<u8, 48> = BoundedVec::from_array([
        84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32,
        106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121,
        32, 100, 111, 103, 46,
    ]);
    // base64: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="
    let expected: BoundedVec<u8, 64> = BoundedVec::from_array([
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52, 61,
    ]);
    // base64: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="
    let expected_no_pad: BoundedVec<u8, 64> = BoundedVec::from_array([
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ]);

    // all configurations should give the same encoding
    let result = STANDARD.encode_var(input);
    assert(result == expected);
    let result = STANDARD_NO_PAD.encode_var_no_pad(input);
    assert(result == expected_no_pad);
    let result = URL_SAFE_WITH_PAD.encode_var(input);
    assert(result == expected);
    let result = URL_SAFE.encode_var_no_pad(input);
    assert(result == expected_no_pad);
}
