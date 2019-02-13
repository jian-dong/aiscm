(use-modules (oop goops)
             (ice-9 format)
             (rnrs bytevectors)
             (aiscm tensorflow)
             (aiscm core)
             (aiscm pulse))

;(define robot (socket PF_INET SOCK_DGRAM 0))
;(connect robot AF_INET (car (hostent:addr-list (gethostbyname "raspberrypi.local"))) 2200)
;(define commands (list "0,0,0" "-100,-100,0" "100,-100,0" "-100,100,0" "0,0,0"))
(define words (list "stop" "go" "left" "right" "?"))
(define chunk 512)
(define rising 6000)
(define falling 3000)
(define n-hidden 16)
(define rate 11025)
(tf-graph-import "voice-model.meta")

(define x (tf-graph-operation-by-name "x"))
(define h (tf-graph-operation-by-name "h"))
(define c (tf-graph-operation-by-name "c"))
(define hs (tf-graph-operation-by-name "hs"))
(define cs (tf-graph-operation-by-name "cs"))
(define prediction (tf-graph-operation-by-name "prediction"))

(define session (make-session))
(run session '()
     (list (tf-graph-operation-by-name "init-wf")
           (tf-graph-operation-by-name "init-wi")
           (tf-graph-operation-by-name "init-wo")
           (tf-graph-operation-by-name "init-wc")
           (tf-graph-operation-by-name "init-uf")
           (tf-graph-operation-by-name "init-ui")
           (tf-graph-operation-by-name "init-uo")
           (tf-graph-operation-by-name "init-uc")
           (tf-graph-operation-by-name "init-bf")
           (tf-graph-operation-by-name "init-bi")
           (tf-graph-operation-by-name "init-bo")
           (tf-graph-operation-by-name "init-bc")
           (tf-graph-operation-by-name "init-wy")
           (tf-graph-operation-by-name "init-by")))

(define h_ #f)
(define c_ #f)
(define pred #f)

(define (zeros . shape) (fill <double> shape 0.0))

(define status 'off)

(define record (make <pulse-record> #:typecode <sint> #:channels 1 #:rate rate))

(while #t
  (let* [(samples  (read-audio record chunk))
         (loudness2 (/ (sum (* (to-type <float> samples) samples)) chunk))]
    (if (and (eq? status 'off) (> loudness2 (* rising rising)))
      (begin
        (set! status 'on)
        (set! h_ (zeros 1 n-hidden))
        (set! c_ (zeros 1 n-hidden))))
    (if (> loudness2 (* rising rising))
      (let [(batch (list (cons h h_) (cons c c_) (cons x (reshape samples '(512)))))]
        (set! h_ (run session batch hs))
        (set! c_ (run session batch cs))
        (set! pred (get (run session batch prediction) 0))))
    (if (and (eq? status 'on) (< loudness2 (* falling falling)))
      (begin
        (set! status 'off)
        ;(display (list-ref commands pred) robot)
        (format #t "~a~&" (list-ref words pred))))))