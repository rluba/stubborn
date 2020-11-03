assert_that :: (actual: $T, matcher: *$M, reason := "", loc := #caller_location) {
	if !matches(matcher, actual) {
		description: Description;
		defer free_buffers(*description.builder);

		if reason {
			append(*description, reason);
			append(*description, "\n");
		}

		append(*description, "Expected: ");
		describe(matcher, *description);

		indented(*description, #code {
			append(*description, "\nbut: ");
			describe_mismatch(matcher, actual, *description);
		});

		error := builder_to_string(*description.builder);
		compiler_report_error(loc.fully_pathed_filename, loc.line_number, loc.character_number, error);
	}
}

#load "description.jai";
#load "matchers/contains.jai";
#load "matchers/contains_unordered.jai";
#load "matchers/count.jai";
#load "matchers/is.jai";
#load "matchers/not.jai";

#scope_module

TNew :: ($T: Type, $initialized := true) -> *T {
	return New(T, initialized, __temporary_allocator, null);
}

slice :: inline (array: [] $T, index: int, count: int) -> [] T {
    assert(index >= 0, "index = %", index);             // @@ Should we also clamp in these cases?
    assert(count >= 0, "count = %", count);
	c: [] T = ---;
    if index >= array.count {
		c.data = null;
		c.count = 0;
		return c;
	}

    if index + count > array.count {
        count = array.count - index;
    }

    c.data = array.data + index;
    c.count = count;
    return c;
}

#scope_file

#import "Compiler";
