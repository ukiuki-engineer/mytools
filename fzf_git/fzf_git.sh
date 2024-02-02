# ------------------------------------------------------------------------------
# fzfによるgit操作
# このファイルを`source`で読み込むと、以下のコマンドが使用可能になる
#
# - gitBranches
# - gitStatus
# - gitLogs
#
# NOTE: fzfがインストールされていることが前提
# https://github.com/junegunn/fzf
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# コマンド(alias)から直接呼ばれる関数

# branches
_fzf_git_branches() {
  # git projectでなければ終了する
  if ! git status >/dev/null; then
    return 1
  fi

  tmp=$(mktemp)
  header="Enter: checkout, >: Select action"
  preview='
    git log  \
    --oneline \
    --graph \
    --date=format:"%Y/%m/%d %H:%M:%S" \
    --color=always \
    --pretty="%C(auto)%h %C(blue)%ad %C(green)[%an]%C(reset) %s" \
    {1}
  '

  # 選択
  selected_all=$(
    (
      echo -e "\e[35;1mCreate a new branch"
      git branch -a \
        --sort=-committerdate \
        --sort=-HEAD \
        --color=always \
        --format=$'%(HEAD) %(color:yellow)%(refname:short)\t%(color:green)%(committerdate:short)\t%(color:blue)%(subject)%(color:reset)'
    ) \
      | column -ts$'\t' \
      | fzf \
        --ansi \
        --border \
        --border-label ' Branches' \
        --height=80% \
        --header $header \
        --preview $preview \
        --preview-window='right,50%' \
        --bind=">:execute(echo 'select-action' > $tmp)+accept" \
      | sed -e 's/\*//'
  )

  # 選択されてなければ中断
  if [[ -z $selected_all ]]; then
    rm $tmp
    return 1
  fi

  selected=$(echo $selected_all | awk '{print $1}')

  # select action
  if [[ $(cat $tmp) =~ 'select-action' ]]; then
    rm $tmp
    __branch_actions $selected
    return
  fi

  rm $tmp

  if [[ $selected_all =~ "Create a new branch" ]]; then
    # create a new branch
    __create_new_branch
    return
  else
    # checkout
    __checkout $selected
  fi
}

# status
# TODO: promptに未pullと未pushのcommit数を表示する
_fzf_git_status() {
  tmp=$(mktemp)
  header="CTRL-s: Stage all, CTRL-u: Unstage all, >: Select action"
  preview='
    if echo {} | grep -E "^ M|^ D" >/dev/null; then
      git -c color.diff=always diff -- {2}
    elif echo {} | grep -E "^M|^D" >/dev/null; then
      git -c color.diff=always diff --staged {2}
    elif [[ {1} == "??" ]]; then
      bat --color=always {2}
    elif [[ {1} == "A" ]]; then
      git -c color.diff=always diff --staged {2}
    fi
  '

  selected=$(
    (
      echo -e "\e[35;1mDelete latest commit"
      echo -e "\e[35;1mDiscard all changes"
      git -c color.status=always status --porcelain -s --find-renames
    ) \
      | fzf \
        --multi \
        --ansi \
        --border \
        --border-label 'Git Status' \
        --height=80% \
        --header $header \
        --prompt="TODO: 未pullと未pushのcommit数を表示>" \
        --bind="tab:toggle+down" \
        --bind=">:execute(echo 'select-action' > $tmp)+accept" \
        --bind="ctrl-s:execute(git add . && echo 'stage-all' > $tmp)+accept" \
        --bind="ctrl-u:execute(git reset && echo 'unstage-all' > $tmp)+accept" \
        --preview $preview \
        --preview-window='right,50%'
  )

  # 選択されてなければ中断
  if [[ -z $selected ]]; then
    rm $tmp
    return 1
  fi

  # select action
  if [[ $(cat $tmp) =~ 'select-action' ]]; then
    rm $tmp
    __status_actions $selected
    return
  fi

  # stage-all or unstage-all
  if [[ $(cat $tmp) =~ 'stage-all' ]] || [[ $(cat $tmp) =~ 'unstage-all' ]]; then
    rm $tmp
    _fzf_git_status
    return
  fi

  if [[ $selected == "Delete latest commit" ]]; then
    # 最新のcommitを取消
    if __confirm "最新のcommitを取消して変更をステージングに戻しますか？"; then
      git reset --soft HEAD^
    fi
    # 開き直し
    _fzf_git_status
    return
  elif [[ $selected == "Discard all changes" ]]; then
    # 全ての変更を破棄
    if __confirm "全ての変更を破棄しますか？"; then
      # 変更ごとに処理
      git status --porcelain --find-renames | while read -r line; do
        # 変更を削除
        __discard_change $line
      done
    fi
    # 開き直し
    _fzf_git_status
    return
  fi

  echo $selected
}

# logs
# logと差分のプレビューだけ。actionは特になし。
_fzf_git_logs() {
  git log \
    --oneline \
    --graph \
    --date=format:"%Y/%m/%d %H:%M:%S" \
    --color=always \
    --pretty="%C(auto)%h %C(blue)%ad %C(green)[%an]%C(reset) %s" \
    | fzf \
      --ansi \
      --border \
      --preview 'git diff {2} --color=always' \
      --preview-window='right,50%'

}
# ------------------------------------------------------------------------------
# 内部的呼ばれる関数

# branchに対するaction
__branch_actions() {
  # 引数無しだとエラー
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  branch=$1
  header="Enter: select action, <: back"
  tmp=$(mktemp)

  # 選択肢
  actions="
    checkout,
    delete,
    merge,
    rebase,
    diff,
    echo,
  "
  actions=$(echo $actions | sed -e 's/,/\n/g' -e 's/ //g' | grep -vE '^$')

  # 選択
  action=$(
    echo $actions \
      | fzf \
        --border \
        --border-label 'Branch Actions' \
        --header $header \
        --height=20% \
        --prompt="Select actions for the branch, \"$branch\">" \
        --bind="<:execute(echo 'back' > $tmp)+accept"
  )

  # 選択されてなければ中断
  if [[ -z $action ]]; then
    rm $tmp
    return 1
  fi

  # back
  if [[ $(cat $tmp) =~ 'back' ]]; then
    rm $tmp
    _fzf_git_branches
    return
  fi

  rm $tmp

  # ここからactionの処理
  if [[ $action == "checkout" ]]; then
    # checkout
    __checkout $branch
  elif [[ $action == "delete" ]]; then
    # delete
    git branch -d $branch
    _fzf_git_branches
  elif [[ $action == "merge" ]]; then
    # merge
    git merge $branch
  elif [[ $action == "rebase" ]]; then
    # rebase
    # TODO: 動作未確認
    git rebase $branch
  elif [[ $action == "diff" ]]; then
    # diff
    git diff ${branch}..HEAD
  elif [[ $action == "echo" ]]; then
    # echo
    echo $branch
  fi
}

__status_actions() {
  # 引数無しだとエラー
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  changes=$*
  header="Enter: select action, <: back"
  header_lines="selected changes: "$(echo $changes | awk '{print $2", "}' | tr -d '\n' | sed -e 's/, $//')
  tmp=$(mktemp)

  # TODO: $changesの中身によって選択肢を変える(今は一旦いいや...)
  # →stage済み
  #   - unstage
  # →stageされていない
  #   - stage
  #   - discard
  #   - stash
  # →混合の場合、警告を出して元の画面に戻る

  # staged_changes=""
  # git diff --cached --name-only | while read -r line; do
  #   if [[ $staged_changes == "" ]]; then
  #     staged_changes="$line"
  #   else
  #     staged_changes="$staged_changes|$line"
  #   fi
  # done

  # if [[ condition ]]; then

  # fi
  # if ! echo $changes | grep -E $staged_changes >/dev/null; then
  #   # 全部未ステージ
  #   echo "全部未ステージ"
  # else
  #   count_changes=$(echo $changes | wc -l)
  #   count_staged_changes=$(echo $staged_changes | wc -l)
  #   if [[ $count_changes -eq $count_staged_changes ]]; then
  #     # 全部ステージ済み
  #     echo "全部ステージ済み"
  #   else
  #     # 混合
  #     # TODO: 同じファイルでstage済みと未stageが混在している場合に対応させる
  #     echo "混合"
  #   fi

  # fi

  actions="
    stage,
    unstage,
    stash,
    discard,
  "
  actions=$(echo $actions | sed -e 's/,/\n/g' -e 's/ //g' | grep -vE '^$')

  # 選択
  action=$(
    (
      echo $header_lines
      echo $actions
    ) \
      | fzf \
        --border \
        --border-label 'Status Actions' \
        --header $header \
        --header-lines 1 \
        --height=20% \
        --bind="<:execute(echo 'back' > $tmp)+accept"
  )

  # 選択されてなければ中断
  if [[ -z $action ]]; then
    rm $tmp
    return 1
  fi

  # back
  if [[ $(cat $tmp) =~ 'back' ]]; then
    rm $tmp
    _fzf_git_status
    return
  fi

  rm $tmp

  # ここからactionの処理
  if [[ $action == "stage" ]]; then
    # stage
    echo $changes | while read -r change; do
      change=$(echo $change | awk '{print $2}')
      git add $change
    done
  elif [[ $action == "unstage" ]]; then
    # unstage
    echo $changes | while read -r change; do
      change_kind=$(echo $change | awk '{print $1}')
      change_file=$(echo $change | awk '{print $2}')
      if [[ $change_kind == "R" ]]; then
        # renameをunsgageする
        change_file_after_rename=$(echo $change | sed -e 's/.*-> //')
        git restore --staged $change_file $change_file_after_rename
      else
        # rename以外をunstageする
        git reset $change_file
      fi
    done
  elif [[ $action == "stash" ]]; then
    # stash
    echo "TODO: stash"
    # TODO: stash操作の参考→https://qiita.com/chihiro/items/f373873d5c2dfbd03250
  elif [[ $action == "discard" ]]; then
    # TODO: できれば変更を破棄する前にconfirmを入れたい。ここだけじゃなく他のactionも...
    echo $changes | while read -r change; do
      __discard_change $change
    done
  fi

  # 開き直し
  _fzf_git_status
}

# checkoutする
__checkout() {
  branch=$1
  if [[ $branch =~ 'origin' ]]; then
    # origin
    git checkout -t $branch
  else
    # local
    git checkout $branch
  fi
}

# 新規ブランチを作成する
__create_new_branch() {
  echo -n "Enter a name for the new branch: "
  read new_branch
  git checkout -b $new_branch
  echo "Created and checked out new branch: $new_branch_name"
}

# 変更を削除する
__discard_change() {
  # NOTE: 何故か$1, $2と分離してなくて$1にまとまってたから分離させる...
  change_kind=$(echo $1 | awk '{print $1}')
  change_file=$(echo $1 | awk '{print $2}')

  if [[ $change_kind == "??" ]]; then
    # untrackedなfileは削除
    rm $change_file
  else
    # その他はrestore
    git restore $change_file
  fi
}

# 確認メッセージを表示する
# Parameters:
#   - $1: 確認メッセージ
__confirm() {
  echo -n "$1 (y/n)"
  read -r reply
  echo # 改行
  if [[ $reply =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}
# ------------------------------------------------------------------------------
# alias定義

alias gitBranches='_fzf_git_branches'
alias gitStatus='_fzf_git_status'
alias gitLogs='_fzf_git_logs'
