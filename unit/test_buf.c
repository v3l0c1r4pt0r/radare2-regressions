#include <r_util.h>
#include "minunit.h"

#define FILENAME __FILE__

bool test_r_buf_file_new() {
	RBuffer *b;
	char buffer[1024] = { 0 };
	int r;

	b = r_buf_new_file (FILENAME, 0);
	mu_assert_notnull (b, "r_buf_new_file failed");

	r = r_buf_read_at (b, R_BUF_CUR, buffer, 20);
	mu_assert_eq (r, 20, "r_buf_read_at failed");

	mu_assert_streq (buffer, "#include <r_util.h>\n", "r_buf_read_at has corrupted content");

	mu_end;
}

int all_tests() {
	mu_run_test (test_r_buf_file_new);
	return tests_passed != tests_run;
}

int main(int argc, char **argv) {
	return all_tests();
}
