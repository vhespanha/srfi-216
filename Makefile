CHIBI ?= chibi-scheme

.PHONY: test

# Run the suite; fail on a non-zero exit or any FAIL/ERROR line
# (the same markers snow-chibi checks when it runs --test at install time).
test:
	$(CHIBI) -I . tests/run.scm > test.log 2>&1; status=$$?; cat test.log; \
	  test $$status -eq 0 && ! grep -q -e FAIL -e ERROR test.log
