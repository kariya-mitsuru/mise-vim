# mise-vim

Vim を [vim/vim](https://github.com/vim/vim) のソースからビルドする mise の tool plugin（vfox 形式の Lua）です。

## インストール

```sh
mise plugins install vim https://github.com/kariya-mitsuru/mise-vim
# 開発中はローカルにリンク
mise plugins link vim ./mise-vim
```

> [!NOTE]
> mise の registry にも `vim` が登録されているので（`conda:vim`、`asdf:mise-plugins/mise-vim`）、
> 以前に `vim` を registry 経由で入れていると、`installs/vim/.mise.backend.toml` が残っていて
> そちらが優先されます。その場合は古い vim をアンインストールしてから使ってください。

## 使い方

```toml
[tools]
vim = "latest"

# オプションを指定する場合
vim = { version = "9.2", features = "huge", configure_options = "--with-compiledby=mise --enable-python3interp=dynamic" }
```

リリースタグ以外のブランチ・タグ・コミットは `ref:` を付けて指定できます（GitHub のソースアーカイブからビルド）。

```sh
mise install vim@ref:master
mise install vim@ref:<commit sha>
```

`ref:master` は1つのバージョンとして扱われ、master が進んでも自動では更新されません。最新にするには `mise install -f vim@ref:master` で入れ直してください。

| オプション | 既定値 | 内容 | asdf-vim での対応 |
| --- | --- | --- | --- |
| `features` | `huge` | `--with-features=`（`tiny` / `normal` / `huge`） | `ASDF_VIM_TYPE` |
| `configure_options` | 下記 | configure に渡す引数（指定すると既定値は置き換わる） | `ASDF_VIM_CONFIG` |
| `gui` | なし | `--enable-gui=`。`configure_options` 内の指定より優先（`auto` `no` `gtk2` `gnome2` `gtk3` `gtk4` `motif` `haiku` `photon` `carbon`） | `ASDF_VIM_GUI` |
| `jobs` | `nproc` | `make -j` の並列数 | `ASDF_CONCURRENCY` |

`configure_options` の既定値は mise-plugins/mise-vim（asdf）と同じです（`--with-compiledby` だけ `mise` に変更）:

```
--with-tlib=ncurses --with-compiledby=mise --enable-multibyte --enable-cscope
--enable-terminal --enable-perlinterp --enable-rubyinterp --enable-python3interp
--enable-luainterp --enable-gui=no --without-x
```

開発パッケージが見つからないインタプリタは、エラーにならずに組み込みなしでビルドされます。

`CFLAGS` などの環境変数は mise の `install_env` で渡せます。

## リリース日（minimum_release_age）

mise の `minimum_release_age`（既定 24h）のため、直近のタグについては GitHub の tags Atom フィードからリリース日を取得しています。
取得する範囲は既定で直近3日分です。mise は日付のないバージョンを cutoff で隠さないので、
`minimum_release_age` を3日より長くしている場合は、同じ長さ以上を環境変数で指定してください。

```sh
export MISE_VIM_DATE_WINDOW_DAYS=7
```

範囲を広げるほど、`mise ls-remote vim` が遅くなります（フィード1ページで10タグ、GitHub 側でキャッシュされていないページは1ページ2秒ほどかかります）。

## 依存パッケージ

C コンパイラ（`cc`）、`make`、`tar`、ncurses の開発パッケージ（pkg-config の `ncursesw`）が必要です。
これらは `metadata.lua` の `systemDependencies` に宣言してあり、インストール前に mise が確認します。
足りない場合の動作（警告だけにするか、自動でインストールするか）は mise の `system_deps` 設定で決まります。

perl / python3 / ruby / lua の開発パッケージは optional として宣言してあります。
足りない場合はインストール時に1行表示されるだけで、ビルドは続行されます。
