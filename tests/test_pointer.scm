(use-modules (oop goops)
             (aiscm element)
             (aiscm pointer)
             (aiscm mem)
             (aiscm bool)
             (aiscm int)
             (aiscm var)
             (ice-9 regex)
             (guile-tap))
(planned-tests 17)
(define m1 (make <mem> #:size 10))
(define m2 (make <mem> #:size 4))
(define p1-bool (make-pointer <bool> m1))
(define p2-bool (make-pointer <bool> m2))
(define p1-byte (make-pointer <byte> m1))
(define p2-byte (make-pointer <byte> m2))
(define p1-sint (make-pointer <sint> m1))
(define p2-sint (make-pointer <sint> m2))
(write-bytes m1 #vu8(1 2 3 4 5 6 7 8 9 10))
(write-bytes m2 #vu8(0 0 0 0))
(todo '((ok (equal? p1-bool (make-pointer <bool> m1))
          "equal pointers")) "not working")
(ok (not (equal? p1-bool p2-bool))
  "unequal pointers")
(ok (not (equal? p1-bool p1-byte))
  "unequal pointers (different type)")
(ok (equal? (make-bool #t) (fetch p1-bool))
  "fetch boolean from memory")
(ok (equal? (make-byte 1) (fetch p1-byte))
  "fetch byte from memory")
(ok (equal? (make-sint #x0201) (fetch p1-sint))
  "fetch short integer from memory")
(ok (equal? (make-byte 123) (store p2-byte (make-byte 123)))
  "store function returns value")
(ok (equal? (make-sint 123) (store p2-sint (make-byte 123)))
  "store function converts value to type of target")
(ok (equal? (make-sint #x0201) (begin
                                  (store p2-sint (make-sint #x0201))
                                  (fetch p2-sint)))
  "storing and fetching back short int")
(ok (equal? (+ m2 2) (get-value (+ p2-sint 1)))
  "pointer operations are aware of size of element")
(ok (equal? (make-sint #x0403) (fetch (lookup p1-sint 1 1)))
  "lookup second element with stride 1")
(ok (equal? (make-sint #x0605) (fetch (lookup p1-sint 2 1)))
  "lookup third element with stride 1")
(ok (equal? (make-sint #x0605) (fetch (lookup p1-sint 1 2)))
  "lookup second element with stride 2")
(ok (equal? (make-sint #x0a09) (fetch (lookup p1-sint 2 2)))
  "lookup third element with stride 2")
(ok (equal? <sint> (typecode p1-sint))
  "get element type from pointer")
(ok (string-match "^#<<pointer<int<16,signed>>> #x[0-9a-f]*>$"
  (call-with-output-string (lambda (port) (write p1-sint port))))
  "write pointer object")
(ok (string-match "^#<<pointer<int<16,signed>>> #x[0-9a-f]*>$"
  (call-with-output-string (lambda (port) (display p1-sint port))))
  "display pointer object")
(format #t "~&")
