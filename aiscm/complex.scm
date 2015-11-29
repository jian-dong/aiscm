(define-module (aiscm complex)
  #:use-module (srfi srfi-26)
  #:use-module (oop goops)
  #:use-module (aiscm element)
  #:use-module (aiscm sequence)
  #:use-module (aiscm util)
  #:export (complex
            <complex<>> <meta<complex<>>>))
(define-class* <complex<>> <element> <meta<complex<>>> <meta<element>>)
(define-method (complex (t <meta<element>>))
  (template-class (complex t) <complex<>>
    (lambda (class metaclass)
      (define-method (base (self metaclass))t)
      (define-method (size-of (self metaclass)) (* 3 (size-of t))))))
(define-method (pack (self <complex<>>))
  (let* [(vals       (content (get self)))
         (components (map (cut make (base (class-of self)) #:value <>) vals))
         (size       (size-of (base (class-of self))))]
    (bytevector-concat (map pack components))))
(define-method (unpack (self <meta<complex<>>>) (packed <bytevector>))
  (let* [(size    (size-of (base self)))
         (vectors (map (cut bytevector-sub packed <> size) (map (cut * size <>) (iota 2))))]
    (make self #:value (apply make-rectangular (map (lambda (vec) (get (unpack (base self) vec))) vectors)))))
(define-method (content (self <complex>)) (map inexact->exact (list (real-part self) (imag-part self))))
(define-method (coerce (a <meta<complex<>>>) (b <meta<element>>)) (complex (coerce (base a) b)))
(define-method (coerce (a <meta<element>>) (b <meta<complex<>>>)) (complex (coerce a (base b))))
(define-method (coerce (a <meta<complex<>>>) (b <meta<complex<>>>)) (complex (coerce (base a) (base b))))
(define-method (coerce (a <meta<complex<>>>) (b <meta<sequence<>>>)) (multiarray (coerce a (typecode b)) (dimension b)))
