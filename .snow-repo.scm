(repository
  (package
    (git
      (hash "3611d33573f63da36b7ba7d623e69d4f5bc98944")
      (tag "v1.0.0")
      (url "https://github.com/vhespanha/srfi-216.git"))
    (authors "Vinicius Hespanha Souza")
    (version "1.0.0")
    (license mit)
    (library
      (name
        (srfi 216))
      (path "srfi/216.sld")
      (foreign-depends)
      (depends
        (scheme base)
        (scheme inexact)
        (scheme lazy)
        (scheme time)
        (srfi 18)
        (srfi 27)))
    (manual "doc/srfi-216.html")
    (description "SRFI 216: SICP Prerequisites (Portable)")
    (updated "2026-11-22T12:35:36+00:00")))
