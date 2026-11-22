CHIBI ?= chibi-scheme
SNOW ?= snow-chibi

VERSION = 1.0.0
TAG = v$(VERSION)
TARBALL = srfi-216-$(VERSION).tgz
AUTHOR = Vinicius Hespanha Souza
DESCRIPTION = SRFI 216: SICP Prerequisites (Portable)

LIB = srfi/216.sld
SOURCES = $(LIB) srfi/216.scm srfi/216/test.sld tests/run.scm
DOC = doc/srfi-216.html

# snow-chibi saves prompt history under $HOME/.snow on every run.  Packaging
# needs no keys or config, so run it with a throwaway HOME inside the repo.
BUILD_HOME = $(CURDIR)/.build-home

.PHONY: all test package index clean

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

# Add this release to .snow-repo.scm, the index users point --repo at.
# Run it on the commit tagged $(TAG), then commit the index on main.
#
# snow-chibi rebuilds a git-installed package from the .sld files alone,
# so run-tests.scm never reaches the installer and a (test ...) entry would
# make every install fail its tests.  The index is therefore built from a
# test-less tarball; the release tarball above keeps the suite.
#
# git-index reads remote.origin.url and mangles scp-style git@host:user/repo
# URLs (the user becomes a port), so hand it the https URL through git's
# environment config, which outranks the repo's own.
INDEX_DIR = $(BUILD_HOME)/index
REPO_URL = https://github.com/vhespanha/srfi-216.git

index:
	@test "$$(git describe --exact-match --tags HEAD 2>/dev/null)" = "$(TAG)" || \
	  { echo "HEAD is not tagged $(TAG)" >&2; exit 1; }
	$(MAKE) test
	mkdir -p $(INDEX_DIR)
	HOME=$(BUILD_HOME) $(SNOW) package \
	  --version $(VERSION) \
	  --authors "$(AUTHOR)" \
	  --license mit \
	  --description "$(DESCRIPTION)" \
	  --doc $(DOC) \
	  --output-dir $(INDEX_DIR) \
	  $(LIB)
	HOME=$(BUILD_HOME) GIT_CONFIG_COUNT=1 \
	  GIT_CONFIG_KEY_0=remote.origin.url GIT_CONFIG_VALUE_0=$(REPO_URL) \
	  $(SNOW) git-index $(INDEX_DIR)/$(TARBALL)

clean:
	rm -rf $(TARBALL) *.log test-out.txt test-err.txt $(BUILD_HOME)
