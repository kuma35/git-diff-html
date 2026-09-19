# CLAUDE.md

## プロジェクトの目的

git のリポジトリ内にある html ファイルについて、指定したリビジョン(省略時 HEAD)時点の
内容と、作業コピー(ワーキングツリー)の内容を、Web ブラウザ上で並べてレンダリング表示し、
さらに語句単位の diff(挿入=緑・削除=赤でハイライト)も表示する git のサブコマンド
(`git diff-html`)。表示専用で、生成したページから編集はできない。

もともとは `git-docs-ja`(git 本体ドキュメントの日本語翻訳プロジェクト)で、翻訳した
info/html の「今回どこを訳したか」をレビューしやすくするために作った Emacs コマンド
`magit-last-html-diff`(さらにその前段の Claude Artifact 版「Diff Triptych」)から、
Emacs/magit に依存しない git サブコマンドとして切り出したもの。git-docs-ja とは独立に
使えるツールなので、このリポジトリに分離した。

## 構成

- `git-diff-html.sh` — 本体(bash スクリプト)。開発用ソース。
- `diff-html-template.html` — 3ペイン(A/B/Diff)表示用の html/CSS/JS 一式。
  Myers 差分アルゴリズム(html タグ/空白/CJK1文字/英数語単位でトークン化)による
  語句単位ハイライトと、ペイン間の同期スクロール(scroll-all-mode 風、%ベース)を含む。
- `git-diff-html.1` / `git-diff-html.ja.1` — man ページ(英語/日本語)。
- `install-git-diff-html.sh` — リリース(インストール)スクリプト。

## リリース(インストール)方法

開発はこのリポジトリで行い、`./install-git-diff-html.sh` を実行すると以下へコピーされる。

```
git-diff-html.sh        -> ~/bin/git-diff-html
diff-html-template.html -> ~/share/diff-html/diff-html-template.html
git-diff-html.1          -> ~/share/man/man1/git-diff-html.1
git-diff-html.ja.1       -> ~/share/man/ja/man1/git-diff-html.1
```

`~/bin` が `$PATH` に入っていれば、`git-diff-html ...` または git のサブコマンドとして
`git diff-html ...` で使える。`~/share/man` が `MANPATH` に含まれていれば
`git diff-html --help` / `man git-diff-html` で man ページが表示される
(man-db の言語別ディレクトリ機能により `$LANG` が日本語ロケールなら自動的に日本語版)。

## 使い方

```
git diff-html [<revision>] [--] <path>
git diff-html --cleanup | -C
```

- `<revision>` 省略時は `HEAD`。フルの40/64桁ハッシュを指定した場合は表示上
  `git rev-parse --short` で略称化される。
- `<path>` は通常の git の pathspec と同様、現在のディレクトリからの相対パス
  (サブディレクトリで実行してもよい。`GIT_PREFIX`/`git rev-parse --show-prefix` で解決)。
- `--cleanup`(`-C`)は比較を行わず、生成済みの一時ファイル
  (`${TMPDIR:-/tmp}/git-diff-html-*.html`)をすべて削除する。対象が無ければ無出力。
  このスクリプトはセッション状態を持たないため、見つかったものを全部消す方式。

詳細は `man git-diff-html`(または `git-diff-html.1` / `.ja.1`)を参照。

## 実施記録

以下は `git-docs-ja` リポジトリの `Documentation-po/elisp/SPEC.md` に記録されていた
"git diff-html" 節を、このリポジトリへの分離にあたって移送したもの。今後の作業記録は
このファイルに追記していく。

- **2026/09/20**
  - 指示: 「@Documentation-po/elisp/SPEC.md を読んで git diff-html の minimum success」
  - 回答: `magit-last-html-diff` と同じ 3ペイン(A/B/Diff)html を、magit/Emacs を使わず git + bash だけで生成する `git-diff-html` を作成。テンプレートは `magit-last-html-diff-template.html` を共用(単一ソース、当時)。リビジョンは `-r REVISION` オプションで指定可能(省略時 HEAD)。PATH は git リポジトリのトップレベルからの相対パス。出力は `xdg-open` でブラウザに開く。対象が REVISION または working tree に無い場合は他コマンドと同様の英語エラーメッセージを stderr に出して exit 1。
  - 作業: `git-diff-html`(実行可能な bash スクリプト)を新規作成。`bash -n` で構文確認、実機で (a) デフォルト HEAD、(b) `-r HEAD~1` 指定、(c) 存在しないファイル指定時のエラー、(d) 引数無し時の usage、をそれぞれ確認。生成 html の base64 埋め込みデータをデコードし、実際の翻訳差分(英→日)が正しく入っていること、`hide-a-toggle` 等のテンプレート要素も含まれることを確認。将来 `git のサブコマンド化`しやすいよう、ファイル名は `git-` プレフィックス付きの実行可能スクリプトにしてある。
- **2026/09/20**
  - 指示: 「これをgitのサブコマンドにするばあい、bash, python, Cのどれが望ましいですか?」→「bashのままで進めて。templateの名前をdiff-html-template.htmlにして、配置場所は私のgitは`~/bin`なので、`~/share/diff-html/`が望ましいかな?」
  - 回答: bash を推奨(既に動く実装があり、書き直し不要)。テンプレートの共用方針について確認したところ「(Emacs版とは)別々に保つ」、リポジトリ側の扱いについて確認したところ「`git-diff-html.sh` として残し、開発主体はリポジトリ、リリース毎に `~/bin`/`~/share/diff-html` にセットする」との回答。
  - 作業: `git-diff-html` を `git-diff-html.sh` に改名(開発用ソース)。Emacs 版のテンプレートとは独立に `diff-html-template.html` を用意。`git-diff-html.sh` のテンプレート探索を「まず script と同じディレクトリの `diff-html-template.html`、無ければ `~/share/diff-html/diff-html-template.html`」の2段構えに変更。リリース作業を自動化する `install-git-diff-html.sh` を新規作成。実機で install 実行→`~/bin`経由(PATH解決)での `git-diff-html` 実行→生成htmlの検証、まで確認。
- **2026/09/20**
  - 指示: 「実行したところ、`$ git diff-html HEAD -- new-command.html` と `Usage: git-diff-html [-r REVISION] PATH` と怒られました。」
  - 回答: 2つ不具合があった。(1) 引数解析が `-r REVISION PATH` 専用で、`git diff`/`git log` などおなじみの `REVISION -- PATH` 形式(`--` 区切り)に対応していなかった。(2) `git diff-html` は git サブコマンドとして呼ばれるため、PATH は本来 git の pathspec と同様「現在のディレクトリからの相対パス」として解釈されるべきだが、リポジトリのトップレベル相対パス固定になっていた(サブディレクトリで bare なファイル名を指定すると見つからない別の不具合)。
  - 作業: 引数解析を `[<revision>] [--] <path>` 形式(`--`ありなし両対応)に変更しつつ、旧 `-r <revision> <path>` 形式も後方互換で残した(後日削除、下記参照)。パス解決は `GIT_PREFIX`(git サブコマンド経由時に渡る)または `git rev-parse --show-prefix`(単体実行時)でカレントディレクトリのリポジトリルートからの相対位置を取得し、PATH の前に付加するよう修正。実機で (a) `git diff-html HEAD -- <path>` 形式、(b) サブディレクトリから bare ファイル名を指定するケース、(c) `--` 無し `REVISION PATH` 形式、(d) PATH のみ、(e) legacy `-r` 形式、をすべて確認。
- **2026/09/20**
  - 指示: 「template の Aペインの文言が HEAD 固定になっているので指定リビジョン(または省略形)を表示して」→「また、Hide HEAD(A) の文言も修正」
  - 回答: `diff-html-template.html` に `__REVISION_LABEL__` プレースホルダを追加し、Aペインのラベル・iframe title・「Hide HEAD (A)」トグルの3箇所を差し替え。フルの40/64桁ハッシュ指定時は `git rev-parse --short` で略称化し、それ以外(HEAD, HEAD~1, ブランチ名等)はそのまま表示する `revision_label` を計算して埋め込む。ヘッダーの `__PATH_LABEL__` 表示も同じ略称に統一。
  - 作業: `diff-html-template.html` と `git-diff-html.sh` を修正、再インストール。実機で HEAD/HEAD~1/フルハッシュ指定の3パターンを確認。
- **2026/09/20**
  - 指示: 「cleanupオプションは `git diff-html --cleanup` と指定します。」→「`git diff-html --cleanup`、`git diff-html -C` が動くようにするのがbash版で大変なら、`git diff-html-cleanup` コマンド追加してもいいです。」
  - 回答: このスクリプトはセッション状態を持たないため、`--cleanup`/`-C` は `${TMPDIR:-/tmp}/git-diff-html-*.html` に一致するものを全部削除する方式にした。bash での実装は難しくなかったので、別コマンド化はせず `--cleanup`/`-C` の2エイリアスとして実装。
  - 作業: `--cleanup`/`-C` を追加(`nullglob` でファイルが1つも無い場合も安全に処理)。usage 内の `${TMPDIR:-/tmp}` がシングルクォート heredoc で展開されていなかった表示上の不具合も修正。
- **2026/09/20**
  - 指示: 「`git-diff-html -r <revision> <path>` 形式の指定は削除して。使い方からも削除。また既に cleanup 済みの場合は何もメッセージを出さない(`no files to remove` をエラーメッセージと勘違いしていました)」
  - 回答: 了承。legacy `-r` 形式のコード分岐と usage 記載を削除。cleanup 対象が0件の場合は何も出力せず exit 0 にする(削除した時だけ件数を表示)よう変更。
  - 作業: `-r` 分岐を削除、`--cleanup`/`-C` の「0件時メッセージ」を削除。実機で (a) `-r` 指定が usage エラーになること、(b) 対象0件の cleanup が無出力であること、(c) 通常の比較動作、(d) 対象ありの cleanup、をそれぞれ確認。
- **2026/09/20**
  - 指示: 「git の流儀では `--help` でも usage 出すので、そのように追加して。」
  - 回答: 調査の結果、`git <サブコマンド> --help` は git 自身が `--help` を横取りして `man git-<サブコマンド>` を試みる仕様(`-h` はスクリプトまで届くが `--help` は届かない)と判明。スクリプト側にはコードを足さず、man ページ(`git-diff-html.1`)を用意して `~/share/man/man1/` に配置する方針にした。
  - 作業: `git-diff-html.1` を新規作成(NAME/SYNOPSIS/DESCRIPTION/OPTIONS/EXAMPLES/SEE ALSO)。`install-git-diff-html.sh` に man ページのインストールを追加。実機で `man git-diff-html`、および `git diff-html --help`(パイプ経由・非対話)がともに man ページ内容を正しく表示し exit 0 になることを確認。
- **2026/09/20**
  - 指示: 「man は英語のままがいいでしょうか? 日本語版も欲しいのですがどうすればいいですか? a.日本語版に差し替える、b.両方用意ししてインストール時に選ぶ(デフォルトは日本語版)、c.その他(あなたの提案)」→「1」(提案した「man-db のロケール別ディレクトリ機能を使い、`$LANG` に応じて自動選択」案で進めることを承認)
  - 回答: man-db は `<mandir>/<lang>/man<section>/` という言語別ディレクトリを見て `$LANG` に応じて自動選択する仕組みを持つ。英語版は `~/share/man/man1/`、日本語版は `~/share/man/ja/man1/` に置けば、選択の手間や実行時オプション無しで自動的に正しい言語が出る。
  - 作業: `git-diff-html.ja.1`(日本語訳man)を新規作成。`install-git-diff-html.sh` を両言語インストール対応に変更。実機で `$LANG=ja_JP.UTF-8`(日本語版)と `LANG=C`(英語版フォールバック)を確認。日本語部分で troff の "cannot adjust line" 警告(右揃えできないだけの表示上無害な既知の問題)が1箇所残るが、実際の表示内容は正しく完全なので許容。
- **2026/09/20**
  - 指示: 「git-diff-html を独立させて `~/work/git-diff-html` に移せ。@Documentation-po/elisp/SPEC.md より git-diff-html 関連を @~/work/git-diff-html/CLAUDE.md にコピーして続行。関連ファイルもコピー。install スクリプトコピー後修正(必要あれば)。@~/work/git-docs-ja/ の方に別プロジェクトに移行した旨コミット」
  - 回答: `git-docs-ja` (翻訳プロジェクト) から独立した専用リポジトリ `~/work/git-diff-html` を新設し、本体一式を移送。`git-docs-ja` 固有のパス参照(`Documentation-po/` 等)やコメントを、独立リポジトリとして正しい内容に修正。
  - 作業: `git-diff-html.sh` / `diff-html-template.html` / `git-diff-html.1` / `git-diff-html.ja.1` / `install-git-diff-html.sh` を `~/work/git-diff-html/` にコピーし、冒頭コメントの `git-docs-ja` 固有パス参照を修正(機能面の変更は無し、`script_dir` からの相対探索なのでコピー先が変わっても動作は不変)。実機で新しい場所からの `install-git-diff-html.sh` 実行→`git diff-html` の通常比較・`--cleanup`・`--help`(man)動作、をすべて再確認。`git-docs-ja` 側では移行元ファイルを削除し、移行した旨をコミット(別途記録)。
