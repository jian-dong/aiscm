(use-modules (oop goops)
             (srfi srfi-1)
             (srfi srfi-26)
             (ice-9 optargs)
             (ice-9 curried-definitions)
             (aiscm util)
             (aiscm element)
             (aiscm pointer)
             (aiscm mem)
             (aiscm sequence)
             (aiscm jit)
             (aiscm op)
             (aiscm int))

(define a (make <var> #:type <int> #:symbol 'a))
(define b (make <var> #:type <int> #:symbol 'b))
(define c (make <var> #:type <int> #:symbol 'c))

(define prog (list (MOV a 0) (NOP) (MOV b a) (RET)))
(define l (live-intervals (live-analysis prog) (variables prog)))
(define s (spill-variable a (ptr <int> RSP 8) prog))
(update-intervals l (index-groups s))
(length (flatten-code s))

(use-modules (oop goops))
(define-class <x> ())
(define x (make <x>))
(define-method (- (x <x>)) (list '- x))
(define-method (+ (x <x>)) (list '+ x))
