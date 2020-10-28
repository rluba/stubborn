# Stubborn – a test assertion and matcher library for Jai

Stubborn is a first attempt at porting [Hamjest](https://github.com/rluba/hamjest) to Jai.
It’s still very, *very*, **veeery** early and contains only a handful of matchers, but it already supports …

* … enumerating and running all tests at compile-time.
* … parameterized tests
* … compile errors that point to the failed assertion

Unfortunately, I haven’t found an elegant way to support nesting of matchers yet. Baby steps.

# Writing tests

Tests are normal functions annotated with `@Test` inside any file ending in `.spec.jai`:

```Jai
// visit_files.spec.jai
your_test_function_with_a_descriptive_name :: () {

} @Test
```

Use `assert_that(actualValue, matcher)` to write test assertions:

```Jai
// visit_files.spec.jai
ignores_dirs_and_follows_links_by_default :: () {
	result: [..] string;
	defer cleanup(result);

	success := visit_files("tests/links", true, *result, (info: *File_Visit_Info, result: * [..] string) {
		array_add(result, copy_string(info.full_name));
	});

	assert_that(success, is(true));
	assert_that(result, contains_in_any_order(
		"tests/links/link_dir/file.txt",
		"tests/links/real_dir/file.txt",
		"tests/links/linked.txt",
		"tests/links/broken_link"
	));
} @Test
```

The first failing assertion will stop compilation with an error at the line of the assert.
See [Matchers](#Matchers) for a list of available matchers.

## Parameterized tests

You probably want to parameterize some of your tests to avoid repeating the same test code over and over again.
Simply provide a global array with the parameters thats called like your test function + `_params` and let your test function take an argument:

```Jai
// count_a.spec.jai

Count_Test_Args :: struct {
	input: string;
	expected: int;
}

counts_number_of_as_correctly_params :: Count_Test_Args.[
	.{"jonathan", 2},
	.{"raphael", 2},
	.{"jim", 0},
	.{"jane", 1},
];

counts_number_of_as_correctly :: (args: Count_Test_Args) {
	result := count_a(args.input);

	assert_that(result, is(args.expected));
} @Test
```

Running the tests will (hopefully) output:

```
count_a.spec.jai:
	counts_number_of_as_correctly({"jonathan", 2}): PASSED
	counts_number_of_as_correctly({"raphael", 2}): PASSED
	counts_number_of_as_correctly({"jim", 0}): PASSED
	counts_number_of_as_correctly({"jane", 1}): PASSED
```

# Running the tests

`#load` (not `#import`!) the [run.jai](./run.jai) as part of you build file and call `build_tests(…)`:

```Jai
#load "modules/stubborn/run.jai";

#run {
	args := compiler_get_command_line_arguments();

	entrypoint := ifx args.count then args[0] else "";
	if entrypoint == "test" {
		run_tests("<path_to_your_test_folder>", #string END
			// Any code or modules that should be loaded before the tests are run goes here…
			// For example:
			#load "your_main_entry_file.jai";
		END, <paths to custom modules go here>);
	} else {
		// Your normal build stuff goes here…
	}
}
```

Stubborn will recursively enumerate all files ending in `.spec.jai` inside the folder you pass to `run_tests`, compile them, find all methods annotated with `@Test` and run them.

Tests will be run in the lexicographical order of their file names and in the order they’re define inside each file.

The first failing assertion stops compilation.

# Matchers

For now, this module contains only a minimal set of [Hamjest’s](https://github.com/rluba/hamjest) matchers:

* `is(expected_value)` for any type
* `contains(.. expected_values)` for arrays
* `contains_in_any_order(.. expected_values` for arrays
* `has_count` for anything with a `.count` member (arrays, strings, collections, …)

None of the matchers support nesting, yet.

