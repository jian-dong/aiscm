;; AIscm - Guile extension for numerical arrays and tensors.
;; Copyright (C) 2013, 2014, 2015, 2016, 2017, 2018, 2019 Jan Wedekind <jan@wedesoft.de>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
(define-module (aiscm filters)
  #:use-module (oop goops)
  #:use-module (system foreign)
  #:use-module (aiscm core)
  #:export (gauss-filter))

(define pi 3.141592653589793)

(define (sgn x) (if (positive? x) 1 -1))

(define erf (pointer->procedure double (dynamic-func "erf" (dynamic-link)) (list double)))

(define (normalize f) (/ f (sum f)))

(define (gauss-filter sigma size)
  (let [(size2 (/ size 2))]
    (normalize
      (to-array
        (map (lambda (x)
               (let* [(a (- x size2))
                      (b (+ a 1))
                      (scale (/ 1 (* (sqrt 2) sigma)))]
          (/ (- (erf (* scale b)) (erf (* scale a))) 2)))
          (iota size))))))
