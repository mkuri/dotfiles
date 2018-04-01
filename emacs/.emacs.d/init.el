;; package
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

;; visual
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode -1)
(show-paren-mode 1)
(setq ring-bell-function 'ignore)

;; color
(load-theme 'dracula t)

;; backup
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq delete-auto-save-files t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (js2-mode yasnippet-snippets yasnippet web-mode ranger dracula-theme company counsel swiper ivy ddskk evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; font
(create-fontset-from-ascii-font
 "IPAGothic-11" nil "ipagothic")
(set-fontset-font
 "fontset-ipagothic" 'unicode "IPAGothic-11" nil 'append)
(add-to-list 'default-frame-alist '(font . "fontset-ipagothic"))

;; evil
(evil-mode 1)

;; ivy
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)
(setq enable-recursive-minibuffers t)
(global-set-key (kbd "C-s") 'swiper)
(define-key evil-normal-state-map (kbd "SPC SPC") 'counsel-M-x)
(define-key evil-normal-state-map (kbd "SPC f f") 'counsel-find-file)
(define-key evil-normal-state-map (kbd "SPC f r") 'counsel-recentf)
(define-key evil-normal-state-map (kbd "SPC b b") 'ivy-switch-buffer)

;; company
(global-company-mode)
(global-set-key (kbd "C-SPC") 'company-complete)
(define-key company-active-map (kbd "C-h") 'delete-backward-char)
(define-key company-active-map (kbd "C-n") 'company-select-next)
(define-key company-active-map (kbd "C-p") 'company-select-previous)
(define-key company-search-map (kbd "C-n") 'company-select-next)
(define-key company-search-map (kbd "C-p") 'company-select-previous)
(setq company-idle-delay nil)

;; yasnippet
(yas-global-mode 1)

;; org-mode
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key (kbd "C-c b") 'org-iswitchb)
(setq org-startup-indented t)

;; skk
(global-set-key (kbd "C-x j") 'skk-mode)
(setq skk-server-host "localhost")
(setq skk-server-portnum 1178)
(setq skk-sticky-key ";")
(setq skk-jisyo-code 'utf-8)
(setq skk-jisyo (concat (getenv "XDG_DATA_HOME") "/skk/skk-jisyo.utf8"))
(setq skk-backup-jisyo (concat (getenv "XDG_DATA_HOME") "/skk/skk-jisyo.utf8.bak"))
(setq skk-record-file (concat (getenv "XDG_DATA_HOME") "/skk/skk-record"))

;; ranger
(define-key evil-normal-state-map (kbd "SPC f d") 'ranger)
(setq ranger-cleanup-eagerly t)

;; modes
;;; web-mode
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

;; key binding
(global-set-key (kbd "C-h") 'delete-backward-char)
;;(define-key evil-insert-state-map (kbd "C-n") 'next-line)
;;(define-key evil-insert-state-map (kbd "C-p") 'previous-line)
(define-key evil-insert-state-map (kbd "C-a") 'beginning-of-line)
(define-key evil-insert-state-map (kbd "C-e") 'end-of-line)
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)
(define-key evil-normal-state-map (kbd "SPC f e d")
  '(lambda ()
     (interactive)
     (find-file "~/.emacs.d/init.el")))
(define-key evil-normal-state-map (kbd "SPC !") 'shell-command)
;;; window
(define-key evil-normal-state-map (kbd "SPC w d") 'delete-window)
(define-key evil-normal-state-map (kbd "SPC w h") 'split-window-vertically)
(define-key evil-normal-state-map (kbd "SPC w v") 'split-window-horizontally)
