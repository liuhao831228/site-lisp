;;An's emacs conf

;;javascript mode
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
;; (add-hook 'js2-mode-hook 'my-common-mode-auto-pair)



;; comment/uncomment
(defun qiang-comment-dwim-line (&optional arg)
  "Replacement for the comment-dwim command.
If no region is selected and current line is not blank and we are not at the end of the line,
then comment current line.
Replaces default behaviour of comment-dwim, when it inserts comment at the end of the line."
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (comment-dwim arg)))
(global-set-key "\M-;" 'qiang-comment-dwim-line)


;; Smart copy, if no region active, it simply copy the current whole line
(defadvice kill-line (before check-position activate)
  (if (member major-mode
              '(emacs-lisp-mode scheme-mode lisp-mode
                                c-mode c++-mode objc-mode js-mode
                                latex-mode plain-tex-mode))
      (if (and (eolp) (not (bolp)))
          (progn (forward-char 1)
                 (just-one-space 0)
                 (backward-char 1)))))
 
(defadvice kill-ring-save (before slick-copy activate compile)
  "When called interactively with no active region, copy a single line instead."
  (interactive (if mark-active (list (region-beginning) (region-end))
                 (message "Copied line")
                 (list (line-beginning-position)
                       (line-beginning-position 2)))))
 
(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))
 
;; Copy line from point to the end, exclude the line break
(defun qiang-copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring"
  (interactive "p")
  (kill-ring-save (point)
                  (line-end-position))
                  ;; (line-beginning-position (+ 1 arg)))
  (message "%d line%s copied" arg (if (= 1 arg) "" "s")))
 
(global-set-key (kbd "M-k") 'qiang-copy-line)


;;set the load-path
(add-to-list 'load-path "~/.emacs.d/site-lisp")





;;[new] background color solution
(require 'color-theme)
;;(color-theme-initialize)
(load-file "~/.emacs.d/site-lisp/color-theme-blackboard.el")
(color-theme-blackboard)


;;[old] original  background color solution 
;; (set-background-color "black") ;; 使用黑色背景
;; (set-foreground-color "grey85") ;; 使用白色前景
;; (set-face-foreground 'region "green")  ;; 区域前景颜色设为绿色
;; (set-face-background 'region "blue") ;; 区域背景色设为蓝色

;;show line number
(load-file "~/.emacs.d/site-lisp/linum.el")
(require 'linum)
(global-linum-mode 1)

;;load xcscope
(load-file "~/.emacs.d/site-lisp/xcscope.el")
(require 'xcscope)

;;ctrl + scroll , implement zoom in/out
(global-set-key [C-mouse-4] 'text-scale-increase)
(global-set-key [C-mouse-5] 'text-scale-decrease)

;;highlight the word
(load-file "~/.emacs.d/site-lisp/highlight-symbol.el")
(require 'highlight-symbol)                                                  
;;(global-set-key "/C-cgg" 'highlight-symbol-at-point)
(global-set-key [(control f3)] 'highlight-symbol-at-point)
(global-set-key [f3] 'highlight-symbol-next)
(global-set-key [(shift f3)] 'highlight-symbol-prev)
(global-set-key [(meta f3)] 'highlight-symbol-prev)

;;load yasnippet
(add-to-list 'load-path "~/.emacs.d/site-lisp/yasnippet-0.6.1c")
(require 'yasnippet)
(yas/initialize)
(yas/load-directory "~/.emacs.d/site-lisp/yasnippet-0.6.1c/snippets")
;;load yasnippet automaticlly , not need to type alt+x eval-buffer
(add-to-list 'load-path
          "~/.emacs.d/site-lisp")
;;(require 'yasnippet-bundle)



;;load cedet
(load-file "~/.emacs.d/site-lisp/cedet-1.0.1/common/cedet.el")

;;;; 具体说明可参考源码包下的INSTALL文件，或《A Gentle introduction to Cedet》

;; Enabling Semantic (code-parsing, smart completion) features

;; Select one of the following:
;;(semantic-load-enable-minimum-features)

;;(semantic-load-enable-code-helpers)

;;(semantic-load-enable-gaudy-code-helpers)

(semantic-load-enable-excessive-code-helpers)

;;(semantic-load-enable-semantic-debugging-helpers)



;;;; 使函数体能够折叠或展开

;; Enable source code folding

;;(global-semantic-tag-folding-mode 1)



;; Key bindings

(defun my-cedet-hook ()

  (local-set-key [(control return)] 'semantic-ia-complete-symbol)

  (local-set-key "/C-c?" 'semantic-ia-complete-symbol-menu)

  (local-set-key "/C-cd" 'semantic-ia-fast-jump)

  (local-set-key "/C-cr" 'semantic-symref-symbol)

  (local-set-key "/C-cR" 'semantic-symref))

(add-hook 'c-mode-common-hook 'my-cedet-hook)



;;;; 当输入"."或">"时，在另一个窗口中列出结构体或类的成员

(defun my-c-mode-cedet-hook ()

  (local-set-key "." 'semantic-complete-self-insert)

  (local-set-key ">" 'semantic-complete-self-insert))

(add-hook 'c-mode-common-hook 'my-c-mode-cedet-hook)

;;;;自动补齐策略

(defun my-indent-or-complete ()

   (interactive)

   (if (looking-at "//>")

          (hippie-expand nil)

          (indent-for-tab-command))

)



(global-set-key [(control tab)] 'my-indent-or-complete)



(autoload 'senator-try-expand-semantic "senator")

(setq hippie-expand-try-functions-list

          '(

              senator-try-expand-semantic

                   try-expand-dabbrev

                   try-expand-dabbrev-visible

                   try-expand-dabbrev-all-buffers

                   try-expand-dabbrev-from-kill

                   try-expand-list

                   try-expand-list-all-buffers

                   try-expand-line

        try-expand-line-all-buffers

        try-complete-file-name-partially

        try-complete-file-name

        try-expand-whole-kill

        )

)

;;install ecb
(add-to-list 'load-path "/home/luckyan315/.emacs.d/site-lisp/ecb-2.32")
(require 'ecb)

;;;auto start ecb
;; (setq ecb-auto-activate t
      ;; ecb-tip-of-the-day nil)

;;;; 各窗口间切换

(global-set-key [M-left] 'windmove-left)

(global-set-key [M-right] 'windmove-right)

(global-set-key [M-up] 'windmove-up)

(global-set-key [M-down] 'windmove-down)



;;;; 隐藏和显示ecb窗口

(define-key global-map [(control f1)] 'ecb-hide-ecb-windows)

(define-key global-map [(control f2)] 'ecb-show-ecb-windows)

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(ecb-options-version "2.32"))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )


;; set auto-complete

(add-to-list 'load-path "~/.emacs.d/site-lisp/auto-complete-1.3.1/")
; Load the default configuration
(require 'auto-complete-config)
; Make sure we can find the dictionaries
(add-to-list 'ac-dictionary-directories "~/.emacs.d/site-lisp/auto-complete-1.3.1/dict")
; Use dictionaries by default
(setq-default ac-sources (add-to-list 'ac-sources 'ac-source-dictionary))
(global-auto-complete-mode t)
; Start auto-completion after 2 characters of a word
(setq ac-auto-start 2)
; case sensitivity is important when finding matches
(setq ac-ignore-case nil)