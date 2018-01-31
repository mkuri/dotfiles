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
    (dracula-theme company counsel swiper ivy ddskk evil))))
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

;; company
(global-company-mode)

;; org-mode
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key (kbd "C-c b") 'org-iswitchb)
(setq org-startup-indented t)

;; skk
(global-set-key (kbd "C-x C-j") 'skk-mode)
(setq skk-server-host "localhost")
(setq skk-server-portnum 1178)
(setq skk-sticky-key ";")
(setq skk-jisyo-code 'utf-8)
(setq skk-jisyo "~/.local/share/skk/skk-jisyo.utf8")
(setq skk-backup-jisyo "~/.local/share/skk/skk-jisyo.utf8.bak")
(setq skk-record-file "~/.local/share/skk/skk-record")

;; key binding
(global-set-key (kbd "C-h") 'delete-backward-char)
(define-key evil-normal-state-map (kbd "SPC f e d")
  '(lambda ()
     (interactive)
     (find-file "~/.emacs.d/init.el")))
