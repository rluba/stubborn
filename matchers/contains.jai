contains :: (itemsOrMatchers: .. $T, $is_equal: (T, T) -> bool = null) -> *Contains_Ordered_Matcher(T, is_equal) {
	// ToDo: Check if T is a matcher or not
	// If it isn’t, we need to wrap it in a "is" matcher
	matcher := TNew(Contains_Ordered_Matcher(T, is_equal));
	matcher.items = array_copy(itemsOrMatchers);
	return matcher;
}

matches :: (using m: *Contains_Ordered_Matcher($T, $E), actual: [] T) -> bool {
	if actual.count != items.count	return false;
	for actual {
		if !is_equal(it, items[it_index])	return false;
	}
	return true;
}

describe :: (using m: *Contains_Ordered_Matcher($T, $E), description: *Description) {
	append_list(description, items, start = "[", end = "]");
}

describe_mismatch :: (using m: *Contains_Ordered_Matcher($T, $E), actual: [] T, description: *Description) {
	first := true;
	for actual {
		if items.count > it_index {
			if !is_equal(it, items[it_index]) {
				if first {
					first = false;
				} else {
					append(description, "\n");
				}
				append(description, "item ");
				append(description, it_index);
				append(description, ": ");
				// ToDo: Use mismatch description instead:
				append(description, it);
			}
		}
	}
	if (!first) {
		append(description, "\n");
	}
	if actual.count > items.count {
		indented(description, #code {
			append_list(description, slice(actual, items.count, actual.count - items.count), start = "not matched:\n");
		});
	} else if (actual.count < items.count) {
		indented(description, #code {
			append_list(description, slice(items, actual.count, items.count - actual.count), start = "missing:\n");
		});
	}
}

#scope_file

Contains_Ordered_Matcher :: struct (T: Type, given_is_equal: (T, T) -> bool) {
	items: [] T;
    #if given_is_equal {
        is_equal :: given_is_equal;
    } else {
        is_equal :: (a: T, b: T) -> bool { return a == b; };
    }
}

