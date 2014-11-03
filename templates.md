# テンプレート

![テンプレート](images/templates.png)

Flaskは特定のテンプレート言語を強制しませんが、ここではJinjaを使うことにします。
Flaskコミュニティでは殆どの開発者がJinjaテンプレートを利用しているので私はこれを推奨します。
他のテンプレート言語を利用するFlask拡張には[Flask-Genshi](http://pythonhosted.org/Flask-Genshi/) や [Flask-Mako](http://pythonhosted.org/Flask-Mako/) などがあります。
特に理由が無い限りデフォルトのJinjaテンプレートを利用してください。
シンタックスをよく知らなくても構いません、これは悩みの種を減らすでしょう。

**注記**

この本でのJinjaとは、Jinja2の事を示しています。
Jinja1というものがありましたがここではこれを扱いません。
Jinjaと言えば、<http://jinja.pocoo.org/>の事だと思ってください。

## Jinja入門

Jinjaの構文と言語機能については公式ドキュメントに素晴らしい説明があります。
ここで繰り返し説明は行いませんが最も重要な説明だけを抜粋します。

> `{% ... %}`と`{{ ... }}`という2種類のカッコ文字があります。
> `{% ... %}`はfor文や代入文などの式の実行に利用します。
> `{{ ... }}`はテンプレート中に記述した式の評価結果を表示する為に利用します。
>
> --- [Jinja Template Designer Documentation](http://jinja.pocoo.org/docs/templates/#synopsis)

## テンプレートの管理方法

テンプレートは何処に配置すれば良いのでしょうか。
ここまで読んできたあなたはFlaskはどこに何を配置するかという点について柔軟であることに気がついたかもしれません。
テンプレートも例外ではありません。
ただし、これまでと同様に推奨される場所が存在します。
テンプレートはパッケージディレクトリに配置します。

~~~
myapp/
    __init__.py
    models.py
    views/
    templates/
    static/
run.py
requirements.txt
~~~

~~~
templates/
    layout.html
    index.html
    about.html
    profile/
        layout.html
        index.html
    photos.html
    admin/
        layout.html
        index.html
        analytics.html
~~~

テンプレートディレクトリの構造はルーティングの構造と類似しています。
*myapp.com/admin/analytics*というURLでルーティングするテンプレートは、*templates/admin/analytics.html*に配置します。
直接レンダリングされないテンプレートも同じ場所に配置します。
たとえば*layout.html*は他のテンプレートから継承されるファイルです。

## 継承
数あるバットマンの物語のように、テンプレートディレクトリはよく継承されます。
通常、全ての**子テンプレート**の一般的な構造を**親テンプレート**に定義します。
今回の例では、*layout.html*が親テンプレートであり、その他の*.html*ファイルが子テンプレートです。

最上位に配置する*layout.html*にはサイトの全てのページで一般的なレイアウトを定義します。
先ほどのディレクトリ構造を見ると、トップレベルに配置されている*myapp/templates/layout.html*は*myapp/templates/profile/layout.html*や*myapp/templat-es/admin/layout.html*から継承されていることが解ります。

継承を行うには`{% extends %}`タグと`{% block %}`タグを利用します。
親テンプレートでは子テンプレートで上書きするブロックを定義します。

~~~ {language="HTML"}
{# _myapp/templates/layout.html_ #}

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>{% block title %}{% endblock %}</title>
    </head>
    <body>
    {% block body %}
        <h1>This heading is defined in the parent.</h1>
    {% endblock %}
    </body>
</html>
~~~

そして、子テンプレートでは親テンプレートを継承してブロックの内容を記述します。

~~~ {language="HTML"}
{# _myapp/templates/index.html_ #}

{% extends "layout.html" %}
{% block title %}Hello world!{% endblock %}
{% block body %}
    {{ super() }}
    <h2>This heading is defined in the child.</h2>
{% endblock %}
~~~

この`super()`関数は元々親テンプレートのブロックに定義されていた内容を表示します。

**注記**
継承についての情報は[Jinja Template Inheritence documentation](http://jinja.pocoo.org/docs/templates/#template-inheritance)を参照してください。

## マクロの作成
We can implement DRY (Don't Repeat Yourself) principles in our templates
by abstracting snippets of code that appear over and over into
**macros**. If we're working on some HTML for our app's navigation, we
might want to give a different class to the "active" link (i.e. the link
to the current page). Without macros we'd end up with a block of
`if ... else` statements that check each link to find the active one.

Macros provide a way to modularize that code; they work like functions.
Let's look at how we'd mark the active link using a macro.

~~~ {language="HTML"}
{# myapp/templates/layout.html #}

{% from "macros.html" import nav_link with context %}
<!DOCTYPE html>
<html lang="en">
    <head>
    {% block head %}
        <title>My application</title>
    {% endblock %}
    </head>
    <body>
        <ul class="nav-list">
            {{ nav_link('home', 'Home') }}
            {{ nav_link('about', 'About') }}
            {{ nav_link('contact', 'Get in touch') }}
        </ul>
    {% block body %}
    {% endblock %}
    </body>
</html>
~~~

What we are doing in this template is calling an undefined macro —
`nav_link` — and passing it two parameters: the target endpoint (i.e.
the function name for the target view) and the text we want to show.

> **note**
>
> You may notice that we specified `with context` in the import
> statement. The Jinja **context** consists of the arguments passed to
> the `render_template()` function as well as the Jinja environment
> context from our Python code. These variables are made available in
> the template that is being rendered.
>
> Some variables are explicitly passed by us, e.g.
> `render_template("index.html", color="red")`, but there are several
> variables and functions that Flask automatically includes in the
> context, e.g. `request`, `g` and `session`. When we say
> `{% from ... import ... with context %}` we are telling Jinja to make
> all of these variables available to the macro as well.

> **note**
>
> -   All of the global variables that are passed to the Jinja context
>     by Flask:
>     <http://flask.pocoo.org/docs/templating/#standard-context>}
> -   We can define variables and functions that we want to be merged
>     into the Jinja context with context processors:
>     <http://flask.pocoo.org/docs/templating/#context-processors>

Now it's time to define the `nav_link` macro that we used in our
template.

    {# myapp/templates/macros.html #}

    {% macro nav_link(endpoint, text) %}
    {% if request.endpoint.endswith(endpoint) %}
        <li class="active"><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
    {% else %}
        <li><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
    {% endif %}
    {% endmacro %}

Now we've defined the macro in *myapp/templates/macros.html*. In this
macro we're using Flask's `request` object — which is available in the
Jinja context by default — to check whether or not the current request
was routed to the endpoint passed to `nav_link`. If it was, than we're
currently on that page, and we can mark it as active.

> **note**
>
> The from x import y statement takes a relative path for x. If our
> template was in *myapp/templates/user/blog.html* we would use
> `from "../macros.html" import nav_link with context`.

Custom filters
--------------

Jinja filters are functions that can be applied to the result of an
expression in the `{{ ... }}` delimeters. It is applied before that
result is printed to the template.

    <h2>{{ article.title|title }}</h2>

In this code, the `title` filter will take `article.title` and return a
title-cased version, which will then be printed to the template. This
looks and works a lot like the UNIX practice of "piping" the output of
one program to another.

> **note**
>
> There are loads of built-in filters like `title`. See [the full
> list](http://jinja.pocoo.org/docs/templates/#builtin-filters) in the
> Jinja docs.

We can define our own filters for use in our Jinja templates. As an
example, we'll implement a simple `caps` filter to capitalize all of the
letters in a string.

> **note**
>
> Jinja already has an `upper` filter that does this, and a `capitalize`
> filter that capitalizes the first character and lowercases the rest.
> These also handle unicode conversion, but we'll keep our example
> simple to focus on the concept at hand.

We're going to define our filter in a module located at
*myapp/util/filters.py*. This gives us a `util` package in which to put
other miscellaneous modules.

    # myapp/util/filters.py

    from .. import app

    @app.template_filter()
    def caps(text):
        """Convert a string to all caps."""
        return text.uppercase()

In this code we are registering our function as a Jinja filter by using
the `@app.template_filter()` decorator. The default filter name is just
the name of the function, but you can pass an argument to the decorator
to change that.

    @app.template_filter('make_caps')
    def caps(text):
        """Convert a string to all caps."""
        return text.uppercase()

Now we can call `make_caps` in the template rather than `caps`:

~~~
{{ "hello world!"|make_caps }}
~~~


To make our filter available in the templates, we just need to import it
in our top-level *\_\_init.py\_\_*.

    # myapp/__init__.py

    # Make sure app has been initialized first to prevent circular imports.
    from .util import filters

## まとめ
- Jinjaテンプレートを使ってください。
- Jinjaでは2種類のカッコを利用します: `{% ... %}` と `{{ ... }}`です。前者のカッコは式の実行やfor文、値の代入などで利用し、後者のカッコはテンプレート内で式の評価結果を表示します。
- テンプレートは*myapp/templates/*という様なアプリケーションのパッケージ内に配置します。
- テンプレートディレクトリはアプリケーションのURL構造と対応させる事を推奨します。
- サイト内の全てのページで共通のレイアウトをトップレベルの*layout.html*に配置し、継承すると良いでしょう。
-   Macros are like functions made-up of template code.
-   Filters are functions made-up of Python code and used in templates.

