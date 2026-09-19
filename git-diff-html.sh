#!/usr/bin/env bash
# git-diff-html.sh --- compare a revision's html file against the working
# copy in a browser (A/B/Diff panes), as a git subcommand.
#
# JP: git と bash(と base64/xdg-open)だけで動く git のサブコマンド。
# 開発はこのリポジトリで行い、リリース時に git-diff-html (拡張子無し)
# として ~/bin に、テンプレートは diff-html-template.html として
# ~/share/diff-html/ に、man ページは ~/share/man/ にそれぞれコピーして
# 使う(install-git-diff-html.sh 参照)。
#
# もともとは git-docs-ja (翻訳プロジェクト) 内の Emacs コマンド
# magit-last-html-diff.el 用に作った html diff ビューアを、Emacs/magit
# 非依存のスクリプトとして切り出したのが始まり。git-docs-ja とは独立
# して使えるツールなので、このリポジトリに分離した。
#
# Usage: git-diff-html [<revision>] [--] <path>
#        git-diff-html --cleanup | -C
#   REVISION       比較対象のリビジョン(省略時 HEAD)。working copy
#                  (作業コピー)ともう一方を比較する。
#   PATH           git の pathspec と同様、現在のディレクトリからの
#                  相対パス(サブディレクトリで実行してもよい)。
#   --cleanup, -C  生成した一時ファイル(/tmp/git-diff-html-*.html)を
#                  まとめて削除する。このスクリプトはセッション状態を
#                  持たないため、見つかったものを全部消す(セッション
#                  限定の追跡はしない)。

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: git-diff-html [<revision>] [--] <path>
       git-diff-html --cleanup | -C

Render <revision>'s version of <path> (default revision: HEAD) and the
working copy's version side by side, plus a word-level diff, and open it
in a browser. <path> is resolved like any git pathspec (relative to the
current directory). Display only.

--cleanup (or -C) removes every generated temporary file
(${TMPDIR:-/tmp}/git-diff-html-*.html) instead of comparing anything.
EOF
}

if [ "${1-}" = "--cleanup" ] || [ "${1-}" = "-C" ]; then
  if [ $# -ne 1 ]; then
    usage
    exit 1
  fi
  shopt -s nullglob
  files=("${TMPDIR:-/tmp}"/git-diff-html-*.html)
  shopt -u nullglob
  if [ ${#files[@]} -gt 0 ]; then
    rm -f -- "${files[@]}"
    echo "git-diff-html --cleanup: removed ${#files[@]} file(s)"
  fi
  exit 0
fi

revision=HEAD
path=

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
  usage
  exit 0
else
  # git-idiomatic form: [REVISION] [--] PATH
  case $# in
    1)
      path=$1
      ;;
    2)
      if [ "$1" = "--" ]; then
        path=$2
      else
        revision=$1
        path=$2
      fi
      ;;
    3)
      if [ "$2" = "--" ]; then
        revision=$1
        path=$3
      else
        usage
        exit 1
      fi
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository." >&2
  exit 1
}
# git のサブコマンドとして呼ばれた時は GIT_PREFIX (呼び出し時のカレント
# ディレクトリのリポジトリルートからの相対パス) が渡ってくる。単体で
# 実行した場合は `git rev-parse --show-prefix` で同じものを取得する。
prefix=${GIT_PREFIX:-$(git rev-parse --show-prefix 2>/dev/null || true)}
path="${prefix}${path}"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
template_candidates=(
  "$script_dir/diff-html-template.html"
  "$HOME/share/diff-html/diff-html-template.html"
)
template=""
for candidate in "${template_candidates[@]}"; do
  if [ -f "$candidate" ]; then
    template=$candidate
    break
  fi
done
if [ -z "$template" ]; then
  echo "Error: template not found (looked in: ${template_candidates[*]})" >&2
  exit 1
fi

cd "$repo_root"

if ! git cat-file -e "$revision:$path" 2>/dev/null; then
  echo "\"$path\" not found at $revision.  The file does not exist, or you may be running this in a different git repository.  Please check that you are running the command from the correct folder." >&2
  exit 1
fi
if [ ! -f "$path" ]; then
  echo "\"$path\" not found in the working tree.  The file does not exist, or you may be running this in a different git repository.  Please check that you are running the command from the correct folder." >&2
  exit 1
fi

old_b64=$(git show "$revision:$path" | base64 -w0)
new_b64=$(base64 -w0 "$path")
title="Diff: $(basename "$path")"

# 表示用のリビジョン名。フルの40/64桁ハッシュならその略称にし、
# それ以外(HEAD, HEAD~1, ブランチ名など)はそのまま表示する。
if [[ "$revision" =~ ^[0-9a-f]{40}$ || "$revision" =~ ^[0-9a-f]{64}$ ]]; then
  revision_label=$(git rev-parse --short "$revision")
else
  revision_label=$revision
fi

page=$(cat "$template")
page=${page//__TITLE__/$title}
page=${page//__PATH_LABEL__/$path ($revision_label)}
page=${page//__REVISION_LABEL__/$revision_label}
page=${page//__OLD_B64__/$old_b64}
page=${page//__NEW_B64__/$new_b64}

outfile=$(mktemp "${TMPDIR:-/tmp}/git-diff-html-XXXXXX.html")
printf '%s' "$page" > "$outfile"

xdg-open "$outfile" >/dev/null 2>&1 &
disown

echo "git-diff-html: opened $path ($revision vs working copy) in the web browser" >&2
echo "$outfile"
