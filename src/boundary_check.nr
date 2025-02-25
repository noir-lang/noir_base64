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
    let r = unsafe {
        //@safety r contains claims about whether `r[i] >= limit`. the rest of this function checks this claim is correct
        __boundary_check(limit)
    };

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
        assert_eq(r[Range - 1] * r[Range - 1], r[Range - 1]);
        transition_index = transition_index + (1 - r[Range - 1]) * limit as Field;
        assert(transition_index == limit as Field);
        r
    } else {
        [0; Range]
    }
}
