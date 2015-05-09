# フォーム処理

![フォーム処理](images/forms.png)

フォームはWEBアプリケーションでユーザーの入力を扱うための基本的な機能です。
Flask自体が直接フォームを処理するわけではありませんが、Flask-WTFという拡張モジュールでWTFormsという有名なパッケージを利用することが出来ます。
WTFormsはフォームを定義したり送信されたフォームの処理を簡単するためのパッケージです。

## Flask-WTF

Flask-WTFをインストールした後、まず初めに`myapp.forms`パッケージにフォームを定義します。

~~~ {language="Python"}
# ourapp/forms.py

from flask.ext.wtf import Form
from wtforms.fields import TextField, PasswordField
from wtforms.validators import Required, Email

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email()])
    password = PasswordField('Password', validators=[Required()])
~~~

**注記**

Flask-WTFのバージョン0.9まではWTFormsのフィールドやバリデーターをラップしていました。
ですので`TextField`や`PasswordField`を利用する際は`wtforms`の代わりに`flask.ext.wtforms`からインポートする必要がありました。

0.9以降は例のように`wtforms`からインポートしてください。

先ほど定義したのはサインインフォームです。
`SignInForm()`という名前を付けたくなるかもしれませんが、このフォームを別の用途で再利用出来る様に、ここでは抽象的な名前にしておきます。
目的に応じてフォームの名前を付けると、同じ内容のフォームを複数定義することになり、あまり良くありません。
フォームに含まれるフィールドに基づいてユニークな名前を付けたほうがより簡潔になります。
もちろん、1箇所でしか利用しないフォームは目的に応じた名前を付けても良いでしょう。

このサインインフォームは幾つかの機能を持っています。
CSRF対策を行ったり、入力値の検証を行い適切にレンダリングすることも可能です。

### CSRF対策と入力値の検証

CSRFとはクロスサイトリクエストフォージェネリの略です。
CSRF攻撃は第3者がフォーム送信などのリクエストを強要させることです。
脆弱なサーバーはそのリクエストをフォームから送信されたデータとして処理してしまいます。

例えば、メールアカウントを削除するフォームがあるとします。
ログイン済みのユーザーがこのフォームから`account_delete`というエンドポイントに対してPOSTリクエストを送信するとアカウントが削除されます。
これと同じエンドポイントに対してPOSTリクエストを行うフォームは第三者でも作成することが出来ます。
そしてログインを行った誰かが偽装された「送信」ボタンを押したり、JavaScriptを実行するとアカウントを削除されてしまうのです。
これを防ぐには、送信されたPOSTリクエストが自分たちの正しいフォームから送信されたリクエストであることを知る必要があります。

それではどの様にして、正しいフォームから送信されたことを判別すれば良いのでしょうか?
WTFormsはフォームをレンダリングする際にユニークなトークンを生成することが出来ます。
POSTリクエストがサーバーに送られてくると、フォームデータを処理する前にこのトークンを検証します。
重要なのはこのトークンはユーザーのセッション(Cookie)に紐付けられており、一定の時間(30分程度)で有効期限が切れるということです。
これにより正しいフォームを送信できる人物は、同じパソコンを利用して一定時間以内にページを読み込んだユーザーのみに限られます。

**注記**

- WTFormsが生成するトークンについての詳細は[こちらのドキュメント](http://wtforms.simplecodes.com/docs/1.0.1/ext.html#module-wtforms.ext.csrf.session)を参照してください。
- CSRFについてもっと学ぶには[OWASP wiki](https://www.owasp.org/index.php/CSRF)を読んでください。

Flask-WTFを利用してCSRF対策を行うには、ログインページのビュー以下のように定義します。

~~~ {language="Python"}
# ourapp/views.py

from flask import render_template, redirect, url_for

from . import app
from .forms import EmailPasswordForm

@app.route('/login', methods=["GET", "POST"])
def login():
    form = EmailPasswordForm()
    if form.validate_on_submit():

        # パスワードのチェックとログイン処理
        # [...]

        return redirect(url_for('index'))
    return render_template('login.html', form=form)
~~~

さきほど定義した`forms`パッケージからフォームインポートして呼び出します。
この時、`form.validate_on_submit()`を実行します。
この関数はHTTPメソッドがPOSTかPUTであり、*forms.py*で定義した検証が通れば`True`を返します。

**注記**

-   [Form.validate\_on\_submitのドキュメント](https://flask-wtf.readthedocs.org/en/latest/api.html#flask_wtf.Form.validate_on_submit)
-   [Form.validate\_on\_submitのソース](https://github.com/lepture/flask-wtf/blob/v0.9.5/flask_wtf/form.py#L151)

正しく検証が通ればログイン処理を継続することが出来ます。
POSTリクエストでなくGETリクエストの場合はテンプレートに記述したフォームレンダリングします。
以下は、CSRF対策を行ったフォームテンプレートです。

~~~ {language="HTML"}
{# ourapp/templates/login.html #}

{% extends "layout.html" %}
<html>
    <head>
        <title>ログインページ</title>
    </head>
    <body>
        <form action="{{ url_for('login') }}" method="post">
            <input type="text" name="email" />
            <input type="password" name="password" />
            {{ form.csrf_token }}
        </form>
    </body>
</html>
~~~

`{{ form.csrf_token }}`はCSRFトークンを含むhiddenフィールドをレンダリングします。
このトークンの正当性は`form.validate_on_submit()`で検証しますので、これ以上のことは行う必要はありません、わーい。

#### AJAX呼び出しのCSRF対策

Flask-WTFのCSRFトークンはフォーム送信以外のリクエストの保護も行います。
アプリケーションがAJAXの様なリクエストを行う場合でもCSRF対策を行うことが出来ます。

**注記**

詳しくは[Flask-WTFのドキュメント](https://flask-wtf.readthedocs.org/en/latest/csrf.html#ajax)を参照してください。

### カスタムバリデーター

WTFormsが提供する組み込みのバリデーター(`Required()`や`Email()`など)だけでなく、バリデーターを自作することも可能です。
この節では、データーベースをチェックして同一の値が存在するかどうかを確認する`Unique()`バリデーターを作成する例を示します。
これはユーザー名やメールアドレスをチェックして既に利用されているかどうかを確認することが出来ます。
WTFormsを使用しなければビューの中でチェックしていたでしょう。WTFormsを利用することでバリデーター処理をフォームの中に隠蔽することが出来ます。

それでは単純なサインアップフォームを定義してみましょう。

~~~ {language="Python"}
# ourapp/forms.py
from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required, Email

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email()])
    password = PasswordField('Password', validators=[Required()])
~~~

そして既にデーターベースにこのメールアドレスが存在するかどうかを確認するバリデーターを実装します。
この新しいバリデーターは`util`モジュールの`util.validators`に定義します。

~~~ {language="Python"}
# ourapp/util/validators.py
from wtforms.validators import ValidationError

class Unique(object):
    def __init__(self, model, field, message=u'This element already exists.'):
        self.model = model
        self.field = field

    def __call__(self, form, field):
        check = self.model.query.filter(self.field == field.data).first()
        if check:
            raise ValidationError(self.message)
~~~

これはSQLAlchemyを利用してモデルを定義していることを前提にしたバリデーターです。
WTFormsはバリデーターが呼び出し可能オブジェクトであることを期待します。

*\_\_init\_\_*ではバリデーターに渡す引き数を指定できます。
今回の例では関連するモデル(`User`モデル)とチェックを行うフィールドを渡します。
バリデーターが呼び出されフォームから送信された値がデータベースに存在した場合、`ValidationError`を投げます。
この時表示するメッセージも指定するとこが可能です。

それではこの`Unique`バリデーターを使う様に`EmailPasswordForm`を修正してみましょう。

~~~ {language="Python"}
# ourapp/forms.py

from flask.ext.wtforms import Form
from wtforms import TextField, PasswordField, Required, Email

from .util.validators import Unique
from .models import User

class EmailPasswordForm(Form):
    email = TextField('Email', validators=[Required(), Email(),
        Unique(
            User,
            User.email,
            message='There is already an account with that email.'])
    password = PasswordField('Password', validators=[Required()])
~~~

**注記**

バリデーターは呼び出し可能なクラスである必要はありません。
呼び出し可能オブジェクトまたは普通の関数でも構いません。
WTFormsのドキュメントに[幾つかの例](http://wtforms.simplecodes.com/docs/0.6.2/validators.html#custom-validators)が載っています。

### フォームのレンダリング

WTFormsはフォームをHTMLとしてレンダリングする機能も持っています。
WTFormsの`Field`クラスはテンプレートの中で呼び出すだけでHTMLをレンダリングします。
`csrf_token`フィールドと同じような感じです。

以下にWTFormsを利用してログインフォームをレンダリングする例を示します。

~~~ {language="HTML"}
{# ourapp/templates/login.html #}

{% extends "layout.html" %}
<html>
    <head>
        <title>ログインページ</title>
    </head>
    <body>
        <form action="" method="post">
            {{ form.email }}
            {{ form.password }}
            {{ form.csrf_token }}
        </form>
    </body>
</html>
~~~

以下のように、フィールドに引き数を渡すことにより、レンダリング方法をカスタマイズできます。

~~~ {language="HTML"}
<form action="" method="post">
    {{ form.email.label }}: {{ form.email(placeholder='yourname@email.com') }}
    <br>
    {{ form.password.label }}: {{ form.password }}
    <br>
    {{ form.csrf_token }}
</form>
~~~

**注記**

HTML属性の「class」を指定したい時は、`class_=''`という引き数を指定する必要があります。
なぜなら「class」というキーワードはPythonで予約されているからです。

**注記**

WTFormsのドキュメントに[利用可能なフィールドプロパティの一覧](http://wtforms.simplecodes.com/docs/1.0.4/fields.html#wtforms.fields.Field.name)があります。

**注記**

知っていると思いますがここでJinjaの`|safe`を使う必要はありません。
WTFormsは安全なHTML文字列をレンダリングしてくれます。

詳細は[ドキュメント](https://flask-wtf.readthedocs.org/en/v0.8.4/#using-the-safe-filter)を参照してください。

## まとめ

- フォームはセキュリティ上恐ろしいことが出来てしまいます。
- WTForms(Flask-WTF)は安全なフォームを簡単に定義することができます。
- Flask-WTFのCSRF保護機能を利用して安全なフォームを作成してください。
- Flask-WTFを利用して、AJAX呼び出しのCSRF対策行うことができます。
- バリデーションのロジックをビューの外に記述したい場合はカスタムバリデーターを定義します。
- WTFormsのフィールドに基づいてフォームのHTMLがレンダリングされますので、HTMLを直接記述する必要はありません。

