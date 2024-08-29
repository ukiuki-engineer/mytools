# fzf_git
fzfによるgit操作ツール(自分用)

## Demo
- `gitBranches`

https://github.com/ukiuki-engineer/mytools/assets/101523180/2d447763-b416-4d83-8fa1-4d6ba83c3d41

- `gitStatus`

https://github.com/ukiuki-engineer/mytools/assets/101523180/90278963-0475-4f87-9f40-943e313f2abe

## Requirements
- [fzf](https://github.com/junegunn/fzf)

```sh
# apt
sudo apt update && sudo apt -y install fzf
# homebrew
brew update && brew install fzf
# git clone
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

- [bat](https://github.com/sharkdp/bat)

```sh
# apt
sudo apt update && sudo apt -y install bat
# homebrew
brew update && brew install bat
```

## Installation
シェルの設定ファイル(.bashrcや.zshrc)中でこのscriptを`source`するだけ。

```sh
source (path to this script)
```

## Usage
以下のコマンドが使用可能。
- `gitBranches`
→オプション: `git branch`のオプションの内、以下が使用可能
    - `-a`: すべてのブランチを表示
    - `-r`: リモートブランチのみ表示
- `gitStatus`
- `gitLogs`
- `gitStashList`

## Inspired By
- [fzf-git.sh](https://github.com/junegunn/fzf-git.sh)
- [fzf-preview.vim](https://github.com/yuki-yano/fzf-preview.vim)

## TODO

- [ ] 各関数に引数のコメントを書いておく
