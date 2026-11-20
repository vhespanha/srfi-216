;; Tests for (srfi 216), using only its public interface.
(define-library (srfi 216 test)
  (export run-tests)
  (import (scheme base) (srfi 18) (srfi 64) (srfi 216))
  (begin
    (define (run-tests)
      (test-begin "srfi-216")
      (test-end "srfi-216"))))
