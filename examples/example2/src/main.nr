use dep::noir_base64;

fn main(input: [u8; 44]) {
    let result: [u8; 32] = noir_base64::base64_encode(input);
    let expected = [
        27, 19, 37, 131, 2, 226, 202, 153, 213, 172,
        77, 130, 209, 39, 248, 203, 56, 92, 89, 57,
        0, 133, 38, 121, 249, 97, 17, 132, 168, 87,
        182, 85
    ];
    assert(result == expected);
}
