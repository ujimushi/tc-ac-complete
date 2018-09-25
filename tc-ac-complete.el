;;; tc-ac-complete.el --- Auto Completion for GNU Emacs with tc.el

;; Copyright (C) 2015, 2018 ujimushi(@srad.jp)

;; Author: ujimushi <no mail addrress>
;; URL: https://github.com/ujimushi/tc-ac-complete
;; Keywords: direct kanji input, completion

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'auto-complete)
(require 'tc-complete)

;; tc-complete.el内の同名関数を書き換え

(defun tcode-complete-make-candidate-list-string (prefix candidate-list)
  "補完候補のリストを表す文字列を作る。"
  (format "%s%s"
	  (let ((candidate (car candidate-list)))
	    (if (string= prefix
			 (substring candidate 0 (length prefix)))
		(substring candidate (length prefix))
	      (concat "(" candidate ")")))
	  (let ((candidate-list (mapcar (lambda (candidate)
					  (substring candidate 
						     (length prefix)))
					(cdr candidate-list))))
	    (if candidate-list
		(concat " ["
			(let ((count 1))
			  (mapconcat (lambda (candidate)
				       (format "%d)%s"
					       (setq count (1+ count))
					       candidate))
				     (cdr candidate-list)
				     " "))
			"]")
	    ""))))

;; tc-completeのキーを初期化
(global-set-key (kbd "M-RET") nil)

;;
;; tc-completeで動作させている
;; `tcode-complete-display-function'
;; をpost-command-hookから外す
;;
(remove-hook 'post-command-hook 'tcode-complete-display-function)

(defun tcode-complete-candidate-start ()
  "従来型tc-completeのバックグラウンド処理スタート"
  (interactive)
  (global-set-key (kbd "M-RET") 'tcode-complete-insert)
  (add-hook 'post-command-hook 'tcode-complete-display-function))

(defun tcode-complete-candidate-stop ()
  "従来型tc-completeのバックグラウンド処理ストップ"
  (interactive)
  (remove-hook 'post-command-hook 'tcode-complete-display-function)
  (setq tcode-complete-candidate-list nil))


(defun tcode-complete-save-dictionary ()
  "変更された補完辞書の内容を辞書ファイルに書き込む。"
  (interactive)
  (tcode-save-buffer tcode-complete-buffer-name
		     tcode-complete-dictionary-name)
  (tcode-verbose-message "補完用辞書を保存しました" " "))

; 交ぜ書き候補一つだけの時の後処理用変数
(defvar tcode-ac-no-match-point nil)
(defvar tcode-ac-no-match-string nil)
; 自動で交ぜ書き辞書から補完辞書に追加する用
(defvar tcode-ac-last-prefix nil)

(defun tcode-ac-complete-set ()
  "Auto-complete用に完全候補リストを設定する。
 バッファローカルの変数である
 `tcode-complete-candidate-list' に格納される。
`tcode-complete-display' を参考にした"
  (let* ((candidates (tcode-complete-search-candidate
		      (tcode-complete-scan-backward)))
	 (prefix (cdr (car candidates))))
    (if (< (length prefix) tcode-complete-min-context-length)
	(setq tcode-complete-candidate-list nil)
      (setq tcode-complete-candidate-list candidates))
    ))
    

(defun tcode-ac-prefix ()
  "auto-completeに開始位置を渡す"
  (car (car tcode-complete-candidate-list)))

(defun tcode-ac-candidate ()
  "auto-completeに候補リストを渡す"
  (cdr tcode-complete-candidate-list))

(defun tcode-ac-match (ac-prefix candidates)
  "auto-completeにmatch文字列を返す"
  (setq tcode-ac-no-match-point nil)
  (setq tcode-ac-no-match-string nil)
  (let ((tc-complete-prefix (car tcode-complete-candidate-list))
	(candidate-list (cdr tcode-complete-candidate-list))
	(top-candidate (car (cdr tcode-complete-candidate-list)))
	(matches))
    (setq tcode-ac-last-prefix (cdr tc-complete-prefix))
    (if (or
	 (/= (length candidate-list) 1)
	 (string-match ac-prefix top-candidate))
	(setq matches candidate-list)
      (setq tcode-ac-no-match-point (car tc-complete-prefix))
      (setq tcode-ac-no-match-string top-candidate)
      (setq  matches (list (concat (cdr tc-complete-prefix) tcode-message-overlay-prefix
				   top-candidate tcode-message-overlay-suffix))))))

(defun tcode-ac-action ()
  "交ぜ書き候補が一つのみの時の後処理と
交ぜ書き辞書が補完辞書に無かった時の対応"
  (if tcode-ac-no-match-point
      (progn
	(delete-region tcode-ac-no-match-point (point))
	(insert tcode-ac-no-match-string)))
  (let ((candidate))
    (if tcode-ac-no-match-point
	(setq candidate tcode-ac-no-match-string)
      (setq candidate (cdr ac-last-completion)))
    (tcode-complete-copy-entry-from-mazegaki-dictionary tcode-ac-last-prefix candidate))
  )

(defun tcode-ac-complete-set-function ()
  "`post-command'にフックしてバックグラウンドで候補リストを作成する。
`tcode-complete-display-function' を参考にした。"
  (if (and (tcode-on-p)
	   (memq last-command tcode-input-command-list))
      (tcode-ac-complete-set)))

(defvar ac-source-tcode-complete
  '(
    (prefix . tcode-ac-prefix)
    (match . tcode-ac-match)
    (action . tcode-ac-action)
    (symbol . "T"))
  "tc-completeの機能を使ったAuto-Completeの補完機能")

(defun tcode-ac-complete-light ()
  "auto-tcode-completeの機能を補完のみに切り替える"
  (interactive)
  (setq ac-source-tcode-complete
	'(
	  (prefix . tcode-ac-prefix)
	  (candidates . tcode-ac-candidate)
	  (symbol . "T"))))

(defun tcode-ac-complete-full ()
  "auto-tcode-completeの機能を交ぜ書き変換ありに切り替える"
  (interactive)
  (setq ac-source-tcode-complete
	'(
	  (prefix . tcode-ac-prefix)
	  (match . tcode-ac-match)
	  (action . tcode-ac-action)
	  (symbol . "T"))))

(defun tcode-ac-candidate-start ()
  "auto-tcode-complete用のバックグラウンド処理を開始"
  (interactive)
  (add-hook 'post-command-hook 'tcode-ac-complete-set-function))

(defun tcode-ac-candidate-stop ()
  "auto-tcode-complete用のバックグラウンド処理を停止"
  (interactive)
  (remove-hook 'post-command-hook 'tcode-ac-complete-set-function)
  (setq tcode-complete-candidate-list nil)
  (setq tcode-ac-no-match-point nil)
  (setq tcode-ac-no-match-string nil))


(provide 'tc-ac-complete)

;;; tc-ac-complete.el ends here
