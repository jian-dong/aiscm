(define-module (aiscm sequence)
  #:use-module (oop goops)
  #:use-module (ice-9 optargs)
  #:use-module (aiscm element)
  #:use-module (aiscm util)
  #:use-module (aiscm mem)
  #:use-module (aiscm pointer)
  #:export (sequence
            get-size
            sequence->list))
(define-class <meta<sequence<>>> (<meta<element>>))
(define-class <sequence<>> (<element>)
              (size #:init-keyword #:size #:getter get-size)
              #:metaclass <meta<sequence<>>>)
(define (sequence type)
  (let* ((name (format #f "<sequence~a>" (class-name type)))
         (metaname (format #f "<meta~a>" name))
         (metaclass (def-once metaname (make <class>
                                             #:dsupers (list <meta<sequence<>>>)
                                             #:slots '()
                                             #:name metaname)))
         (retval (def-once name (make metaclass
                                      #:dsupers (list <sequence<>>)
                                      #:slots '()
                                      #:name name))))
    (define-method (initialize (self retval) initargs)
      (let-keywords initargs #f (size value)
        (let* ((mem (make <mem> #:size (* (storage-size type) size)))
               (ptr (or value (make (pointer type) #:value mem))))
          (next-method self `(#:value ,ptr #:size ,size)))))
    (define-method (typecode (self metaclass)) type)
    retval))
(define-method (shape (self <sequence<>>)) (list (get-size self)))
(define-method (set (self <sequence<>>) (i <integer>) o)
  (begin (store (+ (get-value self) i) (make (typecode self) #:value o)) o))
(define-method (get (self <sequence<>>) (i <integer>))
  (get-value (fetch (+ (get-value self) i))))
(define-method (slice (self <sequence<>>) (offset <integer>) (size <integer>))
  (make (class-of self) #:value (+ (get-value self) offset) #:size size))
(define (sequence->list seq)
  (if (> (get-size seq) 0)
    (cons (get seq 0) (sequence->list (slice seq 1 (- (get-size seq) 1)))) '()))
(define-method (write (self <sequence<>>) port)
  (format port "#~a:~&~a" (class-name (class-of self)) (sequence->list self)))
(define-method (display (self <sequence<>>) port)
  (format port "#~a:~&~a" (class-name (class-of self)) (sequence->list self)))
