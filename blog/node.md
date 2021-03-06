<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. 简介</a></li>
<li><a href="#sec-2">2. javascript / node.js 语法相关</a>
<ul>
<li><a href="#sec-2-1">2.1. js2-mode</a></li>
<li><a href="#sec-2-2">2.2. espresso</a></li>
<li><a href="#sec-2-3">2.3. exuberant-ctags 提供类似Go To Definition 功能</a></li>
<li><a href="#sec-2-4">2.4. js2-highlight-vars 作用域内变量的 highlight 功能</a></li>
</ul>
</li>
<li><a href="#sec-3">3. 其他各种通用神器</a>
<ul>
<li><a href="#sec-3-1">3.1. find-file-suggest</a></li>
<li><a href="#sec-3-2">3.2. highlight-parentheses 高亮显示配对的括号（不同颜色显示）</a></li>
<li><a href="#sec-3-3">3.3. tramp 直接修改服务端代码或配置文件如同本地操作</a>
<ul>
<li><a href="#sec-3-3-1">3.3.1. 利用tramp提升root权限修改：</a></li>
<li><a href="#sec-3-3-2">3.3.2. 利用tramp修改远程服务器代码</a></li>
</ul>
</li>
<li><a href="#sec-3-4">3.4. yasnippet 提供各种语言的模板代码</a></li>
<li><a href="#sec-3-5">3.5. 版本控制</a>
<ul>
<li><a href="#sec-3-5-1">3.5.1. psvn 通过SVN管理你的代码</a></li>
<li><a href="#sec-3-5-2">3.5.2. git-emacs 通过git管理代码</a></li>
</ul>
</li>
<li><a href="#sec-3-6">3.6. Unit Test</a>
<ul>
<li><a href="#sec-3-6-1">3.6.1. Mocha yas 模板</a></li>
</ul>
</li>
</ul>
</li>
<li><a href="#sec-4">4. 总结</a></li>
</ul>
</div>
</div>


# 简介

之前的因为项目用node来构建，网上搜集了相关的插件，涉及到整个开发流程，共大家参考

# javascript / node.js 语法相关

## js2-mode

对于使用emacs来开发javascript的人来说js2-mode应该是必备神器，此工具可以提示js语法错误，
并用红色下滑线给予提示(当初像我这样js语法都没有过关的人来讲确实帮助挺大的^^)

配置过程：

    $ svn checkout http://js2-mode.googlecode.com/svn/trunk/ js2-mode
    $ cd js2-mode
    $ emacs --batch -f batch-byte-compile js2-mode.el
    $ cp js2-mode.elc ~/.emacs.d/

**有的童鞋可能会问怎么修改~/.emacs 文件，下面我会一起提供**

## espresso

刚接触node的人对缩进会有些头痛，这个插件就帮我们搞定node的缩进

    $wget http://download.savannah.gnu.org/releases-noredirect/espresso/espresso.el
    $cp ./espresso.el ~/.emacs.d/

**因为使用espresso的时候可能会跟yasnippet的快捷键冲突，建议大家按照下面进行修改**

首先创建nodejs.el文件

    $touch ~/.emacs.d/nodejs.el

把以下内容拷贝到nodejs.el里面

    ;;;; load & configure js2-mode 
    (autoload 'js2-mode "js2-mode" nil t)
    (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
    
    ;;; espresso mode
    (autoload 'espresso-mode "espresso")
    
    (add-hook 'js2-mode-hook
    (lambda ()
    (yas-global-mode 1)))
    
    (eval-after-load 'js2-mode
    '(progn
    (define-key js2-mode-map (kbd "TAB") (lambda()
    (interactive)
    (let ((yas/fallback-behavior 'return-nil))
    (unless (yas/expand)
    (indent-for-tab-command)
    (if (looking-back "^\s*")
    (back-to-indentation))))))))
    
    
    
    (defun my-js2-indent-function ()
    (interactive)
    (save-restriction
    (widen)
    (let* ((inhibit-point-motion-hooks t)
    (parse-status (save-excursion (syntax-ppss (point-at-bol))))
    (offset (- (current-column) (current-indentation)))
    (indentation (espresso--proper-indentation parse-status))
    node)
    
    (save-excursion
    
    ;; I like to indent case and labels to half of the tab width
    (back-to-indentation)
    (if (looking-at "case\\s-")
    (setq indentation (+ indentation (/ espresso-indent-level 2))))
    
    ;; consecutive declarations in a var statement are nice if
    ;; properly aligned, i.e:
    ;;
    ;; var foo = "bar",
    ;; bar = "foo";
    (setq node (js2-node-at-point))
    (when (and node
    (= js2-NAME (js2-node-type node))
    (= js2-VAR (js2-node-type (js2-node-parent node))))
    (setq indentation (+ 4 indentation))))
    
    (indent-line-to indentation)
    (when (> offset 0) (forward-char offset)))))
    
    (defun my-indent-sexp ()
    (interactive)
    (save-restriction
    (save-excursion
    (widen)
    (let* ((inhibit-point-motion-hooks t)
    (parse-status (syntax-ppss (point)))
    (beg (nth 1 parse-status))
    (end-marker (make-marker))
    (end (progn (goto-char beg) (forward-list) (point)))
    (ovl (make-overlay beg end)))
    (set-marker end-marker end)
    (overlay-put ovl 'face 'highlight)
    (goto-char beg)
    (while (< (point) (marker-position end-marker))
    ;; don't reindent blank lines so we don't set the "buffer
    ;; modified" property for nothing
    (beginning-of-line)
    (unless (looking-at "\\s-*$")
    (indent-according-to-mode))
    (forward-line))
    (run-with-timer 0.5 nil '(lambda(ovl)
    (delete-overlay ovl)) ovl)))))
    
    (defun my-js2-mode-hook ()
    (require 'espresso)
    (setq espresso-indent-level 2
    indent-tabs-mode nil
    c-basic-offset 2)
    (c-toggle-auto-state 0)
    (c-toggle-hungry-state 1)
    (set (make-local-variable 'indent-line-function) 'my-js2-indent-function)
    (define-key js2-mode-map [(meta control |)] 'cperl-lineup)
    (define-key js2-mode-map [(meta control \;)]
    '(lambda()
    (interactive)
    (insert "/* -----[ ")
    (save-excursion
    (insert " ]----- */"))
    ))
    (define-key js2-mode-map [(return)] 'newline-and-indent)
    (define-key js2-mode-map [(backspace)] 'c-electric-backspace)
    (define-key js2-mode-map [(control d)] 'c-electric-delete-forward)
    (define-key js2-mode-map [(control meta q)] 'my-indent-sexp)
    (if (featurep 'js2-highlight-vars)
    (js2-highlight-vars-mode))
    (message "My JS2 hook"))
    
    (add-hook 'js2-mode-hook 'my-js2-mode-hook)
    
    (provide 'nodejs)

然后最后修改~/.emacs 文件,增加以下内容

    (require 'nodejs)

## exuberant-ctags 提供类似Go To Definition 功能

此工具给我们提供跳到函数定义处类似的功能 , 不过如果出现同名函数的话还是会出现误跳的现象。

所以如果对函数名命名的时候多加考虑的话一般还是可以准确的跳转到定义处的。

    $sudo apt-get install exuberant-ctags
    $cd your_project_dir
    $ctags -e --recurse (跟目录下会创建TAGS索引文件)
    打开编辑器， 光标移动到要找的函数名处， "M-." 触发查找tag命令, 第一次会让你选择索引文件，就把刚才创建的TAGS文件找出来打开就可以了。

## js2-highlight-vars 作用域内变量的 highlight 功能

当写node的时候嵌套很多层，有时候自己也犯迷糊，所以自动高亮显示光标所在变量的话也会很有帮助的

    $wget http://mihai.bazon.net/projects/editing-javascript-with-emacs-js2-mode/js2-highlight-vars-mode/js2-highlight-vars.el
    $cp js2-highlight-vars.el ~/.emacs.d

修改~/.emacs文件

    ;; ;;js2-highlight vars
    (require 'js2-highlight-vars)
    (if (featurep 'js2-highlight-vars)
        (js2-highlight-vars-mode))

# 其他各种通用神器

介绍通用的emacs写代码必备神器， 相信你肯定也需要^^

## find-file-suggest

遇到多级项目工程目录结构，是否“C-x C-f" 按到手痛？或者添加 bookmark ?

这个插件就是帮我们索引项目文件的，就像source insight那样，只要输入文件名任意字段(当然支持RegExp)，就帮你定位到那个文件里。

配置过程：

    $wget https://find-file-suggest.googlecode.com/files/find-file-suggest_2010-03-02.zip
    $unzip find-file-suggest_2010-03-02.zip
    $cp find-file-suggest_2010-03-02 ~/.emacs.d

然后修改~/.emacs,把以下内容添加进去

    ;;find-file-suggest
    (require 'find-file-suggest)
    (global-set-key [(control x) (meta f)] 'find-file-suggest)
    (global-set-key [(control x) (meta g)] 'ffs-grep)

然后就是要建立搜引，以下给出两个node工程和C/C++工程的例子

    ;;c/c++ 工程创建索引(参数：别名, 工程目录, 要索引的文件名后缀, 要过滤的文件夹)
    (ffs-create-file-index "ejoy" "~/code/github/ejoy2d" "\\.h\\|\\.c\\|\\.lua" "\\doc$\\|\\.git$")
    ;;js/node.js 工程创建索引
    (ffs-create-file-index "sails" "/usr/local/lib/node_modules/sails/lib" "\\.js\\|\\.ejs\\|\\.html" "") 

用法：

    - 打开emacs， 输入 "M-x ffs-use-file-index" 回车
    - 输入 ejoy2d(之前建立的工程别名) 回车
    - "C-x M-f" 之后会显示所有索引到的文件列表
    - 直接输入想要查找的文件名（C-n 向下， C-p 向上），回车

## highlight-parentheses 高亮显示配对的括号（不同颜色显示）

多层嵌套的问题，对刚学node的人来说会有些头疼，1个 tab 2个空格已经够头痛了，还多层嵌套 -\_-!，

括号就更看不清了。所以把这个插件推荐给大家！（话说node嵌套问题，已经有了很多解决方案了 async, step, eventproxy&#x2026;有兴趣童鞋可以查找相关资料）

    $wget http://nschum.de/src/emacs/highlight-parentheses/highlight-parentheses.el
    $cp highlight-parentheses.el ~/.emacs.d
    修改~/.emacs
    (require 'highlight-parentheses)
    打开emacs
    (M-x highlight-parentheses-mode) 来触发该功能

## tramp 直接修改服务端代码或配置文件如同本地操作

emscs23 以上版本开始已经把tramp集成进去了，所以免额外的配置过程，直接使用。

### 利用tramp提升root权限修改：

    打开emacs
    "C-x C-f" 打开文件操作
    "C-a C-k" 删除当前路径
    输入 /su::/etc/ 按下 Tab按键
    输入 密码 （当然， 前提是当前用户是 sudoer）
    再次按下Tab 就能通过root访问所有文件了

### 利用tramp修改远程服务器代码

    "C-x C-f" 打开文件操作
    "C-a C-k" 删除当前路径
    输入 /luckyan315@192.168.3.2:/home/ 按下Tab
    按提示输入，第一次可能要建立ssh连接（反正按照提示输入yes 或者 y就行了），然后输入密码
    再次按下Tab 就能访问远程服务器目录了 ^_^

## yasnippet 提供各种语言的模板代码

从TextMate继层过来的非常有用的一个功能，提供各种语言的模板代码。

    $wget http://yasnippet.googlecode.com/files/yasnippet-0.6.1c.tar.bz2
    $cp yasnippet-0.6.1c ~/.emacs.d
    $cd ~/.emacs.d
    $mv yasnippet-0.6.1c yasnippet
    修改~/.emacs
    (add-to-list 'load-path
                 "~/.emacs.d/yasnippet")
    (require 'yasnippet) ;; not yasnippet-bundle
    (yas-global-mode 1)

**当我们安装js2-mode之后，我们需要手动创建一个js2-mode相关的snippets**

    $cd ~/.emacs.dyasnippet/snippets
    $cp -r js-mode js2-mode

## 版本控制

### psvn 通过SVN管理你的代码

前期原形代码很多人用svn来管理，使用过程中 用psvn个人感觉已经够用了

    $wget http://lifegoo.pluskid.org/wiki/lisp/psvn.el
    $cp ./psvn.el ~/.emacs.d
    修改~/.emacs, 添加以下内容
    ;;svn support
    (require 'psvn)

具体用法:

    g     - svn-status-update:               run 'svn status -v'
    M-s   - svn-status-update:               run 'svn status -v'
    C-u g - svn-status-update:               run 'svn status -vu'
    =     - svn-status-show-svn-diff         run 'svn diff'
    l     - svn-status-show-svn-log          run 'svn log'
    i     - svn-status-info                  run 'svn info'
    r     - svn-status-revert                run 'svn revert'
    X v   - svn-status-resolved              run 'svn resolved'
    U     - svn-status-update-cmd            run 'svn update'
    M-u   - svn-status-update-cmd            run 'svn update'
    c     - svn-status-commit                run 'svn commit'
    a     - svn-status-add-file              run 'svn add --non-recursive'
    A     - svn-status-add-file-recursively  run 'svn add'
    +     - svn-status-make-directory        run 'svn mkdir'
    R     - svn-status-mv                    run 'svn mv'
    D     - svn-status-rm                    run 'svn rm'
    M-c   - svn-status-cleanup               run 'svn cleanup'
    b     - svn-status-blame                 run 'svn blame'
    X e   - svn-status-export                run 'svn export'
    RET   - svn-status-find-file-or-examine-directory
    ^     - svn-status-examine-parent
    ~     - svn-status-get-specific-revision
    E     - svn-status-ediff-with-revision
    X X   - svn-status-resolve-conflicts
    s     - svn-status-show-process-buffer
    e     - svn-status-toggle-edit-cmd-flag
    ?     - svn-status-toggle-hide-unknown
    _     - svn-status-toggle-hide-unmodified
    m     - svn-status-set-user-mark
    u     - svn-status-unset-user-mark
    $     - svn-status-toggle-elide
    w     - svn-status-copy-filename-as-kill
    DEL   - svn-status-unset-user-mark-backwards
    \* !   - svn-status-unset-all-usermarks
    \* ?   - svn-status-mark-unknown
    \* A   - svn-status-mark-added
    \* M   - svn-status-mark-modified
    \* D   - svn-status-mark-deleted
    \* *   - svn-status-mark-changed
    .     - svn-status-goto-root-or-return
    f     - svn-status-find-file
    o     - svn-status-find-file-other-window
    v     - svn-status-view-file-other-window
    I     - svn-status-parse-info
    V     - svn-status-svnversion
    P l   - svn-status-property-list
    P s   - svn-status-property-set
    P d   - svn-status-property-delete
    P e   - svn-status-property-edit-one-entry
    P i   - svn-status-property-ignore-file
    P I   - svn-status-property-ignore-file-extension
    P C-i - svn-status-property-edit-svn-ignore
    P k   - svn-status-property-set-keyword-list
    P y   - svn-status-property-set-eol-style
    P x   - svn-status-property-set-executable
    h     - svn-status-use-history
    q     - svn-status-bury-buffer
    
    C-x C-j - svn-status-dired-jump

### git-emacs 通过git管理代码

因为很多快捷键和 psvn 相同，如果熟悉了psvn，不需要记住额外的快捷键就可以使用git-emacs来完成常用操作了(是的，我们是懒惰的 -\_-!)。

    $git clone https://github.com/tsgates/git-emacs.git
    $cp git-emacs ~/.emacs.d
    修改~/.emacs
    (add-to-list 'load-path "~/.emacs.d/git-emacs/")
    (require 'git-emacs)

和psvn一样，进入“M-x git-status” 进入控制面板。

常用命令：

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="left">Command</th>
<th scope="col" class="left">Comment</th>
</tr>
</thead>

<tbody>
<tr>
<td class="left">p/n</td>
<td class="left">在所有文件之间上下移动</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">P/N</td>
<td class="left">在变更过的文件之间上下移动</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left"></></td>
<td class="left">定位到列表的头部/尾部</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">v</td>
<td class="left">以只读方式打开文件</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">m/u/SPC</td>
<td class="left">设置/取消/切换标记，标记用于批量处理文件</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">a</td>
<td class="left">将文件加入版本控制</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">i</td>
<td class="left">将文件加入ignore</td>
</tr>
</tbody>

<tbody>
<tr>
<td class="left">c</td>
<td class="left">提交</td>
</tr>
</tbody>
</table>

## Unit Test

### Mocha yas 模板

因为我们之前安装了 yasnippet ，所以很多模板我们都可以网上找得到，以下是mocha 单元测试相关的模板

    $git clone https://github.com/jamescarr/mochajs-snippets.git
    $cp -r mochajs-snippets/javascript/* ~/.emacs.d/yasnippet/snippet/js2-mode
    如果已经打开emacs （重新打开时候自动reload）
    "M-x yas-reload-all" 
    就可以使用各种断言模板了，非常便利^^

# 总结

以上所有涉及到的文件，都可以在 <https://github.com/luckyan315/site-lisp> 这里找到，希望这个文章对大家学习 node 或者 emacs 有所帮助!
今天就到这里，改天继续^^