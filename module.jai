assert_that :: (actual: $T, matcher: *$M, reason := "", loc := #caller_location) {
	if !matches(matcher, actual) {
        output_recorded_log();

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

Log_Record :: struct {
    message: string;
    is_error: bool;
    stack_trace: *Stack_Trace_Node;
}

log_records: [..] Log_Record;

push_recording_logger :: () #expand {
    remember_allocators(*log_records);
    array_reset_keeping_memory(*log_records);
    old_logger := context.logger;
    context.logger = test_recording_logger;
    `defer context.logger = old_logger;
}

test_recording_logger :: (message: string, data: *void, info: Log_Info) {
    if !message then return;

    push_allocator(log_records.allocator);
    record: Log_Record;
    record.message = copy_string(message);
    record.is_error = (info.common_flags & .ERROR) != 0;
    // if context.stack_trace {
    //     record.stack_trace = context.stack_trace.next;
    // }
    array_add(*log_records, record);
}

output_recorded_log :: () {
    write_string("\n");
    for log_records {
        if it.message[it.message.count-1] != #char "\n" {
            write_strings(it.message, "\n", to_standard_error = it.is_error);
        } else {
            write_string(it.message, to_standard_error = it.is_error);
        }

        if it.is_error && it.stack_trace {
            node := it.stack_trace;
            while node && node.info && (node.info.name == "log" || node.info.name == "log_error") {
                node = node.next;
            }
            print_stack_trace(node, to_standard_error = true);
        }
    }
}

#load "description.jai";
#load "matchers/contains.jai";
#load "matchers/contains_unordered.jai";
#load "matchers/count.jai";
#load "matchers/is.jai";
#load "matchers/not.jai";
#load "matchers/close_to.jai";
#load "matchers/comparison.jai";

#scope_module

TNew :: ($T: Type, $initialized := true) -> *T {
	return New(T, initialized,, temp);
}

#scope_file

#import "Compiler";
