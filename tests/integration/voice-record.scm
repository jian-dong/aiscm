(use-modules (oop goops)
             (srfi srfi-18)
             (ice-9 format)
             (aiscm core)
             (aiscm ffmpeg)
             (aiscm pulse)
             (aiscm util))

(define words (list "stop" "go" "left" "right"))
(define rate 11025)
(define chunk 512)
(define rising 2000)
(define falling 1000)
(define output (open-ffmpeg-output "voice-commands.mp3" #:rate rate #:typecode <sint> #:channels 1 #:audio-bit-rate 80000))
(define csv (open-file "voice-commands.csv" "wl"))
(define record (make <pulse-record> #:typecode <sint> #:channels 1 #:rate rate))
(format csv "time,word~&")
(define time 0.0)
(define choice "")
(define status 'on)
(while #t
  (let* [(samples (read-audio record chunk))
        (loudness (sqrt (/ (sum (* (to-type <int> samples) samples)) chunk)))]
    (if (and (eq? status 'off) (> loudness rising)) (set! status 'on))
    (if (and (eq? status 'on) (< loudness falling))
      (begin
        (set! status 'off)
        (set! choice (list-ref words (random (length words))))
        (format #t "Say \"~a\"~&" choice)))
    (write-audio samples output)
    (format csv "~a,~a~&" time (if (eq? status 'off) "" choice))
    (set! time (+ time (/ chunk rate)))))
(destroy output)
