;;---------------------------------------------------------------
;; $Id: .emacs,v 1.12 1999/09/27 23:11:43 lord Exp lord $
;;---------------------------------------------------------------

(setq load-path
      (cons "/opt/local/share/emacs/site-lisp"
            (cons "/opt/local/share/mercurial/contrib"
                  (cons (expand-file-name "~/lisp")
                        (cons "/usr/share/emacs/site-lisp/"
                              load-path)))))

;; Load LLVM mode, if present
(if (file-exists-p "/usr/share/emacs/site-lisp/llvm/llvm-mode.el")
    (progn
      (load-file "/usr/share/emacs/site-lisp/llvm/llvm-mode.el")
      (require 'llvm-mode)))

;;(if (file-exists-p "~/.cask/cask.el")
;;    (progn
;;      (require 'cask "~/.cask/cask.el")
;;      (cask-initialize)))
      
;; Prevent split window on startup
(setq inhibit-startup-screen t)

;; auto-scroll compilation output
(setq compilation-scroll-output t)

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

(setq my-prompts `(
    (default . "You are a large language model living in Emacs and a helpful
                assistant. Respond concisely.")

    (paper . "You are my proofreader. Your job is to proofread the text I give
              you and correct grammar and spelling mistakes. Do
              not diverge too far from the original text and try
              to preserve as much as possible of the original
              sentence structure. Do not change any quoted
              text (inside quotation marks). The text you will be
              proofreading may occasionally use LaTeX syntax. If
              original text uses LaTeX quoation marks preserve
              them. For double quotes in LaTeX, use two
              backticks (`) for opening and two single quotes (')
              for closing: ``like this''. This is academic writing and I am using
              British English.")
    
    (ukrainian . "You are my Ukrainian proofreader. Your job is to proofread the
                  text I give you and correct mistakes. The
                  original text could be in any language but you
                  should output only Ukrainian.")
    
    (forums . "You are my proofreader. I write in British
              English. The post or a comment you will be
              reviewing is intended for a general audience (like
              forums or social media) and the tone needs to be
              brief and informal. Proofread and brush-up whatever
              I will send to you.")

    (email-formal .
                  "You are my proofreader. I write in British
                   English. I would like the style of my emails to be
                   business-like but not overly formal. Please review my reply to
                   the email (quoted). Please brush it up. Output just my reply,
                    without quoted text.")
    (email-informal .
                    "You are my proofreader. I write in British English. I would like the
                     style of my emails to be casual and collegial and not overly
                     formal. Minimize unnecessary pleasantries. But stay away from the slang
                      and overly informal expressions. Please review my reply to the email
                      (quoted). Please brush it up. Output just my reply, without quoted
text.")
    ))


(use-package multiple-cursors
  :ensure t
  :bind (("C-S-c C-S-c" .  'mc/edit-lines))
  :config (define-key mc/keymap (kbd "<return>") nil)
  )

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
  (use-package helm-ls-git :ensure t)
  (use-package helm-swoop
    :ensure t
    :config
    ;; Split direction.  'split-window-vertically or 'split-window-horizontally
    (setq helm-swoop-split-direction 'split-window-horizontally)
    :bind (("M-i" . helm-swoop)
           ("M-I" . 'helm-swoop-back-to-last-point))
    )
  )

(use-package flyspell
  :ensure t  
  :init
  ;; spell checking  via hunspell
  ;; sudo apt install hunspell hunspell-en-gb hunspell-uk
  (setq ispell-program-name "hunspell")
  (setq ispell-dictionary "en_GB")
)

(use-package helm-flyspell
  :ensure t  
  :bind (:map flyspell-mode-map ("C-;" . 'helm-flyspell-correct)))

(use-package imenu-anywhere
  :ensure t
  :ensure helm
  :init
  (global-set-key (kbd "C-.") 'helm-imenu-anywhere))

(use-package solarized-theme :ensure t) ;; https://github.com/bbatsov/solarized-emacs
(use-package cc-mode :ensure t)

(use-package tex-site
  :ensure auctex
  :ensure helm
  :ensure imenu-anywhere
  :mode ("\\.tex\\'" . LaTeX-mode)
  :config
  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (flyspell-mode)
	      (helm-mode)
              (imenu-add-menubar-index)
              (define-key LaTeX-mode-map (kbd "C-c C-,") 'helm-imenu-anywhere)
              ;(define-key LaTeX-mode-map (kbd "C-c C-e") 'chatgpt-shell-prompt-compose)
              )))

;; Temporary disabled due to https://debbugs.gnu.org/cgi/bugreport.cgi?bug=72999
;;(use-package latex-extra
;;  :ensure t
;;  :hook (LaTeX-mode . latex-extra-mode))

;; Emergency (magit): Magit requires ‘seq’ >= 2.24,
;; but due to bad defaults, Emacs’ package manager, refuses to
;; upgrade this and other built-in packages to higher releases
;; from GNU Elpa.
;; To fix this, you have to add this to your init file:
;(setq package-install-upgrade-built-in t)
(use-package magit
  :ensure t
  :init (global-set-key (kbd "C-x g") 'magit-status))
  
(use-package helm-ag
  :ensure t
  :init
  (global-set-key (kbd "C-<XF86Search>") 'helm-ag)
  (global-set-key (kbd "C-S-<XF86Search>") 'helm-ag-this-file)
  (global-set-key (kbd "<f7>") 'helm-ag)
  (global-set-key (kbd "C-<f7>") 'helm-ag-this-file))
  

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
(setq column-number-indicator-zero-based nil)
(setq-default indent-tabs-mode nil)
(setq default-tab-width 4)
(setq remote-shell-program "ssh")
(delete-selection-mode 1)

;; Keys
;(global-set-key [f7]   'grep-find)
(global-set-key [f8]   'next-error)
;;(global-set-key [f9]   'tramp-compile)
(global-set-key [f9]   'compile)
(global-set-key [home] 'beginning-of-line)
(global-set-key [end]  'end-of-line)

(global-set-key [backspace]      'delete-backward-char)

(global-set-key "\M-?" 'help-command)
(global-unset-key (kbd "M-SPC"))
(global-set-key (kbd "M-SPC") 'cycle-spacing)

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
                ("\\.lem$"       . tuareg-mode) ;; close enough
                ("\\.lsl$"       . lsl-mode)
                ("\\.l[hg]s$"    . literate-haskell-mode)
                ("\\.js\\'"      . javascript-mode)
                ) auto-mode-alist))


;; Require 'stylish-haskell' system package installed
(use-package haskell-mode
  :ensure t
  :mode "\\.hs\\'"
  :hook ((haskell-mode . turn-on-haskell-decl-scan)
         (haskell-mode . turn-on-haskell-doc-mode)
         (haskell-mode . turn-on-haskell-indentation))
  :bind (:map haskell-mode-map
              ("C-," . 'haskell-move-nested-left)
              ("C-." . 'haskell-move-nested-right)
              ("C-c C-l" . 'haskell-process-load-or-reload)
              ("C-c C-c" . 'haskell-compile)  
              ("C-c C-a C-a"   . hoogle)
              ("C-c s"   . haskell-mode-stylish-buffer)
              )
  :config (message "Loaded haskell-mode")
  (setq haskell-process-type 'stack-ghci)
  ;(setq haskell-process-type 'cabal-repl)
  (setq haskell-stylish-on-save t)
  (setq haskell-hoogle-url "https://www.stackage.org/lts/hoogle?q=%s")
  ;;(setq haskell-mode-stylish-haskell-path "brittany")
  )
  
(use-package dante
  :ensure t
  :defer t
  :after haskell-mode
  :commands 'dante-mode
  :init
  (add-hook 'haskell-mode-hook 'flycheck-mode)
  ;; OR for flymake support:
  ;;(add-hook 'haskell-mode-hook 'flymake-mode)
  (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake)
  (add-hook 'haskell-mode-hook 'dante-mode)
  )

(autoload 'javascript-mode "javascript" nil t)

(use-package helm-file-preview
  :ensure t
  :config
  (helm-file-preview-mode 1))

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

;; Display pretty tables in org mode
;; https://github.com/Fuco1/org-pretty-table
(if (file-exists-p "~/lisp/org-pretty-table/org-pretty-table.el")
    (progn
      (load-file "~/lisp/org-pretty-table/org-pretty-table.el")
      (add-hook 'org-mode-hook (lambda () (org-pretty-table-mode)))))

;; https://github.com/seagle0128/doom-modeline
(use-package all-the-icons :ensure t) ;manually run `all-the-icons-install-fonts` once after install
(use-package doom-modeline
  :ensure t
  :custom
  (doom-modeline-icon t)
  (doom-modeline-support-imenu t)
  (doom-modeline-height 1) ; optional
  (doom-modeline-project-detection 'project)
  :config
  (doom-modeline-mode 1)
  (custom-set-faces
   '(mode-line ((t (:family "Noto Sans" :height 0.9))))
   '(mode-line-active ((t (:family "Noto Sans" :height 0.9))))
   '(mode-line-inactive ((t (:family "Noto Sans" :height 0.9)))))
  :requires (all-the-icons))

(use-package proof-general
  :ensure t
  :after doom-modeline
  :mode ("\\.v\\'" . coq-mode)
  :custom
  (coq-smie-user-tokens '(("≈" . "=") ("≡" . "=")))
  (proof-splash-enable nil)
  (coq-prog-name "coqtop")
  (coq-compile-before-require nil)
  :hook
  (coq-mode . (lambda ()
                (ws-butler-mode)
                (helm-mode)
                ; to display number of goals
                (add-to-list 'global-mode-string '(" " (:eval (assq 'proof-active-buffer-fake-minor-mode minor-mode-alist))) " ")
                )))

(use-package company-coq
  :ensure t
  :custom (company-coq-live-on-the-edge t)
  :config
  :hook
  (coq-mode . (lambda ()
                (company-coq-mode)
                ; to display the rooster
                (add-to-list 'global-mode-string '(" " (:eval (assq 'company-coq-mode minor-mode-alist))) " ")
                )))
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

(use-package dune  :ensure t)
(use-package dune-format  :ensure t)

(use-package tuareg
  :ensure t
  :config (add-to-list 'auto-mode-alist '("\\.ml\\'" . tuareg-mode)) ;Overwrite default mode for .ml which was SLIME
  :init
  (add-hook 'tuareg-mode-hook `ws-butler-mode)
  (add-hook 'tuareg-mode-hook
            (lambda()
              (when (functionp 'prettify-symbols-mode)
                (prettify-symbols-mode))))
  (use-package merlin
    :ensure t
    :bind (:map merlin-mode-map ("M-." . merlin-locate))
    :bind (:map merlin-mode-map ("M-," . merlin-pop-stack))
    :init
    (autoload 'merlin-mode "merlin" "Merlin mode" t)
    (add-hook 'tuareg-mode-hook 'merlin-mode)
    (add-hook 'caml-mode-hook 'merlin-mode)
    (use-package merlin-company
      :ensure t
      :init
      (with-eval-after-load 'company
        (add-to-list 'company-backends 'merlin-company-backend))
      (add-hook 'merlin-mode-hook 'company-mode))
    :config
    (setq merlin-error-on-single-line t)
    :bind (("M-o" . merlin-occurrences))
    ))

(use-package org
  :ensure t
  :init
  (setq org-log-done 'time)
  (setq org-directory "~/ProtonDrive/Notes/")
  (use-package org-bullets
    :ensure t
    :init (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))
  (add-hook 'org-mode-hook
            (lambda ()
              (progn
                (define-key org-mode-map [(control tab)] nil) ; release C-tab
                (define-key org-mode-map "\C-cb" 'org-iswitchb)
                (setq org-hide-emphasis-markers t)
                ;; The following might not work wiht older
                ;; versions of emacs, which depend on imagemagick
                ;; for image resizing.
                (setq org-image-actual-width nil)
                
                ;; Capture templates for links to pages having [ and ]
                ;; characters in their page titles - notably ArXiv
                ;; From https://github.com/sprig/org-capture-extension
                ;; Requires some OS-level installation (registering protocol)
                (defun transform-square-brackets-to-round-ones(string-to-transform)
                  "Transforms [ into ( and ] into ), other chars left unchanged."
                  (concat 
                   (mapcar #'(lambda (c) (if (equal c ?\[) ?\( (if (equal c ?\]) ?\) c))) string-to-transform)))
                (setq org-capture-templates `(
                                              ("L" "Protocol Link" entry (file+headline ,(concat org-directory "notes.org") "Inbox")
                                               "* %? [[%:link][%(transform-square-brackets-to-round-ones \"%:description\")]]\n")
                                              
                                              ("p" "Protocol" entry (file+headline ,(concat org-directory "notes.org") "Inbox")
                                               "* %^{Title}\nSource: [[%:link][%(transform-square-brackets-to-round-ones \"%:description\")]]\n#+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?")
                                              ("t" "Protocol" entry (file+headline ,(concat org-directory "notes.org") "Inbox")
                                               "* %:description\n#+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?")
                                              
                                              ))
                )))
  :config
  (setq org-file-apps
        (append '(("\\.ll$" . emacs)
                  ("\\.core$" . emacs)) org-file-apps))
  
  :bind (:map org-mode-map ("C-c l" . 'org-store-link))
  )


(use-package epresent
  :ensure t
  :hook
  (epresent-mode . (lambda ()
                     (when (bound-and-true-p lsp-mode)
                       (lsp-mode -1)))))

(if (file-exists-p "~/lisp/mathematica.el")
    (load-file "~/lisp/mathematica.el"))

;; TODO: move inside "use-package org" section above
(require 'org-protocol)

;; Emacs iPython notebook
;; Requires `pip3 install notebook`
(use-package ein
  :ensure t
  :config
  ;; Execute ein source blocks in org-mode
  (org-babel-do-load-languages
   'org-babel-load-languages
   (append org-babel-load-languages '((ein . t))))
  )

(use-package langtool
  :ensure t
  :config
  (setq langtool-http-server-host "localhost" langtool-http-server-port 8010)
  (setq langtool-default-language "en-GB")
  )

(use-package lsp-mode
  :ensure t
  :commands lsp
  
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")

  :custom
  (lsp-auto-execute-action nil)
  
  :config
  ;(add-to-list 'lsp-language-id-configuration '(org-mode . "plaintext"))
  ;;:hook ((org-mode . lsp))
  )

(use-package lsp-grammarly
  :ensure t
  :hook (text-mode . (lambda ()
                       (require 'lsp-grammarly)
                       (lsp)))
  :custom
  (lsp-grammarly-dialect "british")
  (lsp-grammarly-domain "academic")
  (lsp-grammarly-audience "expert")
  (lsp-grammarly--show-debug-message t)
  )

(use-package keytar :ensure t)
(use-package lsp-ui
  :ensure t
  :config
  (setq lsp-ui-doc-enable nil)
  (setq lsp-ui-sideline-show-code-actions t)
  (setq lsp-ui-sideline-wait-for-all-symbols nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  ;;(setq lsp-ui-sideline-update-mode 'point)
  )

;; Does not seems to wrok
(use-package helm-lsp
  :ensure t
  :commands helm-lsp-workspace-symbol
  :bind (:map lsp-mode-map
              ("C-c l a a" . helm-lsp-code-actions))
  )

(use-package chatgpt-shell
  :ensure t
  :commands (chatgpt-shell chatgpt-shell-prompt-compose)
  :custom ((chatgpt-shell-openai-key
            (lambda () (auth-source-pick-first-password :host "api.openai.com"))))
  :config
  (setq chatgpt-shell-system-prompts (append
                                      chatgpt-shell-system-prompts
                                      (mapcar (lambda (p)
                                               (cons (symbol-name (car p))
                                                     (cdr p))) my-prompts
                                                     )))
  :bind (("C-c p" . chatgpt-shell-proofread-region)
         :map org-mode-map
         ("C-c C-e" . chatgpt-shell-prompt-compose)
         :map eshell-mode-map
         ("C-c C-e" . chatgpt-shell-prompt-compose)
         :map markdown-mode-map
         ("C-c C-e" . chatgpt-shell-prompt-compose)
         :map emacs-lisp-mode-map
         ("C-c C-e" . chatgpt-shell-prompt-compose))
  :hook (chatgpt-shell-mode . helm-mode))


(use-package rust-mode
  :ensure t)

;; Make PDFs displayed in latex-preview-pane-mode look nices
;(add-hook 'doc-view-mode-hook '(setq doc-view-resolution 300))

;; To avoid tramp's "... too long for Unix domain socket" error under MacOS
(require 'tramp)
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

;; OPAM stuff
(if (file-exists-p "~/.emacs.d/opam-user-setup.el")
    (require 'opam-user-setup "~/.emacs.d/opam-user-setup.el"))
(setq opam-share (substring (shell-command-to-string "opam config var share") 0 -1))
(add-to-list 'load-path (concat opam-share "/emacs/site-lisp"))

(use-package opam-switch-mode
  :ensure t
  :hook
  (coq-mode . opam-switch-mode))

(if (locate-library "ott-mode")
    (require 'ott-mode))

(if (locate-library "ocp-indent")
     (require 'ocp-indent))

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

(setq browse-url-browser-function 'browse-url-firefox
      browse-url-new-window-flag  nil
      browse-url-firefox-new-window-is-tab t)


;; Requires emacs 29!
;; TODO: https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode
;; (define-derived-mode core-ts-mode prog-mode "core"
;;   "Major mode for editing Core language files."
;;   ;; You can add mode-specific settings here.
;;   )
;; (use-package treesit-auto
;;   :ensure t
;;   :config
;;   (setq core-tsauto-config
;;         (make-treesit-auto-recipe
;;          :lang 'core
;;          :ts-mode 'core-ts-mode
;;          :url "https://github.com/vzaliva/tree-sitter-core"
;;          :revision "main"
;;          :source-dir "src"  
;;          :ext "\\.core\\'"
;;          :cc "/snap/emacs/current/usr/bin/gcc-10"
;;          :c++ "/snap/emacs/current/usr/bin/g++-10"
;;          ))
;;   (add-to-list 'treesit-auto-recipe-list core-tsauto-config)
;;   (setq treesit-auto-langs '(core))
;;   (treesit-auto-add-to-auto-mode-alist '(core))
;;   (global-treesit-auto-mode)
;;   (setq-default treesit-font-lock-level 4)
;;   )


;; BEGIN Iris support
;; https://gitlab.mpi-sws.org/iris/iris/-/blob/master/docs/editor.md

(use-package math-symbol-lists :ensure t)

(require 'math-symbol-lists)
; Automatically use math input method for Coq files
(add-hook 'coq-mode-hook (lambda () (set-input-method "math")))
; Input method for the minibuffer
(defun my-inherit-input-method ()
  "Inherit input method from `minibuffer-selected-window'."
  (let* ((win (minibuffer-selected-window))
         (buf (and win (window-buffer win))))
    (when buf
      (activate-input-method (buffer-local-value 'current-input-method buf)))))
(add-hook 'minibuffer-setup-hook #'my-inherit-input-method)
; Define the actual input method
(quail-define-package "math" "UTF-8" "Ω" t)
(quail-define-rules ; add whatever extra rules you want to define here...
 ("\\fun"    ?λ)
 ("\\mult"   ?⋅)
 ("\\ent"    ?⊢)
 ("\\valid"  ?✓)
 ("\\diamond" ?◇)
 ("\\box"    ?□)
 ("\\bbox"   ?■)
 ("\\later"  ?▷)
 ("\\pred"   ?φ)
 ("\\and"    ?∧)
 ("\\or"     ?∨)
 ("\\comp"   ?∘)
 ("\\ccomp"  ?◎)
 ("\\all"    ?∀)
 ("\\ex"     ?∃)
 ("\\to"     ?→)
 ("\\sep"    ?∗)
 ("\\lc"     ?⌜)
 ("\\rc"     ?⌝)
 ("\\Lc"     ?⎡)
 ("\\Rc"     ?⎤)
 ("\\lam"    ?λ)
 ("\\empty"  ?∅)
 ("\\Lam"    ?Λ)
 ("\\Sig"    ?Σ)
 ("\\-"      ?∖)
 ("\\aa"     ?●)
 ("\\af"     ?◯)
 ("\\auth"   ?●)
 ("\\frag"   ?◯)
 ("\\iff"    ?↔)
 ("\\gname"  ?γ)
 ("\\incl"   ?≼)
 ("\\latert" ?▶)
 ("\\update" ?⇝)

 ;; accents (for iLöb)
 ("\\\"o" ?ö)

 ;; subscripts and superscripts
 ("^^+" ?⁺) ("__+" ?₊) ("^^-" ?⁻)
 ("__0" ?₀) ("__1" ?₁) ("__2" ?₂) ("__3" ?₃) ("__4" ?₄)
 ("__5" ?₅) ("__6" ?₆) ("__7" ?₇) ("__8" ?₈) ("__9" ?₉)

 ("__a" ?ₐ) ("__e" ?ₑ) ("__h" ?ₕ) ("__i" ?ᵢ) ("__k" ?ₖ)
 ("__l" ?ₗ) ("__m" ?ₘ) ("__n" ?ₙ) ("__o" ?ₒ) ("__p" ?ₚ)
 ("__r" ?ᵣ) ("__s" ?ₛ) ("__t" ?ₜ) ("__u" ?ᵤ) ("__v" ?ᵥ) ("__x" ?ₓ)
)
(mapc (lambda (x)
        (if (cddr x)
            (quail-defrule (cadr x) (car (cddr x)))))
      ; need to reverse since different emacs packages disagree on whether
      ; the first or last entry should take priority...
      ; see <https://mattermost.mpi-sws.org/iris/pl/46onxnb3tb8ndg8b6h1z1f7tny> for discussion
      (reverse (append math-symbol-list-basic math-symbol-list-extended)))

;; Fonts
(set-face-attribute 'default nil :height 110) ; height is in 1/10pt
(dolist (ft (fontset-list))
  ; Main font
  (set-fontset-font ft 'unicode (font-spec :name "Monospace"))
  ; Fallback font
  ; Appending to the 'unicode list makes emacs unbearably slow.
  ;(set-fontset-font ft 'unicode (font-spec :name "DejaVu Sans Mono") nil 'append)
  (set-fontset-font ft nil (font-spec :name "DejaVu Sans Mono"))
)
; Fallback-fallback font
; If we 'append this to all fontsets, it picks Symbola even for some cases where DejaVu could
; be used. Adding it only to the "t" table makes it Do The Right Thing (TM).
(set-fontset-font t nil (font-spec :name "Symbola"))

(setq coq-smie-user-tokens
   '(("," . ":=")
	("∗" . "->")
	("-∗" . "->")
	("∗-∗" . "->")
	("==∗" . "->")
	("=∗" . "->") 			;; Hack to match ={E1,E2}=∗
	("|==>" . ":=")
	("⊢" . "->")
	("⊣⊢" . "->")
	("↔" . "->")
	("←" . "<-")
	("→" . "->")
	("=" . "->")
	("==" . "->")
	("/\\" . "->")
	("⋅" . "->")
	(":>" . ":=")
	("by" . "now")
	("forall" . "now")              ;; NB: this breaks current ∀ indentation.
   ))


;; END Iris support


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "PfEd" :slant normal :weight normal :height 140 :width normal))))
 '(mode-line ((t (:family "Noto Sans" :height 0.9))))
 '(mode-line-active ((t (:family "Noto Sans" :height 0.9))))
 '(mode-line-inactive ((t (:family "Noto Sans" :height 0.9)))))

;; Mark theme as "safe" to avoid startup warnings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(chatgpt-shell-prompt-header-proofread-region
   "You are my proofreader. Your job is to proofread the text I give you\12and correct grammar and spelling mistakes. Do not diverge too far from\12the original text and try to preserve as much as possible of the\12original sentence structure. Do not change any quoted text (inside\12quotation marks). The text you will be proofreading may occasionally\12use LaTeX syntax. If theoriginal text uses LaTeX quoation marks preserve\12them. For double quotes in LaTeX, use two backticks (`) for opening and two single quotes (') for closing: ``like this''. This is academic writing and I am using British English. Output just proofread text without any intro, comments or explanations.")
 '(custom-safe-themes
   '("2809bcb77ad21312897b541134981282dc455ccd7c14d74cc333b6e549b824f3" "5dbdb4a71a0e834318ae868143bb4329be492dd04bdf8b398fb103ba1b8c681a" "f8b886e3fce3b23ba517bd4ff29dd2c874c70b13d0fbdd1b3441be1d63f782eb" "5cd4770f787ad997ca9243662728031766736fc12f310b822a93de3c51d81878" "a68670dce845d18af9ec87716b4d4c2ea071271eccc80242be4d232c58b3cca2" "0598c6a29e13e7112cfbc2f523e31927ab7dce56ebb2016b567e1eff6dc1fd4f" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default))
 '(doc-view-resolution 300)
 '(latex-preview-pane-use-frame t)
 '(line-number-mode 1)
 '(lsp-grammarly-dialect "british")
 '(lsp-grammarly-domain "academic")
 '(lsp-ui-sideline-show-code-actions t)
 '(merlin-debug t)
 '(merlin-default-flags nil)
 '(merlin-error-on-single-line t)
 '(merlin-locate-in-new-window 'never)
 '(org-agenda-files
   '("~/ProtonDrive/Notes/codeminders.org" "~/ProtonDrive/Notes/research.org" "~/ProtonDrive/Notes/personal.org"))
 '(org-export-backends '(ascii beamer html latex md odt))
 '(package-selected-packages
   '(0xc auth-source auth-souce auto-souce auctex latex-extra 0x0 epresent 0blayout rust-mode abl-mode eglot faceup flymake jsonrpc project soap-client tramp use-package-ensure-system-package verilog-mode seq treesit-auto chatgpt-shell minions typescript-mode compat wfnames spinner f shrink-path request reformatter prop-menu polymode nerd-icons merlin-company magit-section lv eldoc lsp-mode grammarly lsp-grammarly lcr idris-mode flymake-grammarly anaphora deferred dante auto-complete gnu-elpa-keyring-update ac-c-headers ac-helm ac-html ac-math dockerfile-mode yaml-mode opam-switch-mode all-the-icons doom-modeline helm-file-preview graphviz-dot-mode helm-lsp langtool dune dune-format keytar lsp-ui markchars helm-swoop ein yasnippet async with-editor websocket web-server bind-key caml transient dash macrostep s popup epl pkg-info math-symbol-lists ht helm-core helm flymake-easy flycheck company company-math helm-org helm-flyspell transpose-frame multiple-cursors haskell-snippets helm-c-yasnippet dispwatch helm-ls-git helm-ls-hg helm-ls-svn imenu-anywhere tabbar cargo flycheck-rust flymake-rust ob-rust company-coq magit-popup haskell-mode org-bullets academic-phrases proof-general markdown-mode org ws-butler use-package tuareg solarized-theme slime quack python-mode osx-plist merlin markdown-preview-mode markdown-preview-eww markdown-mode+ magit latex-preview-pane iflipb highlight hi2 helm-idris helm-ag-r helm-ag flycheck-haskell facemenu+ diminish csv-mode coq-commenter bison-mode))
 '(safe-local-variable-values
   '((eval visual-line-mode t)
     (eval let
           ((default-directory
             (locate-dominating-file buffer-file-name ".dir-locals.el")))
           (setq-local coq-prog-args
                       `("-coqlib" ,(expand-file-name "..")
                         "-R" ,(expand-file-name ".")
                         "Coq"))
           (setq-local coq-prog-name
                       (expand-file-name "../bin/coqtop")))
     (eval progn
           (let
               ((coq-root-directory
                 (when buffer-file-name
                   (locate-dominating-file buffer-file-name ".dir-locals.el")))
                (coq-project-find-file
                 (and
                  (boundp 'coq-project-find-file)
                  coq-project-find-file)))
             (set
              (make-local-variable 'tags-file-name)
              (concat coq-root-directory "TAGS"))
             (setq camldebug-command-name
                   (concat coq-root-directory "dev/ocamldebug-coq"))
             (unless coq-project-find-file
               (set
                (make-local-variable 'compile-command)
                (concat "make -C " coq-root-directory))
               (set
                (make-local-variable 'compilation-search-path)
                (cons coq-root-directory nil)))
             (when coq-project-find-file
               (setq default-directory coq-root-directory))))))
 '(send-mail-function 'mailclient-send-it)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(transient-mark-mode 1)
 '(warning-suppress-log-types '((comp) (comp) (comp)))
 '(warning-suppress-types '((comp) (comp))))

;; Start in org-agenda window
(setq initial-buffer-choice (lambda ()
                              (org-agenda nil "t")
                              (delete-other-windows)
                              (get-buffer "*Org Agenda*")
                              ))

