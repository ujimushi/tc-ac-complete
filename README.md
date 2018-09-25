# tc-ac-complete auto-completion for Emacs with tc.el


## tc-ac-completeとは?

Emacsの漢直入力環境であるtc.elに，auto-complete.el
の機能を用いた補完環境を提供します。


## 使い方

 `load-path` の通っているフォルダに `tc-ac-complete.el` を置いて下さい。


### 設定方法

設定は

`init.el`等のEmacs初期化に次のような設定を追加します。

```emacs
;; 
(require 'tc-ac-complete)

;; 利用したいモードにフックして`ac-sources'に
;; `ac-source-tcode-complete' を追加
(add-hook 'text-mode-hook
 (function (lambda ()
  (setq ac-sources
   '(ac-source-tcode-complete ac-source-dictionary ac-source-abbrev)))))

;; テキストモードを補完対象とする
(add-to-list 'ac-modes 'text-mode)
```
ここで，`ac-sources` を `ac-source-tcode-complete` だけにすると，
`.tc`内で変更した `tcode-complete-min-context-length` 等が
反映されないことがあるようです。

この設定のように，`ac-source-dictionary` 等も含める(となぜがうまくいく)か，
`(setq tcode-complete-min-context-length 2)` 等，hookに含めるかをすれば
いいと思います。


また，`tcode-init-file-name`(通常は`~/.tc`) のファイルに次のような設定を追加します。

```emacs
(add-hook 'tcode-ready-hook
	  (function
	   (lambda ()
	   (tcode-ac-candidate-start)
	   )))
```

`tcode-ready-hook`のタイミングで，`tcode-ac-candidate-start`を実行するという
ものです。





