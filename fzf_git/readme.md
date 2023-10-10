# fzf_git
fzfによるgit操作ツール。

## Demo
TODO: 後で貼る。

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
- `gitStatus`
→まだ実装中。

## Inspired By
- [fzf-git.sh](https://github.com/junegunn/fzf-git.sh)
- [fzf-preview.vim](https://github.com/yuki-yano/fzf-preview.vim)

## TODO
- [ ] stage-all, unstage-allを選択肢に入れる
- [ ] 
- [ ] 
