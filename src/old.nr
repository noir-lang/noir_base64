// global BASE64_DECODE_BE: [u8; 128] = [
// 0,0,0,0,0,0,0,0,0,0,           // 0-9
// 0,0,0,0,0,0,0,0,0,0,           // 10-19
// 0,0,0,0,0,0,0,0,0,0,           // 20-29
// 0,0,0,0,0,0,0,0,0,0,           // 30-39
// 0,0,0,                         // 40-42
// 62,                            // 43
// 0,0,0,                         // 44-46
// 63,                            // 47
// 52,53,54,55,56,57,58,59,60,61, // 48-57
// 0,0,0,0,0,0,0,                 // 58-64
// 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25, // 65-90 (A-Z)
// 0,0,0,0,0,0,                   // 91-96
// 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51, // 97-122 (a-z)
// 0,0,0,0,0                      // 123-127
// ];

// global BASE64_DECODE_LE: [u8; 128] = [
// 0,0,0,0,0,0,0,0,0,0,           // 0-9
// 0,0,0,0,0,0,0,0,0,0,           // 10-19
// 0,0,0,0,0,0,0,0,0,0,           // 20-29
// 0,0,0,0,0,0,0,0,0,0,           // 30-39
// 0,0,0,                         // 40-42
// 62,                            // 43
// 0,0,0,                         // 44-46
// 63,                            // 47
// 52,53,54,55,56,57,58,59,60,61, // 48-57
// 0,0,0,0,0,0,0,                 // 58-64
// 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25, // 65-90 (A-Z)
// 0,0,0,0,0,0,                   // 91-96
// 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51, // 97-122 (a-z)
// 0,0,0,0,0                      // 123-127
// ];

// ok so base64...we convert into a bunch of big endian values. these represent 6 bit chunks
// we then take the resulting byte array (concat the bits together) and convert into little endian byte stream

// so say we have 27 and 22
//  0 1 1 1 0 1 (27) = A
//  0 1 0 1 1 0 (22) = B

// total_bits[0] = A[0]
// total_bits[1] = A[1]

// total_bits = [0 1 1 1 0 1 0 1 0 1 1 0]

// output[0] = 
//              total_bits[0] << 7
//              total_bits[1] << 6
//              total_bits[2] << 5
//              total_bits[3] << 4
//              total_bits[4] << 3
//              total_bits[5] << 2
//              total_bits[6] << 1
//              total_bits[7] << 0
//                                  = 0 1 1 1 0 1 0 1
fn base64_decode<let InputElements: u64, let OutputBytes: u64>(input: [u8; InputElements]) -> [u8; OutputBytes] {
    // let BASE64_DECODE_BE: [u8; 128] = [
    //     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 0-9
    //     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 10-19
    //     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 20-29
    //     0, 0, 0, 0, 0, 0, 0, 0, 0, 0,// 30-39
    //     0, 0, 0,// 40-42
    //     62,// 43
    //     0, 0, 0,// 44-46
    //     63,// 47
    //     52, 53, 54, 55, 56, 57, 58, 59, 60, 61,// 48-57
    //     0, 0, 0, 0, 0, 0, 0,// 58-64
    //     0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,// 65-90 (A-Z)
    //     0, 0, 0, 0, 0, 0,// 91-96
    //     26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,// 97-122 (a-z)
    //     0, 0, 0, 0, 0// 123-127
    // ];
    let mut BASE64_DECODE_BE = Lookup::new();

    // 240 bits fits 40 6-bit chunks and 30 8-bit chunks
    // we pack 40 base64 values into a field element and convert into 30 bytes
    // TODO: once we support arithmetic ops on generics, derive OutputBytes from InputBytes
    let mut result: [u8; OutputBytes] = [0; OutputBytes];
    let BASE64_ELEMENTS_PER_CHUNK: u64 = 40;
    let BYTES_PER_CHUNK: u64 = 30;
    let num_chunks = (InputElements / BASE64_ELEMENTS_PER_CHUNK)
        + (InputElements % BASE64_ELEMENTS_PER_CHUNK != 0) as u64;
    println(f"num chunks = {num_chunks}");
    for i in 0..num_chunks - 1 {
        let mut slice: Field = 0;
        for j in 0..BASE64_ELEMENTS_PER_CHUNK {
            slice *= 64;
            let idx = input[i * BASE64_ELEMENTS_PER_CHUNK + j] as Field;
            slice += BASE64_DECODE_BE.get(idx);
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
        slice += BASE64_DECODE_BE.get(input[(num_chunks - 1) * BASE64_ELEMENTS_PER_CHUNK + j] as Field);
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

#[test]
fn test_bodyhash_base64_decode1() {
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
    let res: [u8; 32] = base64_decode(input);
    println(f"DECODED = {res}");
    let expected_res: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ];
    assert(res == expected_res);
}

fn base64_lookup_old(input: u8) -> u8 {
    // A-Z: 65-90
    if input >= 65 & input <= 90 {
        input - 65
    } else if input >= 97 & input <= 122 {
        // a-z: 97-122
        input - 71
    } else if input >= 48 & input <= 57 {
        // 0-9: 48-57
        input + 4
    } else if input == 43 {
        // +
        62
    } else if input == 47 {
        // /
        63
    } else {
        // =
        0
    }
}
global BODY_HASH_BASE64_LENGTH: u64 = 44;

fn bodyhash_base64_decode_old(encoded: [u8; BODY_HASH_BASE64_LENGTH]) -> [u8; 32] {
    let mut total_bits = [0 as u1; BODY_HASH_BASE64_LENGTH * 6];
    for i in 0..BODY_HASH_BASE64_LENGTH {
        let translate = base64_lookup_old(encoded[i] as u8);
        // Store as big endian
        let translate_bits = (translate as Field).to_be_bits(6);
        for j in 0..6 {
            total_bits[i * 6 + j] = translate_bits[j];
        }
    }

    // Since we're returning the SHA256 hash, only need first 32 bytes (=256 bits)
    let mut output = [0 as u8; 32];
    for i in 0..32 {
        for j in 0..8 {
            // Convert from big endian back to little endian
            output[i] |= (total_bits[i * 8 + j] as u8) << (7 - j) as u8;
        }
    }

    output
}

#[test]
fn test_bodyhash_base64_decode_old() {
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
    let res: [u8; 32] = bodyhash_base64_decode_old(input);
    println(f"DECODED = {res}");
    let expected_res: [u8; 32] = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ];
    assert(res == expected_res);
}

// 130,485
// 143,241
// 12,756
fn main2(x: [u8; 44]) {
    for i in 0..11 {
        let r = bodyhash_base64_decode_old(x);
        println(f"{r}");
    }
}

struct Lookup {
    table: [Field; 128]
}

impl Lookup {
    fn new() -> Self {
        Lookup {
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
                0, 0, 0, 0, 0, 0, 0,// 58-64
                0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,// 65-90 (A-Z)
                0, 0, 0, 0, 0, 0,// 91-96
                26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,// 97-122 (a-z)
                0, 0, 0, 0, 0// 123-127
            ]
        }
    }

    fn get(self, idx: Field) -> Field {
        self.table[idx]
    }
}

// global foo: Lookup = Lookup::new();

fn main3(x: [Field; 44]) {
    let mut Table = Lookup::new();

    // 12 constraints per iteration?
    for i in 0..34 {
        let ff = Table.get(x[i]);
        println(f"{ff}");
        // slice += BASE64_DECODE_BEE[x[i] as Field] as Field;
        // println(f"{slice}");
    }
}
// 489 - 18 = 471
// 779 - 1250 = 471
fn main(x: [u8; 44]) {
    for i in 0..1 {
        let r: [u8; 32] = base64_decode(x);
        println(f"{r}");
    }
}
// 11,748
// 11,488

// 1448
// 2018
// 570