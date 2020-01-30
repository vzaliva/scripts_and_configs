;;---------------------------------------------------------------
;; $Id: .emacs,v 1.12 1999/09/27 23:11:43 lord Exp lord $
;;---------------------------------------------------------------

(setq load-path
      (cons "/opt/local//share/emacs/site-lisp"
            (cons "/opt/local/share/mercurial/contrib"
                  (cons (expand-file-name "~/lisp")
                        (cons "/usr/share/emacs/site-lisp/"
                              load-path)))))

;; Load LLVM mode, if present
(if (file-exists-p "/usr/share/emacs/site-lisp/llvm-6.0/llvm-mode.el")
    (lambda ()
      (load-file "/usr/share/emacs/site-lisp/llvm-6.0/llvm-mode.el")
      (require 'llvm-mode)))

;;(if (file-exists-p "~/.cask/cask.el")
;;    (progn
;;      (require 'cask "~/.cask/cask.el")
;;      (cask-initialize)))
      
;; Prevent split window on startup
(setq inhibit-startup-screen t)

;; Boostrap package management, with MELPA repository
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
(package-initialize)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Load some handy packages 

(use-package helm
  :ensure t
  :bind (("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-x C-b" . helm-buffers-list)
         ("C-x b" . helm-browse-project)
         )
  :config
  (add-hook 'helm-find-files-after-init-hook
            (lambda ()
              (define-key helm-find-files-map (kbd "C-<backspace>") 'helm-find-files-up-one-level)
              (setq helm-ff-skip-git-ignored-files t)))
  (setq helm-split-window-in-side-p t)
  (use-package helm-ls-git :ensure t))

(use-package solarized-theme :ensure t) ;; https://github.com/bbatsov/solarized-emacs
(use-package cc-mode :ensure t)
(use-package tex-site
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :init
  (add-hook 'LaTeX-mode-hook 'flyspell-mode))

(use-package latex-extra
  :ensure t
  :hook (LaTeX-mode . latex-extra-mode))

(use-package magit
  :ensure t
  :init (global-set-key (kbd "C-x g") 'magit-status))
  
(use-package helm-ag
  :ensure t
  :init
  (global-set-key (kbd "C-<XF86Search>") 'helm-ag)
  (global-set-key (kbd "C-S-<XF86Search>") 'helm-ag-this-file))

(use-package imenu-anywhere
  :ensure t
  :init
  (global-set-key (kbd "C-.") 'imenu-anywhere))

(use-package iflipb
  :ensure t
  :init 
  (global-set-key (kbd "<C-tab>") 'iflipb-next-buffer)
  (global-set-key
   (if (featurep 'xemacs) (kbd "<C-iso-left-tab>") (kbd "<C-S-iso-lefttab>"))
   'iflipb-previous-buffer))


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
(delete-selection-mode 1)

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
  (add-hook 'haskell-mode-hook 'turn-on-haskell-decl-scan)
  (add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
  ;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)
  (define-key haskell-mode-map (kbd "C-c C-l") 'haskell-process-load-or-reload)
  (define-key haskell-mode-map (kbd "C-c C-c") 'haskell-compile))


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

(use-package proof-general
  :mode ("\\.v\\'" . coq-mode)
  :init (setq coq-smie-user-tokens '(("≈" . "=") ("≡" . "=")))
  (add-hook 'coq-mode-hook
            (lambda ()
              (company-coq-initialize)
              (ws-butler-mode)
              (helm-mode)))
  (add-hook 'coq-mode-hook #'company-coq-mode)
  (add-hook 'my-mode-hook 'imenu-add-menubar-index)
  (setq proof-splash-enable nil)
  (setq coq-prog-name "coqtop")
  (setq coq-compile-before-require t)
  (use-package company-coq
    :ensure t
    :commands company-coq-mode)  
  )

;; SLIME
(setq inferior-lisp-program "ccl64")
;;(setq inferior-lisp-program "clisp")
(use-package slime
  :ensure t
;  :config (require `slime-asdf)
  )

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

(use-package org
  :ensure t
  :init
  (setq org-log-done 'time)
  (use-package org-bullets
    :ensure t
    :init (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))
  (add-hook 'org-mode-hook
            (lambda ()
              (progn
                (define-key org-mode-map [(control tab)] nil) ; release C-tab
                (setq org-hide-emphasis-markers t)
                (if (image-type-available-p 'imagemagick)
                    (setq org-image-actual-width 500))
                ))
            )
  )

;; Make PDFs displayed in latex-preview-pane-mode look nices
;(add-hook 'doc-view-mode-hook '(setq doc-view-resolution 300))

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

;; Save minibuffer history between launches
(savehist-mode 1)

;; Replace on yank
(delete-selection-mode 1)

;; Forces fixed-width font in org-mode
(setq solarized-use-variable-pitch nil
      solarized-scale-org-headlines nil)
(load-theme 'solarized-dark t)

(setq x-underline-at-descent-line t)

(if (file-exists-p "~/.emacs.d/opam-user-setup.el")
    (require 'opam-user-setup "~/.emacs.d/opam-user-setup.el"))

;;(desktop-save-mode 1)

(put 'scroll-left 'disabled t)

;; Inspired by https://www.emacswiki.org/emacs/BookmarkPlus#BulkDownloadCompileLoad 
(defun fetch-and-load-elisp (pkg-name pkg-files base-url base-dir)
  (let ((pkg-dir (concat (file-name-as-directory base-dir) (symbol-name pkg-name))))
    (require 'url)
    (add-to-list 'load-path pkg-dir)
    (make-directory pkg-dir t)
    (mapcar (lambda (arg)
              (let ((local-file (concat (file-name-as-directory pkg-dir) arg)))
                (unless (file-exists-p local-file)
                  (url-copy-file (concat base-url arg) local-file t))))
            pkg-files)
    (byte-recompile-directory pkg-dir 0)
    (require pkg-name)))

(when (fetch-and-load-elisp 'zoom-frm '("frame-cmds.el" "frame-fns.el" "zoom-frm.el") "https://www.emacswiki.org/emacs/download/" "~/lisp/")
      (define-key ctl-x-map [(control ?+)] 'zoom-in/out)
      (define-key ctl-x-map [(control ?-)] 'zoom-in/out)
      (define-key ctl-x-map [(control ?=)] 'zoom-in/out)
      (define-key ctl-x-map [(control ?0)] 'zoom-in/out))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "PfEd" :slant normal :weight normal :height 140 :width normal)))))

;; Mark theme as "safe" to avoid startup warnings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(browse-url-browser-function (quote browse-url-chrome))
 '(custom-safe-themes
   (quote
    ("2809bcb77ad21312897b541134981282dc455ccd7c14d74cc333b6e549b824f3" "5dbdb4a71a0e834318ae868143bb4329be492dd04bdf8b398fb103ba1b8c681a" "f8b886e3fce3b23ba517bd4ff29dd2c874c70b13d0fbdd1b3441be1d63f782eb" "5cd4770f787ad997ca9243662728031766736fc12f310b822a93de3c51d81878" "a68670dce845d18af9ec87716b4d4c2ea071271eccc80242be4d232c58b3cca2" "0598c6a29e13e7112cfbc2f523e31927ab7dce56ebb2016b567e1eff6dc1fd4f" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(doc-view-resolution 300)
 '(latex-preview-pane-use-frame t)
 '(line-number-mode 1)
 '(merlin-locate-in-new-window (quote never))
 '(org-agenda-files
   (quote
    ("~/Dropbox/Notes/codeminders.org" "~/Dropbox/Notes/research.org" "~/Dropbox/Notes/personal.org")))
 '(org-export-backends (quote (ascii beamer html latex md odt)))
 '(package-selected-packages
   (quote
    (multiple-cursors haskell-snippets helm-c-yasnippet dispwatch gnu-elpa-keyring-update helm-ls-git helm-ls-hg helm-ls-svn imenu-anywhere centaur-tabs tabbar cargo flycheck-rust flymake-rust ob-rust rust-mode company-coq magit-popup haskell-mode org-bullets academic-phrases latex-extra proof-general markdown-mode org ws-butler use-package tuareg solarized-theme slime quack python-mode osx-plist merlin markdown-preview-mode markdown-preview-eww markdown-mode+ magit latex-preview-pane iflipb highlight hi2 helm-idris helm-ag-r helm-ag flycheck-haskell facemenu+ diminish csv-mode coq-commenter bison-mode auctex)))
 '(safe-local-variable-values
   (quote
    ((eval let
           ((default-directory
              (locate-dominating-file buffer-file-name ".dir-locals.el")))
           (setq-local coq-prog-args
                       (\`
                        ("-coqlib"
                         (\,
                          (expand-file-name ".."))
                         "-R"
                         (\,
                          (expand-file-name "."))
                         "Coq")))
           (setq-local coq-prog-name
                       (expand-file-name "../bin/coqtop")))
     (eval progn
           (let
               ((coq-root-directory
                 (when buffer-file-name
                   (locate-dominating-file buffer-file-name ".dir-locals.el")))
                (coq-project-find-file
                 (and
                  (boundp
                   (quote coq-project-find-file))
                  coq-project-find-file)))
             (set
              (make-local-variable
               (quote tags-file-name))
              (concat coq-root-directory "TAGS"))
             (setq camldebug-command-name
                   (concat coq-root-directory "dev/ocamldebug-coq"))
             (unless coq-project-find-file
               (set
                (make-local-variable
                 (quote compile-command))
                (concat "make -C " coq-root-directory))
               (set
                (make-local-variable
                 (quote compilation-search-path))
                (cons coq-root-directory nil)))
             (when coq-project-find-file
               (setq default-directory coq-root-directory)))))))
 '(send-mail-function (quote mailclient-send-it))
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(transient-mark-mode 1))
