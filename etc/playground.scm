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
  (sym #:init-keyword #:sym #:getter sym))

(define-method (write (self <index>) port)
  (format port "(index ~a)" (sym self)))

(define (index)
  (make <index> #:sym (gensym)))

(define-class <lambda> ()
  (index #:init-keyword #:index #:getter index)
  (term #:init-keyword #:term #:getter term)
  (size #:init-keyword #:size #:getter size))

(define-method (write (self <lambda>) port)
  (format port "(lamb ~a ~a ~a)" (index self) (term self) (size self)))

(define-method (lamb index term size)
  (make <lambda> #:index index #:size size #:term term))

(define-class <lookup> ()
  (index #:init-keyword #:index #:getter index)
  (term #:init-keyword #:term #:getter term)
  (stride #:init-keyword #:stride #:getter stride))

(define-method (write (self <lookup>) port)
  (format port "(lookup ~a ~a ~a)" (index self) (term self) (stride self)))

(define-method (lookup index term stride)
  (make <lookup> #:index index #:term term #:stride stride))

(define-method (lookup idx (t <lambda>) stride)
  (lamb (index t) (lookup idx (term t) stride) (size t)))

(define-method (fetch (p <foreign>))
  (bytevector-u8-ref (pointer->bytevector p 1) 0))

(define-method (+ (a <foreign>) (b <integer>))
  (make-pointer (+ (pointer-address a) b)))

(define-method (get (x <foreign>)) (fetch x))

(define (arr->tensor a)
  (if (zero? (dimensions a))
    (memory a)
    (let [(i (index))]
      (lamb i (lookup i (arr->tensor (project a)) (last (strides a))) (last (shape a))))))

(define m (arr 1 2 3))
(arr->tensor m)

(define n (arr (1 2 3) (4 5 6)))
(arr->tensor n)
