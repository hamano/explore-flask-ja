# テンプレート

![テンプレート](images/templates.png)

Flaskは特定のテンプレート言語を強制しませんが、ここではJinjaを使うことにします。
Flaskコミュニティでは殆どの開発者がJinjaテンプレートを利用しているので私はJinjaを推奨します。
他のテンプレート言語を利用するFlask拡張には[Flask-Genshi](http://pythonhosted.org/Flask-Genshi/) や [Flask-Mako](http://pythonhosted.org/Flask-Mako/) などがあります。
特に理由が無い限りデフォルトのJinjaテンプレートを利用してください。
シンタックスをよく知らなくても構いません。
これが一番手っ取り早いです。

**注記**

この本でのJinjaとは、Jinja2の事を示しています。
Jinja1というものがありましたがここではこれを扱いません。
Jinjaと言えばこの[Jinja2](http://jinja.pocoo.org/)の事だと思ってください。

## Jinja入門

Jinjaの構文と言語機能については公式ドキュメントに素晴らしい説明があります。
ここで繰り返し説明は行いませんが最も重要な説明だけを抜粋します。

> `{% ... %}`と`{{ ... }}`という2種類のカッコがあります。
> `{% ... %}`はfor文や代入文などの式の実行に利用します。
> `{{ ... }}`はテンプレート中に記述した式の評価結果を表示する為に利用します。
>
> --- [Jinja Template Designer Documentation](http://jinja.pocoo.org/docs/templates/#synopsis)

## テンプレートの管理方法

テンプレートは何処に配置すれば良いのでしょうか。
ここまで読んできた方はFlaskはどこに何を配置するかという点について柔軟であることに気がついているかもしれません。
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

テンプレートディレクトリの構造はルーティングの構造とよく似ています。
*myapp.com/admin/analytics*というURLでルーティングするテンプレートは、*templates/admin/analytics.html*に配置します。
直接レンダリングされないテンプレートも同じ場所に配置します。
たとえば*layout.html*は他のテンプレートから継承されるファイルです。

## 継承
数あるバットマンの物語のように、テンプレートディレクトリはよく継承されます。
通常、全ての**子テンプレート**に共通する構造を**親テンプレート**に定義します。
今回の例では、*layout.html*が親テンプレートであり、その他の*.html*ファイルが子テンプレートです。

最上位に配置する*layout.html*にはサイトの全てのページに共通するレイアウトを定義します。
先ほどのディレクトリ構造を見ると、トップレベルに配置されている*myapp/templates/layout.html*は*myapp/templates/profile/layout.html*や*myapp/templat-es/admin/layout.html*から継承されていることが解ります。

継承を行うには`{% extends %}`タグと`{% block %}`タグを利用します。
親テンプレートでは子テンプレートで上書きされるブロックを定義します。

~~~ {language="HTML"}
{# _myapp/templates/layout.html_ #}

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>{% block title %}{% endblock %}</title>
    </head>
    <body>
    {% block body %}
        <h1>親テンプレートで定義した見だしです。</h1>
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
    <h2>子テンプレートで定義した見出しです。</h2>
{% endblock %}
~~~

この`super()`関数は元々親テンプレートのブロックに定義されていた内容を表示します。

**注記**
継承についての情報は[Jinja Template Inheritence documentation](http://jinja.pocoo.org/docs/templates/#template-inheritance)を参照してください。

## マクロの作成
マクロを作成してコードを抽象化する事でDRY(同じことを繰り返さない)の原則を実践することが出来ます。
例えば、ナビゲーションバーを表示するHTMLでは現在表示されているページへのリンクは異なるCSSクラスを指定したいはずです。
マクロを利用せずこれを実装すると、`if ... else`文で現在のページを判別してリンクを記述しなければなりません。

マクロを作成することでこの様なコードを関数の様ににモジュール化出来ます。
それでは、マクロを利用してナビゲーションバーを実装してみましょう。

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

このテンプレートではまだ定義していないマクロ`nav_link`を呼び出しています。
このマクロには2つのパラメーター(遷移先のビューの関数名と表示文字列)を渡しています。

**注記**

インポート文で`with context`を指定していることに気がついたでしょうか?
Jinjaのコンテキストとは`render_template()`関数で渡された引き数と、Pythonコードから渡された環境コンテキストを含みます。
このインポート文により、これらの値をテンプレート内で利用できるようになります。

例えば、以下のように値を渡します。

~~~ {language="Python"}
`render_template("index.html", color="red")`
~~~

Flaskには自動的にコンテキストを渡す機能(`request`や`g`や`session`)がありますが、`{% from ... import ... with context %}`を指定した時はマクロに対して利用可能な全ての値を渡します。

**注記**

- Jinjaコンテキストに渡されるグローバル変数の一覧はこちら:
  <http://flask.pocoo.org/docs/templating/#standard-context>
- Jinjaコンテキストにマージする独自のコンテキストプロセッサーを定義することもできます。
  <http://flask.pocoo.org/docs/templating/#context-processors>

それでは、テンプレート内に`nav_link`マクロを定義してみましょう。

~~~ {language="HTML"}
{# myapp/templates/macros.html #}

{% macro nav_link(endpoint, text) %}
{% if request.endpoint.endswith(endpoint) %}
    <li class="active"><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
{% else %}
    <li><a href="{{ url_for(endpoint) }}">{{text}}</a></li>
{% endif %}
{% endmacro %}
~~~

このマクロは*myapp/templates/macros.html*に配置しています。
ここではJinjaコンテキストでデフォルトで利用可能な`request`オブジェクトを利用しています。
URLのエンドポイントをチェックして、現在表示しているページであればCSSクラスを変更します。

**注記**

*myapp/templates/user/blog.html*というテンプレートから、相対パスでマクロをインポートする場合、
`from "../macros.html" import nav_link with context`とします。

## カスタムフィルター
Jinjaのフィルーター機能は`{{ ... }}`内で利用できます。
この処理はテンプレートが表示される前に適用されます。

~~~ {language="HTML"}
<h2>{{ article.title|title }}</h2>
~~~

このコードでは`article.title`を`title`フィルターに渡し、最初の文字を大文字に変換して表示します。これはUNIXでプログラムの出力を別のプログラムに渡す「パイプ」の動作によく似ています。

**注記**

上記の`title`の様な組み込みフィルターの一覧は[Jinjaのドキュメント](http://jinja.pocoo.org/docs/templates/#builtin-filters)を参照してください。

Jinjaテンプレート内で独自のフィルターを定義することも可能です。
以下に、全ての文字を大文字に変換する単純なフィルターの実装例を示します。

**注記**
Jinjaには既にこれを実現する`upper`フィルターや`capitalize`フィルターが存在しますので、実用ではこちらを利用してください。

フィルターモジュールは*myapp/util/filters.py*に配置することにします。
この`util`パッケージは種々様々なモジュールを置きます。

~~~ {language="Python"}
# myapp/util/filters.py

from .. import app

@app.template_filter()
def caps(text):
    """全ての文字を大文字に変換します。"""
    return text.uppercase()
~~~

このコードでは`@app.template_filter()`デコレーターを利用してJinjaフィルターを登録しています。
デフォルトでは単純に関数名がフィルター名になりますが、以下の様にデコレーターに引き数を渡してフィルター名を変更することができます。

~~~ {language="Python"}
@app.template_filter('make_caps')
def caps(text):
    """全ての文字を大文字に変換します。"""
    return text.uppercase()
~~~

以下のように関数名の`caps`ではなく、`make_caps`という名前でフィルターを呼び出せます。

~~~ {language="HTML"}
{{ "hello world!"|make_caps }}
~~~

フィルターを有効にするには、最上位の*\_\_init.py\_\_*でインポートする必要があります。

~~~ {language="Python"}
# myapp/__init__.py

# 循環importを避けるためにappが初期化されていることを確認してください。
from .util import filters
~~~

## まとめ
- Jinjaテンプレートを使ってください。
- Jinjaでは2種類のカッコを利用します: `{% ... %}` と `{{ ... }}`です。前者のカッコは式の実行やfor文、値の代入などで利用し、後者のカッコは式の評価結果を表示します。
- テンプレートは*myapp/templates/*という様なアプリケーションのパッケージ内に配置します。
- テンプレートディレクトリはアプリケーションのURL構造と対応させる事を推奨します。
- サイト内のページで共通するレイアウトをトップレベルの*layout.html*に配置し、継承すると良いでしょう。
- マクロはテンプレート内で利用できる関数の様なものです。
- フィルターはテンプレート内で変数を加工する機能です。

