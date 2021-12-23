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
		if get_current_workspace() == 0 {
			print("Assertion failed at %:%:%:\n%\n", loc.fully_pathed_filename, loc.line_number, loc.character_number, error);
			exit(1);
		} else {
			compiler_report(error, loc);
		}
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
	return New(T, initialized, __temporary_allocator);
}

#scope_file

#import "Compiler";
