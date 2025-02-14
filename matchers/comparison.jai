
build_comparison_matcher :: (compare_to_value : $T, compare_op : $F, compare_desc : string) -> *Comparison_Matcher(T) {
	matcher := TNew(Comparison_Matcher(T));
   matcher.compare_op = compare_op;
	matcher.compare_to_value = compare_to_value;
   matcher.compare_desc = compare_desc;
	return matcher;

}

less_than :: (compare_to_value: $T) -> *Comparison_Matcher(T) {
   compare_op :: (a : T, b : T) -> bool {
      return a < b;
   }
   return build_comparison_matcher(compare_to_value, compare_op, " less than ");
}

less_than_or_equal_to :: (compare_to_value: $T) -> *Comparison_Matcher(T) {
   compare_op :: (a : T, b : T) -> bool {
      return a <= b;
   }
   return build_comparison_matcher(compare_to_value, compare_op, " less than or equal to ");
}

greater_than :: (compare_to_value: $T) -> *Comparison_Matcher(T) {
   compare_op :: (a : T, b : T) -> bool {
      return a > b;
   }
   return build_comparison_matcher(compare_to_value, compare_op, " greater than ");
}

greater_than_or_equal_to :: (compare_to_value: $T) -> *Comparison_Matcher(T) {
   compare_op :: (a : T, b : T) -> bool {
      return a >= b;
   }
   return build_comparison_matcher(compare_to_value, compare_op, " greater than or equal to ");
}

matches :: (using m: *Comparison_Matcher($T), actual: T) -> bool {
   return m.compare_op(actual, compare_to_value);
}

describe :: (using m: *Comparison_Matcher($T), description: *Description) {
	info := type_info(T);
	append(description, "a ");
	append(description, info.type);
	append(description, m.compare_desc);
	append_value(description, compare_to_value);
}

describe_mismatch :: (using m: *Comparison_Matcher($T), actual: T, description: *Description) {
	append(description, "was ");
	append_value(description, actual);
}

#scope_file

Comparison_Matcher :: struct (T: Type) {
   compare_to_value: T;
   compare_op : (T, T) -> bool;
   compare_desc : string;
}

Math :: #import "Math";
