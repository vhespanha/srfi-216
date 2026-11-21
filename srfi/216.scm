;; Implementation of SRFI 216, written from the specification text.

;;; Constants

(define true #t)
(define false #f)
(define nil '())
(define the-empty-stream '())

;;; Streams
;; A stream is a pair whose cdr is an R7RS promise, so SICP's own
;; stream-car (car) and stream-cdr (force of the cdr) work unchanged.

(define-syntax cons-stream
  (syntax-rules ()
    ((_ a b) (cons a (delay b)))))

(define (stream-null? x) (null? x))

;;; Time
;; Microseconds since the Epoch, as an exact integer.  Built on
;; current-second rather than jiffies, which have no fixed epoch.

(define (runtime)
  (exact (floor (* (current-second) 1000000))))

;;; Randomness
;; An exact positive integer n gives an exact integer in [0, n).  Any
;; other positive real x gives an inexact real in [0, x).  Anything
;; else is an error.  The default source is randomized at load time so
;; each session sees a different sequence.  Some implementations (Chibi
;; among them) randomize from a clock with one-second resolution, so we
;; also fold in the microsecond part of the current time, using only
;; SRFI 27 operations.

(random-source-randomize! default-random-source)
(random-source-pseudo-randomize! default-random-source
                                 (modulo (runtime) 1000000)
                                 (random-integer 1000000000))

;;; Concurrency
;; Teaching-grade primitives on top of SRFI 18.

;; Run each thunk in its own thread and wait for all of them.  Every
;; thread is joined even if some raise; then the first error, in thunk
;; order, is re-raised in the caller.  Each thread catches its own
;; error so the caller sees the original condition object.  An error
;; is boxed in a one-element list, so the value #f means none.
(define (parallel-execute . thunks)
  (define (capture thunk)
    (guard (e (#t (list e))) (thunk) #f))
  (let* ((threads
          (map (lambda (thunk)
                 (thread-start! (make-thread (lambda () (capture thunk)))))
               thunks))
         (errors
          ;; A thread's result is its own captured error, or #f; a
          ;; join that itself raises (say, a terminated thread) counts too.
          (map (lambda (t) (guard (e (#t (list e))) (thread-join! t)))
               threads)))
    (let loop ((errors errors))
      (cond ((null? errors))
            ((car errors) => (lambda (boxed) (raise (car boxed))))
            (else (loop (cdr errors)))))))

;; One library-wide mutex makes every test-and-set! atomic with respect
;; to every other.
(define test-and-set-mutex (make-mutex 'test-and-set!))

;; If (car cell) is false, set it to #t.  Either way return its old value.
;; The mutex is released on every exit, so a call that raises (say, on
;; an immutable pair) cannot leave every later call deadlocked.
(define (test-and-set! cell)
  (if (not (pair? cell))
      (error "test-and-set!: argument must be a pair" cell))
  (dynamic-wind
   (lambda () (mutex-lock! test-and-set-mutex))
   (lambda ()
     (let ((old (car cell)))
       (if (not old) (set-car! cell #t))
       old))
   (lambda () (mutex-unlock! test-and-set-mutex))))

;; A non-integer x must also be finite once made inexact: +inf.0, or an
;; exact rational too large for a flonum, would yield +inf.0 or +nan.0.
(define (random x)
  (cond ((not (and (real? x)
                   (positive? x)
                   (or (exact-integer? x) (finite? (inexact x)))))
         (error "random: argument must be a positive real number" x))
        ((exact-integer? x) (random-integer x))
        (else (* (inexact x) (random-real)))))
