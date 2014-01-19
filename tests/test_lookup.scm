(use-modules (aiscm element)
             (aiscm lookup)
             (aiscm malloc)
             (aiscm pointer)
             (aiscm var)
             (aiscm int)
             (oop goops)
             (guile-tap))
(define m (make-malloc 8))
(define p (make-pointer <byte> m))
(define v (make-var))
(planned-tests 5)
(ok (equal? p (get-value (make-lookup p v 2)))
  "query value of lookup object")
(ok (eq? v (get-offset (make-lookup p v 2)))
  "query offset of lookup object")
(ok (eqv? 2 (get-stride (make-lookup p v 2)))
  "query stride of lookup object")
(ok (equal? (make-lookup p v 2) (lookup p v 2))
  "lookup with variable")
(ok (equal? (+ p 2) (subst (lookup p v 2) (list (cons v 1))))
  "substituting variable in a lookup object")
(format #t "~&")

