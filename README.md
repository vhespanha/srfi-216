# srfi-216

A portable R7RS implementation of
[SRFI 216: SICP Prerequisites (Portable)](https://srfi.schemers.org/srfi-216/srfi-216.html),
packaged for `snow-chibi`. It gives you the primitives
*Structure and Interpretation of Computer Programs* assumes, so book code runs
unchanged.

## Install

With `snow-chibi` 0.12 or later and `git` on your path:

```sh
snow-chibi --repo=https://raw.githubusercontent.com/vhespanha/srfi-216/main/.snow-repo.scm \
  install '(srfi 216)'
```

`--repo` points `snow-chibi` at this repository's package index, and the
package is cloned from the tagged release it names. Install-time tests are
not run this way; clone the repo and run `make test` for those.

Without `git`, download `srfi-216-1.0.0.tgz` from the
[v1.0.0 release](https://github.com/vhespanha/srfi-216/releases/tag/v1.0.0)
and install the file directly, which also runs the test suite:

```sh
snow-chibi install srfi-216-1.0.0.tgz
```

The library needs `(srfi 18)` threads and `(srfi 27)` random numbers from the
host Scheme.

## Usage

```scheme
(import (scheme base) (scheme lazy) (srfi 216))

(define (stream-car s) (car s))
(define (stream-cdr s) (force (cdr s)))
(define (integers-from n) (cons-stream n (integers-from (+ n 1))))

(stream-car (stream-cdr (integers-from 1)))   ; => 2
(random 10)                                   ; => exact integer in [0, 10)
(runtime)                                     ; => microseconds since the Epoch
```

`(srfi 216)` does not export `force`, since the SRFI fixes the exports. Import
`(scheme lazy)` yourself to define `stream-cdr` as the book does.

Exports: `true`, `false`, `nil`, `the-empty-stream`, `runtime`, `random`,
`parallel-execute`, `test-and-set!`, `stream-null?`, `cons-stream`.
See [doc/srfi-216.html](doc/srfi-216.html) for how each one behaves where the
SRFI leaves room for choice.

## Development

```sh
make test      # run the SRFI 64 suite on chibi-scheme
make package   # run the tests, then build srfi-216-1.0.0.tgz
make index     # on the v1.0.0 tag: add the release to .snow-repo.scm
make clean     # remove build artefacts
```

SRFI 216 was written by Vladimir Nikishkin. This implementation is MIT licensed;
see [LICENSE](LICENSE).
