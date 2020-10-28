INTERNAL_PREAMBLE :: #string END
#import "stubborn";
END

TEST_TEMPLATE :: #string END
print("\t%1: ");
%1();
print("PASSED\n");
END

PARAMETERIZED_TEST_TEMPLATE :: #string END
for %1_params {
	print("\t%1(%%): ", it);
	%1(it);
	print("PASSED\n");
}
END

run_tests :: (dir: string, preamble := "") {
    build_options := get_build_options();
    build_options.output_type = .NO_OUTPUT;
    set_build_options(build_options);

    w := compiler_create_workspace();
    build_options.output_type = .NO_OUTPUT;
	build_options.backend = .X64;
	array_add(*build_options.modules_search_path_array, "modules");
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
			if message.kind == .CODE_TYPECHECKED {
				tc := cast(*Compiler_Message_Code_Typechecked) message;
				for decl: tc.declarations {
					if !is_test_decl(decl)	continue;

					header := cast(*Code_Procedure_Header) decl.root_expression;
					test: Test;
					test.filename = copy_string(header.filename);
					test.line_number = header.l0;
					test.name = copy_string(header.name);
					test.is_parameterized = header.arguments.count > 0;

					array_add(*tests, test);
				}
			} else if message.kind == .COMPILATION_PHASE {
				mp := cast(*Compiler_Message_Compilation_Phase) message;
				if mp.phase == .ALL_SOURCE_CODE_THAT_CAN_CURRENTLY_BE_INFERRED_IS_INFERRED && !tests_injected {
					tests_injected = true;

					intro_sort(tests, sort_by_file_and_line);

					test_builder: String_Builder;
					defer free_buffers(*test_builder);
					append(*test_builder, "#run {\n");
					last_filename: string;
					for tests {
						if compare(last_filename, it.filename) {
							print_to_builder(*test_builder, "print(\"%%:\\n\", \"%\");\n", it.filename);
							last_filename = it.filename;
						}
						if it.is_parameterized {
							print_to_builder(*test_builder, PARAMETERIZED_TEST_TEMPLATE, it.name);
						} else {
							print_to_builder(*test_builder, TEST_TEMPLATE, it.name);
						}
					}
					append(*test_builder, "}\n");

					run_tests_code := builder_to_string(*test_builder);
					defer free(run_tests_code);

					add_build_string(run_tests_code, w);
				}
			}
			if message.kind == .COMPLETE break;
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

