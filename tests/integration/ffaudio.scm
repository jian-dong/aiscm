(use-modules (oop goops) (aiscm ffmpeg) (aiscm pulse) (aiscm element))
(define audio (open-input-audio "test.mp3"))
(define output (make <pulse-play> #:rate (rate audio) #:channels (channels audio) #:type (typecode audio)))
(write-samples (lambda _ (read-audio audio)) output)