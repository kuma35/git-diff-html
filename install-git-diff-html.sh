#!/usr/bin/env bash
# install-git-diff-html.sh --- release git-diff-html.sh / diff-html-template.html
# from this repo checkout (development copy) into their runtime locations.
#
# JP: 開発はこのリポジトリで行い、リリース(インストール)のたびに
# このスクリプトを実行して以下へコピーする。
#   git-diff-html.sh        -> ~/bin/git-diff-html
#   diff-html-template.html -> ~/share/diff-html/diff-html-template.html
#   git-diff-html.1          -> ~/share/man/man1/git-diff-html.1
#   git-diff-html.ja.1       -> ~/share/man/ja/man1/git-diff-html.1
#
# ~/bin が $PATH に入っていれば、以後 `git-diff-html ...` あるいは
# git のサブコマンドとして `git diff-html ...` として使える。
# man ページを入れておくと、git 自身が `git diff-html --help` を
# 横取りして `man git-diff-html` を試みた時にも内容を表示できる
# (`~/share/man` が MANPATH に含まれている前提)。日本語版は man-db の
# 言語別ディレクトリ (`<mandir>/ja/man1/`) に置くことで、$LANG が
# 日本語ロケールの時だけ自動的にこちらが選ばれる(それ以外は英語版)。

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

src_script="$script_dir/git-diff-html.sh"
src_template="$script_dir/diff-html-template.html"
src_man_en="$script_dir/git-diff-html.1"
src_man_ja="$script_dir/git-diff-html.ja.1"

dest_bin="$HOME/bin"
dest_script="$dest_bin/git-diff-html"

dest_share="$HOME/share/diff-html"
dest_template="$dest_share/diff-html-template.html"

dest_man_en_dir="$HOME/share/man/man1"
dest_man_en="$dest_man_en_dir/git-diff-html.1"

dest_man_ja_dir="$HOME/share/man/ja/man1"
dest_man_ja="$dest_man_ja_dir/git-diff-html.1"

for f in "$src_script" "$src_template" "$src_man_en" "$src_man_ja"; do
  if [ ! -f "$f" ]; then
    echo "Error: $f not found." >&2
    exit 1
  fi
done

mkdir -p "$dest_bin" "$dest_share" "$dest_man_en_dir" "$dest_man_ja_dir"

install -m 0755 "$src_script" "$dest_script"
install -m 0644 "$src_template" "$dest_template"
install -m 0644 "$src_man_en" "$dest_man_en"
install -m 0644 "$src_man_ja" "$dest_man_ja"

echo "install-git-diff-html: installed"
echo "  $dest_script"
echo "  $dest_template"
echo "  $dest_man_en"
echo "  $dest_man_ja"
