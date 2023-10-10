# ------------------------------------------------------------------------------
# fzfによるgit操作
# ------------------------------------------------------------------------------
# branches
_fzf_git_branches() {
  # git projectでなければ終了する
  if ! git status >/dev/null; then
    return 1
  fi

  local tmp=$(mktemp)
  local header="Enter: checkout, >: Select action"
  local preview='
    git log  \
    --oneline \
    --graph \
    --date=format:"%Y/%m/%d %H:%M:%S" \
    --color=always \
    --pretty="%C(auto)%h %C(blue)%ad %C(green)[%an]%C(reset) %s" \
    {1}
  '

  # 選択
  local branch=$(
    git branch -a \
      --sort=-committerdate \
      --sort=-HEAD \
      --color=always \
      --format=$'%(HEAD) %(color:yellow)%(refname:short)\t%(color:green)%(committerdate:short)\t%(color:blue)%(subject)%(color:reset)' \
      | column -ts$'\t' \
      | fzf \
        --ansi \
        --border \
        --border-label ' Branches' \
        --height=80% \
        --header $header \
        --preview $preview \
        --preview-window='right,70%' \
        --bind=">:execute(echo 'select-action' > $tmp)+accept" \
      | sed -e 's/\*//' \
      | awk '{print $1}'
  )

  # 選択されてなければ中断
  if [[ -z $branch ]]; then
    rm $tmp
    return 1
  fi

  # select action
  if [[ $(cat $tmp) =~ 'select-action' ]]; then
    rm $tmp
    __branch_actions $branch
    return
  fi

  rm $tmp

  # checkout
  __checkout $branch
}

# status
_fzf_git_status() {
  local tmp=$(mktemp)
  local header="CTRL-a: Stage all, CTRL-u: Unstage all, >: Select action"
  local preview='
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

  changes=$(
    git -c color.status=always status --porcelain -s --find-renames \
      | fzf \
        --multi \
        --ansi \
        --border \
        --border-label 'Git Status' \
        --height=80% \
        --header $header \
        --bind="tab:toggle+down" \
        --bind=">:execute(echo 'select-action' > $tmp)+accept" \
        --bind="ctrl-a:execute(git add . && echo 'stage-all' > $tmp)+accept" \
        --bind="ctrl-u:execute(git reset && echo 'unstage-all' > $tmp)+accept" \
        --preview $preview \
        --preview-window='right,70%'
  )

  # 選択されてなければ中断
  if [[ -z $changes ]]; then
    rm $tmp
    return 1
  fi

  # select action
  if [[ $(cat $tmp) =~ 'select-action' ]]; then
    rm $tmp
    __status_actions $changes
    return
  fi

  # stage-all or unstage-all
  if [[ $(cat $tmp) =~ 'stage-all' ]] || [[ $(cat $tmp) =~ 'unstage-all' ]]; then
    rm $tmp
    _fzf_git_status
    return
  fi

  echo $changes
}
# ------------------------------------------------------------------------------
# branchに対するaction
__branch_actions() {
  # 引数無しだとエラー
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  local branch=$1
  local header="Enter: select action, <: back"
  local tmp=$(mktemp)

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
  local action=$(
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

# checkoutする
__checkout() {
  local branch=$1
  if [[ $branch =~ 'origin' ]]; then
    # origin
    git checkout -t $branch
  else
    # local
    git checkout $branch
  fi
}

__status_actions() {
  # 引数無しだとエラー
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  local changes=$*
  local header="Enter: select action, <: back"
  local tmp=$(mktemp)

  # 選択肢
  actions="
    add,
    reset,
    stash,
  "
  actions=$(echo $actions | sed -e 's/,/\n/g' -e 's/ //g' | grep -vE '^$')

  # 選択
  local action=$(
    echo $actions \
      | fzf \
        --border \
        --border-label 'Status Actions' \
        --header $header \
        --height=20% \
        --prompt="\"$changes\">" \
        --bind="<:execute(echo 'back' > $tmp)+accept"
  )

  # ここからactionの処理
  if [[ $action == "add" ]]; then
    # add
    echo $changes | while read -r change; do
      change=$(echo $change | awk '{print $2}')
      git add $change
    done
    _fzf_git_status
  elif [[ $action == "reset" ]]; then
    # reset
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
    _fzf_git_status
  elif [[ $action == "stash" ]]; then
    # stash
    echo "TODO: stash"
  fi
}
# ------------------------------------------------------------------------------
alias gitBranches='_fzf_git_branches'
alias gitStatus='_fzf_git_status'
