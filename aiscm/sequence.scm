(define-module (aiscm sequence)
  #:use-module (aiscm element)
  #:use-module (aiscm mem)
  #:use-module (aiscm pointer)
  #:use-module (aiscm lookup)
  #:use-module (aiscm lambda)
  #:use-module (aiscm var)
  #:use-module (oop goops)
  #:export (make-sequence
            make-sequence-class
            sequence->list))
(define-class <meta<sequence<>>> (<class>))
(define-class <sequence<>> (<element>) #:metaclass <meta<sequence<>>>)
(define (make-sequence-class type)
  (let* ((name (format #f "<sequence>" (class-name type)))
         (metaname (format #f "<meta~a" name))
         (metaclass (make-class (list <meta<sequence<>>>) '() #:name metaname))
         (retval (make-class (list <sequence<>>)
                             '()
                             #:name name
                             #:metaclass metaclass)))
    (define-method (typecode (self metaclass)) type)
    retval))
(define (make-sequence type size)
  (let* ((mem (make <mem> #:size (* (storage-size type) size)))
         (ptr (make-pointer type mem))
         (var (make-var))
         (lookup (make-lookup ptr var 1)))
    (make-lambda lookup var size)))
(define (sequence->list seq)
  (let ((n (get-length seq)))
    (if (> n 0)
      (cons (get seq 0) (sequence->list (slice seq 1 (- n 1))))
      '())))
(define-method (write (self <lambda>) port)
  (format port "#<sequence~a>:~&~a"
          (class-name (typecode self))
          (sequence->list self)))
(define-method (display (self <lambda>) port)
  (format port "#<sequence~a>:~&~a"
          (class-name (typecode self))
          (sequence->list self)))
