(use-modules (oop goops) (ice-9 binary-ports) (rnrs bytevectors) (aiscm core) (system foreign) (aiscm xorg) (ice-9 format))
; http://yann.lecun.com/exdb/mnist/
(define f (open-file "train-images-idx3-ubyte" "rb"))
(define magic (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(if (not (eqv? magic 2051)) (error "Images file has wrong magic number"))
(define n (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(define h (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(define w (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(define bv (get-bytevector-n f (* n h w)))
(define images (make (multiarray <ubyte> 3) #:memory (bytevector->pointer bv) #:shape (list n h w)))

(define f (open-file "train-labels-idx1-ubyte" "rb"))
(define magic (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(if (not (eqv? magic 2049)) (error "Label file has wrong magic number"))
(define n2 (bytevector-u32-ref (get-bytevector-n f 4) 0 (endianness big)))
(if (not (eqv? n n2)) (error "Number of labels does not match number of images"))
(define bv (get-bytevector-n f n))
(define labels (make (multiarray <ubyte> 1) #:memory (bytevector->pointer bv) #:shape (list n)))

(define i -1)
(show
  (lambda _
    (set! i (modulo (1+ i) n))
    (format #t "~a~&" (get labels i))
    (- 255 (get images i)))
  #:io IO-OPENGL #:width 256)
