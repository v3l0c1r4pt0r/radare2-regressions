import (
	os
	filepath
	radare.r2
)

struct R2R {
mut:
	cmd_tests []R2RTest
	r2 &r2.R2
	failed int
}

struct R2RTest {
mut:
	name string
	file string
	source string
	cmds string
	expect string
	broken bool
	failed bool
}

pub fn main() {
	println('Loading tests')
	mut r2r := R2R{}
	r2r.load_tests()
	r2r.run_tests()
}

fn (r2r mut R2R) load_cmd_test(testfile string) {
	mut test := R2RTest{}
	println(testfile)
	lines := os.read_lines(testfile) or { panic(err) }
	mut slurp_token := '' 
	mut slurp_data := ''
	mut slurp_target := &test.cmds
	test.source = testfile
	for line in lines {
		if line.len == 0 {
			continue
		}
		if slurp_token.len > 0 {
			if line == slurp_token {
				*slurp_target = slurp_data
				slurp_data = ''
				slurp_token = ''
			} else {
				slurp_data += '${line}\n'
			}
			continue
		}
		kv := line.split('=')
		if kv.len == 0 {
			continue
		}
		match kv[0] {
			'CMDS' {
				if kv.len > 1 {
					token := kv[1]
					if token.starts_with('<<') {
						slurp_target = &test.cmds
						slurp_token = token.substr(2, token.len)
					} else {
						test.expect = line.substr(7, line.len)
					}
				} else {
				 	panic('Missing arg to cmds')
				}
			}
			'BROKEN' {
				test.broken = false // kv.len > 0 && kv[1].len > 0 && kv[1] == '1'
			}
			'EXPECT' {
				if kv.len < 2 {
					panic('<2')
				}
				token := kv[1]
				if token.starts_with('<<') {
					slurp_target = &test.expect
					slurp_token = token.substr(2, token.len)
				} else {
					test.expect = line.substr(7, line.len)
				}
			}
			'ARGS' {
				println('TODO: ARGS')
			}
			'FILE' {
				test.file = line.substr(5, line.len)
			}
			'NAME' {
				test.name = line.substr(5, line.len)
			}
			'RUN' {
				if test.name.len == 0 {
					println('Invalid name')
				} else {
						if test.name == '' {
							panic('invalid test')
						} else {
							r2r.cmd_tests << test
						}
					test = R2RTest{}
					test.source = testfile
				}
			}
		}
		// println(line)
	}
}

fn (r2r R2R)run_commands(file string, cmds []string) string {
	mut res := ''
	for cmd in cmds {
		if isnil(cmd) {
			continue
		}
		println('1: ${cmd}')
		res += r2r.r2.cmd(cmd)
		println('2: ${cmd}')
	}
	return res
}

fn (r2r mut R2R)run_test(test mut R2RTest) {
	println('Running test ${test.name}')
	res := r2r.run_commands(test.file, test.cmds.split("\n"))
	if res != test.expect {
		test.failed = true
		r2r.failed++
		println("[XX]")
	} else {
		println("OK")
	}
}

fn (r2r mut R2R)run_tests() {
	r2r.r2 = r2.new()
	for t in r2r.cmd_tests {
		r2r.run_test(mut t)
		println('[${t.source}] ${t.name}')
		println('  ${t.cmds}')
	}
	println('')
	println('Total ${r2r.cmd_tests.len} tests executed')
	println('Failed ${r2r.failed}')
}

fn (r2r mut R2R)load_cmd_tests(testpath string) {
	files := os.ls(testpath) or { panic(err) }
	for file in files {
		f := filepath.join(testpath, file)
		if os.is_dir (f) {
			r2r.load_cmd_tests(f)
		} else {
			r2r.load_cmd_test(f)
		}
	}
}

fn (r2r R2R)load_asm_tests(testpath string) {
	println('TODO: asm tests')
}

fn (r2r mut R2R)load_tests() {
	r2r.cmd_tests = []
	db_path := '../db'
	dirs := os.ls(db_path) or { panic(err) }
	for dir in dirs {
		if dir == 'archos' {
			println('TODO: archos tests')
		} else if dir == 'asm' {
			r2r.load_asm_tests('$(db_path)/$(dir)')
		} else {
			println(dir)
			r2r.load_cmd_tests('${db_path}/${dir}')
		}
	}
}
