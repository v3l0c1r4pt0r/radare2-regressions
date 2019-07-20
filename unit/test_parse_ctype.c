#include <r_parse.h>
#include "minunit.h"

bool test_r_parse_ctype(void) {
	RParseCType *ctype = r_parse_ctype_new ();
	mu_assert_notnull (ctype, "r_parse_ctype_new");
	char *error;
	RParseCTypeType *type = r_parse_ctype_parse (ctype, "const char * [0x42] const * [23]", &error);
	if (error) {
		eprintf ("%s\n", error);
		free (error);
	}
	mu_assert_notnull (type, "r_parse_ctype_parse");

	RParseCTypeType *cur = type;

	mu_assert_eq (cur->kind, R_PARSE_CTYPE_TYPE_KIND_ARRAY, "array");
	mu_assert_eq (cur->array.count, 23, "array count (dec)");
	cur = cur->array.type;

	mu_assert_eq (cur->kind, R_PARSE_CTYPE_TYPE_KIND_POINTER, "pointer");
	mu_assert_eq (cur->pointer.is_const, true, "pointer const");
	cur = cur->pointer.type;

	mu_assert_eq (cur->kind, R_PARSE_CTYPE_TYPE_KIND_ARRAY, "array");
	mu_assert_eq (cur->array.count, 0x42, "array count (hex)");
	cur = cur->array.type;

	mu_assert_eq (cur->kind, R_PARSE_CTYPE_TYPE_KIND_POINTER, "pointer");
	mu_assert_eq (cur->pointer.is_const, false, "pointer non-const");
	cur = cur->pointer.type;

	mu_assert_eq (cur->kind, R_PARSE_CTYPE_TYPE_KIND_IDENTIFIER, "identifier");
	mu_assert_eq (cur->identifier.is_const, true, "identifier const");
	mu_assert_streq (cur->identifier.name, "char", "identifier name");

	r_parse_ctype_type_free (type);
	r_parse_ctype_free (ctype);
	mu_end;
}

int all_tests() {
	mu_run_test (test_r_parse_ctype);
	return tests_passed != tests_run;
}

int main(int argc, char **argv) {
	return all_tests();
}
