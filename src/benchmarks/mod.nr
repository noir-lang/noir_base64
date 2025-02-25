use crate::decoder::{Base64DecodeBE, Base64DecodeBENoPad};
use crate::encoder::{Base64EncodeBE, Base64EncodeBENoPad, Base64EncodeBEUrlSafe};

#[export]
fn bench_encode_610(input: [u8; 610]) -> [u8; 816] {
    Base64EncodeBE::encode(input)
}

#[export]
fn bench_encode_610_url_safe(input: [u8; 610]) -> [u8; 814] {
    Base64EncodeBEUrlSafe::encode(input)
}

#[export]
fn bench_encode_610_var(input: BoundedVec<u8, 610>) -> BoundedVec<u8, 816> {
    Base64EncodeBE::encode_var(input)
}

#[export]
fn bench_encode_610_url_safe_var(input: BoundedVec<u8, 610>) -> BoundedVec<u8, 814> {
    Base64EncodeBEUrlSafe::encode_var(input)
}

#[export]
fn bench_encode_610_no_pad(input: [u8; 610]) -> [u8; 814] {
    Base64EncodeBENoPad::encode(input)
}

#[export]
fn bench_encode_610_var_no_pad(input: BoundedVec<u8, 610>) -> BoundedVec<u8, 814> {
    Base64EncodeBENoPad::encode_var(input)
}

#[export]
fn bench_decode_610(input: [u8; 816]) -> [u8; 610] {
    (Base64DecodeBE::decode(input))
}

#[export]
fn bench_decode_610_var(input: BoundedVec<u8, 816>) -> BoundedVec<u8, 610> {
    let r = (Base64DecodeBE::decode_var(input));
    r
}

#[export]
fn bench_decode_610_no_pad(input: [u8; 816]) -> [u8; 610] {
    (Base64DecodeBENoPad::decode(input))
}

#[export]
fn bench_decode_610_var_no_pad(input: BoundedVec<u8, 816>) -> BoundedVec<u8, 610> {
    let r = (Base64DecodeBENoPad::decode_var(input));
    r
}
