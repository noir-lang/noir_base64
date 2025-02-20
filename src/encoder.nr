use super::defaults::{BASE64_ELEMENTS_PER_CHUNK, BASE64_PADDING_CHAR, BYTES_PER_CHUNK};

use crate::tables::{
    BASE64_ENCODE_BE_TABLE, BASE64_ENCODE_BE_VAR_TABLE, BASE64URL_ENCODE_BE_TABLE,
    BASE64URL_ENCODE_BE_VAR_TABLE,
};

pub use crate::boundary_check::boundary_check;

global CONVERT_MODULO3_TO_PADDING_BYTES: [u32; 3] = [0, 2, 1];
global PAD_1: [Field; 3] = [0, 1, 1];
global PAD_2: [Field; 3] = [0, 1, 0];

/// Encoder methods that use the standard Base64 Alphabet (base64) specified in RFC 4648
/// (https://datatracker.ietf.org/doc/html/rfc4648#section-4)
pub mod Base64EncodeBE {
    pub fn encode<let InputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2)] {
        crate::encoder::encode::<InputBytes, 0, 1>(input)
    }

    pub fn encode_var<let MAX_INPUT_LEN: u32>(
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 3) + (((MAX_INPUT_LEN % 3) / 2) * 2)> {
        crate::encoder::encode_var::<_, 0, 1>(input)
    }
}

/// Encoder methods that use the standard Base64 Alphabet (base64) specified in RFC 4648
/// (https://datatracker.ietf.org/doc/html/rfc4648#section-4), but WITHOUT padding
pub mod Base64EncodeBENoPad {
    pub fn encode<let InputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2)) + (((InputBytes % 3) / 2))] {
        crate::encoder::encode::<InputBytes, 0, 0>(input)
    }

    pub fn encode_var<let MAX_INPUT_LEN: u32>(
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, (((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2)) + (((MAX_INPUT_LEN % 3) / 2)))> {
        crate::encoder::encode_var::<_, 0, 0>(input)
    }
}

/// Encoder methods that use the URL and Filename Safe Alphabet specified in RFC 4648
/// https://datatracker.ietf.org/doc/html/rfc4648#section-5
pub mod Base64EncodeBEUrlSafe {
    pub fn encode<let InputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2)) + (((InputBytes % 3) / 2))] {
        crate::encoder::encode::<_, 1, 0>(input)
    }

    pub fn encode_var<let MAX_INPUT_LEN: u32>(
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, (((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2)) + (((MAX_INPUT_LEN % 3) / 2)))> {
        crate::encoder::encode_var::<_, 1, 0>(input)
    }
}

/// Encoder methods that use the URL and Filename Safe Alphabet specified in RFC 4648
/// https://datatracker.ietf.org/doc/html/rfc4648#section-5, but WITH padding added
pub mod Base64EncodeBEUrlSafeWithPad {
    pub fn encode<let InputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * 3) + (((InputBytes % 3) / 2) * 2)] {
        crate::encoder::encode::<_, 1, 1>(input)
    }
    pub fn encode_var<let MAX_INPUT_LEN: u32>(
        input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * 3) + (((MAX_INPUT_LEN % 3) / 2) * 2)> {
        crate::encoder::encode_var::<_, 1, 1>(input)
    }
}

/**
 * @brief Take an array of ASCII values and convert into base64 values
 * @tparam InputElements: The size of the array being encoded
 * @tparam UseUrlTable: are we encoding using the URL and Filename Safe Alphabet, or standard Base64 Alphabet? 
 **/
fn encode_elements<let InputElements: u32, let UseUrlTable: u1>(
    input: [u8; InputElements],
) -> [u8; InputElements] {
    let mut result: [u8; InputElements] = [0; InputElements];

    for i in 0..InputElements {
        let token: u8 = if UseUrlTable == 1 {
            BASE64URL_ENCODE_BE_TABLE[input[i]]
        } else {
            BASE64_ENCODE_BE_TABLE[input[i]]
        };
        result[i] = token as u8;
    }

    result
}

/**
 * @brief Encode a variable-length ASCII string into Base64 values
 **/
fn encode_var<let MAX_INPUT_LEN: u32, let UseURLTable: u1, let HasPadding: u32>(
    input: BoundedVec<u8, MAX_INPUT_LEN>,
    ) -> BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2)) + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))> {
    assert((HasPadding == 0) | (HasPadding == 1), "invalid HasPadding parameter");
    // The max number of output Base64 values can be derived from the max input size
    let mut result_arr: [u8; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2)) + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))] = [
        0; ((MAX_INPUT_LEN * 8) / 6)
            + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2))
            + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))
    ];

    // Note: is this correct?
    let output_length = ((MAX_INPUT_LEN * 8) / 6)
        + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2))
        + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding));

    // Step 1: convert the input into six-bit chunks. We can map each chunk into Base64 values.
    let raw: [u8; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2)) + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))] =
        crate::encoder::split_into_six_bit_chunks::<_, _, 1>(input.storage());

    let real_length = input.len();
    // The input length modulo 3 can be used to determine the number of padding bytes
    let real_length_mod_3 = if HasPadding == 1 { real_length % 3 } else { 0 };
    // encoded_length = the number of Base64 values minus padding
    let encoded_length = ((real_length * 8) + 5) / 6;
    let final_length = encoded_length
        + if HasPadding == 1 {
            CONVERT_MODULO3_TO_PADDING_BYTES[real_length_mod_3]
        } else {
            0
        };

    // Get an array of Field elements where boundary_flags[i] = 0 if i < encoded_length, otherwise i = 1.
    // We use this array to determine if the result array should contain a valid Base64 encoded value, 0 or if an error state has been reached
    let boundary_flags: [Field; ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2)) + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))] =
        boundary_check(encoded_length);

    // Using 2 lookups is slightly cheaper than figuring out if the 1st/2nd padding byte is set from the padding length param... I think?
    let has_first_padding_byte = if HasPadding == 1 {
        PAD_1[real_length_mod_3]
    } else {
        0
    };
    let has_second_padding_byte = if HasPadding == 1 {
        PAD_2[real_length_mod_3]
    } else {
        0
    };

    // If we have actual data to iterate through, populate the 1st result entry with the base64 encoding of `raw[0]`.
    // Note: if `boundary_flags[0] = 1`, the `BASE64_ENCODE_BE_VAR_TABLE` lookup will output 0.
    // Note: `MAX_INPUT_LEN` is known at compile time so this `if` statement should not incur constraints.
    if MAX_INPUT_LEN > 0 {
        result_arr[0] = BASE64_ENCODE_BE_VAR_TABLE[raw[0] as Field + boundary_flags[0] * 64] as u8;
    }

    let mut previous_was_first_padding_byte = 0;
    for i in 1..output_length {
        let exceed_length = boundary_flags[i];
        // hit_limit = we are at the first location where a padding Base64 character *could* be enerated

        let mut encoding_index: Field = 0;

        if HasPadding == 1 {
            let hit_limit: Field = (1 - boundary_flags[i - 1]) * boundary_flags[i];
            // We need to write a padding byte if `i == encoding_length` and `has_first_padding_byte == 1`
            let write_first_padding_byte: Field = hit_limit * has_first_padding_byte;
            // We need to write a padding byte if `i == encoding_length + 1` and `has_second_padding_byte == 1`
            let write_second_padding_byte =
                previous_was_first_padding_byte * has_second_padding_byte;

            // Look up the encoded Base64 value given an input 6-bit chunk.
            // We have 2 edge cases that we need to handle efficiently (writing padding bytes or we have exceeded the input length)
            // Instead of expensive conditional logic we apply lookup tables as a quasi state machine to handle these edge cases.
            // CASE 1: `exceed_length = 0`, `write_first_padding_byte = 0`, `write_second_padding_byte = 0`
            //      outcome: we map the 6-bit input value into a Base64 encoding
            // CASE 2: `exceed_length = 1` AND `write_first_padding_byte = 0` AND `write_second_padding_byte = 0`
            //      outcome: if `raw[i] = 0`, the returned value is 0. All other inputs for `raw[i]` return an error state
            // CASE 3: `exceed_length = 1` AND ()`write_first_padding_byte = 1` OR `write_second_padding_byte = 1`)
            //      outcome: if `raw[i] = 0`, the returned value is BASE64_PADDING_CHAR. All other inputs for `raw[i]` return an error state
            // Note: due to how they are constructed, it is not possible for both `write_first_padding_byte` and `write_second_padding_byte` to equal 1.
            //       Similarly, it is not possible for `exceed_length = 0` and either of `write_first_padding_byte` or `write_second_padding_byte` to equal 1.
            encoding_index = raw[i] as Field
                + (exceed_length + write_first_padding_byte + write_second_padding_byte) * 64;
            previous_was_first_padding_byte = write_first_padding_byte;
        } else {
            // We have 2 edge cases that we need to handle efficiently (writing padding bytes or we have exceeded the input length)
            // Instead of expensive conditional logic we apply lookup tables as a quasi state machine to handle these edge cases.
            // CASE 1: `exceed_length = 0`
            //      outcome: we map the 6-bit input value into a Base64 encoding
            // CASE 2: `exceed_length = 1`
            //      outcome: if `raw[i] = 0`, the returned value is 0. All other inputs for `raw[i]` return an error state

            encoding_index = raw[i] as Field + (exceed_length * 64);
        }

        // Note: this `if` condition is known at compile time so should not incur additional constraints
        let token: u8 = if UseURLTable == 1 {
            BASE64_ENCODE_BE_VAR_TABLE[encoding_index]
        } else {
            BASE64URL_ENCODE_BE_VAR_TABLE[encoding_index]
        };
        (token as Field).assert_max_bit_size::<7>();
        result_arr[i] = token;
    }

    // we can use `from_parts_unchecked` here because the table BASE64_ENCODE_BE_VAR_TABLE (and it's URL equivalent)
    // will produce an error if a nonzero input is given past `final_length`
    let mut r: BoundedVec<u8, ((MAX_INPUT_LEN * 8) / 6) + (((MAX_INPUT_LEN % 3) % 2) * (1 + HasPadding * 2)) + (((MAX_INPUT_LEN % 3) / 2) * (1 + HasPadding))> =
        BoundedVec::from_parts_unchecked(result_arr, final_length);

    r
}

/**
 * @brief Take an array of ASCII bytes and convert into an array of six-bit chunks
 **/
fn split_into_six_bit_chunks<let InputBytes: u32, let OutputElements: u32, let HasPadding: u32>(
    input: [u8; InputBytes],
) -> [u8; OutputElements] {
    // Calculate the number of padding characters and the length of the output without padding

    // input bytes modulo 3 . e.g.

    // input = 5 implies 1 padding char = 40 bits of data = 6 base64 vals + 2 bits
    // 1 is padding so we have 5 base64 vals
    let rem = InputBytes % 3;
    let num_padding_chars = if HasPadding == 1 {
        if rem == 1 {
            2
        } else if rem == 2 {
            1
        } else {
            0
        }
    } else {
        0
    };

    let mut result: [u8; OutputElements] = [0; OutputElements];

    let num_chunks = (InputBytes / BYTES_PER_CHUNK) + (InputBytes % BYTES_PER_CHUNK != 0) as u32;

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
            let slice_base64_chunks: [u8; BASE64_ELEMENTS_PER_CHUNK] = slice.to_be_radix(64);
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

        // extract the 6-bit values from the Field element
        let slice_base64_chunks: [u8; BASE64_ELEMENTS_PER_CHUNK] = slice.to_be_radix(64);
        for i in 0..num_elements_in_final_chunk {
            // If padding is enabled, we can skip setting the last `non_padded_output_length` chars
            // N.B. if statement is compile time so shouldn't add c onstraints
            if HasPadding == 1 {
                let non_padded_output_length = OutputElements - num_padding_chars;
                if (base64_offset + i < non_padded_output_length) {
                    result[base64_offset + i] = slice_base64_chunks[i];
                }
            } else {
                result[base64_offset + i] = slice_base64_chunks[i];
            }
        }
    }

    result
}

fn encode<let InputBytes: u32, let UseUrlTable: u1, let UsePadding: u32>(
    input: [u8; InputBytes],
    ) -> [u8; ((InputBytes * 8) / 6) + (((InputBytes % 3) % 2) * (1 + UsePadding * 2)) + (((InputBytes % 3) / 2) * (1 + UsePadding))] {
    assert((UsePadding == 0 as u32) | (UsePadding == 1 as u32), "UsePadding must be 0 or 1");
    let mut result = crate::encoder::encode_elements::<_, UseUrlTable>(
        crate::encoder::split_into_six_bit_chunks::<_, _, UsePadding>(input),
    );
    // this relationship should be evaluated at compile time
    let OutputElements = ((InputBytes * 8) / 6)
        + (((InputBytes % 3) % 2) * (1 + UsePadding * 2))
        + (((InputBytes % 3) / 2) * (1 + UsePadding));
    if UsePadding == 1 {
        // handle padding
        let rem = InputBytes % 3;
        if (rem == 1) {
            result[OutputElements - 1] = BASE64_PADDING_CHAR;
            result[OutputElements - 2] = BASE64_PADDING_CHAR;
        } else if (rem == 2) {
            result[OutputElements - 1] = BASE64_PADDING_CHAR;
        }
    }
    result
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

    let ascii_result = crate::encoder::encode_elements::<_, 0>(input);

    assert(ascii_result == ascii_expected);
}

#[test]
fn test_encode_empty() {
    let input: [u8; 0] = [];
    let result = Base64EncodeBE::encode(input);
    let expected: [u8; 0] = [];

    assert(result == expected);
}

#[test]
fn test_encode_padding() {
    // f
    let input: [u8; 1] = [102];
    let expected: [u8; 4] = [90, 103, 61, 61];
    let result = Base64EncodeBE::encode(input);

    assert(result == expected);

    // fo
    let input: [u8; 2] = [102, 111];
    let expected: [u8; 4] = [90, 109, 56, 61];
    let result = Base64EncodeBE::encode(input);

    assert(result == expected);

    // foo
    let input: [u8; 3] = [102, 111, 111];
    let expected: [u8; 4] = [90, 109, 57, 118];
    let result = Base64EncodeBE::encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_standard_no_pad() {
    // f
    let input: [u8; 1] = [102];
    let expected: [u8; 2] = [90, 103];
    let result = Base64EncodeBENoPad::encode(input);

    assert(result == expected);

    // fo
    let input: [u8; 2] = [102, 111];
    let expected: [u8; 3] = [90, 109, 56];
    let result = Base64EncodeBENoPad::encode(input);

    assert(result == expected);

    // foo
    let input: [u8; 3] = [102, 111, 111];
    let expected: [u8; 4] = [90, 109, 57, 118];
    let result = Base64EncodeBENoPad::encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_max_byte() {
    let input: [u8; 1] = [255];

    let result: [u8; 4] = Base64EncodeBE::encode(input);
    let expected: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    assert(result == expected);

    let result: [u8; 2] = Base64EncodeBENoPad::encode(input);
    let expected: [u8; 2] = [47, 119]; // "/w"
    assert(result == expected);

    let result: [u8; 4] = Base64EncodeBEUrlSafeWithPad::encode(input);
    let expected: [u8; 4] = [95, 119, 61, 61]; // "_w=="
    assert(result == expected);

    let result: [u8; 2] = Base64EncodeBEUrlSafe::encode(input);
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
    let result = Base64EncodeBE::encode(input);
    assert(result == expected);
    let result = Base64EncodeBENoPad::encode(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafeWithPad::encode(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafeWithPad::encode(input);
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
    let result = Base64EncodeBE::encode(input);
    assert(result == expected);
    let result = Base64EncodeBENoPad::encode(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafeWithPad::encode(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafeWithPad::encode(input);
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
    let result = Base64EncodeBE::encode(input);
    assert(result == expected);

    let expected: [u8; 59] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ];
    let result = Base64EncodeBENoPad::encode(input);
    assert(result == expected);
}

#[test]
fn test_encode_standard() {
    // test encoding to / and +
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 4] = [47, 43, 65, 61];
    let result: [u8; 4] = Base64EncodeBE::encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_url_safe_with_pad() {
    // test encoding to _ and -
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 4] = [95, 45, 65, 61];
    let result: [u8; 4] = Base64EncodeBEUrlSafeWithPad::encode(input);

    assert(result == expected);
}

#[test]
fn test_encode_url_safe() {
    // test encoding to _ and -
    let input: [u8; 2] = [255, 224];
    let expected: [u8; 3] = [95, 45, 65];
    let result: [u8; 3] = Base64EncodeBEUrlSafe::encode(input);
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

    let result = Base64EncodeBENoPad::encode(input);
    assert(result == expected);
}

#[test]
fn test_base64_encode_slash() {
    let input: [u8; 1] = [63]; // '/' in Base64
    let result: [u8; 1] = crate::encoder::encode_elements::<_, 0>(input);

    // Should map to '/' in ASCII, which is 47
    assert(result[0] == 47);
}

#[test]
fn test_encode_var_empty() {
    let input: BoundedVec<u8, 3> = BoundedVec::new();
    let result = Base64EncodeBE::encode_var(input);
    let expected: BoundedVec<u8, 4> = BoundedVec::new();
    assert(result == expected);

    let input: BoundedVec<u8, 0> = BoundedVec::new();
    let result = Base64EncodeBE::encode_var(input);
    let expected: BoundedVec<u8, 0> = BoundedVec::new();
    assert(result == expected);
}

#[test]
fn test_encode_var_padding() {
    // f
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103, 61, 61]);
    let result = Base64EncodeBE::encode_var(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56, 61]);
    let result = Base64EncodeBE::encode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let result = Base64EncodeBE::encode_var(input);

    assert(result == expected);
}

#[test]
fn test_encode_var_standard_no_pad() {
    // f
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103]);
    let result = Base64EncodeBENoPad::encode_var(input);

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56]);
    let result = Base64EncodeBENoPad::encode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let expected: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let result = Base64EncodeBENoPad::encode_var(input);

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
    let result = Base64EncodeBE::encode_var(input);
    println(f"result = {result}");
    assert(result == expected);
    let result = Base64EncodeBENoPad::encode_var(input);
    assert(result == expected_no_pad);
    let result = Base64EncodeBEUrlSafeWithPad::encode_var(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafe::encode_var(input);
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
    let result = Base64EncodeBE::encode_var(input);
    assert(result == expected);
    let result = Base64EncodeBENoPad::encode_var(input);
    assert(result == expected_no_pad);
    let result = Base64EncodeBEUrlSafeWithPad::encode_var(input);
    assert(result == expected);
    let result = Base64EncodeBEUrlSafe::encode_var(input);
    assert(result == expected_no_pad);
}
