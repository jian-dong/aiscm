(use-modules (aiscm core))
(- (arr <int> 2 3 5))
;#<multiarray<int<32,signed>,1>>:
;(-2 -3 -5)
(~ (arr <byte> -128 -3 -2 -1 0 1 2 127))
;#<multiarray<int<8,signed>,1>>:
;(127 2 1 0 -1 -2 -3 -128)
(red (to-array (list (rgb 2 3 5) (rgb 3 5 7))))
;#<sequence<int<8,unsigned>>>:
;(2 3)
(green (to-array (list (rgb 2 3 5) (rgb 3 5 7))))
;#<sequence<int<8,unsigned>>>:
;(3 5)
(blue (to-array (list (rgb 2 3 5) (rgb 3 5 7))))
;#<sequence<int<8,unsigned>>>:
;(5 7)
(red (arr 2 3 5))
;#<sequence<int<8,unsigned>>>:
;(2 3 5)
(real-part (arr 2+3i 5+7i))
;#<sequence<int<16,signed>>>:
;(2 5)
(real-part (arr 2 3 5))
;#<sequence<int<8,unsigned>>>:
;(2 3 5)
(imag-part (arr 2+3i 5+7i))
;#<sequence<int<16,signed>>>:
;(3 7)
(imag-part (arr 2 3 5))
;#<sequence<int<8,unsigned>>>:
;(0 0 0)
(conj (arr 2+3i 5+7i))
;#<sequence<complex<int<8,signed>>>:
;(2.0-3.0i 5.0-7.0i)
(conj (arr 2 3 5))
;#<sequence<int<8,unsigned>>>:
;(2 3 5)
