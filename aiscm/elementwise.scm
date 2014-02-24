(define-module (aiscm elementwise)
  #:use-module (ice-9 r5rs)
  #:use-module (oop goops)
  #:use-module (aiscm element)
  #:use-module (ice-9 r5rs)
  #:use-module (aiscm int)
  #:export (minus
            plus))
(define-method (minus (x <element>))
  (make (class-of x) #:value (- (get-value x))))
(define-method (plus (a <element>) (b <element>))
  (make (coerce (class-of a) (class-of b)) #:value (+ (get-value a) (get-value b))))
