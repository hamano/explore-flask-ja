# ビューとルーティングの高度なパターン

![ビューとルーティングの高度なパターン](images/views.png)

## ビューデコレーター
デコレーターとは関数を他の関数に変換するPythonの機能です。
デコレートされた関数を呼び出すと、替りにデコレーターが呼び出されます。
デコレーターでは何らかの処理を行ったり、引き数を変更、処理の中断、元々の関数を実行したりすることができます。
Flaskではビューをラップして何らかのコードを実行するためにデコレーターを利用します。

~~~ {language="Python"}
@decorator_function
def decorated():
    pass
~~~

これまでのチュートリアルを読んでいる方はこの構文に見覚えがあるでしょう。
Flaskアプリケーションでは`@app.route`というデコレーターを利用してURLに対応するビュー関数を呼び出します。

それではFlaskアプリケーションで利用できるその他のデコレーターを見て行きましょう。

### 認証
Flask-Login拡張を利用することで認証システムを簡単に実装することができます。
さらに、Flask-Loginはユーザー認証機能を提供するだけでなく、認証済みのユーザーのみアクセスを許可する`@login_required`デコレーターを利用できます。

~~~ {language="Python"}
# app.py

from flask import render_template
from flask.ext.login import login_required, current_user

@app.route('/')
def index():
    return render_template("index.html")

@app.route('/dashboard')
@login_required
def account():
    return render_template("account.html")
~~~

**警告**

`@app.route`デコレーターは最も外側に記述しなければなりません。

上記のコードでは認証済みのユーザーのみ*/dashboard*にアクセス可能です。
Flask-Loginの設定次第では未認証のユーザーをログインページへリダイレクトしたり、HTTP 401を返したり好きなようにできます。

**注記**
Flask-Loginについてはこちらの公式サイトを参照して下さい。

<http://flask-login.readthedocs.org/en/latest/>

### キャッシュ
ちょっと想像してみて下さい。
あなたのアプリケーションがCNNやその他のニュースサイトで紹介されたとすると、1秒間に数千リクエストものアクセスが殺到します。
このアプリケーションはリクエスト毎にデーターベースアクセスを行うので非常に遅くなります。
どの様にすれば訪問者を逃さないようにこのサイトを高速化できるでしょうか?

これには多くの解決方法がありますが、ここではキャッシュを利用してこの問題を解決します。
具体的には[Flask-Cache](http://pythonhosted.org/Flask-Cache/)拡張を利用します。
この拡張は特定のビューの応答を一定時間キャッシュするデコレーターを提供します。

Flask-Cacheは異なるキャッシュバックエンドを利用するように設定可能です。
人気があるキャッシュサーバーは[Redis](http://redis.io/)でしょう。
Redisは簡単にセットアップして利用することができます。
既にFlask-Cacheの設定が完了しているとして、どの様にデコレーターを使用するかを以下に示します。

~~~ {language="Python"}
# app.py

from flask.ext.cache import Cache
from flask import Flask

app = Flask()

# 以下の呼び出してキャッシュの設定も行います。
cache = Cache(app)

@app.route('/')
@cache.cached(timeout=60)
def index():
    [...] # ここで何回かのデーターベースアクセスが発生します。
    return render_template(
        'index.html',
        latest_posts=latest_posts,
        recent_users=recent_users,
        recent_photos=recent_photos
    )
~~~

これにより、この関数は60秒に1度キャッシュの有効期限が切れた時しか実行されません。
応答はキャッシュに保存され、有効期限内はキャッシュが利用されます。


**注記**

Flask-Cacheは関数呼び出しの結果をキャッシュするメモ化機能も提供します。
これにより、計算コストの大きいJinja2テンプレートのレンダリング結果をキャッシュすることができます。

### カスタムデコレーター

この節では、毎月ユーザーに課金するアプリケーションを実装してみましょう。
ユーザーアカウントの有効期限が切れていれば支払いを行うページにリダイレクトする必要があります。

~~~ {language="Python" numbers=left}
# myapp/util.py

from functools import wraps
from datetime import datetime

from flask import flash, redirect, url_for

from flask.ext.login import current_user

def check_expired(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if datetime.utcnow() > current_user.account_expires:
            flash("Your account has expired. Update your billing info.")
            return redirect(url_for('account_billing'))
        return func(*args, **kwargs)

    return decorated_function
~~~

10行目
:   `@check_expired`でデコレートされた関数が呼び出されると、まずこの`check_expired()`が呼び出されます。

11行目
:   `@wraps`は`decorated_function()`関数に対するデコレーターです。
    より自然な書き方で元の関数を呼び出せるようになります。

12行目
:   `decorated_function`は元のビュー関数に渡された引数やキーワード引数を全て受け取ります。
    そしてユーザーアカウントの有効期限をチェックし、有効期限が切れていたらメッセージを出力して支払いページヘリダイレクトします。

16行目
:   やるべきことは終わったので元々のビュー関数`func()`を呼び出します。

複数のデコレーターが指定された場合、最も上に記述したデコレーターが最初に呼び出され、次の行のデコレーターが呼ばれます。
デコーレーター構文はちょっとしたシンタックスシュガーです。

~~~ {language="Python"}
# デコレーターを利用したコード:
@foo
@bar
def one():
    pass

r1 = one()

# これは上記のコードと同じです
def two():
    pass

two = foo(bar(two))
r2 = two()

r1 == r2 # True
~~~

以下はFlask-Login拡張の`@login_required`デコレーターとカスタムデコレーターを利用するサンプルコードです。
この様に複数のデコレーターを重ねることができます。

~~~ {language="Python"}
# myapp/views.py

from flask import render_template

from flask.ext.login import login_required

from . import app
from .util import check_expired

@app.route('/use_app')
@login_required
@check_expired
def use_app():
    """有料コンテンツ"""
    # [...]
    return render_template('use_app.html')

@app.route('/account/billing')
@login_required
def account_billing():
    """支払い情報の更新。"""
    # [...]
    return render_template('account/billing.html')
~~~

ユーザーが*/use\_app*にアクセスすると、まず`check_expired()`でチェックを行い有効期限内であればビューを表示します。

**注記**

`wraps()`についての詳細はこちらを参照して下さい。

<http://docs.python.org/2/library/functools.html#functools.wraps>

## URL変換規則

### 組み込み変換規則

FlaskのURLルーティングの定義では、URLの一部をPythonの変数に変換してビュー関数に渡すことができます。

~~~ {language="Python"}
@app.route('/user/<username>')
def profile(username):
    pass
~~~

`<username>`と名前が付けられたURLの一部はビュー関数の引き数として渡されます。
また、ビューに渡される前に変換規則を指定することができます。

~~~ {language="Python"}
@app.route('/user/id/<int:user_id>')
def profile(user_id):
    pass
~~~

上記のコードでは、
*http://myapp.com/user/id/Q29kZUxlc3NvbiEh* というURLは404 Not Foundを返します。
整数であることを期待したURLの一部が実際には文字列だったからです。
文字列を受け入れる2つ目のビューを持つことも可能です。

以下の表はFlaskの組み込みURL変換規則です。

  --------- --------------------------------------------------
  string    スラッシュを除く全ての文字列を受け入れます(デフォルト)
  int       整数を受け入れます。
  float     浮動少数を受け入れます。
  path      スラッシュを含めた文字列を受け取ります。
  --------- --------------------------------------------------

### カスタム変換規則

必要に応じてカスタム変換規則を作ることも可能です。
有名なリンク共有サイトRedditでは特定のテーマのコミュニティを作成することができます。
例えば、*reddit.com/r/python* や *reddit.com/r/flask* という様にURLパスにコミュニティ名を含みます。
Redditの面白い機能として、URL中の+記号を区切り文字として複数カテゴリの投稿を表示することができます。
例えば、*reddit.com/r/python+flask* という様なURLです。

この様な機能はカスタムデコレーターを利用して実装することができます。
それでは+記号で区切られた複数の要素を受け取る変換規則のための`ListConverter`クラスを作成してみましょう。

~~~ {language="Python"}
# myapp/util.py

from werkzeug.routing import BaseConverter

class ListConverter(BaseConverter):

    def to_python(self, value):
        return value.split('+')

    def to_url(self, values):
        return '+'.join(BaseConverter.to_url(value)
                        for value in values)
~~~

ここでは2つのメソッド`to_python()`と`to_url()`を定義しています。
名前から想像できる通り、`to_python()`はURLパスからPythonオブジェクトに変換する際に呼ばれます。
`to_url()`は`url_for()`によって引き数から適切なURLを作成する際に呼ばれます。

この`ListConverter`を利用するには、Flaskにこの変換規則を登録する必要があります。

~~~ {language="Python"}
# /myapp/__init__.py

from flask import Flask

app = Flask(__name__)

from .util import ListConverter

app.url_map.converters['list'] = ListConverter
~~~

**警告**

もしも`util`モジュールの中に`from . import app`という行があった場合、インポート処理がループする問題が発生する可能性があります。
ここでは、`ListConverter`をインポートする前にappを初期化することでこれを避けています。

これで`ListConverter`変換規則が登録されました。
`@app.route()`に"list"と指定することで変換規則を利用できます。

~~~ {language="Python"}
# myapp/views.py

from . import app

@app.route('/r/<list:subreddits>')
def subreddit_home(subreddits):
    """受け取った全てのカテゴリの投稿を表示します。"""
    posts = []
    for subreddit in subreddits:
        posts.extend(subreddit.posts)

    return render_template('/r/index.html', posts=posts)
~~~

これでRedditのマルチredditシステムの様に動作するはずです。
この様にしてURL変換規則を自由に作ることが可能です。

## まとめ

- Flask-Login拡張の`@login_required`デコレーターはビューに対してユーザー認証を要求することができます。
- Flask-Cache拡張は様々なキャッシュ機能を持ったデコレーターを提供します。
- カスタムビューデコレーターを開発することでDRYを避け、可読性の高いコードを書くことができます。
- カスタムURL変換規則は独創的なURLルーティング処理を実装できます。

