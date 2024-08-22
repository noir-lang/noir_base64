struct Base64EncodeBE {
    table: [u8; 128]
}
impl Base64EncodeBE {
    fn new() -> Self {
        Base64EncodeBE {
            table: [
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 0-9
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 10-19
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 20-29
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 30-39
                0, 0, 0,// 40-42
                62,// 43
                0, 0, 0,// 44-46
                63,// 47
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61,// 48-57
                0, 0, 0,// 58-60,
                0,// 61
                0, 0, 0,// 62-64
                0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,// 65-90 (A-Z)
                0, 0, 0, 0, 0, 0,// 91-96
                26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,// 97-122 (a-z)
                0, 0, 0, 0, 0// 123-127
            ]
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }
}

struct Base64DecodeBE {
    table: [u8; 64]
}
impl Base64DecodeBE {
    fn new() -> Self {
        Base64DecodeBE {
            table: [
                65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,// 0-25 (A-Z)
                97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,// 26-51 (a-z)
                48, 49, 50, 51, 52, 53, 54, 55, 56, 57,// 52-61
                43,// 62
                47// 63
            ]
        }
    }

    fn get(self, idx: Field) -> u8 {
        self.table[idx]
    }
}

/**
 * @brief Take an array of ASCII values and convert into base64 values
 **/
pub fn base64_encode_elements<let InputElements: u32>(input: [u8; InputElements]) -> [u8; InputElements] {
    // for some reason, if the lookup table is not defined in a struct, access costs are expensive and ROM tables aren't being used :/
    let mut Base64Encoder = Base64EncodeBE::new();

    let mut result: [u8; InputElements] = [0; InputElements];

    for i in 0..InputElements {
        result[i] = Base64Encoder.get(input[i] as Field);
    }
    result
}

/**
 * @brief Take an array of base64 values and convert into ASCII values
 **/
pub fn base64_decode_elements<let InputElements: u32>(input: [u8; InputElements]) -> [u8; InputElements] {
    // for some reason, if the lookup table is not defined in a struct, access costs are expensive and ROM tables aren't being used :/
    let mut Base64Decoder = Base64DecodeBE::new();

    let mut result: [u8; InputElements] = [0; InputElements];

    for i in 0..InputElements {
        result[i] = Base64Decoder.get(input[i] as Field);
    }
    result
}

/**
 * @brief Take an array of ASCII values and convert into *packed* byte array of base64 values
 *        Each Base64 value is 6 bits. This method will produce a byte array where data is concatenated so that there are no sparse bits
 *        (e.g. encoding 4 ASCII values produces 24 bits of Base64 data = 3 bytes of output data)
 **/
pub fn base64_encode<let InputElements: u32, let OutputBytes: u32>(input: [u8; InputElements]) -> [u8; OutputBytes] {
    let encoded: [u8; InputElements] = base64_encode_elements(input);
    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // we pack 40 base64 values into a field element and convert into 30 bytes
    // TODO: once we support arithmetic ops on generics, derive OutputBytes from InputBytes
    let mut result: [u8; OutputBytes] = [0; OutputBytes];
    let BASE64_ELEMENTS_PER_CHUNK: u32 = 40;
    let BYTES_PER_CHUNK: u32 = 30;
    let num_chunks = (InputElements / BASE64_ELEMENTS_PER_CHUNK)
        + (InputElements % BASE64_ELEMENTS_PER_CHUNK != 0) as u32;

    for i in 0..num_chunks - 1 {
        let mut slice: Field = 0;
        for j in 0..BASE64_ELEMENTS_PER_CHUNK {
            slice *= 64;
            slice += encoded[i * BASE64_ELEMENTS_PER_CHUNK + j] as Field;
        }
        let slice_bytes: [u8; 30] = slice.to_be_bytes(30).as_array();
        for j in 0..BYTES_PER_CHUNK {
            result[i * BYTES_PER_CHUNK + j] = slice_bytes[j];
        }
    }

    let base64_elements_in_final_chunk = InputElements - ((num_chunks - 1) * BASE64_ELEMENTS_PER_CHUNK);

    let mut slice: Field = 0;
    for j in 0..base64_elements_in_final_chunk {
        slice *= 64;
        slice += encoded[(num_chunks - 1) * BASE64_ELEMENTS_PER_CHUNK + j] as Field;
    }
    for _ in base64_elements_in_final_chunk..BASE64_ELEMENTS_PER_CHUNK {
        slice *= 64;
    }
    // TODO: check is it cheaper to use a constant value in `to_be_bytes` or can we use `bytes_in_final_chunk`?
    let slice_bytes: [u8; 30] = slice.to_be_bytes(30).as_array();
    let num_bytes_in_final_chunk = OutputBytes - ((num_chunks - 1) * BYTES_PER_CHUNK);
    for i in 0..num_bytes_in_final_chunk {
        result[(num_chunks - 1) * BYTES_PER_CHUNK + i] = slice_bytes[i];
    }
    result
}

/**
 * @brief Take an array of packed base64 encoded bytes and convert into ASCII
 **/
pub fn base64_decode<let InputBytes: u32, let OutputElements: u32>(input: [u8; InputBytes]) -> [u8; OutputElements] {
    //  let decoded: [u8; InputBytes] = base64_decode_elements(input);
    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // we pack 40 base64 values into a field element and convert into 30 bytes
    // TODO: once we support arithmetic ops on generics, derive OutputBytes from InputBytes
    let mut result: [u8; OutputElements] = [0; OutputElements];
    let BASE64_ELEMENTS_PER_CHUNK: u32 = 40;
    let BYTES_PER_CHUNK: u32 = 30;
    let num_chunks = (InputBytes / BYTES_PER_CHUNK) + (InputBytes % BYTES_PER_CHUNK != 0) as u32;

    for i in 0..num_chunks - 1 {
        let mut slice: Field = 0;
        for j in 0..BYTES_PER_CHUNK {
            slice *= 256;
            slice += input[i * BYTES_PER_CHUNK + j] as Field;
        }

        let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64, 40).as_array();
        for j in 0..BASE64_ELEMENTS_PER_CHUNK {
            result[i * BASE64_ELEMENTS_PER_CHUNK + j] = slice_base64_chunks[j];
        }
    }

    let bytes_in_final_chunk = InputBytes - ((num_chunks - 1) * BYTES_PER_CHUNK);

    let mut slice: Field = 0;
    for j in 0..bytes_in_final_chunk {
        slice *= 256;
        slice += input[(num_chunks - 1) * BYTES_PER_CHUNK + j] as Field;
    }
    for _ in bytes_in_final_chunk..BYTES_PER_CHUNK {
        slice *= 256;
    }

    // TODO: check is it cheaper to use a constant value in `to_be_bytes` or can we use `bytes_in_final_chunk`?
    let slice_base64_chunks: [u8; 40] = slice.to_be_radix(64, 40).as_array();

    let num_elements_in_final_chunk = OutputElements - ((num_chunks - 1) * BASE64_ELEMENTS_PER_CHUNK);
    for i in 0..num_elements_in_final_chunk {
        result[(num_chunks - 1) * BASE64_ELEMENTS_PER_CHUNK + i] = slice_base64_chunks[i];
    }
    base64_decode_elements(result)
}

// ooook so we take ascii and encode as base64, we get an undefined character
#[test]
fn test_base64_decode_elements() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU=
    // Translated directly to ASCII (with the = padding character stripped)
    let ascii_expected: [u8; 43] = [
        71, 120, 77, 108, 103,
        119, 76, 105, 121, 112,
        110, 86, 114, 69, 50,
        67, 48, 83, 102, 52,
        121, 122, 104, 99, 87,
        84, 107, 65, 104, 83,
        90, 53, 43, 87, 69,
        82, 104, 75, 104, 88,
        116, 108, 85
    ];

    let input: [u8; 43] = [
        6, 49, 12, 37, 32, 48, 11, 34, 50, 41, 39, 21, 43, 4, 54, 2, 52, 18, 31, 56, 50, 51, 33, 28, 22, 19, 36, 0, 33, 18, 25, 57, 62, 22, 4, 17, 33, 10, 33, 23, 45, 37, 20
    ];

    let ascii_result = base64_decode_elements(input);

    assert(ascii_result == ascii_expected);
}

#[test]
fn test_base64_encode() {
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

    let result: [u8; 32] = base64_encode(input);
    let expected: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ];
    assert(result == expected);
}

#[test]
fn test_base64_decode() {
    // Raw bh: GxMlgwLiypnVrE2C0Sf4yzhcWTkAhSZ5+WERhKhXtlU
    // Translated directly to ASCII (with padding byte character stripped)
    let expected: [u8; 43] = [
        71, 120, 77, 108, 103,
        119, 76, 105, 121, 112,
        110, 86, 114, 69, 50,
        67, 48, 83, 102, 52,
        121, 122, 104, 99, 87,
        84, 107, 65, 104, 83,
        90, 53, 43, 87, 69,
        82, 104, 75, 104, 88,
        116, 108, 85
    ];

    let input: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ];

    let result: [u8; 43] = base64_decode(input);
    assert(result == expected);
}

#[test]
fn test_base64_decode_slash() {
    let input: [u8; 1] = [63]; // '/' in Base64
    let result: [u8;1] = base64_decode_elements(input);

    // Should map to '/' in ASCII, which is 47
    assert(result[0] == 47);
}
