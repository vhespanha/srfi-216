;; SRFI 216: SICP Prerequisites (Portable)
;; Library declaration; the implementation lives in 216.scm.
(define-library (srfi 216)
  (export true false nil the-empty-stream
          runtime random parallel-execute test-and-set!
          stream-null? cons-stream)
  (import (scheme base) (scheme lazy) (scheme time) (srfi 18) (srfi 27))
  (include "216.scm"))
