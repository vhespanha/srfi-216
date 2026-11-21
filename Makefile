CHIBI ?= chibi-scheme
SNOW ?= snow-chibi

VERSION = 1.0.0
TARBALL = srfi-216-$(VERSION).tgz
AUTHOR := $(shell git config user.name)
DESCRIPTION = SRFI 216: SICP Prerequisites (Portable)

LIB = srfi/216.sld
SOURCES = $(LIB) srfi/216.scm srfi/216/test.sld tests/run.scm
DOC = doc/srfi-216.html

# snow-chibi saves prompt history under $HOME/.snow on every run.  Packaging
# needs no keys or config, so run it with a throwaway HOME inside the repo.
BUILD_HOME = $(CURDIR)/.build-home

.PHONY: all test package publish clean

all: test

# Run the suite; fail on a non-zero exit or any FAIL/ERROR line
# (the same markers snow-chibi checks when it runs --test at install time).
test:
	$(CHIBI) -I . tests/run.scm > test.log 2>&1; status=$$?; cat test.log; \
	  test $$status -eq 0 && ! grep -q -e FAIL -e ERROR test.log

# The tarball is only built after the tests pass.  --test-library (rather
# than --test with a program) ships srfi/216/test.sld in the tarball and
# generates run-tests.scm, so snow-chibi can run the same suite at install.
package: $(TARBALL)

$(TARBALL): $(SOURCES) $(DOC)
	$(MAKE) test
	mkdir -p $(BUILD_HOME)
	HOME=$(BUILD_HOME) $(SNOW) package \
	  --version $(VERSION) \
	  --authors "$(AUTHOR)" \
	  --license mit \
	  --description "$(DESCRIPTION)" \
	  --doc $(DOC) \
	  --test-library "(srfi 216 test)" \
	  $(LIB)

# Upload to snow-fort with the maintainer's key.  Maintainer only.
publish: $(TARBALL)
	$(SNOW) upload $(TARBALL)

clean:
	rm -rf $(TARBALL) *.log test-out.txt test-err.txt $(BUILD_HOME)
