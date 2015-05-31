# ユーザー処理のパターン

![ユーザー処理のパターン](images/users.png)

ユーザー処理は現代のWEBアプリケーションに共通して必要な機能です。
ユーザーアカウントを持つアプリケーションはユーザーの登録やメール確認、パスワードの強度の確認、パスワードリセット、認証処理など非常に多くの機能が必要です。
ユーザー処理には多くのセキュリティ上の問題が付きまといますので、この件に関しては標準的なパターンに従うことを強く推奨します。

**注記**

この章ではユーザーの入力処理を行う際にWTFormsとSQLAlchemyのモデル利用していることを前提としています。
もしこれらを利用していない場合は必要に応じて読み替えてください。

## メール確認

新規ユーザーがメールアドレスを入力した場合、一般的にはこのメールアドレスの正当性を確認したいはずです。
この確認を行うことで私達は安心してパスワードのリセットメールやその他の重要なメールを配信できるようになります。

メールアドレスを確認する一般的な方法は、パスワードをリセットするユニークなURLを含むリンクを送信し、そのURLにアクセスさせて確認する方法です。
例えば、`john@example.com`というメールアドレスでサインアップが行われたとします。
そうするとまずデーターベースの`email_confirmed`というカラムを`False`に設定して確認メールを送信します。
このメールにはユニークなトークンを含んだURLが記載されています。
例えばこの様なURLです:

*<http://myapp.com/accounts/confirm-/Q2hhZCBDYXRsZXR0IHJvY2tzIG15IHNvY2tz>*

Johnがこのメールを受け取りクリックすると、アプリケーションはトークンをチェックしてJohnの`email_confirmed`カラムを`True`に設定します。

どの様にしてトークンの確認を行うのでしょうか?
一つの方法はトークンをデーターベースに格納してこれと照合する方法です。
これは負荷が高いですし、今回の場合不必要です。

ここではメールアドレスをエンコードしてトークンを生成する方法を利用します。
このトークンにタイムスタンプを含めることで有効期限を設定することも可能です。
これを行うために`itsdangerous`パッケージを利用します。
このパッケージは信頼されていない環境に対して重要なデータを送信するためのツールを提供します。
今回はこの`itsdangerous`パッケージの`URLSafeTimedSerializer`クラスを利用します。

~~~ {language="Python"}
# ourapp/util/security.py

from itsdangerous import URLSafeTimedSerializer

from .. import app

ts = URLSafeTimedSerializer(app.config["SECRET_KEY"])
~~~

このシリアライザーを利用してメールアドレスを確認するトークンを生成することができます。
ここではこの方法を用いて簡単なアカウント生成処理を実装していきます。

~~~ {language="Python"}
# ourapp/views.py

from flask import redirect, render_template, url_for

from . import app, db
from .forms import EmailPasswordForm
from .util import ts, send_email

@app.route('/accounts/create', methods=["GET", "POST"])
def create_account():
    form = EmailPasswordForm()
    if form.validate_on_submit():
        user = User(
            email = form.email.data,
            password = form.password.data
        )
        db.session.add(user)
        db.session.commit()

	# ここで確認メールを送信します。
        subject = "Confirm your email"

        token = ts.dumps(self.email, salt='email-confirm-key')

        confirm_url = url_for(
            'confirm_email',
            token=token,
            _external=True)

        html = render_template(
            'email/activate.html',
            confirm_url=confirm_url)

	# send_email は myapp/util.py で定義済みです。
        send_email(user.email, subject, html)

        return redirect(url_for("index"))

    return render_template("accounts/create.html", form=form)
~~~

ここで定義したビューはユーザーの作成処理を行い、登録したメールアドレスに確認メールを送信します。
メールの文章を生成する際にHTMLテンプレートを使用しています。

~~~ {language="HTML"}
{# ourapp/templates/email/activate.html #}

アカウントの作成に成功しました。<br>
アカウントを有効にするには以下のリンクをクリックしてメールアドレスを確
認してください。

<p>
<a href="{{ confirm_url }}">{{ confirm_url }}</a>
</p>

<p>
--<br>
なにか質問があればこちらまで hello@example.com
</p>
~~~

これでメールの送信処理は大丈夫ですね。
あとは確認メールのリンクにアクセスした時の処理を実装する必要があります。

~~~ {language="Python"}
# ourapp/views.py

@app.route('/confirm/<token>')
def confirm_email(token):
    try:
        email = ts.loads(token, salt="email-confirm-key", max_age=86400)
    except:
        abort(404)

    user = User.query.filter_by(email=email).first_or_404()

    user.email_confirmed = True

    db.session.add(user)
    db.session.commit()

    return redirect(url_for('signin'))
~~~

このビューはとても単純な構造をしています。
トークンが有効かどうかを確認するために`try ... except`文を記述しています。
トークンにはタイムスタンプが含まれているので、`max_age`より古いトークンだと`ts.loads()`は例外を投げます。
今回の場合、`max_age`に86400秒を設定していますのでトークンの有効期限は1日となります。

**注記**
メールアドレスの更新処理を実装する際にも似たような方法を利用できます。
古いアドレスと新しいアドレスを含むトークンを生成すると良いでしょう。
このトークンを検証した後に新しいアドレスへ変更します。

## 強力なパスワード

1つ目のルールはパスワードのハッシュアルゴリズムにBcryptを利用することです。
scryptでも構いませんがここではBcryptを利用します。
決してプレーンテキストのままパスワードを格納しないでください。
それはセキュリティ上の重大な問題であり、ユーザにとって不利益をもたらします。
実装が大変な処理は既にモジュール化されていますので、あとは最適な方法を利用するだけです。

**注記**

OWASPはWEBアプリケーションのセキュリティについてこの業界で最も信頼できる情報源の一つです。
[こちら](https://www.owasp.org/index.php/Secure_Coding_Cheat_Sheet#Password_Storage)で推奨されているセキュアコーディングを読んでおいてください。

ここではアプリケーションでbcryptを利用するためにFlask-Bcrypt拡張を利用します。
この拡張は`py-bcrypt`の単純なラッパーですがエンコーディングのチェックなど幾つかの面倒な処理をやってくれます。

~~~ {language="Python"}
# ourapp/__init__.py

from flask.ext.bcrypt import Bcrypt

bcrypt = Bcrypt(app)
~~~

Bcryptアルゴリズムを強く推奨した理由の一つは「未来に順応」するからです。
これは時代と共に計算能力がより安価になった場合でも、ブルートフォース攻撃を困難に出来ることを意味します。
パスワードをより多くの「ラウンド回数」で繰り返しハッシュすることにより、推測により時間が掛かるようになります。
例えばパスワードを格納する前に20回ハッシュした場合、攻撃者はパスワードを推測する度に20回のハッシュを行う必要があります。

あまり多くのラウンド数ハッシュを行うとアプリケーションがレスポンスを返すのに時間が掛かってしまうことに注意してください。
このラウンド数を決定する際には、セキュリティとユーザービリティのバランスが重要になります。
一定時時間に処理可能なラウンド数はアプリケーションが動作する計算リソースに依存します。
幾つかのラウンド数を試してみて、パスワードのハッシュ時間が0.25秒〜0.5秒に収まるようにすることをお勧めします。

以下のようなPythonスクリプトでパスワードのハッシュ時間を計測できます。

~~~ {language="Python"}
# benchmark.py

from flask.ext.bcrypt import generate_password_hash

# 実行時間が0.25秒〜0.5秒に収まるようにラウンド数を変更してください。
generate_password_hash('password1', 12)
~~~

UNIXの`time`コマンドで実行時間を計測できます。

~~~ {language="command"}
$ time python test.py

real    0m0.496s
user    0m0.464s
sys     0m0.024s
~~~

私達は非力なサーバーで計測したので12ラウンドが適当でした。
これを設定ファイルに記述します。

~~~ {language="Python"}
# config.py

BCRYPT_LOG_ROUNDS = 12
~~~

Flask-Bcryptの設定は完了しましたのでパスワードのハッシュ処理を実装しましょう。
サインアップフォームからの入力を受け取るビューでこの処理を行うことも出来ますが、パスワードリセットやパスワードの変更ビューでも同じことをやらなければなりません。
ですので、ハッシュ処理はもっと抽象レイヤで行うと良いでしょう。
ここではモデルにセッターを定義して、`user.password = 'password1'`を実行した時に自動的にパスワードがBcryptでハッシュされるようにします。

~~~ {language="Python"}
# ourapp/models.py

from sqlalchemy.ext.hybrid import hybrid_property

from . import bcrypt, db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username = db.Column(db.String(64), unique=True)
    _password = db.Column(db.String(128))

    @hybrid_property
    def password(self):
        return self._password

    @password.setter
    def _set_password(self, plaintext):
        self._password = bcrypt.generate_password_hash(plaintext)
~~~

ここではSQLAlchemyのhybrid拡張を利用しています。
`user.password`に対して代入を行うと新しく定義したセッターが呼び出されます。
このセッターの中で平文のパスワードをハッシュ化し、データーベースの`_password`カラムに格納しています。
hybridプロパティを利用しているので`user.password`プロパティにアクセスするとハッシュ化されたパスワードを取得できます。

それでは、このモデルを利用してサインアップビューを実装してみましょう。

~~~ {language="Python"}
# ourapp/views.py

from . import app, db
from .forms import EmailPasswordForm
from .models import User

@app.route('/signup', methods=["GET", "POST"])
def signup():
    form = EmailPasswordForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, password=form.password.data)
        db.session.add(user)
        db.session.commit()
        return redirect(url_for('index'))

    return render_template('signup.html', form=form)
~~~

## 認証

データーベースにユーザーが入りましたので認証処理を実装することが出来ます。
まずユーザーがユーザー名とパスワード(メールアドレスとパスワードかもしれません)を送信し、そのパスワードが正しいことを確認します。
全てのチェックが通ると、ブラウザにクッキーを設定して認証済みである印を付けます。
次回からアクセスはこのクッキーを参照することでログイン済みであることが解ります。

それではWTFormsで`UsernamePassword`というクラスを定義してみましょう。

~~~ {language="Python"}
# ourapp/forms.py

from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required

class UsernamePasswordForm(Form):
    username = TextField('Username', validators=[Required()])
    password = PasswordField('Password', validators=[Required()])
~~~

次に、ユーザーのモデルにハッシュ化されたパスワードと比較するメソッドを追加します。

~~~ {language="Python"}
# ourapp/models.py

from . import db

class User(db.Model):

    # [...] columns and properties

    def is_correct_password(self, plaintext)
        return bcrypt.check_password_hash(self._password, plaintext)
~~~

### Flask-Login

次の目標はサインインフォームからの入力を受け付けるビューを定義することです。
ユーザーが正しいパスワードを入力するとFlask-Login拡張が認証処理を行います。
この拡張は認証とセッションの処理を簡単にしてくれます。

Flask-Loginを使う準備としてちょっとした設定を行う必要があります。

*\_\_init\_\_.py*にFlask-Loginのオブジェクト`login_manager`を定義してください。

~~~ {language="Python"}
# ourapp/__init__.py

from flask.ext.login import LoginManager

# Create and configure app
# [...]

from .models import User

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view =  "signin"

@login_manager.user_loader
def load_user(userid):
    return User.query.filter(User.id==userid).first()
~~~

ここでは`LoginManager`クラスのインスタンスを生成し、初期化を行い、ログインビューの定義と、ユーザーオブジェクトの取得方法を記述しています。
これがFlask-Loginの基本的な構成です。


**注記**
Flask-Loginのカスタマイズ方法については[こちら](https://flask-login.readthedocs.org/en/latest/#customizing-the-login-process)を参照してください。

そして認証処理を行う`signin`ビューを定義します。

~~~ {language="Python"}
# ourapp/views.py

from flask import redirect, url_for

from flask.ext.login import login_user

from . import app
from .forms import UsernamePasswordForm()

@app.route('signin', methods=["GET", "POST"])
def signin():
    form = UsernamePasswordForm()

    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first_or_404()
        if user.is_correct_password(form.password.data):
            login_user(user)

            return redirect(url_for('index'))
        else:
            return redirect(url_for('signin'))
    return render_template('signin.html', form=form)
~~~

まずFlask-Loginの`login_user`関数をインポートし、パスワードをチェックした後でこの`login_user(user)`を呼び出します。
ログアウトの際には`logout_user()`を呼び出す必要があります。

~~~ {language="Python"}
# ourapp/views.py

from flask import redirect, url_for
from flask.ext.login import logout_user

from . import app

@app.route('/signout')
def signout():
    logout_user()

    return redirect(url_for('index'))
~~~

## パスワードのリカバリ

ここでは「パスワードを忘れた」時にメールを利用してアカウントを復旧させる機能を実装します。
このあたりの処理は認証されていないユーザーにアカウントを渡すことになるので脆弱性が生まれやすい所です。
ここではこれまでに紹介したメール確認のテクニックと同じ方法でパスワードリセットを実装します。


まずパスワードを忘れたユーザーがメールアドレスを入力するフォームが必要になります。
ここではユーザーのモデルにメールアドレスとパスワードを持っていると仮定します。
パスワードは前回実装した通りのハイブリッドプロパティです。

**警告**

有効性を確認していないメールアドレスにパスワードリセットメールを送信しないでください!
パスワードのリセットメールは確実にアカウントの所有者に送らなければなりません。

リカバリには2つのフォームが必要になります。
1つ目はリセットリンクを送信するメールアドレスを入力するフォームと、もうひとつはパスワードの変更を受け付けるフォームです。

~~~ {language="Python"}
# ourapp/forms.py

from flask.ext.wtforms import Form

from wtforms import TextField, PasswordField, Required, Email

class EmailForm(Form):
    email = TextField('Email', validators=[Required(), Email()])

class PasswordForm(Form):
    password = PasswordField('Email', validators=[Required()])
~~~

typoを避けるために新しいパスワードを2回入力させるアプリケーションが多いですが、ここでは1つのパスワードフィールドしか用意していません。
これを行うには単純にもうひとつ`PasswordField`を追加してWTFormsの`EqualTo`バリデーターを指定してください。

**注記**

サインアップフォームに関してはUX(ユーザーエクスペリエンス)のコミュニティで多くの興味深い議論が行われています。

個人的にStack ExchangeでのRoger Attrillが述べた考え方が好きです:
>
> 私達はパスワードを2回入力させるようなことはしません。
> パスワードのリカバリ機能が完璧に機能していれば、1度だけ入力させるだけで十分です。

- この話題についてはこちらを参照してください。

    [Stack ExchangeのUXスレッド](http://ux.stackexchange.com/questions/20953/why-should-we-ask-the-password-twice-during-registration/21141)

- ここにもサインアップやサインインに関しての素晴らしいアイディアがあります。

    [Smashing Magazineの記事](http://uxdesign.smashingmagazine.com/2011/05/05/innovative-techniques-to-simplify-signups-and-logins/)

それでは、まず初めに入力したメールアドレスにパスワードのリセットメールを送信するビューを実装してみましょう。

~~~ {language="Python"}
# ourapp/views.py

from flask import redirect, url_for, render_template

from . import app
from .forms import EmailForm
from .models import User
from .util import send_email, ts

@app.route('/reset', methods=["GET", "POST"])
def reset():
    form = EmailForm()
    if form.validate_on_submit()
        user = User.query.filter_by(email=form.email.data).first_or_404()

        subject = "Password reset requested"

        # Here we use the URLSafeTimedSerializer we created in `util` at the 
        # beginning of the chapter
        token = ts.dumps(self.email, salt='recover-key')

        recover_url = url_for(
            'reset_with_token',
            token=token,
            _external=True)

        html = render_template(
            'email/recover.html',
            recover_url=recover_url)

        # Let's assume that send_email was defined in myapp/util.py
        send_email(user.email, subject, html)

        return redirect(url_for('index'))
    return render_template('reset.html', form=form)
~~~

フォームに入力されたメールアドレスを受け取ると、データベースからユーザーオブジェクトを取得します。
その後リセットトークンを生成し、パスワードリセットURLを送信します。
続いて、リセットリンクに対応するビューに渡されたトークンを検証し、パスワードをリセットします。

~~~ {language="Python"}
# ourapp/views.py

from flask import redirect, url_for, render_template

from . import app, db
from .forms import PasswordForm
from .models import User
from .util import ts

@app.route('/reset/<token>', methods=["GET", "POST"])
def reset_with_token(token):
    try:
        email = ts.loads(token, salt="recover-key", max_age=86400)
    except:
        abort(404)

    form = PasswordForm()

    if form.validate_on_submit():
        user = User.query.filter_by(email=email).first_or_404()

        user.password = form.password.data

        db.session.add(user)
        db.session.commit()

        return redirect(url_for('signin'))

    return render_template('reset_with_token.html', form=form, token=token)
~~~

ここでも前回メールアドレスを検証したのと同じ方法でトークンを検証しています。
ビューはまずURLに含まれるトークンをそのままテンプレートに渡します。
そしてテンプレートはそのトークンを利用してフォームをレンダリングします。
テンプレートは以下のようになります。

~~~ {language="Python"}
{# ourapp/templates/reset_with_token.html #}

{% extends "layout.html" %}

{% block body %}
<form action="{{ url_for('reset_with_token', token=token) }}" method="POST">
    {{ form.password.label }}: {{ form.password }}<br>
    {{ form.csrf_token }}
    <input type="submit" value="パスワード変更" />
</form>
{% endblock %}
~~~

## まとめ
- メールアドレスを確認するためのトークンを生成したり検証するにはitsdangerousパッケージを利用してください。
- アカウントの作成や、メールアドレスの変更、パスワードを忘れた時にもこのトークンを利用してメールアドレスを検証することが出来ます。
- ユーザーの認証処理はセッション管理を自前で実装するのではなくFlask-Loginを利用してください。
- 悪意あるユーザーがあなたの意図していない行為を行えないか常に注意しましょう。


