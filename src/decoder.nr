use super::defaults::{
    BASE64_ELEMENTS_PER_CHUNK, BASE64_PADDING_CHAR, BYTES_PER_CHUNK, INVALID_DECODE_VALUE,
};

pub use crate::boundary_check::boundary_check;
use crate::tables::{
    BASE64_DECODE_BE_TABLE, BASE64_DECODE_BE_URL_TABLE, BASE64_DECODE_BE_URL_VAR_TABLE,
    BASE64_DECODE_BE_VAR_TABLE,
};

/// Decoder methods that use the standard Base64 Alphabet (base64) specified in RFC 4648
/// (https://datatracker.ietf.org/doc/html/rfc4648#section-4)
pub mod Base64DecodeBE {
    pub fn decode<let InputBytes: u32, let OutputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; OutputBytes] {
        crate::decoder::decode::<InputBytes, OutputBytes, 1, 0>(input)
    }

    pub fn decode_var<let MaxInputBytes: u32, let MaxOutputBytes: u32>(
        input: BoundedVec<u8, MaxInputBytes>,
    ) -> BoundedVec<u8, MaxOutputBytes> {
        crate::decoder::decode_var::<MaxInputBytes, MaxOutputBytes, 1, 0>(input)
    }
}

/// Decoder methods that use the standard Base64 Alphabet (base64) specified in RFC 4648
/// (https://datatracker.ietf.org/doc/html/rfc4648#section-4), but WITHOUT padding
pub mod Base64DecodeBENoPad {
    pub fn decode<let InputBytes: u32, let OutputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; OutputBytes] {
        crate::decoder::decode::<InputBytes, OutputBytes, 0, 0>(input)
    }

    pub fn decode_var<let MaxInputBytes: u32, let MaxOutputBytes: u32>(
        input: BoundedVec<u8, MaxInputBytes>,
    ) -> BoundedVec<u8, MaxOutputBytes> {
        crate::decoder::decode_var::<MaxInputBytes, MaxOutputBytes, 0, 0>(input)
    }
}

/// Decoder methods that use the URL and Filename Safe Alphabet specified in RFC 4648
/// https://datatracker.ietf.org/doc/html/rfc4648#section-5
pub mod Base64DecodeBEUrlSafe {
    pub fn decode<let InputBytes: u32, let OutputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; OutputBytes] {
        crate::decoder::decode::<InputBytes, OutputBytes, 0, 1>(input)
    }

    pub fn decode_var<let MaxInputBytes: u32, let MaxOutputBytes: u32>(
        input: BoundedVec<u8, MaxInputBytes>,
    ) -> BoundedVec<u8, MaxOutputBytes> {
        crate::decoder::decode_var::<MaxInputBytes, MaxOutputBytes, 0, 1>(input)
    }
}

/// Decoder methods that use the URL and Filename Safe Alphabet specified in RFC 4648
/// https://datatracker.ietf.org/doc/html/rfc4648#section-5, but WITH padding added
pub mod Base64DecodeBEUrlSafeWithPad {
    pub fn decode<let InputBytes: u32, let OutputBytes: u32>(
        input: [u8; InputBytes],
    ) -> [u8; OutputBytes] {
        crate::decoder::decode::<InputBytes, OutputBytes, 1, 1>(input)
    }

    pub fn decode_var<let MaxInputBytes: u32, let MaxOutputBytes: u32>(
        input: BoundedVec<u8, MaxInputBytes>,
    ) -> BoundedVec<u8, MaxOutputBytes> {
        crate::decoder::decode_var::<MaxInputBytes, MaxOutputBytes, 1, 1>(input)
    }
}

/**
 * @brief Return a human-readable error if the input is invalid Base64
 * @details We constrain the decoding to be correct by using a lookup table to decode Base64.
 *          Validation is performed by batch-checking that no lookups returned an error state.
 *          This produces unhelpful error messages so we put this sanitised check in an unconstrained fn
 **/
unconstrained fn __validate_decoded(decoded: Field, input_byte: u8, offset: u32) {
    assert(
        decoded != INVALID_DECODE_VALUE,
        f"DecodeError: invalid symbol {input_byte}, offset {offset}.",
    );
}

/**
 * @brief Given a variable-sized number of Base64 encoded characters, return a *claim* about how many are padding chars
 * @note The returned value is only a claim and must be validated
 **/
unconstrained fn __get_num_padding_chars_var<let InputElements: u32>(
    input: BoundedVec<u8, InputElements>,
) -> (bool, bool) {
    let len = input.len();
    let r1 = if len > 1 {
        input.get(len - 2) == BASE64_PADDING_CHAR
    } else {
        false
    };
    let r2 = if len > 0 {
        input.get(len - 1) == BASE64_PADDING_CHAR
    } else {
        false
    };
    (r1, r2)
}

/**
 * @brief Take an array of Base64 values and convert back into ASCII
 *        Each Base64 value is 6 bits. This method will produce a byte array where data is concatenated so that there are no sparse bits
 *        (e.g. encoding 4 ASCII values produces 24 bits of Base64 data = 3 bytes of output data)
 **/
fn decode<let InputElements: u32, let OutputBytes: u32, let Pad: u1, let UseURLTable: u1>(
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
    if Pad != 0 {
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

    // validity_check = accumulator value that we add every output from BASE64_DECODE_BE_TABLE into.
    // Invalid error states will return a lookup value of -2^32 , which will cause `validity_check` to fail a 32-bit range check.
    // This batch-validation technique is more efficient than asserting every returned token is valid.
    let mut validity_check: Field = 0;
    if num_chunks > 0 {
        let final_chunk = num_chunks - 1;

        for i in 0..final_chunk {
            let mut slice: Field = 0;
            for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                slice *= 64;
                let offset = i * BASE64_ELEMENTS_PER_CHUNK + j;
                let input_byte = input[offset];
                let decoded = if UseURLTable == 1 {
                    BASE64_DECODE_BE_URL_TABLE[input_byte]
                } else {
                    BASE64_DECODE_BE_TABLE[input_byte]
                };
                validity_check += decoded;
                slice += decoded as Field;
                unsafe {
                    //@safety get a sensible error message out if the decoding is invalid.
                    // Note that we *constrain* the encoding is correct by performing a range check on `validity_check`
                    // If the decoding is invalid, `decoded = -2^{32}`. We add up all `decoded` values and apply a 32-bit range check.
                    // Given all valid encodings are 8-bit, as long as the input length is less than 2^24 bytes, it is not possible to
                    // underflow validity_check with an invalid encoding, and then overflow again by adding up valid encodings
                    __validate_decoded(decoded, input_byte, offset);
                }
            }
            let slice_bytes: [u8; 30] = slice.to_be_bytes();
            for j in 0..BYTES_PER_CHUNK {
                result[i * BYTES_PER_CHUNK + j] = slice_bytes[j];
            }
        }

        // process the final chunk, which may contain padding
        let base64_offset: u32 = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
        let byte_offset = final_chunk * BYTES_PER_CHUNK;
        let base64_elements_in_final_chunk = if Pad != 0 {
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
            let decoded = if UseURLTable == 1 {
                BASE64_DECODE_BE_URL_TABLE[input_byte]
            } else {
                BASE64_DECODE_BE_TABLE[input_byte]
            };
            validity_check += decoded;
            slice += decoded as Field;
            unsafe {
                //@safety get a sensible error message out if the decoding is invalid.
                // Note that we *constrain* the encoding is correct by performing a range check on `validity_check`
                // If the decoding is invalid, `decoded = -2^{32}`. We add up all `decoded` values and apply a 32-bit range check.
                // Given all valid encodings are 8-bit, as long as the input length is less than 2^24 bytes, it is not possible to
                // underflow validity_check with an invalid encoding, and then overflow again by adding up valid encodings
                __validate_decoded(decoded, input_byte, offset);
            }
        }

        // If any lookups returned an error state, this 32-bit range check will fail.
        validity_check.assert_max_bit_size::<32>();
        for _ in base64_elements_in_final_chunk..BASE64_ELEMENTS_PER_CHUNK {
            slice *= 64;
        }

        let slice_bytes: [u8; 30] = slice.to_be_bytes();
        let num_bytes_in_final_chunk = OutputBytes - byte_offset;
        for i in 0..num_bytes_in_final_chunk {
            result[byte_offset + i] = slice_bytes[i];
        }
    }

    result
}

/**
 * @brief Take a variable-length vector of Base64 values and convert back into ASCII
 *        Each Base64 value is 6 bits. This method will produce a byte array where data is concatenated so that there are no sparse bits
 *        (e.g. encoding 4 ASCII values produces 24 bits of Base64 data = 3 bytes of output data)
 **/
pub fn decode_var<let InputElements: u32, let OutputBytes: u32, let Pad: u1, let UseURLTable: u1>(
    input: BoundedVec<u8, InputElements>,
) -> BoundedVec<u8, OutputBytes> {
    // We don't know how many padding bytes the input string contains - we use an unconstrained fn to return a *claim* that we will later validate
    let (has_first_padding_byte_claim, has_second_padding_byte_claim) = if (Pad == 1) {
        unsafe {
            //@safety get claims about whether the bytes input[input.len() - 2] and input[input.len() - 1] are padding chars
            // we validate this later on by requiring these characters equal BASE64_PADDING_CHAR by looking up BASE64_DECODE_BE_VAR_TABLE
            crate::decoder::__get_num_padding_chars_var::<InputElements>(input)
        }
    } else {
        (false, false)
    };

    // num_padding_chars is a claim that depends on has_first_padding_byte_claim and has_second_padding_byte_claim being correct
    let num_padding_chars: u32 = if Pad == 1 {
        has_first_padding_byte_claim as u32 + has_second_padding_byte_claim as u32
    } else {
        0
    };

    let input_length = input.len();
    let input = input.storage();

    // boundary_flags = array of Field elements.
    // if `i < input_length, boundary_flags[i] = 0`
    // if `i >= input_length, boundary_flags[i+1] = 1`
    // used as cheap(ish) predicates when iterating over bounded vector elements
    let boundary_flags: [Field; InputElements] = boundary_check(input_length);
    let mut result: [u8; OutputBytes] = [0; OutputBytes];

    let max_num_chunks = (InputElements / BASE64_ELEMENTS_PER_CHUNK)
        + (InputElements % BASE64_ELEMENTS_PER_CHUNK != 0) as u32;

    let mut validity_check: Field = 0;
    // if statement should be known at compile time
    if max_num_chunks > 0 {
        let final_chunk: u32 = max_num_chunks - 1;

        for i in 0..final_chunk {
            let mut slice: Field = 0;
            for j in 0..BASE64_ELEMENTS_PER_CHUNK {
                slice *= 64;
                let offset = i * BASE64_ELEMENTS_PER_CHUNK + j;
                let input_byte = input[offset];

                let mut decode_index: Field = 0;
                if Pad == 1 {
                    let mut might_be_second_padding_char = 0;
                    let mut might_be_first_padding_char = 0;
                    // These if statements should not cost extra gates as the condition is known at compile time
                    if (offset + 2 < InputElements) {
                        might_be_first_padding_char = (1 - boundary_flags[offset])
                            * (1 - boundary_flags[offset + 1])
                            * boundary_flags[offset + 2];
                        might_be_second_padding_char =
                            (1 - boundary_flags[offset]) * (boundary_flags[offset + 1]);
                    } else if (offset + 1 < InputElements) {
                        // might_be_second_padding_char = (1 - boundary_flags[offset]) + (boundary_flags[offset + 1]);
                        might_be_first_padding_char =
                            (1 - boundary_flags[offset]) * (1 - boundary_flags[offset + 1]);
                        might_be_second_padding_char =
                            (1 - boundary_flags[offset]) * (boundary_flags[offset + 1]);
                    } else // last character
                    {
                        might_be_first_padding_char = 0;
                        might_be_second_padding_char = (1 - boundary_flags[offset]);
                    }

                    // Cases where we need to require a padding character is present:
                    // Case 1: we are at byte position `input.len() - 2` and `has_first_padding_byte_claim = true`
                    // Case 2: we are at byte position `input.len() - 1` and `has_second_padding_byte_claim = true`
                    let require_padding = might_be_first_padding_char
                        * has_first_padding_byte_claim as Field
                        + (might_be_second_padding_char * has_second_padding_byte_claim as Field);

                    // The `decode_index` is used to map the input Base64 character into an output decoded character.
                    // We know `input_byte` is in the range 0-255 , so we use a size 768 lookup to handle the following 3 cases:
                    // Case 1 (index range 0-255): No special cases. We decode the Base64 ASCII char into an ASCII char
                    // Case 2 (index range 256-511): We have exceeded the length of the input. The only valid input is 0, which decodes to 0 (all other byte values return an error state)
                    // Case 3 (index range 512-767): A claim has been made that a padding byte is present, and we are at the appropriate byte location to check this.
                    //                               The only valid input is BASE64_PADDING_CHAR, which decodes to 0. All other inputs return an error state
                    decode_index =
                        input_byte as Field + boundary_flags[offset] * 256 + require_padding * 512;
                } else {
                    decode_index = input_byte as Field + boundary_flags[offset] * 256;
                }
                let decoded = if UseURLTable == 1 {
                    BASE64_DECODE_BE_URL_VAR_TABLE[decode_index]
                } else {
                    BASE64_DECODE_BE_VAR_TABLE[decode_index]
                };

                validity_check += decoded;
                slice += decoded;
                unsafe {
                    //@safety get a sensible error message out if the decoding is invalid.
                    // Note that we *constrain* the encoding is correct by performing a range check on `validity_check`
                    // If the decoding is invalid, `decoded = -2^{32}`. We add up all `decoded` values and apply a 32-bit range check.
                    // Given all valid encodings are 8-bit, as long as the input length is less than 2^24 bytes, it is not possible to
                    // underflow validity_check with an invalid encoding, and then overflow again by adding up valid encodings
                    __validate_decoded(decoded, input_byte, offset);
                }
            }
            // convert the decoded slice into bytes and populate result array
            let slice_bytes: [u8; 30] = slice.to_be_bytes();
            for j in 0..BYTES_PER_CHUNK {
                result[i * BYTES_PER_CHUNK + j] = slice_bytes[j];
            }
        }
        // process the final chunk
        let base64_offset: u32 = final_chunk * BASE64_ELEMENTS_PER_CHUNK;
        let byte_offset = final_chunk * BYTES_PER_CHUNK;
        // might include padding characters
        let base64_elements_in_final_chunk = InputElements - base64_offset;

        // pack the base64 values into the field element
        let mut slice: Field = 0;
        for j in 0..base64_elements_in_final_chunk {
            slice *= 64;
            let offset = base64_offset + j;
            let input_byte = input[offset];

            let mut decode_index: Field = 0;
            if Pad == 1 {
                let mut might_be_second_padding_char = 0;
                let mut might_be_first_padding_char = 0;
                // These if statements should not cost extra gates as the condition is known at compile time
                if (offset + 2 < InputElements) {
                    might_be_first_padding_char = (1 - boundary_flags[offset])
                        * (1 - boundary_flags[offset + 1])
                        * boundary_flags[offset + 2];
                    might_be_second_padding_char =
                        (1 - boundary_flags[offset]) * (boundary_flags[offset + 1]);
                } else if (offset + 1 < InputElements) {
                    // might_be_second_padding_char = (1 - boundary_flags[offset]) + (boundary_flags[offset + 1]);
                    might_be_first_padding_char =
                        (1 - boundary_flags[offset]) * (1 - boundary_flags[offset + 1]);
                    might_be_second_padding_char =
                        (1 - boundary_flags[offset]) * (boundary_flags[offset + 1]);
                } else // last character
                {
                    might_be_first_padding_char = 0;
                    might_be_second_padding_char = (1 - boundary_flags[offset]);
                }

                let require_padding = might_be_first_padding_char
                    * has_first_padding_byte_claim as Field
                    + (might_be_second_padding_char * has_second_padding_byte_claim as Field);
                decode_index =
                    input_byte as Field + boundary_flags[offset] * 256 + require_padding * 512;
            } else {
                decode_index = input_byte as Field + boundary_flags[offset] * 256;
            }
            let decoded = if UseURLTable == 1 {
                BASE64_DECODE_BE_URL_VAR_TABLE[decode_index]
            } else {
                BASE64_DECODE_BE_VAR_TABLE[decode_index]
            };
            unsafe {
                //@safety get a sensible error message out if the decoding is invalid.
                // Note that we *constrain* the encoding is correct by performing a range check on `validity_check`
                // If the decoding is invalid, `decoded = -2^{32}`. We add up all `decoded` values and apply a 32-bit range check.
                // Given all valid encodings are 8-bit, as long as the input length is less than 2^24 bytes, it is not possible to
                // underflow validity_check with an invalid encoding, and then overflow again by adding up valid encodings
                __validate_decoded(decoded, input_byte, offset);
            }
            validity_check += decoded;
            slice += decoded as Field;
        }

        validity_check.assert_max_bit_size::<32>();

        for _ in base64_elements_in_final_chunk..BASE64_ELEMENTS_PER_CHUNK {
            slice *= 64;
        }

        let slice_bytes: [u8; 30] = slice.to_be_bytes();
        let num_bytes_in_final_chunk = OutputBytes - byte_offset;
        for i in 0..num_bytes_in_final_chunk {
            result[byte_offset + i] = slice_bytes[i];
        }
    }

    if Pad == 1 {
        assert(input_length % 4 == 0, "base64 encoded strings must be a multiple of 4 bytes");
    }

    assert_eq(
        has_first_padding_byte_claim,
        has_second_padding_byte_claim * has_first_padding_byte_claim,
        "if first byte contains padding so must the second",
    );
    let output_length = ((input_length * 3) / 4) - num_padding_chars;
    BoundedVec::from_parts_unchecked(result, output_length)
}

#[test]
fn test_decode_empty() {
    let input: [u8; 0] = [];
    let expected: [u8; 0] = [];
    let result = Base64DecodeBE::decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_padding() {
    // f
    let input: [u8; 4] = [90, 103, 61, 61];
    let expected: [u8; 1] = [102];
    let result = Base64DecodeBE::decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 4] = [90, 109, 56, 61];
    let expected: [u8; 2] = [102, 111];
    let result = Base64DecodeBE::decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = Base64DecodeBE::decode(input);

    assert(result == expected);
}

#[test]
fn test_decode_standard_no_pad() {
    // f
    let input: [u8; 2] = [90, 103];
    let expected: [u8; 1] = [102];
    let result = Base64DecodeBENoPad::decode(input);

    assert(result == expected);

    // fo
    let input: [u8; 3] = [90, 109, 56];
    let expected: [u8; 2] = [102, 111];
    let result = Base64DecodeBENoPad::decode(input);

    assert(result == expected);

    // foo
    let input: [u8; 4] = [90, 109, 57, 118];
    let expected: [u8; 3] = [102, 111, 111];
    let result = Base64DecodeBENoPad::decode(input);

    assert(result == expected);
}

#[test]
fn test_decode_max_byte() {
    let expected: [u8; 1] = [255];

    let input: [u8; 4] = [47, 119, 61, 61]; // "/w=="
    let result: [u8; 1] = Base64DecodeBE::decode(input);
    assert(result == expected);

    let input: [u8; 2] = [47, 119]; // "/w"
    let result: [u8; 1] = Base64DecodeBENoPad::decode(input);
    assert(result == expected);

    let input: [u8; 4] = [95, 119, 61, 61]; // "_w=="
    let result: [u8; 1] = Base64DecodeBEUrlSafeWithPad::decode(input);
    assert(result == expected);

    let input: [u8; 2] = [95, 119]; // "_w"
    let result: [u8; 1] = Base64DecodeBEUrlSafe::decode(input);
    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 255, offset 0")]
fn test_decode_invalid() {
    let input: [u8; 2] = [255, 255];
    let _: [u8; 1] = Base64DecodeBENoPad::decode(input);
}

#[test(should_fail_with = "DecodeError: invalid input length for specified output length. Expected 3 input elements, but got 4.")]
fn test_decode_standard_no_pad_fail_with_padding() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = Base64DecodeBENoPad::decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_standard() {
    // test decoding / and +
    let input: [u8; 4] = [47, 43, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = Base64DecodeBE::decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 95, offset 0")]
fn test_decode_underscore_with_standard() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let _: [u8; 2] = Base64DecodeBE::decode(input);
}

#[test]
fn test_decode_url_safe_with_pad() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = Base64DecodeBEUrlSafeWithPad::decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 47, offset 0")]
fn test_decode_slash_with_url_safe() {
    // test decoding / and +
    let input: [u8; 3] = [47, 43, 65];
    let _: [u8; 2] = Base64DecodeBEUrlSafe::decode(input);
}

#[test]
fn test_decode_url_safe() {
    // test decoding _ and -
    let input: [u8; 3] = [95, 45, 65];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = Base64DecodeBEUrlSafe::decode(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid input length for specified output length. Expected 3 input elements, but got 4.")]
fn test_decode_url_safe_no_pad_fail_with_padding() {
    // test decoding _ and -
    let input: [u8; 4] = [95, 45, 65, 61];
    let expected: [u8; 2] = [255, 224];
    let result: [u8; 2] = Base64DecodeBEUrlSafe::decode(input);
    assert(result == expected);
}

#[test]
fn test_decode_ascii() {
    // base64: SGVsbG8gV29ybGQh
    let input: [u8; 16] = [83, 71, 86, 115, 98, 71, 56, 103, 86, 50, 57, 121, 98, 71, 81, 104];
    // "Hello World!"
    let expected: [u8; 12] = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];

    // all configurations should decode the same way
    let result: [u8; 12] = Base64DecodeBE::decode(input);
    assert(result == expected);
    let result: [u8; 12] = Base64DecodeBENoPad::decode(input);
    assert(result == expected);
    let result: [u8; 12] = Base64DecodeBEUrlSafeWithPad::decode(input);
    assert(result == expected);
    let result: [u8; 12] = Base64DecodeBEUrlSafe::decode(input);
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
    let result: [u8; 27] = Base64DecodeBE::decode(input);
    assert(result == expected);
    let result: [u8; 27] = Base64DecodeBENoPad::decode(input);
    assert(result == expected);
    let result: [u8; 27] = Base64DecodeBEUrlSafeWithPad::decode(input);
    assert(result == expected);
    let result: [u8; 27] = Base64DecodeBEUrlSafe::decode(input);
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
    let result: [u8; 44] = Base64DecodeBE::decode(input);
    assert(result == expected);

    let input: [u8; 59] = [
        86, 71, 104, 108, 73, 72, 70, 49, 97, 87, 78, 114, 73, 71, 74, 121, 98, 51, 100, 117, 73,
        71, 90, 118, 101, 67, 66, 113, 100, 87, 49, 119, 99, 121, 66, 118, 100, 109, 86, 121, 73,
        72, 82, 111, 90, 83, 66, 115, 89, 88, 112, 53, 73, 71, 82, 118, 90, 121, 52,
    ];
    let result = Base64DecodeBENoPad::decode(input);
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

    let result: [u8; 32] = Base64DecodeBE::decode(input);
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
    let result = Base64DecodeBE::decode_var(input);
    assert(result == expected);
}

#[test]
fn test_decode_var_padding() {
    // f
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103, 61, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let result = Base64DecodeBE::decode_var(input);
    println(f"result {result}");
    println(f"expected {expected}");

    assert(result == expected);

    // fo
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let result = Base64DecodeBE::decode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 8> = BoundedVec::from_array([90, 109, 57, 118]);
    let expected: BoundedVec<u8, 6> = BoundedVec::from_array([102, 111, 111]);
    let result = Base64DecodeBE::decode_var(input);

    assert(result == expected);
}

#[test]
fn test_decode_var_standard_no_pad() {
    // f
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 103]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102]);
    let result = Base64DecodeBENoPad::decode_var(input);

    // fo
    println(f"result {result}, expected {expected}");

    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 56]);

    assert(result == expected);

    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111]);
    let result = Base64DecodeBENoPad::decode_var(input);

    assert(result == expected);

    // foo
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([90, 109, 57, 118]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([102, 111, 111]);
    let result = Base64DecodeBENoPad::decode_var(input);

    assert(result == expected);
}

#[test(should_fail_with = "DecodeError: invalid symbol 61, offset 3")]
fn test_decode_var_no_pad_fail_with_padding() {
    // test decoding / and +
    let input: BoundedVec<u8, 4> = BoundedVec::from_array([47, 43, 65, 61]);
    let expected: BoundedVec<u8, 3> = BoundedVec::from_array([255, 224]);
    let result = Base64DecodeBENoPad::decode_var(input);
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
    let result = Base64DecodeBE::decode_var(input);
    assert(result == expected);
    let result = Base64DecodeBENoPad::decode_var(input_no_pad);
    println(f"result {result}, expected {expected}");
    assert(result == expected);
    let result = Base64DecodeBEUrlSafeWithPad::decode_var(input);
    assert(result == expected);
    let result = Base64DecodeBEUrlSafe::decode_var(input_no_pad);
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
    let result = Base64DecodeBE::decode_var(input);
    assert(result == expected);
    let result = Base64DecodeBENoPad::decode_var(input_no_pad);
    assert(result == expected);
    let result = Base64DecodeBEUrlSafeWithPad::decode_var(input);
    assert(result == expected);
    let result = Base64DecodeBEUrlSafe::decode_var(input_no_pad);
    assert(result == expected);
}
