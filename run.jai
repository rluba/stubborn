INTERNAL_PREAMBLE :: #string END
#import "stubborn";

print_temporary_usage :: () {
	mark := get_temporary_storage_mark();
	temp_use: s64;
	temp_use = mark.occupied;
	page := mark.top_overflow_page;
	while page {
		temp_use += page.size;
		page = page.next;
	}
	print(" (temporary memory use: %b)", temp_use);
}

END

TEST_TEMPLATE :: #string END
print("\t%1: ");
%1();
print("PASSED\n");
#if %2	print_temporary_usage();
print("\n");
reset_temporary_storage();
END
TEST_SKIPPED_TEMPLATE :: #string END
print("\t%1: SKIPPED\n");
END

PARAMETERIZED_TEST_TEMPLATE :: #string END
for %1_params {
	print("\t%1(%%): ", it);
	%1(it);
	print("PASSED");
	#if %2	print_temporary_usage();
	print("\n");
	reset_temporary_storage();
}
END
PARAMETERIZED_TEST_SKIPPED_TEMPLATE :: #string END
for %1_params {
	print("\t%1(%%): SKIPPED\n", it);
}
END

TEST_ENTRY_POINT :: "run_tests";

// args can currently only be names of tests (to skip all other tests)
build_tests :: (dir: string, preamble := "", module_paths: .. string = .[], args: [] string = .[], run := true, print_temporary_memory_usage := false) {
    build_options := get_build_options();
    build_options.output_type = .NO_OUTPUT;
    set_build_options(build_options);

    w := compiler_create_workspace();

	build_options.backend = .LLVM;
	if run {
		build_options.output_type = .NO_OUTPUT;
	} else {
		build_options.output_type = .EXECUTABLE;
		build_options.output_executable_name = "test";
		build_options.entry_point_name = TEST_ENTRY_POINT;
	}

	build_options.import_path = module_paths;

    set_build_options(build_options, w);

	// Generate #load statements for all test files
	load_builder: String_Builder;
	defer free_buffers(*load_builder);
	append(*load_builder, INTERNAL_PREAMBLE);
	append(*load_builder, preamble);

	visit_files(dir, true, *load_builder, (info: *File_Visit_Info, builder: *String_Builder) {
		if ends_with(info.short_name, ".spec.jai") {
			print_to_builder(builder, "#load \"%\";", info.full_name);
		}
	}, follow_symlinks = false);

	loads := builder_to_string(*load_builder);
	defer free(loads);

	compiler_begin_intercept(w);
	add_build_string(loads, w);

	// Gather all tests from the loaded files and run them
	tests_injected := false;
	tests: [..] Test;
	while true {
		message := compiler_wait_for_message();
		if !message continue;

		if message.workspace == w {
			if message.kind == {
				case .TYPECHECKED;
					tc := cast(*Message_Typechecked) message;
					for decl: tc.declarations {
						if !is_test_decl(decl)	continue;

						header := cast(*Code_Procedure_Header) decl.root_expression;

						test: Test;
						test.filename = copy_string(header.filename);
						test.line_number = header.l0;
						test.name = copy_string(header.name);
						test.is_parameterized = header.arguments.count > 0;
						// Skip all tests that weren’t passed explicitly, if some were passed
						test.is_skipped = args.count && !array_find(args, header.name);

						array_add(*tests, test);
					}
				case .COMPILATION_PHASE;
					mp := cast(*Message_Phase) message;
					if mp.phase == .TYPECHECKED_ALL_WE_CAN && !tests_injected {
						tests_injected = true;

						intro_sort(tests, sort_by_file_and_line);

						test_builder: String_Builder;
						defer free_buffers(*test_builder);
						if run {
							append(*test_builder, "#run {\n");
						} else {
							append(*test_builder, TEST_ENTRY_POINT);
							append(*test_builder, " :: () {\n");
						}
						last_filename: string;
						for tests {
							if compare(last_filename, it.filename) {
								print_to_builder(*test_builder, "print(\"%%:\\n\", \"%\");\n", it.filename);
								last_filename = it.filename;
							}
							template: string;

							if it.is_parameterized {
								template := ifx it.is_skipped then PARAMETERIZED_TEST_SKIPPED_TEMPLATE else PARAMETERIZED_TEST_TEMPLATE;
								print_to_builder(*test_builder, template, it.name, print_temporary_memory_usage);
							} else {
								template := ifx it.is_skipped then TEST_SKIPPED_TEMPLATE else TEST_TEMPLATE;
								print_to_builder(*test_builder, template, it.name, print_temporary_memory_usage);
							}
						}
						append(*test_builder, "}\n");

						run_tests_code := builder_to_string(*test_builder);
						defer free(run_tests_code);

						add_build_string(run_tests_code, w);
					}
				case .COMPLETE;
					break;
			}
		}
	}

	compiler_end_intercept(w);
}

#scope_file

Test :: struct {
	filename: string;
	line_number: s32;
	name: string;
	is_parameterized: bool;
	is_skipped: bool;
}

is_test_decl :: (decl: *Code_Declaration) -> bool {
	if decl.flags & .IS_IMPORTED return false; // Do not process declarations twice.
	if !decl.name || !is_alpha(decl.name[0]) return false; // Make sure it's an identifier that has a name (…and not an operator).

	if !decl.root_expression return false;
	if decl.root_expression.kind != .PROCEDURE_HEADER return false;

	if !decl.notes return false;

	for note: decl.notes {
		if note.text == "Test" {
			return true;
		}
	}
	return false;
}

sort_by_file_and_line :: (a: Test, b: Test) -> int {
	result := compare(a.filename, b.filename);
	if result == 0 {
		return ifx a.line_number < b.line_number then -1 else 1;
	}
	return result;
}

#import "Compiler";
#import "File_Utilities";
#import "Basic";
#import "String";
#import "IntroSort";

