use dep::noir_base64;

fn main(){
}

#[test]
fn test_encode_elements_noir() {
    // Convert "Noir" in ASCII to Base64

    // "Noir" in ASCII equals [78, 111, 105, 114]
    let input: [u8; 4] = [78, 111, 105, 114];
    
    // Mapping to Base64
    // N -> 13
    // o -> 40
    // i -> 34
    // r -> 43
    let result: [u8; 4] = noir_base64::base64_encode_elements(input);
    assert(result == [13, 40, 34, 43]);
}

#[test]
fn test_encode_packed_noir() {
    // Convert "Noir" in ASCII to Base64 (packed)

    // "Noir" in ASCII equals [78, 111, 105, 114]
    let input: [u8; 4] = [78, 111, 105, 114];
    
    // Mapping to Base64
    // N -> 13
    // o -> 40
    // i -> 34
    // r -> 43
    let result: [u8; 3] = noir_base64::base64_encode(input);

    // Base64 values are 6 bits. 
    // Instead of putting each of them in a separate byte, glue them together and then chop up into bytes:

    // 13      |   40    |   34    |   43 
    // 001101  | 101000  | 100010  | 101011
    // 001101101000100010101011 <- glue together
    // 00110110 | 10001000 | 10101011 <- chop up in bytes
    //    54     |    136    |    171 <- decimal representation

    assert(result == [54, 136, 171]);
}

