/// Decomposes a Field into base-64 values, big-endian.
///
/// Example:
///
/// ```noir
/// assert_eq(to_be_radix_64::<2>(42), [0, 42]);
/// assert_eq(to_be_radix_64::<2>(1 * 64 + 2), [1, 2]);
/// assert_eq(to_be_radix_64::<3>(3 * 64 * 64 + 2 * 64 + 1), [3, 2, 1]);
/// ```
pub(crate) fn to_be_radix_64<let N: u32>(x: Field) -> [u8; N] {
    // For convenience, we get bytes in little-endian to traverse them from the beginning.
    // Because the base64 decomposition has more elements than the bytes decomposition,
    // it turns out `N * 3 / 4` is enough bytes for this.
    let bytes = x.to_le_bytes::<N * 3 / 4>();
    let mut result = [0; N];

    // For the result, we start writing from the end.
    let mut result_index = N - 1;

    // For the first byte we can simply do `byte % 64` for the low part
    // and `byte / 64` for the high part.
    // However, the second byte equals to 256 times its value. That's 4 times 64,
    // so we multiply the byte value by 4.
    // For the third byte, it equals 256*256 times its value. That's 16 times 64*64,
    // so we multiply the byte value by 16 this time.
    // For the fourth byte, it equals 256*256*256 times its value. That's 64 times 64*64*64
    // so here we just need to start writing to the result position shifting by one.
    // And so on...
    let mut multiplier = 1;

    for index in 0..bytes.len() {
        let byte = bytes[index] as u16 * multiplier;

        result[result_index] += (byte % 64) as u8;
        result[result_index - 1] += (byte / 64) as u8;
        result_index -= 1;

        multiplier *= 4;
        if (multiplier == 64) & (index != bytes.len() - 1) {
            multiplier = 1;
            result_index -= 1;
        }
    }

    result
}

#[test]
fn test_to_be_radix_64(field: Field) {
    let bytes = to_be_radix_64::<43>(field);

    // Compute the field value from the bytes decomposition
    // and check that it ends up being the same as the original value.
    let mut result = 0;
    let mut multiplier = 1;
    for index in 0..bytes.len() {
        let index = bytes.len() - index - 1;
        let byte = bytes[index];
        let value = byte as Field * multiplier;
        result += value;
        multiplier *= 64;
    }
    assert_eq(field, result);
}
