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
" ------------------------------------------------------------------------------
"  Custom for 823
" ------------------------------------------------------------------------------
function! SqlToJavaCode(value_name) abort
  " 変数名のデフォルト値
  let l:value_name = "stSql"
  if a:value_name != ""
    " 引数が指定されたらそれを使う
    let l:value_name = a:value_name
  endif

  let l:insert_str_head = l:value_name .. " = " .. l:value_name .. " + \""
  let l:insert_str_tail = "\";"
  let l:command_insert_head = "%norm! I" .. l:insert_str_head
  let l:command_insert_tail = "%norm! A" .. l:insert_str_tail

  " 行頭に挿入
  execute l:command_insert_head
  " 行末に挿入
  execute l:command_insert_tail
endfunction

function! StrToArrayElement(symbol) abort
  " 囲む記号のデフォルト
  let l:symbol = "\""
  if a:symbol != ""
    " 引数が指定されたらそれを使う
    let l:symbol = a:symbol
  endif

  let l:insert_str_head = l:symbol
  let l:insert_str_tail = l:symbol .. ","
  let l:command_insert_head = "%norm! I" .. l:insert_str_head
  let l:command_insert_tail = "%norm! A" .. l:insert_str_tail

  " 行頭に挿入
  execute l:command_insert_head
  " 行末に挿入
  execute l:command_insert_tail
endfunction

" コマンド定義
command! -nargs=* SqlToJavaCode :call SqlToJavaCode("<args>")
command! -nargs=* StrToArrayElement :call StrToArrayElement("<args>")
