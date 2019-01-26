(use-modules (ice-9 ftw)
             (ice-9 format)
             (aiscm tensorflow)
             (aiscm core)
             (aiscm ffmpeg)
             (aiscm util))


(define samples '())
(define words '(go stop left right))
(define chunk 512)
(define chunk2 (1+ (/ chunk 2)))
(define m 50)
(define alpha 0.001)
(define n-hidden 16)

(for-each
  (lambda (word)
    (ftw (format #f "tests/integration/speech/~a" word)
      (lambda (filename statinfo flag)
        (format #t "~a\r"filename)
        (if (eq? flag 'regular)
          (let* [(file     (open-ffmpeg-input filename))
                 (wav      (to-array (read-audio file 64000)))
                 (l        (car (shape wav)))
                 (chunked  (- l (modulo l chunk)))
                 (n-chunks (/ chunked chunk))
                 (cropped  (crop chunked wav))]
            (set! samples (cons (cons (index-of word words) (reshape cropped (list n-chunks chunk))) samples))
            (destroy file)))
        #t)))
  words)

(define session (make-session))
(define x (tf-placeholder #:dtype <sint> #:shape (list -1 chunk) #:name "x"))
(define xf (tf-cast x #:DstT <float>))
(define y (tf-placeholder #:dtype <int> #:shape '(-1) #:name "y"))
(define yh (tf-one-hot (tf-cast y #:DstT <int>) (length words) 1.0 0.0))
(define (nth x i) (tf-gather x i))
(define (fourier x) (tf-reshape (tf-rfft x (to-array <int> (list chunk))) (arr <int> 1 -1)))
(define (spectrum x) (let [(f (fourier x))] (tf-log (tf-cast (tf-real (tf-mul f (tf-conj f))) #:DstT <double>))))
(define (safe-log x) (tf-log (tf-maximum x 1e-10)))
(define (invert x) (tf-sub 1.0 x))
(define (zeros . shape) (fill <double> shape 0.0))

(define h (tf-placeholder #:dtype <double> #:shape (list 1 n-hidden) #:name "h"))
(define c (tf-placeholder #:dtype <double> #:shape (list 1 n-hidden) #:name "c"))

(define wf (tf-variable #:dtype <double> #:shape (list   chunk2 n-hidden) #:name "wf"))
(define wi (tf-variable #:dtype <double> #:shape (list   chunk2 n-hidden) #:name "wi"))
(define wo (tf-variable #:dtype <double> #:shape (list   chunk2 n-hidden) #:name "wo"))
(define wc (tf-variable #:dtype <double> #:shape (list   chunk2 n-hidden) #:name "wc"))
(define uf (tf-variable #:dtype <double> #:shape (list n-hidden n-hidden) #:name "uf"))
(define ui (tf-variable #:dtype <double> #:shape (list n-hidden n-hidden) #:name "ui"))
(define uo (tf-variable #:dtype <double> #:shape (list n-hidden n-hidden) #:name "uo"))
(define uc (tf-variable #:dtype <double> #:shape (list n-hidden n-hidden) #:name "uc"))
(define bf (tf-variable #:dtype <double> #:shape (list        1 n-hidden) #:name "bf"))
(define bi (tf-variable #:dtype <double> #:shape (list        1 n-hidden) #:name "bi"))
(define bo (tf-variable #:dtype <double> #:shape (list        1 n-hidden) #:name "bo"))
(define bc (tf-variable #:dtype <double> #:shape (list        1 n-hidden) #:name "bc"))
(define wy (tf-variable #:dtype <double> #:shape (list n-hidden        4) #:name "wy"))
(define by (tf-variable #:dtype <double> #:shape (list        1        4) #:name "by"))

(define initializers
  (list (tf-assign wf (tf-mul (/ 1 chunk2) (tf-truncated-normal (to-array <int> (list chunk2 n-hidden)) #:dtype <double>)))
        (tf-assign wi (tf-mul (/ 1 chunk2) (tf-truncated-normal (to-array <int> (list chunk2 n-hidden)) #:dtype <double>)))
        (tf-assign wo (tf-mul (/ 1 chunk2) (tf-truncated-normal (to-array <int> (list chunk2 n-hidden)) #:dtype <double>)))
        (tf-assign wc (tf-mul (/ 1 chunk2) (tf-truncated-normal (to-array <int> (list chunk2 n-hidden)) #:dtype <double>)))
        (tf-assign uf (tf-mul (/ 1 n-hidden) (tf-truncated-normal (to-array <int> (list n-hidden n-hidden)) #:dtype <double>)))
        (tf-assign ui (tf-mul (/ 1 n-hidden) (tf-truncated-normal (to-array <int> (list n-hidden n-hidden)) #:dtype <double>)))
        (tf-assign uo (tf-mul (/ 1 n-hidden) (tf-truncated-normal (to-array <int> (list n-hidden n-hidden)) #:dtype <double>)))
        (tf-assign uc (tf-mul (/ 1 n-hidden) (tf-truncated-normal (to-array <int> (list n-hidden n-hidden)) #:dtype <double>)))
        (tf-assign bf (zeros 1 n-hidden))
        (tf-assign bi (zeros 1 n-hidden))
        (tf-assign bo (zeros 1 n-hidden))
        (tf-assign bc (zeros 1 n-hidden))
        (tf-assign wy (tf-mul (/ 1 n-hidden) (tf-truncated-normal (to-array <int> (list n-hidden 4)) #:dtype <double>)))
        (tf-assign by (zeros 1 4))))

(define vars (list wf wi wo wc uf ui uo uc bf bi bo bc wy by))

(define (lstm x h c)
  (let* [(f (tf-sigmoid (tf-add-n (list (tf-mat-mul x wf) (tf-mat-mul h uf) bf))))
         (i (tf-sigmoid (tf-add-n (list (tf-mat-mul x wi) (tf-mat-mul h ui) bi))))
         (o (tf-sigmoid (tf-add-n (list (tf-mat-mul x wo) (tf-mat-mul h uo) bo))))
         (g (tf-tanh (tf-add-n (list (tf-mat-mul x wc) (tf-mat-mul h uc) bc))))
         (c_ (tf-add (tf-mul f c) (tf-mul i g)))
         (h_ (tf-mul o (tf-tanh c_)))]
    (cons h_ c_)))

(define (output x) (tf-softmax (tf-add (tf-mat-mul x wy) by)))

(define prediction
  (let* [(memory (lstm (spectrum xf) h c))
         (hs     (tf-identity (car memory) #:name "hs"))
         (cs     (tf-identity (cdr memory) #:name "cs"))
         (ys     (tf-identity (output hs)))]
    (tf-arg-max ys 1 #:name "prediction")))

(define h_ h)
(define c_ c)

(define losses '())
(define steps '())

(for-each
  (lambda (i)
    (let* [(memory    (lstm (spectrum (nth xf i)) h_ c_))
           (y_        (output (car memory)))
           (loss      (tf-neg (tf-mean (tf-add (tf-mul yh (safe-log y_))
                                               (tf-mul (invert yh) (safe-log (invert y_))))
                                       (arr <int> 0 1))))
           (gradients (tf-add-gradient loss vars))
           (step      (map (lambda (v g) (tf-assign v (tf-sub v (tf-mul g alpha)))) vars gradients))]
      (set! losses (attach losses loss))
      (set! steps (attach steps step))
      (set! h_ (car memory))
      (set! c_ (cdr memory))))
  (iota m))

(define h0 (zeros 1 n-hidden))
(define c0 (zeros 1 n-hidden))

(define session (make-session))

(run session '() initializers)

(define j 0.680)

(define feature (cdar samples))
(define label (caar samples))

(define batch (list (cons h h0) (cons c c0) (cons x feature) (cons y label)))
(define l (car  (shape feature)))
(run session batch (list-ref losses (1- l)))
(run session batch (list-ref steps (1- l)))
