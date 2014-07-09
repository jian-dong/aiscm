(define-module (aiscm sequence)
  #:use-module (oop goops)
  #:use-module (ice-9 optargs)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (aiscm element)
  #:use-module (aiscm util)
  #:use-module (aiscm mem)
  #:use-module (aiscm pointer)
  #:export (<meta<sequence<>>> <sequence<>>
            sequence
            multiarray
            multiarray->list
            list->multiarray))
(define-generic element-type)
(define-class <meta<sequence<>>> (<meta<element>>))
(define-class <sequence<>> (<element>)
              (shape #:init-keyword #:shape #:getter shape)
              (strides #:init-keyword #:strides #:getter strides)
              #:metaclass <meta<sequence<>>>)
(define-method (sequence-name (type <meta<element>>))
  (format #f "<sequence~a>" (class-name type)))
(define-method (sequence-name (type <meta<sequence<>>>))
  (format #f "<multiarray~a,~a>" (class-name (typecode type)) (1+ (dimension type))))
(define (default-strides shape)
  (map (compose (cut apply * <>) (cut take shape <>)) (upto 0 (1- (length shape)))))
(define (sequence type)
  (let* [(name      (sequence-name type))
         (metaname  (format #f "<meta~a>" name))
         (metaclass (def-once metaname (make <class>
                                             #:dsupers (list <meta<sequence<>>>)
                                             #:slots '()
                                             #:name metaname)))
         (retval    (def-once name (make metaclass
                                         #:dsupers (list <sequence<>>)
                                         #:slots '()
                                         #:name name)))]
    (define-method (initialize (self retval) initargs)
      (let-keywords initargs #f (shape size value strides)
        (let* [(n   (or size (apply * shape)))
               (t   (typecode type))
               (mem (make <mem> #:size (* (size-of t) n)))
               (val (or value mem))
               (shp (or shape (list size)))
               (str (or strides (default-strides shp)))]
          (next-method self `(#:value ,val #:shape ,shp #:strides ,str)))))
    (define-method (element-type (self metaclass)) (pointer type))
    (define-method (dimension (self metaclass)) (1+ (dimension type)))
    (define-method (typecode (self metaclass)) (typecode type))
    retval))
(define-method (pointer (target-class <meta<sequence<>>>)) target-class)
(define (multiarray type dimension)
  (if (zero? dimension) (pointer type) (multiarray (sequence type) (1- dimension))))
(define-method (size (self <sequence<>>)) (apply * (shape self)))
(define (element self offset)
  (make (element-type (class-of self))
        #:value   (+ (get-value self) (* offset (last (strides self)) (size-of (typecode self))))
        #:shape   (all-but-last (shape self))
        #:strides (all-but-last (strides self))))
(define-method (slice (self <sequence<>>) (offset <integer>) (size <integer>))
  (make (class-of self)
        #:value   (+ (get-value self) (* offset (last (strides self)) (size-of (typecode self))))
        #:shape   (append (all-but-last (shape self)) (list size))
        #:strides (strides self)))
(define-method (fetch (self <sequence<>>)) self)
(define-method (get (self <sequence<>>) . args)
  (if (null? args) self (apply get (cons (fetch (element self (last args))) (all-but-last args)))))
(define-method (set (self <sequence<>>) . args)
  (store (fold-right (lambda (offset self) (element self offset))
                     self
                     (all-but-last args))
         (last args)))
(define-method (store (self <sequence<>>) value)
  (for-each (lambda (i) (store (element self i) value))
            (upto 0 (1- (last (shape self)))))
  value)
(define-method (store (self <sequence<>>) (value <null>)) value)
(define-method (store (self <sequence<>>) (value <pair>))
  (store (element self 0) (car value))
  (store (slice self 1 (1- (last (shape self)))) (cdr value))
  value)
(define-method (multiarray->list self) self)
(define-method (multiarray->list (self <sequence<>>))
  (map (compose multiarray->list (cut get self <>)) (upto 0 (1- (last (shape self))))))
(define-method (shape (self <null>)) #f)
(define-method (shape (self <pair>)) (append (shape (car self)) (list (length self))))
(define (list->multiarray lst)
  (let* [(t      (reduce coerce #f (map match (flatten lst))))
         (shp    (shape lst))
         (retval (make (multiarray t (length shp)) #:shape shp))]
    (store retval lst)
    retval))
(define-method (write (self <sequence<>>) port)
  (format port "#~a:~&~a" (class-name (class-of self)) (multiarray->list self)))
(define-method (display (self <sequence<>>) port)
  (format port "#~a:~&~a" (class-name (class-of self)) (multiarray->list self)))
(define-method (coerce (a <meta<sequence<>>>) (b <meta<element>>))
  (sequence (coerce (typecode a) b)))
(define-method (coerce (a <meta<element>>) (b <meta<sequence<>>>))
  (sequence (coerce a (typecode b))))
(define-method (coerce (a <meta<sequence<>>>) (b <meta<sequence<>>>))
  (sequence (coerce (typecode a) (typecode b))))
