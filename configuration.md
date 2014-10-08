# 設定

![設定](images/configuration.png)

Flaskの設定ファイルはとても単純です。
*config.py*に幾つかの変数を定義するだけで全てが動作します。
しかし本番環境の設定を管理する必要が出てくると、徐々に複雑になってきま
す。
APIキーを秘密にしたり、開発環境と本番環境で異なる設定を行う必要があるか
もしれません。
この章では設定を簡単に管理するFlaskの機能を紹介します。

## 単純な場合
単純なアプリケーションの場合はこれから説明する機能は必要ありません。
*app.py*や*yourapp/\_\_init\_\_.py*からレポジトリ直下に配置した
*config.py*を読み込むだけで良いでしょう。

*config.py*ファイルには1行に1つの変数定義を行うと良いでしょう。
アプリケーションが初期化されると、*config.py*内の変数はFlaskの設定に利
用され`app.config`という辞書でアクセスできます。

例えば、`app.config["DEBUG"]` というようにアクセスします。

~~~ {language="Python"}
DEBUG = True # Flaskのデバッグ機能を有効にする
BCRYPT_LEVEL = 12 # Flask-Bcrypt拡張の設定
MAIL_FROM_EMAIL = "robert@example.com" # メールアドレスの設定
~~~

設定値はFlaskやFlask拡張、またはアプリケーションによって利用されます。
上記の例で`app.config["MAIL_FROM_EMAIL"]`はパスワードリセットメールなど
を送信する際のFromアドレスです。
この様な設定値は後から簡単に変更することが可能です。

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
    主にFlask-BcryptといったFlask拡張で利用されます。これはインスタンス
    フォルダ内で定義し、バージョン管理システムから除外すべきです。
    インスタンスフォルダについては次の節で説明します。
    
    *推奨値:* 複雑なランダム値を設定すべきです。

BCRYPT\_LEVEL
:   Flask-Bcryptを利用してユーザーのパスワードをハッシュ化する際、
    パスワードにハッシュアルゴリズムを適用する**回数**を指定する必要が
    あります。
    Flask-Bcryptを利用していない場合、利用することを検討した方が良いで
    しょう。
    パスワードのハッシュ化を複数回行うことで、攻撃者がパスワードを推測
    するのが困難になります。
    ハッシュ化の回数を増やすことで更に攻撃に必要な計算時間を増やすこと
    が可能です。
    
    *推奨値:* この本では後ほどFlaskアプリケーションでBcryptを利用する際の優れた用例を紹介します。

**警告**

本番環境では`DEBUG = False`に設定されている事を確認してください。
これが設定されていると、外部から任意のPythonコードを実行可能です。

## インスタンスフォルダ

Sometimes you'll need to define configuration variables that contain
sensitive information. We'll want to separate these variables from those
in *config.py* and keep them out of the repository. You may be hiding
secrets like database passwords and API keys, or defining variables
specific to a given machine. To make this easy, Flask gives us a feature
called **instance folders**. The instance folder is a sub-directory of
the repository root and contains a configuration file specifically for
this instance of the application. We don't want to commit it into
version control.

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

To load configuration variables from an instance folder, we use
`app.config.from_pyfile()`. If we set `instance_relative_config=True`
when we create our app with the `Flask()` call,
`app.config.from_pyfile()` will load the specified file from the
*instance/* directory.

    # app.py or app/__init__.py

    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object('config')
    app.config.from_pyfile('config.py')

Now, we can define variables in *instance/config.py* just like you did
in *config.py*. You should also add the instance folder to your version
control system's ignore list. To do this with Git, you would add
`instance/` on a new line in *.gitignore*.

### Secret keys

The private nature of the instance folder makes it a great candidate for
defining keys that you don't want exposed in version control. These may
include your app's secret key or third-party API keys. This is
especially important if your application is open source, or might be at
some point in the future. We usually want other users and contributors
to use their own keys.

    # instance/config.py

    SECRET_KEY = 'Sm9obiBTY2hyb20ga2lja3MgYXNz'
    STRIPE_API_KEY = 'SmFjb2IgS2FwbGFuLU1vc3MgaXMgYSBoZXJv'
    SQLALCHEMY_DATABASE_URI= \
    "postgresql://user:TWljaGHFgiBCYXJ0b3N6a2lld2ljeiEh@localhost/databasename"

### Minor environment-based configuration

If the difference between your production and development environments
are pretty minor, you may want to use your instance folder to handle the
configuration changes. Variables defined in the *instance/config.py*
file can override the value in *config.py*. You just need to make the
call to `app.config.from_pyfile()` after `app.config.from_object()`. One
way to take advantage of this is to change the way your app is
configured on different machines.

    # config.py

    DEBUG = False
    SQLALCHEMY_ECHO = False


    # instance/config.py
    DEBUG = True
    SQLALCHEMY_ECHO = True

In production, we would leave the variables in Listing\~ out of
*instance/-config.py* and it would fall back to the values defined in
*config.py*.

> **note**
>
> -   Read more about Flask-SQLAlchemy's [configuration
>     keys](http://pythonhosted.org/Flask-SQLAlchemy/config.html#configuration-keys)

Configuring based on environment variables
------------------------------------------

The instance folder shouldn't be in version control. This means that you
won't be able to track changes to your instance configurations. That
might not be a problem with one or two variables, but if you have finely
tuned configurations for various environments (production, staging,
development, etc.) you don't want to risk losing that.

Flask gives us the ability to choose a configuration file on load based
on the value of an environment variable. This means that we can have
several configuration files in our repository and always load the right
one. Once we have several configuration files, we can move them to their
own `config` directory.

    requirements.txt
    run.py
    config/
      __init__.py # Empty, just here to tell Python that it's a package.
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

In this listing we have a few different configuration files.

  ---------------- -------------------------------------------------------
  config/default.p Default values, to be used for all environments or
  y                overridden by individual environments. An example might
                   be setting DEBUG = False in config/default.py and DEBUG
                   = True in config/development.py.

  config/developme Values to be used during development. Here you might
  nt.py            specify the URI of a database sitting on localhost.

  config/productio Values to be used in production. Here you might specify
  n.py             the URI for your database server, as opposed to the
                   localhost database URI used for development.

  config/staging.p Depending on your deployment process, you may have a
  y                staging step where you test changes to your application
                   on a server that simulates a production environment.
                   You'll probably use a different database, and you may
                   want to alter other configuration values for staging
                   applications.
  ---------------- -------------------------------------------------------

To decide which configuration file to load, we'll call
`app.config.from_envvar()`.

    # yourapp/__init__.py

    app = Flask(__name__, instance_relative_config=True)

    # Load the default configuration
    app.config.from_object('config.default')

    # Load the configuration from the instance folder
    app.config.from_pyfile('config.py')

    # Load the file specified by the APP_CONFIG_FILE environment variable
    # Variables defined here will override those in the default configuration
    app.config.from_envvar('APP_CONFIG_FILE')

The value of the environment variable should be the absolute path to a
configuration file.

How we set this environment variable depends on the platform in which
we're running the app. If we're running on a regular Linux server, we
can set up a shell script that sets our environment variables and runs
*run.py*.

    # start.sh

    APP_CONFIG_FILE=/var/www/yourapp/config/production.py
    python run.py

*start.sh* is unique to each environment, so it should be left out of
version control. On Heroku, we'll want to set the environment variables
with the Heroku tools. The same idea applies to other PaaS platforms.

Summary
-------

-   A simple app may only need one configuration file: *config.py*.
-   Instance folders can help us hide secret configuration values.
-   Instance folders can be used to alter an application's configuration
    for a specific environment.
-   We should use environment variables and `app.config.from_envvar()`
    for more complicated environment-based configurations.

