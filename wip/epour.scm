;;; Copyright © 2016, 2017, 2018, 2019 Efraim Flashner <efraim@flashner.co.il>
;;;
;;; This file is an addendum to GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (wip epour)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (gnu packages bittorrent)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages enlightenment)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib) ; intltool
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (srfi srfi-1))

(define-public epour
  (package
    (name "epour")
    (version "0.7.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://download.enlightenment.org/rel/apps/epour"
                            "/epour-" version ".tar.xz"))
        (sha256
         (base32
          "0g9f9p01hsq6dcf4cs1pwq95g6fpkyjgwqlvdjk1km1i5gj5ygqw"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f   ; no test target
       #:phases
       (modify-phases %standard-phases
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (invoke "python" "setup.py" "install" (string-append "--prefix=" out))
               #t))))))
    (native-inputs `(("intltool" ,intltool)))
    (propagated-inputs
     `(("libtorrent-rasterbar-local" ,libtorrent-rasterbar-local)
       ("python-dbus" ,python-dbus)
       ("python-distutils-extra" ,python-distutils-extra)
       ("python-efl" ,python-efl)
       ;("python-parse" ,python-parse)
       ("python-pyxdg" ,python-pyxdg)
       ;("python-urllib3" ,python-urllib3)
       ))
    (home-page "https://www.enlightenment.org")
    (synopsis "EFL Bittorrent client")
    (description "Epour is a BitTorrent client based on the @dfn{Enlightenment
Foundation Libraries} (EFL) and rb-libtorrent.")
    (license license:gpl3+)))

(define libtorrent-rasterbar-local
  (package
    (inherit libtorrent-rasterbar)
    (arguments
     (substitute-keyword-arguments (package-arguments libtorrent-rasterbar)
       ((#:tests? _ #f) #f)))
    (inputs
     `(("boost" ,boost-with-python3)
       ,@(alist-delete "boost"
                        (package-inputs libtorrent-rasterbar))))
    (native-inputs
     `(("python" ,python-wrapper)
       ,@(alist-delete "python"
                        (package-native-inputs libtorrent-rasterbar))))))

(define boost-local
  (package
    (inherit boost)
    (arguments
     `(#:imported-modules (,@%gnu-build-system-modules
                            (guix build python-build-system))
       ,@(substitute-keyword-arguments (package-arguments boost)
         ((#:phases phases)
          `(modify-phases ,phases
             (replace 'provide-libboost_python
               (lambda* (#:key outputs inputs #:allow-other-keys)
                 (let* ((out (assoc-ref outputs "out"))
                        (py-version ((@@ (guix build python-build-system)
                                         get-python-version) (assoc-ref inputs "python")))
                        (py-suffix (string-join (string-split py-version #\.) "")))
                   ;; Boost can build support for both Python 2 and Python 3 since
                   ;; version 1.67.0, and suffixes each library with the Python
                   ;; version.  Many consumers only check for libboost_python
                   ;; however, so we provide it here as suggested in
                   ;; <https://github.com/boostorg/python/issues/203>.
                   (with-directory-excursion (string-append out "/lib")
                     (symlink (string-append "libboost_python" py-suffix ".so")
                              "libboost_python.so"))
                   #t))))))))
    (native-inputs
     `(("python" ,python-wrapper)
       ,@(alist-delete "python"
                        (package-native-inputs boost))))))
