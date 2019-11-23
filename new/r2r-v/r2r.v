import (
	os
	time
	term
	filepath
// 	radare.r2
)

struct R2R {
mut:
	cmd_tests []R2RTest
//	r2 &r2.R2
	failed int
}

struct R2RTest {
mut:
	name string
	file string
	args string
	source string
	cmds string
	expect string
	// mutable
	broken bool
	failed bool
	fixed bool
	times i64
}

pub fn main() {
	println('Loading tests')
	os.chdir('..')
	mut r2r := R2R{}
	r2r.load_tests()
	r2r.run_tests()
}

fn (r2r mut R2R) load_cmd_test(testfile string) {
	mut test := R2RTest{}
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
					if token.starts_with("'") {
						println('Warning: Deprecated syntax, use <<EOF in ${test.source} @ ${test.name}')
					} else if token.starts_with('"') {
						println('Warning: Deprecated syntax, use <<EOF in ${test.source} @ ${test.name}')
					} else if token.starts_with('"') {
						println('Warning: Deprecated syntax, use <<EOF in ${test.source} @ ${test.name}')
					} else if token.starts_with('<<') {
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
				if kv.len > 1 {
					test.broken = kv[1].len > 0 && kv[1] == '1'
				} else {
					println('Warning: Missing value for BROKEN in ${test.source}')
				}
			}
			'EXPECT' {
				if kv.len < 2 {
					panic('<2')
				}
				token := kv[1]
				if token.starts_with("'") {
					println('Warning: Deprecated syntax, use <<EOF in ${test.source} @ ${test.name}')
				} else if token.starts_with('"') {
					println('Warning: Deprecated syntax, use <<EOF in ${test.source} @ ${test.name}')
				} else if token.starts_with('<<') {
					slurp_target = &test.expect
					slurp_token = token.substr(2, token.len)
				} else {
					test.expect = line.substr(7, line.len)
				}
			}
			'ARGS' {
				if kv.len > 0 {
					test.args = line.substr(5, line.len)
				} else {
					println('Warning: Missing value for ARGS in ${test.source}')
				}
			}
			'FILE' {
				test.file = line.substr(5, line.len)
			}
			'NAME' {
				test.name = line.substr(5, line.len)
			}
			'RUN' {
				if test.name.len == 0 {
					println('Invalid test name in ${test.source}')
				} else {
					if test.name == '' {
						panic('invalid test')
					} else {
						if test.file == '' {
							test.file = '-'
						}
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

/*
fn (r2r R2R)run_commands(test R2RTest) string {
	res := ''
	for cmd in cmds {
		if isnil(cmd) {
			continue
		}
		res += r2r.r2.cmd(cmd)
	}
	return res
}
*/

fn (r2r mut R2R)run_test(test mut R2RTest) {
	time_start := time.ticks()
	tmp_dir := os.tmpdir()
	tmp_script := filepath.join(tmp_dir, 'script.r2')
	tmp_stderr := filepath.join(tmp_dir, 'stderr.txt')
	tmp_output := filepath.join(tmp_dir, 'output.txt')

	os.write_file(tmp_script, test.cmds)
	// TODO: handle timeout
	os.system('r2 -e scr.utf8=0 -e scr.interactive=0 -e scr.color=0 -NQ -i ${tmp_script} ${test.args} ${test.file} 2> ${tmp_stderr} > ${tmp_output}')
	res := os.read_file(tmp_output) or { panic(err) }

	os.rm(tmp_script)
	os.rm(tmp_output)
	os.rm(tmp_stderr)
	os.rmdir(tmp_dir)

	mut mark := 'OK'
	if res.trim_space() != test.expect.trim_space() {
		test.failed = true
		r2r.failed++
		if !test.broken {
			println(test.file)
			println(term.ok_message(test.cmds))
			println(term.fail_message(test.expect))
			println(term.ok_message(res))
			mark = 'XX'
		} else {
			mark = 'BR'
		}
	} else {
		if test.broken {
			test.fixed = true
			mark = 'FX'
		}
	}
	time_end := time.ticks()
	test.times = time_end - time_start
	println('[${mark}] (time ${test.times}) ${test.source} : ${test.name}')
}

fn (r2r mut R2R)run_tests() {
	println('Running tests')
	// r2r.r2 = r2.new()
	mut fixed := 0
	mut broken := 0
	for t in r2r.cmd_tests {
		r2r.run_test(mut t)
		if t.broken {
			broken++
			if t.fixed {
				fixed++
			}
		}
	}
	println('')
	success := r2r.cmd_tests.len - r2r.failed
	println('Broken: ${broken} / ${r2r.cmd_tests.len}')
	println('Fixxed: ${fixed} / ${r2r.cmd_tests.len}')
	println('Succes: ${success} / ${r2r.cmd_tests.len}')
	println('Failed: ${r2r.failed} / ${r2r.cmd_tests.len}')
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
	db_path := 'db'
	dirs := os.ls(db_path) or { panic(err) }
	for dir in dirs {
		if dir == 'archos' {
			println('TODO: archos tests')
		} else if dir == 'asm' {
			r2r.load_asm_tests('$(db_path)/$(dir)')
		} else {
			r2r.load_cmd_tests('${db_path}/${dir}')
		}
	}
}
