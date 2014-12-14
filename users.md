# ユーザー処理のパターン

![ユーザー処理のパターン](images/users.png)

ユーザー処理は現代のWEBアプリケーションに共通して必要な機能です。
アカウント機能を持ったアプリケーションはユーザーの登録やメール確認、パスワードの強度の確認、パスワードリセット、認証処理など非常に多くの事をする必要があります。
ユーザー処理には多くのセキュリティ上の問題が付きまといますので、この件に関しては標準的なパターンに従うことを強く推奨します。

**注記**

この章では、ユーザーの入力処理をSQLAlchemyのモデルとWTFormsを利用している事を前提としています。
もしこれらを利用していない場合は、必要に応じて読み替えてください。

## メール確認

新規ユーザーがメールアドレスを入力した場合、一般的にはこのメールアドレスの正当性を確認したいはずです。
この確認を行うことで私達は安心してパスワードのリセットメールやその他の重要なメールを配信できるようになります。

メールアドレスを確認する一般的な方法は、パスワードをリセットするユニークなURLを含むリンクを送信し、そのURLにアクセスさせて確認する方法です。
例えば、john@example.com というメールアドレスでサインアップが行われたとします。
そうするとまずデーターベースの`email_confirmed`というカラムを`False`に設定して確認メールを送信します。
このメールにはユニークなトークンを含んだURLが記載されています。
例えばこの様なURLです:

*<http://myapp.com/accounts/confirm-/Q2hhZCBDYXRsZXR0IHJvY2tzIG15IHNvY2tz>*

Johnがこのメールを受け取りクリックすると、アプリケーションはトークンをチェックしてJohnの`email_confirmed`カラムを`True`に設定します。

どの様にしてトークンの確認を行うのでしょうか?
一つの方法はトークンをデーターベースに格納してこれと照合する方法です。
これは負荷が高いですし、私達にとっては不必要です。

ここではメールアドレスをエンコードしてトークンを生成する方法を利用します。
このトークンにタイムスタンプを含めることで有効期限を設定することも可能です。
これを行うために`itsdangerous`パッケージを利用します。
このパッケージは信頼されていない環境に対して重要なデータを送信する為のツールを提供します。
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

        # Now we'll send the email confirmation link
        subject = "Confirm your email"

        token = ts.dumps(self.email, salt='email-confirm-key')

        confirm_url = url_for(
            'confirm_email',
            token=token,
            _external=True)

        html = render_template(
            'email/activate.html',
            confirm_url=confirm_url)

        # We'll assume that send_email has been defined in myapp/util.py
        send_email(user.email, subject, html)

        return redirect(url_for("index"))

    return render_template("accounts/create.html", form=form)
~~~

ここで定義したビューはユーザーの作成処理を行い、登録したメールアドレスに確認メールを送信します。
メールの文章を生成する際にHTMLテンプレートを使用しています。

~~~ {language="HTML"}
{# ourapp/templates/email/activate.html #}

Your account was successfully created. Please click the link below<br>
to confirm your email address and activate your account:

<p>
<a href="{{ confirm_url }}">{{ confirm_url }}</a>
</p>

<p>
--<br>
Questions? Comments? Email hello@myapp.com.
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

Storing passwords
-----------------

Rule number one of handling users is to hash passwords with the Bcrypt
(or scrypt, but we'll use Bcrypt here) algorithm before storing them. We
never store passwords in plain text. It's a massive security issue and
it's unfair to our users. All of the hard work has already been done and
abstracted away for us, so there's no excuse for not following the best
practices here.

> **note**
>
> OWASP is one of the industry's most trusted source for information
> regarding web application security. Take a look at some of their
> [recommendations for secure
> coding](https://www.owasp.org/index.php/Secure_Coding_Cheat_Sheet#Password_Storage).

We'll go ahead and use the Flask-Bcrypt extension to implement the
bcrypt package in our application. This extension is basically just a
wrapper around the `py-bcrypt` package, but it does handle a few things
that would be annoying to do ourselves (like checking string encodings
before comparing hashes).

    # ourapp/__init__.py

    from flask.ext.bcrypt import Bcrypt

    bcrypt = Bcrypt(app)

One of the reasons that the Bcrypt algorithm is so highly recommended is
that it is "future adaptable." This means that over time, as computing
power becomes cheaper, we can make it more and more difficult to brute
force the hash by guessing millions of possible passwords. The more
"rounds" we use to hash the password, the longer it will take to make
one guess. If we hash our passwords 20 times with the algorithm before
storing them the attacker has to hash each of their guesses 20 times.

Keep in mind that if we're hashing our passwords 20 times then our
application is going to take a long time to return a response that
depends on that process completing. This means that when choosing the
number of rounds to use, we have to balance security and usability. The
number of rounds we can complete in a given amount of time will depend
on the computational resources available to our application. It's a good
idea to test out some different numbers and shoot for between 0.25 and
0.5 seconds to hash a password. We should try to use at least 12 rounds
though.

To test the time it takes to hash a password, we can time a quick Python
script that, well, hashes a password.

    # benchmark.py

    from flask.ext.bcrypt import generate_password_hash

    # Change the number of rounds (second argument) until it takes between
    # 0.25 and 0.5 seconds to run.
    generate_password_hash('password1', 12) 

Now we can keep timing our changes to the number of rounds with the UNIX
`time` utility.

    $ time python test.py 

    real    0m0.496s
    user    0m0.464s
    sys     0m0.024s

I did a quick benchmark on a small server that I have handy and 12
rounds seemed to take the right amount of time, so I'll configure our
example to use that.

    # config.py

    BCRYPT_LOG_ROUNDS = 12

Now that Flask-Bcrypt is configured, it's time to start hashing
passwords. We could do this manually in the view that receives the
request from the sign-up form, but we'd have to do it again in the
password reset and password change views. Instead, what we'll do is
abstract away the hashing so that our app does it without us even
thinking about it. We'll use a **setter** so that when we set
`user.password = 'password1'`, it's automatically hashed with Bcrypt
before being stored.

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

We're using SQLAlchemy's hybrid extension to define a property with
several different functions called from the same interface. Our setter
is called when we assign a value to the `user.password` property. In it,
we hash the plaintext password and store it in the `_password` column of
the user table. Since we're using a hybrid property we can then access
the hashed password via the same `user.password` property.

Now we can implement a sign-up view for an app using this model.

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

Authentication
--------------

Now that we've got a user in the database, we can implement
authentication. We'll want to let a user submit a form with their
username and password (though this might be email and password for some
apps), then make sure that they gave us the correct password. If it all
checks out, we'll mark them as authenticated by setting a cookie in
their browser. The next time they make a request we'll know that they
have already logged in by looking for that cookie.

Let's start by defining a `UsernamePassword` form with WTForms.

    # ourapp/forms.py

    from flask.ext.wtforms import Form
    from wtforms import TextField, PasswordField, Required

    class UsernamePasswordForm(Form):
        username = TextField('Username', validators=[Required()])
        password = PasswordField('Password', validators=[Required()])

Next we'll add a method to our user model that compares a string with
the hashed password stored for that user.

    # ourapp/models.py

    from . import db

    class User(db.Model):

        # [...] columns and properties

        def is_correct_password(self, plaintext)
            return bcrypt.check_password_hash(self._password, plaintext)

### Flask-Login

Our next goal is to define a sign-in view that serves and accepts our
form. If the user enters the correct credentials, we will authenticate
them using the Flask-Login extension. This extension simplifies the
process of handling user sessions and authentication.

We need to do a little bit of configuration to get Flask-Login ready to
roll.

In *\_\_init\_\_.py* we'll define the Flask-Login `login_manager`.

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

Here we created an instance of the `LoginManager`, initialized it with
our `app` object, defined the login view and told it how to get a user
object with a user's `id`. This is the baseline configuration we should
have for Flask-Login.

> **note**
>
> See more [ways to customize
> Flask-Login](https://flask-login.readthedocs.org/en/latest/#customizing-the-login-process).

Now we can define the `signin` view that will handle authentication.

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

We simply import the `login_user` function from Flask-Login, check a
user's login credentials and call `login_user(user)`. You can log the
current user out with `logout_user()`.

    # ourapp/views.py

    from flask import redirect, url_for
    from flask.ext.login import logout_user

    from . import app

    @app.route('/signout')
    def signout():
        logout_user()

        return redirect(url_for('index'))

Forgot your password
--------------------

We'll generally want to implement a "Forgot your password" feature that
lets a user recover their account by email. This area has a plethora of
potential vulnerabilities because the whole point is to let an
unauthenticated user take over an account. We'll implement our password
reset using some of the same techniques as our email confirmation.

We'll need a form to request a reset for a given account's email and a
form to choose a new password once we've confirmed that the
unauthenticated user has access to that email address. The code in this
section assumes that our user model has an email and a password, where
the password is a hybrid property as we previously created.

> **warning**
>
> Don't send password reset links to an unconfirmed email address! You
> want to be sure that you are sending this link to the right person.

We're going to need two forms. One is to request that a reset link be
sent to a certain email and the other is to change the password once the
email has been verified.

    # ourapp/forms.py

    from flask.ext.wtforms import Form

    from wtforms import TextField, PasswordField, Required, Email

    class EmailForm(Form):
        email = TextField('Email', validators=[Required(), Email()])

    class PasswordForm(Form):
        password = PasswordField('Email', validators=[Required()])

This code assumes that our password reset form just needs one field for
the password. Many apps require the user to enter their new password
twice to confirm that they haven't made a typo. To do this, we'd simply
add another `PasswordField` and add the `EqualTo` WTForms validator to
the main password field.

> **note**
>
> There a lot of interesting discussions in the User Experience (UX)
> community about the best way to handle this in sign-up forms. I
> personally like the thoughts of one Stack Exchange user (Roger
> Attrill) who said:
>
> "We should not ask for password twice - we should ask for it once and
> make sure that the 'forgot password' system works seamlessly and
> flawlessly."
>
> -   Read more about this topic in the [thread on the User Experience
>     Stack
>     Exchange](http://ux.stackexchange.com/questions/20953/why-should-we-ask-the-password-twice-during-registration/21141).
> -   There are also some cool ideas for simplifying sign-up and sign-in
>     forms in an [article on Smashing Magazine
>     article](http://uxdesign.smashingmagazine.com/2011/05/05/innovative-techniques-to-simplify-signups-and-logins/).

Now we'll implement the first view of our process, where a user can
request that a password reset link be sent for a given email address.

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

When the form receives an email address, we grab the user with that
email address, generate a reset token and send them a password reset
URL. That URL routes them to a view that will validate the token and let
them reset the password.

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

We're using the same token validation method as we did to confirm the
user's email address. The view passes the token from the URL back into
the template. Then the template uses the token to submit the form to the
right URL. Let's have a look at what that template might look like.

    {# ourapp/templates/reset_with_token.html #}

    {% extends "layout.html" %}

    {% block body %}
    <form action="{{ url_for('reset_with_token', token=token) }}" method="POST">
        {{ form.password.label }}: {{ form.password }}<br>
        {{ form.csrf_token }}
        <input type="submit" value="Change my password" />
    </form>
    {% endblock %}

Summary
-------

-   Use the itsdangerous package to create and validate tokens sent to
    an email address.
-   You can use these tokens to validate emails when a user creates an
    account, changes their email or forgets their password.
-   Authenticate users using the Flask-Login extension to avoid dealing
    with a bunch of session management stuff yourself.
-   Always think about how a malicious user could abuse your app to do
    things that you didn't intend.

