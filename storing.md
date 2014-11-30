# データの格納

![データの格納](images/storing.png)

大抵のFlaskアプリケーションは特定のタイミングでデータの格納を行う必要があるでしょう。
データの格納方法には多くの方法があります。
ここでの最適な方法は格納するデータの種類に依存します。
リレーショナルデータを保存したい場合は、リレーショナルデータベースに格納するのが良いでしょう。
その他のデータであればMongoDBの様なNoSQLが適しているかもしれません。

私はあなたのアプリケーションでどの様なデータベースエンジンを選択するかを指定するつもりはありません。
NoSQLが唯一の選択肢だという人もいれば、NoSQLもリレーショナルデータベースも同じだという人もいるかもしれません。
私がここで言えることは、あなたが迷っているのであればMySQLやPostgreSQLなどのリレーショナルデータベースを選択することが無難であるという事です。

そしてリレーショナルデータベースを利用する際はSQLAlchemyを活用すると良いでしょう。

## SQLAlchemy

SQLAlchemyはORM(オブジェクト・リレーション・マッパー)のひとつです。
これはデータベースに対して実行されるSQLクエリーを生成する抽象レイヤーです。
SQLAlchemyは多くの種類のデータベースエンジンに対応した一貫性のあるAPIを提供します。
例えばMySQLやPostgreSQL、SQLiteに対応しています。
これによりデータの移行やデータベースエンジンの変更、スキーマの変更を行い易くなります。

FlaskでSQLAlchemyをもっと簡単に扱うための素晴らしいFlask拡張があります。
これはFlask-SQLAlchemyと呼ばれています。
Flask-SQLAlchemyは既定で妥当な値が設定されています。
これはセッション管理も行ってくれますのでセッションをクリーンナップするコードをアプリケーションで実装する必要はありません。

それではコードを読んでいきましょう。
幾つかのモデルの定義とSQLAlchemyの設定を行ってみましょう。
まずデータベースの定義を*myapp/init.py*に記述し、モデルの定義を*myapp/models.py*に記述します。

~~~ {language="Python"}
# ourapp/__init__.py

from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__, instance_relative_config=True)

app.config.from_object('config')
app.config.from_pyfile('config.py')

db = SQLAlchemy(app)
~~~

まず、Flaskアプリケーションの初期化と設定を行い、続いてSQLAlchemyデータベースハンドラの初期化を行います。
データベースの設定をinstanceフォルダに配置しますのでアプリケーションの初期化時に`instance_relative_config`オプションを指定し、`app.config.from_pyfile`を呼び出して設定を読み込みます。
そしてモデルを定義します。

~~~ {language="Python"}
# ourapp/models.py

from . import db

class Engine(db.Model):

    # Columns

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    title = db.Column(db.String(128))

    thrust = db.Column(db.Integer, default=0)
~~~

`Column`, `Integer`, `String`, `Model`などのクラスはFlask-SQLAlchemyのdbオブジェクトを通じて利用出来ます。
ここでは宇宙船のエンジンの状態を表すモデルを定義した。
エンジンはIDと名前、推進力レベルを持ちます。

あと幾つかデータベースに関する設定を行う必要があります。
機密情報を含む設定をバージョン管理システムから除外する為に、インスタンスフォルダー内の*instance/config.py*に設定を記述します。

~~~ {language="Python"}
# instance/config.py

SQLALCHEMY_DATABASE_URI = "postgresql://user:password@localhost/spaceshipDB"
~~~

**注記**
データベースURIは、データベースを何処でホストしているかにより異なります。
詳しくは[SQLAlchemyのドキュメント](http://docs.sqlalchemy.org/en/latest/core/engines.html?highlight=database#database-urls)を参照してください。

### データベースの初期化

これでデータベースの設定が完了し、モデルが定義されました。
続いてデータベースの初期化を行うことが出来ます。
具体的にはモデルの定義からデータベーススキーマを作成します。

通常これは肩のこる作業だと思いますが、幸運な事にSQLAlchemyにはこれらを全てやってくれるクールなコマンドがあります。

レポジトリの配下でPythonインタプリタを起動してみましょう。

~~~
$ pwd
/Users/me/Code/myapp
$ workon myapp
(myapp)$ python
Python 2.7.5 (default, Aug 25 2013, 00:04:04) 
[GCC 4.2.1 Compatible Apple LLVM 5.0 (clang-500.0.68)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> from myapp import db
>>> db.create_all()
>>>
~~~

SQLAlchemyよありがとう。これで指定した設定に基づいてデータベーステーブルが作成されました。

### Alembicによるデータ移行

データベーススキーマは石の類ではありません。
例えばテーブルに`last_fired`という行を追加したくなるかもしれません。
まだ何もデータが入ってなければ、単純に`db.create_all()`を実行する事も出来ます。
しかしながら運用を開始して6ヶ月後、テーブルにデータが存在する状態でデータを1から作り直したくないはずです。
ここで移行ツールの出番です。

AlembicはSQLAlchemy向けに作られたデータベース移行ツールです。
これは、データベーススキーマをバージョン管理する事で新しいスキーマにアップグレードしたり、古いスキーマにダウングレードすることが出来ます。

Alembicのチュートリアルは膨大ですので、簡単に使い方の概要と、幾つかの注意点をお伝えします。

まず、`alembic init`コマンドを実行してalembicの移行環境を作成します。
レポジトリの直下でこれを行うと、*alembic*というディレクトリが作成されます。
レポジトリのディレクトリ構成は以下のようになっているはずです。

~~~
ourapp/
    alembic.ini
    alembic/
        env.py
        README
        script.py.mako
        versions/
            3512b954651e_add_account.py
            2b1ae634e5cd_add_order_id.py
            3adcc9a56557_rename_username_field.py
    myapp/
        __init__.py
        views.py
        models.py
        templates/
    run.py
    config.py
    requirements.txt
~~~

この*alembic/*ディレクトリにはデータの移行に利用するスクリプトが含まれています。
そして*alembic.ini*はalembicの設定ファイルです。

**注記**

*.gitignore*に*alembic.ini*を追記してください!
このファイルにはデータベースの接続情報が含まれていますのでバージョン管理を行いたくないはずです。

一方*alembic/*ディレクトリのバージョン管理は行いたいはずです。
このディレクトリに機密情報は含まれていませんので、バージョン管理を行うことでバックアップを持つという効果があります。

スキーマの変更を行うには幾つかのステップが必要です。
まず`alembic revision`コマンドを実行して移行スクリプトを生成してください。
続いて、*myapp/alembic/versions/*以下に生成されたPythonスクリプトを開いて`upgrade`関数と`downgrade`関数を実装します。
この関数では、Alembicの`op`オブジェクトを利用します。

移行スクリプトの準備が出来たら`alembic upgrade head`コマンドを実行します。
これでデータを最新バージョンに移行できます。

**注記**

Alembicの設定や移行スクリプトの詳細は[Alembicのチュートリアル](http://alembic.readthedocs.org/en/latest/tutorial.html)を参照してください。

**警告**

定期的なデータのバックアップを忘れないください。
バックアップの詳細についてはこの本の範囲外となりますが、データーベースは安全かつ確実な方法でバックアップする必要があります。

**注記**

FlaskでNoSQLを扱う方法はあまり確立されていませんが、データベースにアクセスするPythonライブラリさえあれば利用できるはずです。
こちらの[Flask extension registry](http://flask.pocoo.org/extensions/)にNoSQLデーターベースを扱う為のFlask拡張がいくつかあります。

## まとめ

- リレーショナルデータベースを扱う際はSQLAlchemyを使ってください。
- FlaskではFlask-SQLAlchemy拡張を利用してください。
- Alembicはスキーマを変更してデータの移行を行う際に役立ちます。
- FlaskではNoSQLデータベースを利用できますが、扱い方は具体的な実装により様々です。
- データのバックアップを行ってください。

