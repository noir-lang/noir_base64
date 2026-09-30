unconstrained fn __boundary_check<let Range: u32>(limit: u32) -> [Field; Range] {
    let mut r: [Field; Range] = [0; Range];
    for i in limit..Range {
        r[i] = 1;
    }
    r
}

/**
 * @brief Return a size-Range array of values that describe whether an index `i` is in the range `0<=i<limit`
 * @details When evaluating variable-length loops of size `limit`, it is neccessary to iterate over a maximum bound defined at compile-time
 *          Any constraints or evaluations that occur where `i >= limit` must be discarded.
 *          This is most efficiently performed by using predicate `Field` values, where `predicate[i] = 0` if `i < limit`, otherwise `predicate[i] = 1`.
 *          This method efficiently generates such predicate values more efficiently than querying whether `i <= limit` at every iteration.
 *          Gate cost is 3 * Range
 **/
pub fn boundary_check<let Range: u32>(limit: u32) -> [Field; Range] {
    // Safety: r contains claims about whether `r[i] >= limit`. assert_boundary_mask checks this claim is correct
    let r = unsafe { __boundary_check(limit) };
    assert_boundary_mask(r, limit)
}

// Validates that `r` is the unique suffix mask for `limit` (r[i] == 1 iff i >= limit).
fn assert_boundary_mask<let Range: u32>(r: [Field; Range], limit: u32) -> [Field; Range] {
    let mut transition_index = 0;
    // **
    // We have an array of Field elements `r` such that:
    // if i < limit, `r = 0`
    // if i >= limit, `r = 1`
    // We validate the predicate list `r` is correct by checking:
    // 1. every r[i] element is 0 or 1
    // 2. if r[i] = 1, r[i+1] must also be 1
    // 3. if r[i] = 0 and r[i+1] = 1, then i == limit
    // we check point 3 by tracking a `transition_index` variable, where
    // transition_index += (1 - r[i]) * (r[i+1]) * i
    // i.e. if r[i] == 0 and r[i+1] == 1, transition_index += i
    //      else transition_index += 0
    // NOTE: total constraint cost is 3 gates per iteration
    // **
    if Range > 0 {
        for i in 0..Range - 1 {
            assert_eq(r[i] * r[i], r[i]);
            assert_eq(r[i] * r[i + 1], r[i]);
            let idx = (r[i + 1] * (1 - r[i])) * (i as Field + 1);
            transition_index = transition_index + idx;
            std::as_witness(transition_index);
        }
        assert_eq(r[Range - 1], (limit < Range) as Field);
        transition_index = transition_index + (1 - r[Range - 1]) * limit as Field;
        assert(transition_index == limit as Field);
        r
    } else {
        [0; Range]
    }
}

#[test]
fn test_boundary_check_limit_zero_masks_everything() {
    assert_eq(boundary_check::<8>(0), [1, 1, 1, 1, 1, 1, 1, 1]);
}

#[test]
fn test_boundary_check_interior_limit() {
    assert_eq(boundary_check::<8>(3), [0, 0, 0, 1, 1, 1, 1, 1]);
    assert_eq(boundary_check::<8>(7), [0, 0, 0, 0, 0, 0, 0, 1]);
}

#[test]
fn test_boundary_check_limit_at_or_beyond_range_masks_nothing() {
    assert_eq(boundary_check::<8>(8), [0; 8]);
    assert_eq(boundary_check::<8>(20), [0; 8]);
}

#[test]
fn test_boundary_check_all_limits_match_definition() {
    for limit in 0..10 as u32 {
        let r = boundary_check::<8>(limit);
        for i in 0..8 {
            assert_eq(r[i], (i >= limit) as Field);
        }
    }
}

#[test]
fn test_boundary_check_range_one() {
    assert_eq(boundary_check::<1>(0), [1]);
    assert_eq(boundary_check::<1>(1), [0]);
}

#[test]
fn test_boundary_check_zero_range() {
    let r: [Field; 0] = boundary_check::<0>(0);
    assert_eq(r.len(), 0);
    let r: [Field; 0] = boundary_check::<0>(5);
    assert_eq(r.len(), 0);
}

// An all-zeroes mask must not work when limit < Range
#[test(should_fail)]
fn test_all_zeros_mask_rejected_when_limit_below_range() {
    let _ = assert_boundary_mask::<8>([0; 8], 3);
}

// The legitimate degenerate case: when limit >= Range the honest mask IS all
// zeros, so any fix for the above must keep accepting it here.
#[test]
fn test_all_zeros_mask_accepted_when_limit_at_range() {
    let _ = assert_boundary_mask::<8>([0; 8], 8);
}

// Other malicious masks the constraints already reject - pin that behavior.
#[test(should_fail)]
fn test_mask_with_wrong_transition_rejected() {
    // transition at 5 instead of 3
    let _ = assert_boundary_mask::<8>([0, 0, 0, 0, 0, 1, 1, 1], 3);
}

#[test(should_fail)]
fn test_non_monotonic_mask_rejected() {
    let _ = assert_boundary_mask::<8>([0, 0, 0, 1, 0, 1, 1, 1], 3);
}

#[test(should_fail)]
fn test_non_boolean_mask_rejected() {
    let _ = assert_boundary_mask::<8>([0, 0, 0, 3, 1, 1, 1, 1], 3);
}

// Honest masks for every limit in 0..=Range are accepted.
#[test]
fn test_honest_masks_accepted() {
    for limit in 0..9 as u32 {
        // Safety: honest hint output, validated by assert_boundary_mask
        let r = unsafe { __boundary_check::<8>(limit) };
        let _ = assert_boundary_mask(r, limit);
        for i in 0..8 {
            assert_eq(r[i], (i >= limit) as Field);
        }
    }
}
