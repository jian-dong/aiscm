(use-modules (oop goops)
             (aiscm element)
             (aiscm int)
             (aiscm elementwise)
             (guile-tap))
(planned-tests 3)
(define i (make <byte> #:value 2))
(define j (make <sint> #:value 3))
(ok (eqv? -2 (get-value (minus i)))
    "negate integer")
(ok (eqv? 5 (get-value (plus i j)))
    "add two integers")
(ok (eqv? 16 (bits (class-of (plus i j))))
    "check type coercion of addition")
(format #t "~&")
