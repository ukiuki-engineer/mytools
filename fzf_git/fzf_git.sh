# ------------------------------------------------------------------------------
# fzfによるgit操作
# このファイルを`source`で読み込むと、以下のコマンドが使用可能になる
#
# - gitBranches
# →オブション
#   - `-a`: すべてのブランチを表示
#   - `-r`: リモートブランチのみ表示
# - gitStatus
# - gitLogs
#
# NOTE: fzfがインストールされていることが前提
# https://github.com/junegunn/fzf
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# コマンド(alias)から直接呼ばれる関数
# ------------------------------------------------------------------------------
# branches
_fzf_git_branches() {
  # git projectでなければ終了する
  if ! git status >/dev/null; then
    return 1
  fi

  git_branch_arg=""

  if [[ $1 == "-a" ]]; then
    git_branch_arg="-a"
  elif [[ $1 == "-r" ]]; then
    git_branch_arg="-r"
  fi

  tmp=$(mktemp)
  header="Enter: checkout, >: Select action"
  preview='
    branch={1}
    if [[ ${branch} = "Create" ]]; then
      return
    fi
    branch="${branch/remotes\//}"; \
    git log  \
    --oneline \
    --graph \
    --date=format:"%Y/%m/%d %H:%M:%S" \
    --color=always \
    --pretty="%C(auto)%h %C(blue)%ad %C(green)[%an]%C(reset) %s" \
    $branch
  '

  # 選択
  selected_branch=$(
    (
      echo -e "\e[35;1mCreate a new branch"
      git branch $git_branch_arg \
        --sort=-committerdate \
        --sort=-HEAD \
        --color=always \
        --format=$'%(HEAD) %(color:yellow)%(refname:short)\t%(color:green)%(committerdate:short)\t%(color:blue)%(subject)%(color:reset)' \
        | sed -e 's/origin\//remotes\/origin\//'
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
  if [[ -z $selected_branch ]]; then
    rm $tmp
    return 1
  fi

  selected_branch_name=$(echo $selected_branch | awk '{print $1}' | sed -e 's/^remotes\///')

  # select action
  if [[ $(cat $tmp) =~ 'select-action' ]]; then
    rm $tmp
    __branch_actions $selected_branch_name
    return
  fi

  rm $tmp

  if [[ $selected_branch =~ "Create a new branch" ]]; then
    # create a new branch
    __create_new_branch
    return
  else
    # checkout
    __checkout $selected_branch_name
  fi
}

# status
_fzf_git_status() {
  # git projectでなければ終了する
  if ! git status >/dev/null; then
    return 1
  fi

  tmp=$(mktemp)
  header="CTRL-s: Stage all, CTRL-u: Unstage all, >: Select action"
  preview='
    if [[ {} = "Delete latest commit" ]] || [[ {} = "Discard all changes" ]]; then
      return
    fi
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

  unpulled_commits=$(__get_unpulled_commits)
  unpushed_commits=$(__get_unpushed_commits)

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
        --prompt="↓${unpulled_commits} ↑${unpushed_commits} >" \
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
      # ステージングされた変更とワーキングディレクトリの変更を破棄
      git reset --hard
      # 未追跡のファイルとディレクトリを削除
      git clean -fd
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
  # git projectでなければ終了する
  if ! git status >/dev/null; then
    return 1
  fi

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
# ------------------------------------------------------------------------------
# branchに対するaction
# Parameters:
#   - $1: ブランチ名
__branch_actions() {
  # 引数無しだとエラー
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  branch=$1
  header="Enter: select action, <: back"
  tmp=$(mktemp)

  if [[ $branch =~ "^origin/" ]]; then
    actions="checkout"
  else
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
  fi

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
    if git branch --merged | grep -qE "^ *${branch}$"; then
      if __confirm "ブランチ '$branch' を削除しますか？"; then
        git branch -d "$branch"
      fi
    else
      if __confirm "ブランチ '$branch' は完全にマージされていません。削除してもよろしいですか？"; then
        git branch -D "$branch"
      fi
    fi
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
    # TODO: stash操作の参考→https://qiita.com/chihiro/items/f373873d5c2dfbd03250
    echo "TODO: stash"
  elif [[ $action == "discard" ]]; then
    if __confirm "選択した変更を全て破棄しますか？"; then
      echo $changes | while read -r change; do
        __discard_change $change
      done
    fi
  fi

  # 開き直し
  _fzf_git_status
}

# checkoutする
__checkout() {
  branch=$1
  if [[ $branch =~ '^origin/' ]]; then
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
    git clean -fd $change_file
  else
    # stagedの場合はunstage
    git restore --staged "$change_file"
    # 変更を削除
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

# 未pushのcommit数を取得
__get_unpushed_commits() {
  git rev-list --count origin/$(git rev-parse --abbrev-ref HEAD)..HEAD 2>/dev/null || echo 0
}

# 未pullのcommit数を取得
__get_unpulled_commits() {
  git rev-list --count HEAD..origin/$(git rev-parse --abbrev-ref HEAD) 2>/dev/null || echo 0
}
# ------------------------------------------------------------------------------
# main関数
# ------------------------------------------------------------------------------
main() {
  alias gitBranches='_fzf_git_branches'
  alias gitStatus='_fzf_git_status'
  alias gitLogs='_fzf_git_logs'
}
# ------------------------------------------------------------------------------

main
