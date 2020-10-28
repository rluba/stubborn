contains_in_any_order :: (itemsOrMatchers: .. $T, $is_equal: (T, T) -> bool = null) -> *Contains_Unordered_Matcher(T, is_equal) {
	// ToDo: Check if T is a matcher or not
	// If it isn’t, we need to wrap it in a "is" matcher
	matcher := TNew(Contains_Unordered_Matcher(T, is_equal));
	matcher.items = array_copy(itemsOrMatchers);
	return matcher;
}

matches :: (using m: *Contains_Unordered_Matcher($T, $E), actual: [] T) -> bool {
	if actual.count != items.count	return false;

	remaining := array_copy(items);
	defer array_free(remaining);

	for item: actual {
		found := false;
		for remaining {
			if is_equal(it, item) {
				found = true;
				remove it;
				break;
			}
		}
		if !found	return false;
	}

	return remaining.count == 0;
}

describe :: (using m: *Contains_Unordered_Matcher($T, $E), description: *Description) {
	append_list(description, items, start = "[", end = "]");
	append(description, " in any order");
}

describe_mismatch :: (using m: *Contains_Unordered_Matcher($T, $E), actual: [] T, description: *Description) {
	remaining := array_copy(items);
	defer array_free(remaining);

	not_found: [..] T;
	for item: actual {
		found := false;
		for remaining {
			if is_equal(it, item) {
				found = true;
				remove it;
				break;
			}
		}
		if !found {
			array_add(*not_found, item);
		}
	}
	if remaining.count {
		append(description, "no item in ");
		append_value(description, actual);
		indented(description, #code {
			append_list(description, remaining, start = " matches:\n", separator = ",\n");
		});
		append(description, "\n");
	}
	if not_found.count {
		indented(description, #code {
			append_list(description, not_found, start = "not matched:\n", separator = ",\n");
		});
	}
}

#scope_file

Contains_Unordered_Matcher :: struct (T: Type, given_is_equal: (T, T) -> bool) {
	items: [] T;
    #if given_is_equal {
        is_equal :: given_is_equal;
    } else {
        is_equal :: (a: T, b: T) -> bool { return a == b; };
    }
}

