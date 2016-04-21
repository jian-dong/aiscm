(define-module (aiscm op)
  #:use-module (oop goops)
  #:use-module (ice-9 curried-definitions)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (aiscm util)
  #:use-module (aiscm asm)
  #:use-module (aiscm jit)
  #:use-module (aiscm mem)
  #:use-module (aiscm element)
  #:use-module (aiscm pointer)
  #:use-module (aiscm bool)
  #:use-module (aiscm int)
  #:use-module (aiscm rgb)
  #:use-module (aiscm complex)
  #:use-module (aiscm sequence)
  #:export (fill)
  #:re-export (+ - * / % = < <= > >= min max))
(define ctx (make <context>)); TODO: remove this

(define-method (to-type (target <meta<element>>) (self <sequence<>>))
  (let [(proc (let [(fun (jit ctx (list (class-of self)) (cut to-type target <>)))]
                (lambda (target self) (fun self))))]
    (add-method! to-type
                 (make <method>
                       #:specializers (list (class-of target) (class-of self))
                       #:procedure proc))
    (to-type target self)))

(define (fill type shape value)
  (let [(retval (make (multiarray type (length shape)) #:shape shape))]
    (store retval value)
    retval))
;(define-unary-op conj conj)
;(define-syntax-rule (capture-binary-argument name type)
;  (begin
;    (define-method (name (a <element>) (b type)) (name a (make (match b) #:value b)))
;    (define-method (name (a type) (b <element>)) (name (make (match a) #:value a) b))))
;(define-syntax-rule (define-binary-op name op)
;  (begin
;    (define-method (name (a <element>) (b <element>))
;      (let [(f (jit ctx (map class-of (list a b)) op))]
;        (add-method! name
;                     (make <method>
;                           #:specializers (map class-of (list a b))
;                           #:procedure (lambda (a b) (f (get a) (get b))))))
;      (name a b))
;    (capture-binary-argument name <boolean>)
;    (capture-binary-argument name <integer>)
;    (capture-binary-argument name <real>)
;    (capture-binary-argument name <rgb>)
;    (capture-binary-argument name <complex>)))

;(define-binary-op max max)
;(define-binary-op min min)

(define (slice arr i n)
  (make (to-type (base (typecode arr)) (class-of arr))
        #:shape (shape arr)
        #:strides (map (cut * n <>) (strides arr))
        #:value (+ (value arr) (* i (size-of (base (typecode arr)))))))
(define-syntax-rule (slice-if-type type arr i n default) (if (is-a? (typecode arr) (class-of type)) (slice arr i n) default))
(define-method (red   (self <sequence<>>)) (slice-if-type <rgb<>> self 0 3 self))
(define-method (green (self <sequence<>>)) (slice-if-type <rgb<>> self 1 3 self))
(define-method (blue  (self <sequence<>>)) (slice-if-type <rgb<>> self 2 3 self))
(define-method (real-part (self <sequence<>>)) (slice-if-type <complex<>> self 0 2 self))
(define-method (imag-part (self <sequence<>>)) (slice-if-type <complex<>> self 1 2 (fill (typecode self) (shape self) 0)))
