" ------------------------------------------------------------------------------
" 最小限の設定
" ------------------------------------------------------------------------------
" NOTE: `:h encoding-values`
" Vim が内部処理に利用する文字コード。保存時に使用する文字コード
set encoding=utf-8
" Vim が 既存ファイルの 文字コード推定に使う文字コードのリスト。
set fileencodings=utf-8,sjis,iso-2022-jp,euc-jp
" 新規ファイルを作成する際の文字コード
set fileencoding=utf-8

" バックアップ、スワップファイルを作らない
set nobackup noswapfile
" ファイルが外部で編集されたら即座に反映
set autoread
set hidden

" カーソル行、列を表示
set cursorline cursorcolumn
" 行番号表示
set number
" 行末記号とかそういうやつを定義
set listchars=tab:»-,trail:-,eol:↓,extends:»,precedes:«,nbsp:%
" ↑を表示
set list
" 長い行を折り返す
set wrap
" テキスト挿入中の自動折り返しを日本語に対応させる
set formatoptions+=mM
" 括弧入力時に対応する括弧を表示
set showmatch
set t_Co=256

" クリップボード連携を有効にする
set clipboard+=unnamed
" クリップボード連携を有効にした時に BackSpace (Delete) が効かなくなるので設定する
" バックスペースでインデントや改行を削除できるようにする
set backspace=indent,eol,start
" <Esc>を押された後次のキー入力を待つ時間
set ttimeoutlen=10

" kaoriya版用の設定
if has('kaoriya')
  " windows likeなキーマップ設定の読み込み
  " -> ctrl+c, ctrl+vとかが使えるようになるやつ
  source $VIMRUNTIME/mswin.vim
endif
" ------------------------------------------------------------------------------
"  Custom for 823
" ------------------------------------------------------------------------------
function! SqlToJavaCode(value_name) abort
  " 変数名のデフォルト値
  let value_name = "stSql"
  if a:value_name != ""
    " 引数が指定されたらそれを使う
    let value_name = a:value_name
  endif

  let insert_str_head = value_name .. " = " .. value_name .. " + \""
  let insert_str_tail = "\";"
  let command_insert_head = "%norm! I" .. insert_str_head
  let command_insert_tail = "%norm! A" .. insert_str_tail

  " 行頭に挿入
  execute command_insert_head
  " 行末に挿入
  execute command_insert_tail
endfunction

function! StrToArrayElement(symbol) abort
  " 囲む記号のデフォルト
  let symbol = "\""
  if a:symbol != ""
    " 引数が指定されたらそれを使う
    let symbol = a:symbol
  endif

  let insert_str_head = symbol
  let insert_str_tail = symbol .. ","
  let command_insert_head = "%norm! I" .. insert_str_head
  let command_insert_tail = "%norm! A" .. insert_str_tail

  " 行頭に挿入
  execute command_insert_head
  " 行末に挿入
  execute command_insert_tail
endfunction

function! AddSpaceToCol73() abort
  " バッファ内の各行ごとに処理
  for lnum in range(1, line('$'))
    " 現在行
    let current_line = getline(lnum)
    " 現在行の長さ
    let line_length = strlen(current_line)

    " 行の長さが73未満の場合、73桁目まで空白を追加
    if line_length < 73
      " 73桁目までの空白を追加
      let spaces_to_add = repeat(' ', 73 - line_length)
      let new_line = current_line . spaces_to_add
      
      " 行を更新
      call setline(lnum, new_line)
    endif
  endfor
endfunction

function! UpdateLineNum(start_num) abort
  " 開始行のデフォルト値
  let start_num = 10
  if a:start_num != ""
    " 引数が指定されたらそれを使う
    let start_num = a:start_num
  endif

  " 行番号の増分
  let increment = 10

  " バッファのすべての行を処理
  for lnum in range(1, line('$'))
    " 現在の行の内容を取得
    let current_line = getline(lnum)
    
    " 行番号を6桁にフォーマットし、行の前に追加
    let formatted_number = printf('%06d', start_num)
    let new_line = formatted_number .. strpart(current_line, 6)

    " 行を更新
    call setline(lnum, new_line)

    " 次の行番号にインクリメント
    let start_num += increment
  endfor
endfunction

"
" コマンド定義
"
" sql文をjavaコードに変換
command! -nargs=* SqlToJavaCode       :call SqlToJavaCode("<args>")
" 文字列を配列の記述に変換
command! -nargs=* StrToArrayElement   :call StrToArrayElement("<args>")
" 73桁目まで空白埋め
command!          AddSpaceToCol73     :call AddSpaceToCol73()
" 初め6桁で行番号
command! -nargs=* UpdateLineNum       :call UpdateLineNum("<args>")
