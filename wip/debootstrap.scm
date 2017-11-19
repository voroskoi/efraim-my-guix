;;; Copyright © 2017 Efraim Flashner <efraim@flashner.co.il>
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

(define-module (wip debootstrap)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages wget))

(define-public debootstrap
  (package
    (name "debootstrap")
    (version "1.0.92")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "mirror://debian/pool/main/d/debootstrap/"
                            "debootstrap_" version ".tar.gz"))
        (sha256
         (base32
          "06gp6ivmfh0ks4mibx1mz0pwzjyxqas319s741pp9b3k091jkip1"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'build)
         (add-after 'unpack 'patch-source
           (lambda _
             (substitute* "debootstrap"
               (("@VERSION@") ,version))
             (substitute* "functions"
               (("wget ") (string-append (which "wget") " ")))
             #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (copy-recursively "scripts"
                                 (string-append out "/share/debootstrap/scripts"))
               (install-file "functions" (string-append out "/share/debootstrap"))
               (install-file "debootstrap" (string-append out "/sbin"))
               (install-file "debootstrap.8" (string-append out "/share/man/man8"))
               #t))))
       #:tests? #f)) ; no tests
    (inputs
     `(("perl" ,perl)
       ("wget" ,wget)))
    (home-page "https://anonscm.debian.org/cgit/d-i/debootstrap.git")
    (synopsis "Bootstrap a basic Debian system")
    (description "Debootstrap is used to create a Debian base system from
scratch, without requiring the availability of @code{dpkg} or @code{apt}.
It does this by downloading .deb files from a mirror site, and carefully
unpacking them into a directory which can eventually be chrooted into.")
    (license license:gpl2)))

(define-public jetring
  (package
    (name "jetring")
    (version "0.25")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "mirror://debian/pool/main/j/" name "/"
                            name "_" version ".tar.xz"))
        (sha256
         (base32
          "0shcnnw0h31b08vmnvf18ni33dg40w18wv9smb69vkklz3h4jhpw"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (delete 'configure) ; no configure script
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (for-each (lambda (file)
                           (install-file file (string-append out "/bin/")))
                         '("jetring-accept" "jetring-apply" "jetring-build"
                           "jetring-checksum" "jetring-diff" "jetring-explode"
                           "jetring-gen" "jetring-review" "jetring-signindex"))
               #t))))
       #:tests? #f)) ; no test phase
    (native-inputs `(("gnupg" ,gnupg)))
    (inputs `(("perl" ,perl)))
    (home-page "https://joeyh.name/code/jetring/")
    (synopsis "gpg keyring maintenance using changesets")
    (description
     "Jetring is a collection of tools that allow for gpg keyrings to be
maintained using changesets.  It was developed with the Debian keyring in mind,
and aims to solve the problem that a gpg keyring is a binary blob that's hard
for multiple people to collaboratively edit.
With jetring, changesets can be submitted, reviewed to see exactly what they
will do, applied, and used to build a keyring.  The origin of every change made
to the keyring is available for auditing, and gpg signatures can be used to
further secure things.")
    (license license:gpl2+)))
