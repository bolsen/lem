(defpackage :lem-vi-mode/tests/operator
  (:use :cl
        :lem
        :rove
        :lem-vi-mode/tests/utils)
  (:import-from :lem/common/killring
                :peek-killring-item)
  (:import-from :lem-fake-interface
                :with-fake-interface)
  (:import-from :named-readtables
                :in-readtable))
(in-package :lem-vi-mode/tests/operator)

(in-readtable :interpol-syntax)

(deftest vi-delete
  (with-fake-interface ()
    (with-vi-buffer (#?"a[b]c\ndef\nghi\njkl\n")
      (cmd "dd")
      (ok (buf= #?"d[e]f\nghi\njkl\n"))
      (cmd "dd")
      (ok (buf= #?"g[h]i\njkl\n"))
      (cmd "p")
      (ok (buf= #?"ghi\n[d]ef\njkl\n"))
      (cmd "2dd")
      (ok (buf= #?"ghi\n[]")))
    (with-vi-buffer (#?"[a]bc\ndef\nghi\njkl\n")
      (cmd "1000dd")
      (ok (buf= "[]")))
    (testing "visual mode"
      (with-vi-buffer (#?"[a]bc\ndef\nghi\n")
        (cmd "Vjd")
        (ok (buf= #?"[g]hi\n"))))
    (testing "with vi-forward-word-begin"
      (with-vi-buffer (#?"[a]bc\n  def\n")
        (cmd "dw")
        (ok (buf= #?"[\n]  def\n"))
        (cmd "dw")
        (ok (buf= #?"  [d]ef\n")))
      (with-vi-buffer (#?"abc\n[ ] def\n")
        (cmd "dw")
        (ok (buf= #?"abc\n[d]ef\n"))))
    (testing "daw"
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "daw")
        (ok (buf= "foo [b]az")))
      (with-vi-buffer ("foo bar b[a]z")
        (cmd "daw")
        (ok (buf= "foo ba[r]")))
      (with-vi-buffer ("foo[ ] bar   baz")
        (cmd "daw")
        (ok (buf= "foo[ ]  baz")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "2daw")
        (ok (buf= "fo[o]")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "d2aw")
        (ok (buf= "fo[o]")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "3daw")
        (ok (buf= "foo b[a]r baz")))
      (with-vi-buffer ("f[o]o$bar")
        (cmd "daw")
        (ok (buf= "[$]bar"))
        (cmd "daw")
        (ok (buf= "[b]ar")))
      (with-vi-buffer (#?"[]\n foo bar\n")
        (cmd "daw")
        (ok (buf= #?"[ ]bar\n"))))
    (testing "diw"
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "diw")
        (ok (buf= "foo [ ]baz"))
        (cmd "diw")
        (ok (buf= "foo[b]az")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "2diw")
        (ok (buf= "foo [b]az"))
        (cmd "2diw")
        (ok (buf= "foo [b]az")))
      (with-vi-buffer ("f[o]o$bar")
        (cmd "diw")
        (ok (buf= "[$]bar"))
        (cmd "diw")
        (ok (buf= "[b]ar")))
      (with-vi-buffer (#?"[]\n foo bar\n")
        (cmd "diw")
        (ok (buf= #?"[]\n foo bar\n"))))
    (testing "di\""
      (with-vi-buffer (" \"f[o]o\"  ")
        (cmd "di\"")
        (ok (buf= " \"[\"]  "))))))

(deftest vi-change
  (with-fake-interface ()
    (testing "change linewise"
      (with-vi-buffer (#?"a[b]c\ndef\n")
        (cmd "cc")
        (ok (buf= #?"[]\ndef\n")))
      (with-vi-buffer (#?"abc\nd[e]f")
        (cmd "cc")
        (ok (buf= #?"abc\n[]"))))
    (testing "change charwise"
      (with-vi-buffer (#?"a[b]c\ndef\n")
        (cmd "cl")
        (ok (buf= #?"a[]c\ndef\n"))))))

(deftest vi-change-whole-line
  (with-fake-interface ()
    (with-vi-buffer (#?"a[b]c\ndef\n")
      (cmd "S")
      (ok (buf= #?"[]\ndef\n")))
    (with-vi-buffer (#?"a[b]c\ndef\n")
      (cmd "2S")
      (ok (buf= #?"[]\n")))))

(deftest vi-join-line
  (with-fake-interface ()
    (lem:window-set-size (lem:current-window) 5 24)
    (with-vi-buffer (#?"[a]bcdefgh\nijklmn\n")
      (cmd "J")
      (ok (buf= #?"abcdefgh[ ]ijklmn\n")))))

(deftest vi-yank
  (with-fake-interface ()
    (flet ((last-kill ()
             (peek-killring-item (current-killring) 0)))
      (with-vi-buffer (#?"a[b]cd\n")
        (cmd "yl")
        (ok (buf= #?"a[b]cd\n"))
        (ok (equal (last-kill) "b")))
      (with-vi-buffer (#?"ef[g]h\n")
        (cmd "yh")
        (ok (buf= #?"e[f]gh\n"))
        (ok (equal (last-kill) "f")))
      (with-vi-buffer (#?"ab[c]d\nefgh\n")
        (cmd "yj")
        (ok (buf= #?"ab[c]d\nefgh\n"))
        (ok (equalp (multiple-value-list (last-kill))
                    (list #?"abcd\nefgh\n" '(:vi-line)))))
      (with-vi-buffer (#?"ijkl\n[m]nop\n")
        (cmd "yk")
        (ok (buf= #?"[i]jkl\nmnop\n"))
        (ok (equalp (multiple-value-list (last-kill))
                    (list #?"ijkl\nmnop\n" '(:vi-line)))))
      (with-vi-buffer (#?"ab[c]d\nefgh\n")
        (cmd "<C-v>hjy")
        (ok (buf= #?"a[b]cd\nefgh\n")))
      (with-vi-buffer (#?"a[b]cd\nefgh\n")
        (cmd "<C-v>jky")
        (ok (buf= #?"a[b]cd\nefgh\n")))
      (with-vi-buffer (#?"abcd\ne[f]gh\n")
        (cmd "<C-v>kly")
        (ok (buf= #?"a[b]cd\nefgh\n")))
      (with-vi-buffer (#?"abcd\nef[g]h\n")
        (cmd "<C-v>khy")
        (ok (buf= #?"a[b]cd\nefgh\n"))))))

(deftest vi-yank-line
  (with-fake-interface ()
    (with-vi-buffer (#?"a[b]cd\nefgh\n")
      (cmd "Y")
      (ok (buf= #?"a[b]cd\nefgh\n"))
      (cmd "jlp")
      (ok (buf= #?"abcd\nefgbc[d]h\n")))))

(deftest vi-delete-next-char
  (with-fake-interface ()
    (with-vi-buffer ("")
      (ok (not (signals (cmd "x")))))))

(deftest vi-replace-char
  (with-fake-interface ()
    (with-vi-buffer ("a[n]t")
      (cmd "rr")
      (ok (buf= "a[r]t")))
    (with-vi-buffer ("sh[o]ut")
      (cmd "2re")
      (ok (buf= "she[e]t")))
    (with-vi-buffer ("<[m]>eat")
      (cmd "rb")
      (ok (buf= "[b]eat")))
    (with-vi-buffer ("p<i[n]>k")
      (cmd "re")
      (ok (buf= "p[e]ek")))
    (with-vi-buffer ("p<[i]c>k")
      (cmd "re")
      (ok (buf= "p[e]ek")))
    (with-vi-buffer (#?"em[a]cs\n")
      (cmd "VrX")
      (ok (buf= #?"[X]XXXX\n")))
    (with-vi-buffer (#?"a[b]cd\nefgh\n")
      (cmd "<C-v>jlrx")
      (ok (buf= #?"a[x]xd\nexxh\n")))
    (with-vi-buffer (#?"ab[c]d\nefgh\n")
      (cmd "<C-v>jhrx")
      (ok (buf= #?"a[x]xd\nexxh\n")))
    (with-vi-buffer (#?"abcd\nef[g]h\n")
      (cmd "<C-v>khrx")
      (ok (buf= #?"a[x]xd\nexxh\n")))
    (with-vi-buffer (#?"abcd\ne[f]gh\n")
      (cmd "<C-v>klrx")
      (ok (buf= #?"a[x]xd\nexxh\n")))))

(deftest vi-repeat
  (with-fake-interface ()
    (with-vi-buffer (#?"[1]:abc\n2:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw")
      (cmd "dd")
      (ok (buf= #?"[2]:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd ".")
      (ok (buf= #?"[3]:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd "2.")
      (ok (buf= #?"[5]:mno\n6:opq\n7:rst\n8:uvw")))
    (with-vi-buffer (#?"[1]:abc\n2:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw")
      (cmd "2d2d")
      (ok (buf= #?"[5]:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd "2.")
      (ok (buf= #?"[7]:rst\n8:uvw")))
    (with-vi-buffer (#?"[f]oo\nbar\nbaz\n")
      (cmd "A-fighters<Esc>")
      (ok (buf= #?"foo-fighter[s]\nbar\nbaz\n"))
      (cmd "j^.")
      (ok (buf= #?"foo-fighters\nbar-fighter[s]\nbaz\n")))))
