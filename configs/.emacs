;;---------------------------------------------------------------
;; $Id: .emacs,v 1.12 1999/09/27 23:11:43 lord Exp lord $
;;---------------------------------------------------------------

(setq load-path
      (cons "/opt/local//share/emacs/site-lisp"
            (cons "/opt/local/share/mercurial/contrib"
                  (cons (expand-file-name "~/lisp")
                        (cons "/usr/share/emacs/site-lisp/"
                              load-path))))
      )



;; Prevent split window on startup
(setq inhibit-startup-screen t)

;; Boostrap package management, with MELPA repository
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Load some packages I use

(use-package solarized-theme :ensure t) ;; https://github.com/bbatsov/solarized-emacs
(use-package cc-mode :ensure t)
(use-package tex-site
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :init (add-hook 'LaTeX-mode-hook 'flyspell-mode))

(use-package magit
  :ensure t
  :init (global-set-key (kbd "C-x g") 'magit-status))

(use-package helm-ag
  :ensure t
  :init (global-set-key (kbd "C-<XF86Search>") 'helm-ag))

(use-package iflipb
  :ensure t
  :init (progn
          (global-set-key (kbd "<C-tab>") 'iflipb-next-buffer)
          (global-set-key
           (if (featurep 'xemacs) (kbd "<C-iso-left-tab>") (kbd "<C-S-iso-lefttab>"))
           'iflipb-previous-buffer)))


(require 'font-lock)
(use-package ws-butler :ensure t)

(global-set-key "\M-BS" 'backward-kill-word)

(defun tidy-buffer ()
  "Tidy up current buffer by re-identing and cleaning up whitespace"
  (interactive)
  (indent-region (point-min) (point-max))
  (whitespace-cleanup-region (point-min) (point-max)))

(defun my-c-setup ()
  "C mode setup"
  (setq truncate-lines t)
  (turn-on-font-lock)
  (c-add-style "Crocodile"
               '(
                 (c-basic-offset . 4)
                 (c-comment-only-line-offset . 0)
                 (c-offsets-alist .
                                  ((statement-block-intro . +)
                                   (arglist-intro         . +)
                                   (arglist-cont          . 0)
                                   (arglist-close         . 0)
                                   (knr-argdecl-intro     . +)
                                   (substatement-open     . 0)
                                   (access-label          . -)
                                   (label                 . -)
                                   (statement-cont        . 0)
                                   (statement-case-open   . 0)
                                   (inline-open           . 0)
                                   (defun-block-intro     . 4)
                                   (brace-list-open       . 0)
                                   (class-open            . 0)

                                   ))))
  (c-set-style "Crocodile")
  )

(add-hook 'c-mode-hook    'my-c-setup)
(add-hook 'c++-mode-hook  'my-c-setup)


;; --- General ---

(setq make-backup-files nil)
(setq transient-mark-mode 1)
(setq scroll-step 1)
(setq compile-command "make")
(put 'downcase-region 'disabled nil)
(put 'upcase-region   'disabled nil)
(setq line-number-mode     1)
(setq-default indent-tabs-mode nil)
(setq default-tab-width 4)
(setq remote-shell-program "ssh")
(delete-selection-mode t)

;; Keys
(global-set-key [f7]   'grep-find)
(global-set-key [f8]   'next-error)
;;(global-set-key [f9]   'tramp-compile)
(global-set-key [f9]   'compile)
(global-set-key [home] 'beginning-of-line)
(global-set-key [end]  'end-of-line)

(global-set-key [backspace]      'delete-backward-char)

(global-set-key "\M-?" 'help-command)

(setq auto-mode-alist
      (append '(("\\.C$"         . c++-mode)
                ("\\.fs\\'"      . forth-mode)
                ("\\.4th\\'"     . forth-mode)
                ("\\.java$"      . java-mode)
                ("\\.cc$"        . c++-mode)
                ("\\.coo$"       . c++-mode)
                ("\\.fs$"        . forth-mode)
                ("\\.4th$"       . forth-mode)
                ("\\.c\\+\\+$"   . c++-mode)
                ("\\.C\\+\\+$"   . c++-mode)
                ("\\.h\\+\\+$"   . c++-mode)
                ("\\.H\\+\\+$"   . c++-mode)
                ("\\.hh$"        . c++-mode)
                ("\\.cxx$"       . c++-mode)
                ("\\.hxx$"       . c++-mode)
                ("\\.c$"         . c-mode)
                ("\\.h$"         . c-mode)
                ("\\.idl$"       . idl-mode)
                ("\\.scm$"       . scheme-mode)
                ("\\.stk$"       . scheme-mode)
                ("\\.stklos$"    . scheme-mode)
                ("\\.objc$"      . objc-mode)
                ("\\.asm$"       . asm-mode)
                ("\\.s$"         . asm-mode)
                ("\\.py$"        . python-mode)
                ("\\.[hg]s$"     . haskell-mode)
                ("\\.hi$"        . haskell-mode)
                ("\\.lsl$"       . lsl-mode)
                ("\\.l[hg]s$"    . literate-haskell-mode)
                ("\\.js\\'"      . javascript-mode)
                ) auto-mode-alist))


(use-package haskell-mode
  :ensure t
  :mode "\\.hs\\'"
  :config
  (progn
    (add-hook 'haskell-mode-hook 'turn-on-haskell-decl-scan)
    (add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
    (add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
    ;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)
    (define-key haskell-mode-map (kbd "C-c C-l") 'haskell-process-load-or-reload)
    ))

(autoload 'python-mode "python-mode" "Python editing mode." t)

(autoload 'javascript-mode "javascript" nil t)

(show-paren-mode t)

(if (eq window-system 'ns)
    ;; --- Mac-specific stuff ---
    ;; Dropping files opens then in new frame, not inserts
    (define-key global-map [ns-drag-file] 'ns-find-file)
  )

;; Jumping to matching bracket
(global-set-key '[M-right] 'forward-list)
(global-set-key '[M-left]  'backward-list)

;; Word jump
(global-set-key '[C-right] 'forward-word)
(global-set-key '[C-left]  'backward-word)

(setq vc-cvs-stay-local nil)
(setenv "CVS_RSH" "ssh");

;; Merge kill-buffer and MacOS clipboard
(setq x-select-enable-clipboard t)

(if (file-exists-p "~/lisp/mathematica.el")
    (load-file "~/lisp/mathematica.el"))

;; Proof general is not on MELPA, so we try to load it
;; from local directory, if available
(if (file-exists-p "~/lisp/ProofGeneral/generic/proof-site.el")
    (use-package proof-site
      :load-path ("~/lisp/ProofGeneral/coq" "~/lisp/ProofGeneral/generic")
      :mode ("\\.v\\'" . coq-mode)
      :config (add-hook 'coq-mode-hook #'company-coq-mode)
      :init
      (add-hook 'coq-mode-hook
                (lambda ()
                  (company-coq-initialize)
                  (ws-butler-mode)))
      (setq proof-splash-enable nil)
      (setq coq-prog-name "coqtop")
      (setq coq-compile-before-require t)
      (use-package company-coq
        :ensure t
        :commands company-coq-mode)
      (use-package coq-commenter
        :ensure t
        :config (add-hook 'coq-mode-hook 'coq-commenter-mode))
      ))

;; SLIME
(setq inferior-lisp-program "ccl64")
;;(setq inferior-lisp-program "clisp")
(use-package slime
  :ensure t
;  :config (require `slime-asdf)
  )

;; For PLT scheme
(use-package quack :ensure t) 

(use-package bison-mode
  :ensure t
  :config (setq auto-mode-alist
                (append '(("\\.mll$"     . bison-mode)
                          ("\\.mly$"     . bison-mode)
                          ) auto-mode-alist)))

;; For ML

(use-package tuareg
  :ensure t
  :config (add-to-list 'auto-mode-alist '("\\.ml\\'" . tuareg-mode)) ;Overwrite default mode for .ml which was SLIME
  :init
  (add-hook 'tuareg-mode-hook `ws-butler-mode)
  (use-package merlin
    :ensure t
    :bind (:map merlin-mode-map ("M-." . merlin-locate))
    :init
    (autoload 'merlin-mode "merlin" "Merlin mode" t)
    (add-hook 'tuareg-mode-hook 'merlin-mode)
    (add-hook 'caml-mode-hook 'merlin-mode)
    (use-package company
      :ensure t
      :init
      (with-eval-after-load 'company
        (add-to-list 'company-backends 'merlin-company-backend))
      (add-hook 'merlin-mode-hook 'company-mode))
    ))

;; To avoid tramp's "... too long for Unix domain socket" error under MacOS
(require 'tramp)
(if (boundp 'aquamacs-version)
    (setq tramp-ssh-controlmaster-options "-o ControlPath=~/tmp -o ControlMaster=auto -o ControlPersist=no"))
;;; For tramp to find remote binaries in non-standard paths
(add-to-list 'tramp-remote-path 'tramp-own-remote-path)

;; Remove antlr-mode as it opens .g SPIRAL files and I do not want this.
(setq auto-mode-alist (remove (rassoc 'antlr-mode auto-mode-alist) auto-mode-alist))

(tool-bar-mode -1)

(cd "~/")
(load "server")
(unless (server-running-p) (server-start))


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "unknown" :slant normal :weight normal :height 140 :width normal)))))
(put 'scroll-left 'disabled t)

;; Mark theme as "safe" to avoid startup warnings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default))))

(load-theme 'solarized-dark)
(setq x-underline-at-descent-line t)

