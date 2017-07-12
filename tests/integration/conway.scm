(use-modules (aiscm xorg) (aiscm convolution) (aiscm tensor) (aiscm bool) (aiscm int) (aiscm jit)
             (aiscm sequence) (aiscm operation) (aiscm element))
(define img (fill <bool> '(100 60) #f))
(set img 0 0 #f) (set img 1 0 #t) (set img 2 0 #f)
(set img 0 1 #f) (set img 1 1 #f) (set img 2 1 #t)
(set img 0 2 #t) (set img 1 2 #t) (set img 2 2 #t)
(set img 4 50 #t) (set img 5 50 #t) (set img 6 50 #t)
(set img 4 51 #f) (set img 5 51 #f) (set img 6 51 #t)
(set img 4 52 #f) (set img 5 52 #t) (set img 6 52 #f)
(set img 27 25 #t) (set img 28 25 #t) (set img 29 25 #t)
(show
  (lambda (dsp)
    (let [(neighbours (convolve (to-type <ubyte> img) (arr (1 1 1) (1 0 1) (1 1 1))))]
      (set! img (tensor (&& (ge neighbours (where img 2 3)) (le neighbours 3))) )
      (where img 255 0))))
