;; Tests for (srfi 216), using only its public interface.
(define-library (srfi 216 test)
  (export run-tests)
  (import (scheme base) (scheme lazy) (srfi 18) (srfi 64) (srfi 216))
  (begin
    (define (run-tests)
      (test-begin "srfi-216")

      (test-group "constants"
        (test-eq "true is #t" #t true)
        (test-eq "false is #f" #f false)
        (test-eqv "if false takes the alternative" 2 (if false 1 2))
        (test-eq "nil is the empty list" '() nil)
        (test-equal "cons onto nil builds a list" '(1) (cons 1 nil))
        (test-eq "the-empty-stream is the empty list" '() the-empty-stream))

      (test-group "streams"
        (let* ((forced 0)
               (s (cons-stream 'a (begin (set! forced (+ forced 1)) 'b))))
          (test-eqv "cons-stream does not evaluate its cdr" 0 forced)
          (test-eq "car of a stream is its first argument" 'a (car s))
          (test-assert "cdr of a stream is a promise" (promise? (cdr s)))
          (test-eq "forcing the cdr yields the second argument" 'b (force (cdr s)))
          (test-eqv "forcing the cdr evaluates it once" 1 forced)
          (force (cdr s))
          (test-eqv "forcing again does not re-evaluate" 1 forced))
        (let ()
          (define (integers-from n) (cons-stream n (integers-from (+ n 1))))
          (define (stream-ref s k)
            (if (= k 0) (car s) (stream-ref (force (cdr s)) (- k 1))))
          (test-eqv "infinite streams work" 10 (stream-ref (integers-from 0) 10)))
        (test-assert "stream-null? on the-empty-stream"
                     (stream-null? the-empty-stream))
        (test-assert "stream-null? on a constructed stream is false"
                     (not (stream-null? (cons-stream 'a 'b)))))

      (test-group "runtime"
        (let* ((t1 (runtime)) (t2 (runtime)))
          (test-assert "runtime returns an exact integer"
                       (and (exact-integer? t1) (exact-integer? t2)))
          (test-assert "runtime never goes down" (<= t1 t2))
          ;; 2020-09-01 (SRFI 216 draft) in microseconds since the Epoch:
          ;; a reading in seconds or milliseconds would be far below it.
          (test-assert "runtime counts microseconds since the Epoch"
                       (> t1 1598918400000000))))

      (test-group "random"
        (test-assert "exact integer n gives exact integers in [0, n)"
                     (every-sample? 1000 (lambda () (random 10))
                                    (lambda (r) (and (exact-integer? r)
                                                     (<= 0 r) (< r 10)))))
        (test-assert "exact integer results cover the range"
                     (let ((seen (make-vector 5 #f)))
                       (do ((i 0 (+ i 1))) ((= i 1000))
                         (vector-set! seen (random 5) #t))
                       (equal? seen (make-vector 5 #t))))
        (test-assert "random 1 is always 0"
                     (every-sample? 100 (lambda () (random 1))
                                    (lambda (r) (eqv? r 0))))
        (test-assert "inexact real x gives inexact reals in [0, x)"
                     (every-sample? 1000 (lambda () (random 2.5))
                                    (lambda (r) (and (real? r) (inexact? r)
                                                     (<= 0 r) (< r 2.5)))))
        (test-assert "exact rational x gives inexact reals in [0, x)"
                     (every-sample? 1000 (lambda () (random 1/2))
                                    (lambda (r) (and (real? r) (inexact? r)
                                                     (<= 0 r) (< r 1/2)))))
        (test-error "random of zero is rejected" (random 0))
        (test-error "random of a negative integer is rejected" (random -5))
        (test-error "random of a negative real is rejected" (random -0.5)))

      (test-group "parallel-execute"
        ;; SICP 3.4.1: the only possible final values of x.
        (test-assert "the book's x example only yields the listed outcomes"
                     (every-sample?
                      200
                      (lambda ()
                        (let ((x 10))
                          (parallel-execute (lambda () (set! x (* x x)))
                                            (lambda () (set! x (+ x 1))))
                          x))
                      (lambda (x) (memv x '(101 121 110 11 100)))))
        (let ((done (make-vector 5 #f)))
          (define (worker i)
            (lambda ()
              (thread-yield!)
              (thread-sleep! 0.01)
              (vector-set! done i #t)))
          (parallel-execute (worker 0) (worker 1) (worker 2)
                            (worker 3) (worker 4))
          (test-equal "returns only after every thunk has finished"
                      (make-vector 5 #t) done))
        (let ((threads '()))
          (parallel-execute
           (lambda () (set! threads (cons (current-thread) threads)))
           (lambda () (set! threads (cons (current-thread) threads))))
          (test-assert "each thunk runs in its own thread"
                       (and (= 2 (length threads))
                            (not (eq? (car threads) (cadr threads)))
                            (not (memq (current-thread) threads))))))

      (test-group "test-and-set!"
        (let ((cell (list false)))
          (test-eq "on a fresh cell it returns false" #f (test-and-set! cell))
          (test-eq "and sets the cell to true" #t (car cell))
          (test-eq "on a set cell it returns true" #t (test-and-set! cell))
          (test-eq "and leaves the cell true" #t (car cell)))
        (test-error "on a non-pair it raises" (test-and-set! 'not-a-pair))
        ;; A literal is immutable in some implementations (Chibi among
        ;; them), so this may raise from set-car! with the lock held.
        (guard (e (#t #f)) (test-and-set! '(#f)))
        (let ((cell (list false)))
          (test-eq "after a raising call it still works on a good cell"
                   #f (test-and-set! cell)))
        ;; SICP 3.4.2 make-mutex, built only from the exported primitives.
        (let ()
          (define (make-mutex)
            (let ((cell (list false)))
              (define (the-mutex m)
                (cond ((eq? m 'acquire)
                       (if (test-and-set! cell)
                           (begin (thread-yield!) (the-mutex 'acquire))))
                      ((eq? m 'release) (set-car! cell false))))
              the-mutex))
          (define threads 8)
          (define increments 200)
          (define counter 0)
          (define mutex (make-mutex))
          (define (incrementer)
            (do ((i 0 (+ i 1))) ((= i increments))
              (mutex 'acquire)
              (let ((v counter))
                (thread-yield!)
                (set! counter (+ v 1)))
              (mutex 'release)))
          (apply parallel-execute (make-list threads incrementer))
          (test-eqv "a mutex built on it excludes concurrent updates"
                    (* threads increments) counter)))

      (test-end "srfi-216"))

    ;; True when (ok? (thunk)) holds for n consecutive samples.
    (define (every-sample? n thunk ok?)
      (let loop ((i 0))
        (or (= i n)
            (and (ok? (thunk)) (loop (+ i 1))))))))
