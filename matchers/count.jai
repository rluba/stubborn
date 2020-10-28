has_count :: (count: int) -> *Count_Matcher {
	matcher := TNew(Count_Matcher);
	matcher.count = count;
	return matcher;
}

matches :: (using m: *Count_Matcher, actual: $T) -> bool {
	return actual.count == count;
}

describe :: (using m: *Count_Matcher, description: *Description) {
	append(description, "an array or collection with ");
	append_value(description, count);
	append(description, " items");
}

describe_mismatch :: (using m: *Count_Matcher, actual: $T, description: *Description) {
	append(description, "count was ");
	append_value(description, actual.count);
	append(description, " for ");
	append_value(description, actual);
}

#scope_file

Count_Matcher :: struct {
	count: int;
}
