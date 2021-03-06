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
(define-module (aiscm opencv)
  #:use-module (oop goops)
  #:use-module (ice-9 optargs)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (aiscm core)
  #:use-module (aiscm util)
  #:export (connected-components charuco-board draw-marker detect-markers interpolate-corners
            draw-corners draw-detected-markers grid camera-calibration write-camera-calibration read-camera-calibration
            estimate-pose-single-markers draw-axis
            DICT_4X4_50 DICT_4X4_50 DICT_4X4_100 DICT_4X4_250 DICT_4X4_1000 DICT_5X5_50 DICT_5X5_100 DICT_5X5_250 DICT_5X5_1000
            DICT_6X6_50 DICT_6X6_100 DICT_6X6_250 DICT_6X6_1000 DICT_7X7_50 DICT_7X7_100 DICT_7X7_250 DICT_7X7_1000
            DICT_ARUCO_ORIGINAL DICT_APRILTAG_16h5 DICT_APRILTAG_25h9 DICT_APRILTAG_36h10 DICT_APRILTAG_36h11))

(load-extension "libguile-aiscm-opencv" "init_opencv")

(define typemap
  (list (cons <bool>         CV_8UC1 )
        (cons <ubyte>        CV_8UC1 )
        (cons (rgb <ubyte>)  CV_8UC3 )
        (cons <byte>         CV_8SC1 )
        (cons (rgb <byte> )  CV_8SC3 )
        (cons <usint>        CV_16UC1)
        (cons (rgb <usint>)  CV_16UC3)
        (cons <sint>         CV_16SC1)
        (cons (rgb <sint> )  CV_16SC3)
        (cons <int>          CV_32SC1)
        (cons (rgb <int>  )  CV_32SC3)
        (cons <float>        CV_32FC1)
        (cons (rgb <float>)  CV_32FC3)
        (cons <double>       CV_64FC1)
        (cons (rgb <double>) CV_64FC3)))

(define* (connected-components img connectivity #:key (label-type <int>))
  "Perform connected component analysis using 4- or 8-connectivity"
  (let* [(result (make (multiarray label-type 2) #:shape (shape img)))
         (count  (opencv-connected-components (memory img)
                                              (memory result)
                                              (shape img)
                                              (assq-ref typemap (typecode img))
                                              connectivity
                                              (assq-ref typemap label-type)))]
    (cons result count)))

(define (charuco-board rows cols size marker-size dict)
  "Draw a Charuco board image"
  (let [(result (make (multiarray <ubyte> 2) #:shape (list (* rows size) (* cols size))))]
    (opencv-charuco-board (memory result) (list (* rows size) (* cols size)) rows cols size marker-size dict)
    result))

(define (draw-marker dict id size)
  "Draw a single Aruco marker"
  (let [(result (make (multiarray <ubyte> 2) #:shape (list size size)))]
    (opencv-draw-marker (memory result) size id dict)
    result))

(define (detect-markers img dict)
  "Detect Aruco markers in image"
  (let [(result (opencv-detect-markers (shape img) (assq-ref typemap (typecode img)) (memory img) dict))]
    (cons (make (multiarray <int> 1) #:shape (list (car result)) #:memory (cadr result))
          (make (multiarray <float> 3) #:shape (list (car result) 4 2) #:memory (caddr result)))))

(define (check-marker-type markers)
  (if (not (eq? (typecode (car markers)) <int>))
    (aiscm-error 'interpolate-corners "Marker ids should be integer (was ~a)" (typecode (car markers))))
  (if (not (eq? (typecode (cdr markers)) <float>))
    (aiscm-error 'interpolate-corners "Marker coordinates should be float (was ~a)" (typecode (cdr markers)))))

(define (interpolate-corners markers img rows cols size marker-size)
  "Locate chessboard corners using Aruco marker positions"
  (check-marker-type markers)
  (let [(result (opencv-interpolate-corners (car (shape (car markers))) (memory (car markers)) (memory (cdr markers))
                                            (shape img) (assq-ref typemap (typecode img)) (memory img)
                                            rows cols size marker-size))]
    (cons (make (multiarray <int> 1) #:shape (list (car result)) #:memory (cadr result))
          (make (multiarray <float> 2) #:shape (list (car result) 2) #:memory (caddr result)))))

(define (draw-corners img corners)
  (check-marker-type corners)
  "Draw corners with ids"
  (let [(result (duplicate img))]
    (opencv-draw-corners (shape result) (assq-ref typemap (typecode result)) (memory result)
                         (car (shape (car corners))) (memory (car corners)) (memory (cdr corners)))
    result))

(define (draw-detected-markers img markers)
  "Draw detected Aruco markers on a copy of the image"
  (check-marker-type markers)
  (let [(result (duplicate img))]
    (opencv-draw-detected-markers (shape result) (assq-ref typemap (typecode result)) (memory result)
                                  (car (shape (car markers))) (memory (car markers)) (memory (cdr markers)))
    result))

(define (grid cols size ids)
  "Compute 3D object points from Charuco board corner indices"
  (let* [(indices (to-type <int> ids))
         (result  (opencv-grid cols size (memory indices) (car (shape indices))))]
    (make (multiarray <float> 2) #:shape (list (car (shape indices)) 3) #:memory result)))

(define (camera-calibration object-points image-points image-size)
  "Calibrate camera using floating point object points and floating point image points"
  (if (not (every (compose (cut eq? <> <float>) typecode) object-points))
    (aiscm-error 'camera-calibration "Object points should be of type float"))
  (if (not (every (compose (cut eq? <> <float>) typecode) image-points))
    (aiscm-error 'camera-calibration "Image points should be of type float"))
  (let [(result (opencv-camera-calibration (length object-points)
                                           (map (compose car shape) object-points)
                                           (map memory object-points)
                                           (map memory image-points)
                                           image-size))]
    (list (car result)
          (make (multiarray <double> 2) #:shape '(3 3) #:memory (cadr result))
          (make (multiarray <double> 1) #:shape '(5) #:memory (caddr result)))))

(define (write-camera-calibration file-name intrinsic distortion)
  "Write camera calibration data to file"
  (if (not (eq? (typecode intrinsic) <double>))
    (aiscm-error 'write-camera-calibration "Camera matrix should be of type double"))
  (if (not (eq? (typecode distortion) <double>))
    (aiscm-error 'write-camera-calibration "Distortion coefficients should be of type double"))
  (opencv-write-calibration file-name (memory intrinsic) (memory distortion)))

(define (read-camera-calibration file-name)
  "Read camera calibration data from file"
  (let [(result (opencv-read-calibration file-name))]
    (cons (make (multiarray <double> 2) #:shape '(3 3) #:memory (car result))
          (make (multiarray <double> 1) #:shape '(5) #:memory (cadr result)))))

(define (estimate-pose-single-markers corners marker-length intrinsic distortion)
  "Determine pose of detected markers"
  (if (not (eq? (typecode corners) <float>))
    (aiscm-error 'estimate-pose-single-markers "Corner coordinates should be of type float"))
  (if (not (eq? (typecode intrinsic) <double>))
    (aiscm-error 'estimate-pose-single-markers "Camera matrix should be of type double"))
  (if (not (eq? (typecode distortion) <double>))
    (aiscm-error 'estimate-pose-single-markers "Distortion coefficients should be of type double"))
  (let [(result (opencv-estimate-pose-single-markers (car (shape corners))
                                                     (memory corners)
                                                     marker-length
                                                     (memory intrinsic)
                                                     (memory distortion)))]
    (cons (make (multiarray <double> 2) #:shape (list (car result) 3) #:memory (cadr result))
          (make (multiarray <double> 2) #:shape (list (car result) 3) #:memory (caddr result)))))

(define (draw-axis image intrinsic distortion rvec tvec len)
  "Draw coordinate system axis for one coordinate system into image"
  (if (not (eq? (typecode intrinsic) <double>))
    (aiscm-error 'draw-axis "Camera matrix should be of type double"))
  (if (not (eq? (typecode distortion) <double>))
    (aiscm-error 'draw-axis "Distortion coefficients should be of type double"))
  (if (not (eq? (typecode rvec) <double>))
    (aiscm-error 'draw-axis "Rotation vectors should be of type double"))
  (if (not (eq? (typecode tvec) <double>))
    (aiscm-error 'draw-axis "Translation vectors should be of type double"))
  (opencv-draw-axis (memory image) (shape image) (assq-ref typemap (typecode image))
                    (memory intrinsic) (memory distortion) (memory rvec) (memory tvec) len)
  image)
