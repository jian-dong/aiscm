(use-modules (oop goops) (aiscm util) (system foreign) (rnrs bytevectors) (aiscm core) (aiscm image) (aiscm magick) (aiscm xorg) (aiscm v4l2) (srfi srfi-1) (srfi srfi-26))

;(define-tensor (name arr size) (tensor [size] i (get arr i)))

;(define-method (native-type2 value) (native-type value))
;(define-method (native-type2 (value <integer>)) <int>)
;
;(define-syntax-rule (define-tensor (name args ...) expression)
;  (define-method (name args ...)
;    (let [(fun (jit (map native-type2 (list args ...)) (lambda (args ...) expression)))]
;      (add-method! name
;                   (make <method> #:specializers (map class-of (list args ...))
;                                  #:procedure fun))
;      (name args ...))))

;(define-tensor (test x) (+ x x))

(define-class <index> ()
  (sym #:init-keyword #:sym #:getter sym)
  (size #:init-keyword #:size #:getter size))

(define-method (write (self <index>) port)
  (format port "(index ~a ~a)" (size self) (sym self)))

(define (index size)
  (make <index> #:sym (gensym) #:size size))

(define-class <lambda> ()
  (index #:init-keyword #:index #:getter index)
  (term #:init-keyword #:term #:getter term))

(define-method (write (self <lambda>) port)
  (format port "(lamb ~a ~a)" (index self) (term self)))

(define-method (lamb index term)
  (make <lambda> #:index index #:term term))

(define-class <lookup> ()
  (index #:init-keyword #:index #:getter index)
  (term #:init-keyword #:term #:getter term)
  (stride #:init-keyword #:stride #:getter stride))

(define-method (write (self <lookup>) port)
  (format port "(lookup ~a ~a ~a)" (index self) (term self) (stride self)))

(define-method (lookup index term stride)
  (make <lookup> #:index index #:term term #:stride stride))

(define-method (lookup idx (t <lambda>) stride)
  (lamb (index t) (lookup idx (term t) stride)))

(define-method (fetch (p <foreign>))
  (bytevector-u8-ref (pointer->bytevector p 1) 0))

(define-method (+ (a <foreign>) (b <integer>))
  (make-pointer (+ (pointer-address a) b)))

(define-method (get (x <foreign>)) (fetch x))

(define-method (get (x <lambda>)) x)

(define-method (get (x <lookup>)) x)

(define-method (get (x <lambda>) i . args)
  (let [(args (cons i args))]
    (apply get (subst (term x) (index x) (last args)) (all-but-last args))))

(define-syntax-rule (tensor i expression)
  (let [(i (index 0)) ]
    (lamb i expression)))

(define-method (subst (x <lambda>) (idx <index>) i)
  (lamb (index x) (subst (term x) idx i)))

(define-method (subst (x <lookup>) (idx <index>) (i <integer>))
  (if (eq? idx (index x))
    (rebase (term x) (* i (stride x)))
    (lookup (index x) (subst (term x) idx i) (stride x))))

(define-method (subst (x <lookup>) (idx <index>) (i <index>))
  (if (eq? idx (index x))
    (begin
      (slot-set! i 'size (size idx))
      (lookup i (term x) (stride x)))
    (lookup (index x) (subst (term x) idx i) (stride x))))

(define-method (rebase (x <lookup>) offset)
  (lookup (index x) (rebase (term x) offset) (stride x)))

(define-method (rebase (x <foreign>) offset)
  (+ x offset))

(define (arr->tensor a)
  (if (zero? (dimensions a))
    (memory a)
    (let [(i (index (last (shape a))))]
      (lamb i (lookup i (arr->tensor (project a)) (last (strides a)))))))

(define m (arr 1 2 3))
(define t (arr->tensor m))
(define v (tensor i (get t i)))

(define n (arr (1 2 3) (4 5 6)))
(define u (arr->tensor n))
(define w (tensor i (tensor j (get u i j))))
