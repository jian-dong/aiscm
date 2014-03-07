(use-modules (aiscm sequence)
             (aiscm element)
             (aiscm lambda)
             (aiscm int)
             (oop goops)
             (guile-tap))
(define s1 (make (sequence <sint>) #:size 3))
(define s2 (make (sequence <sint>) #:size 3))
(set s1 0 2) (set s1 1 3) (set s1 2 5)
(planned-tests 13)
(ok (equal? <sint> (typecode (sequence <sint>)))
    "query element type of sequence class")
(ok (equal? (sequence <sint>) (sequence <sint>))
    "equality of classes")
(ok (eqv? 3 (get-size s1))
    "query size of sequence")
(ok (equal? <sint> (typecode s1))
    "query element type of sequence")
(ok (equal? 9 (begin (set s2 2 9) (get s2 2)))
    "write value to sequence")
(ok (equal? 9 (set s2 2 9))
    "write value returns input value")
(ok (equal? '(3) (shape s1))
    "query shape of sequence")
(ok (equal? 2 (get-size (slice s1 1 2)))
    "size of slice")
(ok (equal? 5 (get (slice s1 1 2) 1))
    "element of slice")
(ok (equal? '(2 3 5) (sequence->list s1))
    "convert sequence to list")
(ok (equal? '(3 5)) (sequence->list (slice s1 1 2))
    "extract slice of values from sequence")
(ok (equal? "#<sequence<int<16,signed>>>:\n(2 3 5)"
      (call-with-output-string (lambda (port) (write s1 port))))
    "write lambda object")
(ok (equal? "#<sequence<int<16,signed>>>:\n(2 3 5)"
      (call-with-output-string (lambda (port) (display s1 port))))
    "display lambda object")
(format #t "~&")
