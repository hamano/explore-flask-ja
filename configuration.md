# 設定

![設定](images/configuration.png)

Flaskの設定ファイルはとても単純です。
*config.py*に幾つかの変数を定義するだけで全てが動作します。
しかし本番環境の設定を管理する必要が出てくると、徐々に複雑になってきます。
APIキーを秘密にしたり、開発環境と本番環境で異なる設定を行う必要があるかもしれません。
この章では設定を簡単に管理するFlaskの機能を紹介します。

## 単純な場合
単純なアプリケーションの場合はこれから説明する機能は必要ありません。
*app.py*や*yourapp/\_\_init\_\_.py*からレポジトリ直下に配置した*config.py*を読み込むだけで良いでしょう。

*config.py*ファイルには1行に1つの変数定義を行うと良いでしょう。
アプリケーションが初期化されると、*config.py*内の変数はFlaskの設定に利用され`app.config`という辞書オブジェクトでアクセスできます。

例えば、`app.config["DEBUG"]` というようにアクセスします。

~~~ {language="Python"}
DEBUG = True # Flaskのデバッグ機能を有効にする
BCRYPT_LEVEL = 12 # Flask-Bcrypt拡張の設定
MAIL_FROM_EMAIL = "robert@example.com" # メールアドレスの設定
~~~

設定値はFlaskやFlask拡張、またはアプリケーションによって利用されます。
上記の例で`app.config["MAIL_FROM_EMAIL"]`はパスワードリセットメールなどを送信する際のFromアドレスです。
これらの設定値は後から簡単に変更することが可能です。

~~~ {language="Python"}
# app.py もしくは app/__init__.py 内で
from flask import Flask

app = Flask(__name__)
app.config.from_object('config')

# これ以降、app.config["変数名"]で設定値にアクセスできます。
~~~

DEBUG
:   エラーをデバッグするための便利なツールを提供します。これにはWEBベースのスタックトレース表示とインタラクティブなPythonコンソールが付属しています。
    
    *推奨値:* 開発環境では`True`を設定し、本番環境では`False`を設定すべきです。

SECRET\_KEY
:   これはFlaskがクッキーに署名するための秘密鍵です。
    主にFlask-BcryptといったFlask拡張で利用されます。
    これはインスタンスフォルダ内で定義し、バージョン管理システムから除外すべきです。
    インスタンスフォルダについては次の節で説明します。
    
    *推奨値:* 複雑なランダム値を設定すべきです。

BCRYPT\_LEVEL
:   Flask-Bcryptを利用してユーザーのパスワードをハッシュ化する際、パスワードにハッシュアルゴリズムを適用する**回数**を指定する必要があります。
    Flask-Bcryptを利用していない場合、利用を検討した方が良いでしょう。
    パスワードのハッシュ化を複数回行うことで、攻撃者がパスワードを推測するのが困難になります。
    ハッシュ化の回数を増やすことで更に攻撃に必要な計算時間を増やすことが可能です。
    
    *推奨値:* この本では後ほどFlaskアプリケーションでBcryptを利用する際の推奨例を紹介します。

**警告**

本番環境では`DEBUG = False`に設定されていることを確認してください。
これが設定されていると、外部から任意のPythonコードを実行可能です。

## インスタンスフォルダ
設定値には機密情報を含むことがあります。
これらの設定値は*config.py*から分離し、バージョン管理から除外したいと思うでしょう。
データーベースのパスワードやAPIキーに加え、特定の実行マシンに関する設定値も除外したいはずです。
この様なことを簡単にするために、Flaskには**インスタンスフォルダ**という機能が提供されています。
インスタンスフォルダはレポジトリの直下に配置されるサブフォルダであり、特定のアプリケーションのインスタンスに関する設定が格納されます。
このインスタンスフォルダはバージョン管理から除外します。

~~~
config.py
requirements.txt
run.py
instance/
  config.py
yourapp/
  __init__.py
  models.py
  views.py
  templates/
  static/
~~~

### インスタンスフォルダの利用
インスタンスフォルダ内の設定値を読み込むには`app.config.from_pyfile()`を利用します。
アプリケーションを作成する`Flask()`の呼び出し時に`instance_relative_config=True`を指定すると、`app.config.from_pyfile()`は*instance/*ディレクトリからの相対的なファイル名を指定できます。

~~~ {language="Python"}
# app.py もしくは app/__init__.py

app = Flask(__name__, instance_relative_config=True)
app.config.from_object('config')
app.config.from_pyfile('config.py')
~~~

*instance/config.py*には*config.py*と同じように設定値を定義することができます。
また、インスタンスフォルダはバージョン管理システムから除外する必要があります。
Gitを利用している場合、*.gitignore*に`instance/`を追記します。

### 秘密鍵
インスタンスフォルダはバージョン管理から除外したい設定値を格納するのに最適です。
これにはアプリケーションの秘密鍵やサードパーティのAPIキーを含むことができます。
これはアプリケーションがオープンソース・ソフトウェアである場合や将来的にソースコードを公開しようと考えている場合は特に重要です。
一般的に、その他のユーザーや開発者は自身の鍵を利用するはずです。

~~~ {language="Python"}
# instance/config.py

SECRET_KEY = 'Sm9obiBTY2hyb20ga2lja3MgYXNz'
STRIPE_API_KEY = 'SmFjb2IgS2FwbGFuLU1vc3MgaXMgYSBoZXJv'
SQLALCHEMY_DATABASE_URI= \
"postgresql://user:TWljaGHFgiBCYXJ0b3N6a2lld2ljeiEh@localhost/databasename"
~~~

### 環境ごとの設定
本番環境や開発環境の違いが軽微であればインスタンスフォルダを利用して設定を切り替えても良いでしょう。
*instance/config.py*に定義された設定値は*config.py*の設定値を上書きすることができます。
これを行うには`app.config.from_object()`を呼び出した後に`app.config.from_pyfile()`を呼び出すだけです。
これはアプリケーションを異なるマシンで動作させる際に役立ちます。

~~~ {language="Python"}
# config.py

DEBUG = False
SQLALCHEMY_ECHO = False
~~~

~~~ {language="Python"}
# instance/config.py

DEBUG = True
SQLALCHEMY_ECHO = True
~~~

本番環境では*instance/config.py*は除外され、*config.py*のみが有効になります。

**注記**

- Flask-SQLAlchemyについてはこちらを参照して下さい。
  [configuration keys](http://pythonhosted.org/Flask-SQLAlchemy/config.html#configuration-keys)

## 環境変数を利用した設定の切り替え
インスタンスフォルダはバージョン管理されることがあってはなりません。
これはインスタンスフォルダに対する変更を追跡できないことを意味しています。
環境が1か2つであればそれほど問題にはなりませんが、本番環境、ステージング環境、開発環境など、多くの環境の設定ファイルを持っている場合これらのファイルを失ってしまうリスクがあります。

Flaskは環境変数の値に基づいて読み込む設定ファイルを切り替える機能を持っています。
これはレポジトリ下にある複数の設定ファイルの中から適切な設定ファイルを選択して読み込む機能です。
例えば`config`ディレクトリに複数の設定ファイルを配置することができます。

~~~
requirements.txt
run.py
config/
  __init__.py # パッケージを意味するただの空ファイルです。
  default.py
  production.py
  development.py
  staging.py
instance/
  config.py
yourapp/
  __init__.py
  models.py
  views.py
  static/
  templates/
~~~

ここでは以下の設定ファイルが登場します。

config/default.py
:   固有の環境設定で上書きされる前のデフォルトの設定値です。
    例えばこの*config/default.py*で`DEBUG = False`を設定し、*config/development.py*で`DEBUG = True`と設定すると良いでしょう。

config/development.py
:   これは開発時に利用する設定ファイルです。
    データーベースの接続URIをlocalhostに設定したりすることができます。

config/production.py
:   これは本番環境で利用されるファイルです。
    開発時とは異なるデーターベースURIを指定することができます。

config/staging.py
:   開発プロセスに依っては、アプリケーションのテストを行うための本番環境をシミュレートするステージング段階を用意している場合もあるでしょう。
    ここでも同様に異なるデーターベースを利用したり、ステージング用の設定を利用することができます。

`app.config.from_envvar()`を呼び出して、どの設定ファイルを読み込むかを決定します。

~~~ {language="Python"}
# yourapp/__init__.py

app = Flask(__name__, instance_relative_config=True)

# デフォルト設定の読み込み
app.config.from_object('config.default')

# インスタンスフォルダからの設定の読み込み
app.config.from_pyfile('config.py')

# APP_CONFIG_FILE環境変数で指定されたファイルを読み込みます。
# この設定でデフォルトの設定値を上書きします。
app.config.from_envvar('APP_CONFIG_FILE')
~~~

環境変数の値は設定ファイルへの絶対パスでなければなりません。

この環境変数を設定する方法はアプリケーションを実行するプラットフォームに依存します。
一般的なLinuxサーバーで実行している場合、シェルスクリプトで環境変数を設定し*run.py*.を実行することができます。

~~~ {language="sh"}
# start.sh

APP_CONFIG_FILE=/var/www/yourapp/config/production.py
python run.py
~~~

*start.sh*は環境固有のスクリプトですのでバージョン管理からは除外すべきでしょう。
Herokuで動作させる場合、Herokuのツールを利用して環境変数を設定することができます。
他のPaaSプラットフォームでも同様のことが可能です。

## まとめ
- 単純なアプリケーションであれば単一の設定ファイル *config.py* のみで良いでしょう。
- インスタンスフォルダは秘密の設定値を隠すのに役立ちます。
- インスタンスフォルダは環境に応じてアプリケーションの設定を切り替える際にも役立ちます。
- より複雑な環境で設定を切り替えたい場合、環境変数と`app.config.from_envvar()`を利用すると良いでしょう。


