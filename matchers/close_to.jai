close_to :: (expected: $T, $tolerance: float = 0.001) -> *Close_To_Matcher(T) {
   matcher := TNew(Close_To_Matcher(T));
   matcher.tolerance = tolerance;
   matcher.expected = expected;
   return matcher;
}

matches :: (using m: *Close_To_Matcher($T), actual: T) -> bool {
   return Math.abs(expected - actual) <= tolerance;
}

describe :: (using m: *Close_To_Matcher($T), description: *Description) {
   info := type_info(T);
   append(description, "a ");
   append(description, info.type);
   append(description, " close to ");
   append_value(description, expected);
}

describe_mismatch :: (using m: *Close_To_Matcher($T), actual: T, description: *Description) {
   append(description, "was ");
   append_value(description, actual);
   append_value(description, " (delta ");
   append_value(description, expected - actual);
   append_value(description, ")");
}

#scope_file

Close_To_Matcher :: struct (T: Type) {
   expected: T;
   tolerance: float;
}

Math :: #import "Math";
