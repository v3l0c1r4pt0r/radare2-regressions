#TESTS=t/cmd_pd
#TESTS+=t/cmd_ph
#TESTS+=t/cmd_disasm
#TESTS+=t/cmd_graph
#TESTS+=t/cmd_help
#TESTS+=t/cmd_i
#TESTS+=t/cmd_json
TESTS+=t.anal/others_anal/aaa


all:
	npm install >/dev/null
	$(npm bin)/r2r

fix:
	npm install > /dev/null
	$(npm bin)/r2r -i

generate:
	mkdir -p db/cmd
	cd .. ; for a in $(TESTS) ; do \
		d=$$(dirname $$a) ; \
		mkdir -p new/db/cmd/$$d ; \
		DUMP=1 $$a > new/db/cmd/$$a ; \
	done

run:
	time node bin/r2r.js
