;;; cfs.el  ---  A frontend to CFS.

;; Copyright (C)  2003  Free Software Foundation, Inc.

;; Author: Marco Parrone
;; Keywords: CFS crypto filesystem external frontend

;; This file is part of GNU cfs-el.
;;
;; GNU cfs-el is not part of GNU Emacs.
;;
;; GNU cfs-el is part of the GNU project, released under the aegis of GNU.
;;
;; GNU cfs-el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; GNU cfs-el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Commentary:

;; GNU cfs-el is a frontend for using CFS (Criptographic File System)
;; from Emacs.
;;
;; For usage and other informations, read the info manual.
;;
;; Please send bug-reports and suggestions or comments to:
;;
;;   bug-cfs-el@gnu.org

;;; Code:

(defgroup cfs nil
  "A frontend for using CFS (Criptographic File System)."
  :prefix "cfs-"
  :group 'external)

(defcustom cfs-attach-lower-security-mode nil
  "*Less secure from the crypto side, but more secure on the
system side (easier backup recovery and less risk of race
conditions). Read the `cattach' (1) man page for details."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-attach-timeout 0
  "*Minutes after which the directory will detach automatically."
  :type 'integer
  :group 'cfs)

(defcustom cfs-attach-inactivity-timeout 0
  "*Minutes of inactivity after which the directory will detach
automatically."
  :type 'integer
  :group 'cfs)

(defcustom cfs-attach-ask-for-lower-security-mode nil
  "*If the user must be prompted about enabling the lower security mode."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-attach-ask-for-timeout nil
  "*If the user must be prompted about the timeout setting."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-attach-ask-for-inactivity-timeout nil
  "*If the user must be prompted about the inactivity timeout setting."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-mount-command "/etc/init.d/cfsd restart"
  "*The command to restart the `cfsd' (8) daemon (and so to mount
the cryptographic filesystem)."
  :type 'string
  :group 'cfs)

(defcustom cfs-cattach-command "cattach"
  "*The `cattach' (1) command."
  :type 'string
  :group 'cfs)

(defcustom cfs-cdetach-command "cdetach"
  "*The `cdetach' (1) command."
  :type 'string
  :group 'cfs)

(defcustom cfs-cmkdir-command "cmkdir"
  "*The `cmkdir' (1) command."
  :type 'string
  :group 'cfs)

(defcustom cfs-mount-use-sudo t
  "*Use `sudo' (8) to execute `cfs-mount-command'."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-make-ask-for-cipher nil
  "*If the user must be prompted for selecting the cipher."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-make-ask-for-options nil
  "*If the user must be prompted for enabling other options."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-make-cipher "-1"
  "*The default cipher used by `cfs-make'."
  :type '(choice (const :tag "two key hybrid mode single des" "-1")
		 (const :tag "three key triple des" "-3")
		 (const :tag "blowfish" "-b")
		 (const :tag "macguffin" "-m")
		 (const :tag "safer-sk128" "-s"))
  :group 'cfs)

(defcustom cfs-make-older-versions-compatibility-mode nil
  "*Enable compatibility with older CFS versions (< 1.3)."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-make-less-memory-consuming-mode nil
  "*Create directories that consume less memory but are less secure
  (read the `cmkdir' (1) man page for details)."
  :type 'boolean
  :group 'cfs)

(defcustom cfs-currently-attached-cleartext-instances-directory "/crypt"
  "*Directory containing the currently attached cleartext instances."
  :type 'string
  :group 'cfs)

;;;###autoload
(defun cfs-list ()
  "List attached directories."
  (interactive)
  (shell-command 
   (concat "ls "
	   cfs-currently-attached-cleartext-instances-directory)))

;;;###autoload
(defun cfs-check-if-mounted ()
  "Check if the CFS is mounted."
  (interactive)
  (shell-command "mount"))

;;;###autoload
(defun cfs-mount ()
  "Mount the CFS (restart cfsd, the CFS daemon)."
  (interactive)
  (shell-command (concat (if cfs-mount-use-sudo
			     (concat "echo "
				     (shell-quote-argument
				      (read-passwd "Password: "))
				     " | sudo -S ")
			   "")
			 cfs-mount-command)))

;;;###autoload
(defun cfs-attach ()
  "Attach an encrypted directory."
  (interactive)
  (let* ((filename
	  (shell-quote-argument
	   (expand-file-name
	    (read-file-name "Encrypted directory: "))))

	 ;; `half-command' rationale: `half-command' exists because,
	 ;; when you use `cattach' using the command-line, typing the
	 ;; passphrase is the last thing you do, and being coherent
	 ;; with the command line version is good.  More important, if
	 ;; you type some wrong option, you can quit before typing the
	 ;; passphrase, and this is good because a) the passphrase is
	 ;; (likely) long to type and b) it's better to type the
	 ;; passphrase as less times as possible, for security
	 ;; reasons.
	 ;;
	 (half-command
	  (concat "| " cfs-cattach-command " -- "
		  (if cfs-attach-ask-for-lower-security-mode
		      (if (y-or-n-p "Enable lower security mode? ")
			  " -l ")
		    (if cfs-attach-lower-security-mode " -l "))
		  " -t "
		  (if cfs-attach-ask-for-timeout
		      (shell-quote-argument
		       (read-string "Timeout (0 = none)? "
				    (number-to-string
				     cfs-attach-timeout)))
		    (number-to-string cfs-attach-timeout))
		  " -i "
		  (if cfs-attach-ask-for-inactivity-timeout
		      (shell-quote-argument
		       (read-string "Inactivity timeout (0 = none)? "
				    (number-to-string
				     cfs-attach-inactivity-timeout)))
		    (number-to-string cfs-attach-inactivity-timeout))
		  " "
		  filename
		  " "
		  (shell-quote-argument
		   (read-string "Cleartext directory name: "
				(file-name-nondirectory
				 (directory-file-name filename)))))))

    (shell-command (concat "echo "
			   (shell-quote-argument
			    (read-passwd "Passphrase: "))
			   half-command))))

;;;###autoload
(defun cfs-detach ()
  "Detach an encrypted directory."
  (interactive)
  (shell-command (concat cfs-cdetach-command " "
			 (shell-quote-argument
			  (file-name-nondirectory
			   (directory-file-name
			    (read-file-name "Encrypted directory: "
					    cfs-currently-attached-cleartext-instances-directory)))))))

;;;###autoload
(defun cfs-detach-all ()
  "Detach all the encrypted directories."
  (interactive)
  (shell-command
   (concat "for x in `ls "
           cfs-currently-attached-cleartext-instances-directory
	   "` ; do " 
	   cfs-cdetach-command
	   " $x ; done")))

;;;###autoload
(defun cfs-make ()
  "Make an encrypted directory."
  (interactive)
  (let* ((ciphers
	  '(("two key hybrid mode single des" . "-1")
	    ("three key triple des" . "-3")
	    ("blowfish" . "-b")
	    ("macguffin" . "-m")
	    ("safer-sk128" . "-s")))
	 (filename
	  (shell-quote-argument
	   (expand-file-name
	    (read-file-name "New encrypted directory: "))))
	 (half-command
	  (concat "| " cfs-cmkdir-command " -- "
		  (if cfs-make-ask-for-cipher
		      (cdr
		       (assoc
			(completing-read "Cipher: "
					 (mapcar 'car ciphers) nil t)
			ciphers))
		    cfs-make-cipher)
		  " "
		  (if cfs-make-ask-for-options
		      (concat
		       (if (y-or-n-p "Enable compatibility with older CFS versions (< 1.3)? ")
			   " -o ")
		       (if (y-or-n-p "Create directories that consume less memory but are less secure? ")
			   " -p "))
		    (concat
		      (if cfs-make-older-versions-compatibility-mode
			  " -o ")
		      (if cfs-make-less-memory-consuming-mode
			  " -p ")))
		  filename)))
    (shell-command (concat "echo "
			   (shell-quote-argument
			    (read-passwd "Passphrase: "))
			   half-command))))

;;;###autoload
(defun cfs-version ()
  "Return a string describing the version of cfs-el."
  (interactive)
  (let ((version
	 "GNU cfs-el version 0.5.0 (stable) of the 13th of October 2003"))
    (if (interactive-p)
	(message "%s" version)
      version)))

(provide 'cfs)

;; Local Variables:
;; mode: emacs-lisp
;; mode: auto-fill
;; fill-column: 70
;; comment-column: 32
;; End:

;;;; cfs.el ends here.
