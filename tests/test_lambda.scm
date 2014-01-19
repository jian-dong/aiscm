(use-modules (aiscm element)
             (aiscm malloc)
             (aiscm int)
             (aiscm var)
             (aiscm pointer)
             (aiscm lookup)
             (aiscm lambda)
             (oop goops)
             (guile-tap))
(planned-tests 3)
(define m (make-malloc 8))
(write-bytes m #vu8(1 2 3 4 5 6 7 8))
(define p (make-pointer <ubyte> m))
(define v (make-var))
(define l (make-lookup p v 1))
(define s (make-lambda v l))
(ok (equal? (get-value s) l)
  "query term of lambda")
(ok (equal? (get-index s) v)
  "query index variable of lambda")
(ok (equal? (make-ubyte 2) (fetch (ref s 1)))
  "pass integer argument to lambda")
(format #t "~&")
