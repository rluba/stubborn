Description :: struct {
	builder: String_Builder;
	indentation := 0;
}

append :: (using d: *Description, value: $T) {
	#if T == string {
		if indentation {
			remaining := value;
			index := find_index_from_left(remaining, #char "\n");
			while index >= 0 {
				segment := slice(remaining, 0, index + 1);
				remaining = slice(remaining, index + 1, remaining.count - index - 1);
				append(*builder, segment);
				for 0..indentation - 1	append(*builder, #char "\t");
				index = find_index_from_left(remaining, #char "\n");
			}
			append(*builder, remaining);
		} else {
			append(*builder, value);
		}
	} else {
		print_to_builder(*builder, "%", value);
	}
}

// ToDo: Cleanup once using works in macros
indented :: (using d: *Description, code: Code) #expand {
	d.indentation += 1;
	#insert code;
	d.indentation -= 1;
}

append_value :: (using d: *Description, value: $T) {
	#insert #run () -> string {
		info := type_info(T);
		if info.type == {
			case .ARRAY;
				return #string END
					append_list(d, value, start = "[", end = "]");
				END;
			case .STRING;
				return #string END
					append(d, "\"");
					append(d, value);
					append(d, "\"");
				END;
			case .INTEGER; #through;
			case .FLOAT;
				return #string END
					print_to_builder(*builder, "<%>", value);
				END;
			case .BOOL;
				return #string END
					print_to_builder(*builder, "%", value);
				END;
			case .STRUCT;
				return #string END
					print_to_builder(*builder, "%", value);
				END;
			case;
				return #string END
					append(d, value);
				END;
		}
	}();
}

append_list :: (using d: *Description, list: [] $T, start := "", separator := ", ", end := "") {
	append(d, start);
	for list {
		if it_index {
			append(d, separator);
		}
		// @ToDo: Handle matchers here
		append_value(d, it);
	}
	append(d, end);
}

#scope_file

#import "Basic";
#import "String";
