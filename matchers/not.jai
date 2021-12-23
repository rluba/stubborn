// @ToDo: This should invert a matcher instead of just comparing to a literal!
is_not :: (expected: $T, $is_equal: (T, T) -> bool = null) -> *Is_Not_Matcher(T, is_equal) {
	matcher := TNew(Is_Not_Matcher(T, is_equal));
	matcher.expected = expected;
	return matcher;
}

matches :: (using m: *Is_Not_Matcher($T, $E), actual: T) -> bool {
	return !is_equal(actual, expected);
}

describe :: (using m: *Is_Not_Matcher($T, $E), description: *Description) {
	info := type_info(T);
	append(description, "a ");
	append(description, info.type);
	append(description, " not equal to ");
	append_value(description, expected);
}

describe_mismatch :: (using m: *Is_Not_Matcher($T, $E), actual: T, description: *Description) {
	append(description, "was ");
	append_value(description, actual);
}

#scope_file

Is_Not_Matcher :: struct (T: Type, given_is_equal: (T, T) -> bool) {
	expected: T;
    #if given_is_equal {
        is_equal :: given_is_equal;
    } else {
        is_equal :: (a: T, b: T) -> bool { return a == b; };
    }
}
