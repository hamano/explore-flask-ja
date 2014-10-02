# 環境

![環境](images/environment.png)

あなたのアプリケーションは、恐らく多くのソフトウェアに依存することにな
るでしょう。
少なくともFlaskパッケージに依存していない場合、あなたは誤った本を読んで
いる可能性があります。
アプリケーションの*環境*とは、それを実行するのに必要となるファイルの事
です。
幸運なことに、環境を構築するための簡単な方法がいくつかあります。

## virtualenvで環境を管理する

virtualenvはアプリケーションを分離された**仮想環境**で動作させるための
ツールです。
仮想環境とはアプリケーションが依存するソフトウェアを格納したディレクト
リの事です。
また、仮想環境内では環境変数が変更されます。
virtualenvではパッケージをシステムディレクトリ、またはユーザーディレク
トリに配置するのではなく、アプリケーション専用の分離されたディレクトリ
に配置します。
これにより、プロジェクト毎に利用するPythonバイナリ、依存ライブラリを簡
単に切り替えることができるようになります。

また、virtualenvはプロジェクト毎に異なるバージョンのパッケージのを使い
分ける事ができます。
あなたが古いシステムで動作するプロジェクトを抱えている場合はこの特徴は
重要です。

一般的にvirtualenvを利用するときには、少なくとも一つのPythonパッケージ
がシステムグローバル環境にインストールされていると思います。
これも一つのvirtualenv環境ですので、ここにpipを利用して`virtualenv`パッ
ケージをインストールすることが出来ます。

システムにvirtualenvパッケージがインストールされると、仮想環境を作成で
きるようになります。
プロジェクトディレクトリに移動し、`virtualenv`コマンドを実行して下さい。
引き数には作成する仮想環境の対象ディレクトリを指定します。
以下に実行例を示します。

~~~ {language=command}
$ virtualenv venv
New python executable in venv/bin/python
Installing Setuptools...........[...].....done.
Installing Pip..................[...].....done.
~~~

これで新しい仮想環境が作成されました。

新しい仮想環境を有効にする為には、仮想環境内に配置されている
*bin/activate* スクリプトを読み込む必要があります。

~~~ {language=command}
$ which python
/usr/local/bin/python
$ source venv/bin/activate
(venv)$ which python
/Users/robert/Code/myapp/venv/bin/python
~~~~

*bin/activate*スクリプトはシェル環境変数を変更することで、グローバル環
 境の代わりに新しい仮想環境を指し示すようになります。
スクリプトを読み込むと、上記のような結果が得られると思います。
仮想環境を有効化すると、`python`コマンドが仮想環境内のバイナリを参照す
るようになります。
ここでpipコマンドを利用すると、システムグローバルではなく仮想環境内に依
存パッケージがインストールされます。

シェルプロンプトも変更されている事に気がついたでしょうか。
virtualenvはシェルプロンプトに現在有効になっている仮想環境の名前を表示
します。
`deactivate`コマンドを実行することで仮想環境を無効化できます。

~~~ {language=command}
(venv)$ deactivate
$
~~~

### virtualenvwrapper

[virtualenvwrapper](http://virtualenvwrapper.readthedocs.org/en/latest/)
はvirtualenv環境を管理するためのパッケージです。
ツールについて言及する為にvirtualenvの基礎について説明しましたが、
virtualenvをそのまま利用するよりも、こちらを推奨します。

仮想環境をプロジェクトディレクトリに作成すると、ソースコードレポジトリがごっちゃになってしまう事があります。
仮想環境のディレクトリは有効にする際に必要なものなのでバージョン管理の必要はありません。
そこで、virtualenvwrapperの出番です。
このパッケージは仮想環境を特定のディレクトリ(通常は ~/.virtualenvs/)で
管理します。

**警告**
virtualenvwrapperをインストールする前に全ての仮想環境を無効化してください。

`virtualenv`コマンドの代わりに`mkvirtualenv`コマンドを実行して環境を作
成します。

~~~ {language=command}
$ mkvirtualenv rocket
New python executable in rocket/bin/python
Installing setuptools...........[...].....done.
Installing pip..................[...].....done.
(rocket)$
~~~~

`mkvirtualenv`コマンドは特定の仮想環境フォルダ(~/.virtualenvs/)に環境を
作成し、有効化します。
先ほどの`virtualenv`と同様に、`python`や`pip`コマンドは仮想環境内のコマ
ンドに切り替わります。
仮想環境を有効化するには、`workon [環境名]`を実行します。
無効化するには先ほどと同様に`deactivate`コマンドを実行します。

### 依存関係を維持する
プロジェクトが大きくなるにつれて、依存関係も増えていることを経験したこ
とがあるでしょう。
Flaskアプリケーションを実行するために数十個の依存ライブラリが必要になる
ことも珍しくありません。
これらの依存関係を管理する最も単純な方法はテキストファイルに記述するこ
とです。
pipはインストール済みのパッケージをテキストファイルで出力できます。
新しい環境にこれらのパッケージをインストールする際には、このテキストファ
イルを読み込むだけで済みます。

#### pip freeze
*requirements.txt*はFlaskアプリケーションの実行に必要な全てのパッケージ
 が記述されているテキストファイルです。
以下に、このファイルの生成方法と、新しい環境テキストファイルから依存パッ
ケージをインストールする例を示します。

~~~ {language=command}
(rocket)$ pip freeze > requirements.txt

$ workon fresh-env
(fresh-env)$ pip install -r requirements.txt
[...]
Successfully installed flask Werkzeug Jinja2 itsdangerous markupsafe
Cleaning up...
(fresh-env)$
~~~

### Manually tracking dependencies

As your project grows, you may find that certain packages listed by
`pip freeze` aren't actually needed to run the application. You'll have
packages that are installed for development only. `pip freeze` doesn't
discriminate between the two, it just lists the packages that are
currently installed. As a result, you may want to manually track your
dependencies as you add them. You can separate those packages needed to
run your application and those needed to develop your application into
*require\_run.txt* and *require\_dev.txt* respectively.

## バージョン管理

Pick a version control system and use it. I recommend Git. From what
I've seen, Git is the most popular choice for new projects these days.
Being able to delete code without worrying about making an irreversible
mistake is invaluable. You'll be able to keep your project free of those
massive blocks of commented out code, because you can delete it now and
revert that change later should the need arise. Plus, you'll have backup
copies of your entire project on GitHub, Bitbucket or your own Gitolite
server.

### What to keep out of version control

I usually keep a file out of version control for one of two reasons.
Either it's clutter, or it's a secret. Compiled *.pyc* files and virtual
environments --- if you're not using virtualenvwrapper for some reason
--- are examples of clutter. They don't need to be in version control
because they can be recreated from the *.py* files and your
*requirements.txt* files respectively.

API keys, application secret keys and database credentials are examples
of secrets. They shouldn't be in version control because their exposure
would be a massive breach of security.

> **note**
>
> When making security related decisions, I always like to assume that
> my repository will become public at some point. This means keeping
> secrets out and never assuming that a security hole won't be found
> because, "Who's going to guess that they can do that?" This kind of
> assumption is known as security by obscurity and it's a bad policy to
> rely on.

When using Git, you can create a special file called *.gitignore* in
your repository. In it, list wildcard patterns to match against
filenames. Any filename that matches one of the patterns will be ignored
by Git. I recommend using the *.gitignore* shown in Listing\~ to get you
started.

    *.pyc
    instance/

Instance folders are used to make secret configuration variables
available to your application in a more secure way. We'll talk more
about them later.

> **note**
>
> You can read more about *.gitignore* here:
> <http://git-scm.com/docs/gitignore>

## デバッグ

### デバッグモード
Flaskはデバッグモードと呼ばれる機能を持っています。
開発環境で`debug = True`と設定するとデバッグモードが有効になります。
デバッグモードではコードの変更を検知して自動的に再読み込みを行い、エラー
が発生した場合はスタックトレースを出力し、インタラクティブコンソールを
利用できます。

**警告**

本番環境でデバッグモードを有効にしないよう注意して下さい。
インタラクティブコンソールは任意のコードを実行できるため、本番環境では重大なセキュリティホールとなってしまいます。

### Flask-DebugToolbar
[Flask-DebugToolbar](http://flask-debugtoolbar.readthedocs.org/en/latest/)
は、アプリケーションの問題をデバッグするためのもうひとつのツールです。
デバッグモードでこれを利用すると、アプリケーションにサイドバーが設置さ
れます。
サイドバーにはSQLクエリやログ、バージョン、テンプレート、設定などその他
愉快な情報が表示され、問題を追跡し易くなります。

**注記**

- 詳しくはこちらのクイックスタートを読んでください。
  <http://flask.pocoo.org/docs/quickstart/#debug-mode>
- こちらに他のデバッガを利用したエラー処理とロギングについての情報があります。
  <http://flask.pocoo.org/docs/errorhandling>

## まとめ
- アプリケーションの依存関係を維持するためにvirtualenvを利用して下さい。
- 仮想環境を維持するためにvirtualenvwrapperを利用して下さい。
- 依存関係はテキストファイルで管理して下さい。
- バージョン管理システムはGitを推奨します。
- バージョン管理システムから秘密のファイルを除外するために.gitignoreを利用して下さい。
- デバッグモードで問題解決に必要な情報を得ることが出来ます。
- Flask-DebugToolbar拡張はもっと詳細な情報を得ることが出来ます。

