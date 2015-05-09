# 静的ファイル

![静的ファイル](images/static.png)

静的ファイルとは、その名の通り変更されないファイルのことです。
一般的に、アプリケーションで利用されるCSSファイルやJavaScriptファイル、画像ファイルをこう呼びます。
音声ファイルなどもこれに含まれるでしょう。

## 静的ファイルの管理

アプリケーションパッケージの配下に*static*というディレクトリを作成します。

~~~
myapp/
    __init__.py
    static/
    templates/
    views/
    models.py
run.py
~~~

どの様に*static/*配下のファイルを整理するかは好みに依ります。
個人的には、自分のJavaScriptやCSSとjQueryやBootstrapなどの外部ライブラリが混ざってしまうのは嫌いです。
これを避けるには外部ライブラリを*lib/*フォルダに分離して配置することをオススメします。
*lib/*の代わりに*vendor/*を使っているプロジェクトもあります。

~~~
static/
    css/
        lib/
            bootstrap.css
        style.css
        home.css
        admin.css
    js/
        lib/
            jquery.js
        home.js
        admin.js
    img/
        logo.svg
        favicon.ico
~~~

### faviconの配信

静的ファイルは*example.com/static/*というURLで配信されますが、
WEBブラウザはデフォルトで*example.com/favicon.ico*というURLでfaviconを取得しようとします。
この食い違いを修正するには、HTMLテンプレートの`<head>`タグ内で以下のように記述する必要があります。

~~~ {language="HTML"}
<link rel="shortcut icon"
      href="{{ url_for('static', filename='img/favicon.ico') }}">
~~~

## Flask-Assetsによる静的ファイルの管理
Flask-Assetsは静的ファイルを管理するためのFlask拡張です。
Flask-Assetsは2つの非常に便利なツールを提供します。
1つ目はテンプレートに静的ファイルを一括して挿入するための*バンドル*を定義する機能です。
2つ目は静的ファイルを*前処理*する機能です。
これによりCSSやJavaScriptの結合と最小化を行い、通信時間を最小化できます。
JavaScriptだけでなく、SassやLESS、CoffeeScriptなどのソースを処理することも可能です。

~~~
static/
    css/
        lib/
            reset.css
        common.css
        home.css
        admin.css
    js/
        lib/
            jquery-1.10.2.js
            Chart.js
        home.js
        admin.js
    img/
        logo.svg
        favicon.ico
~~~

### バンドルの定義

アプリケーションに公開ページ(home)と管理パネル(admin)という2つの項目があるとします。
それぞれの項目につきJavaScriptとCSSがありますので4つのバンドルを定義します。
ここでは`util`パッケージ内でバンドルの定義を行います。

~~~ {language="Python"}
# myapp/util/assets.py

from flask.ext.assets import Bundle, Environment
from .. import app

bundles = {

    'home_js': Bundle(
        'js/lib/jquery-1.10.2.js',
        'js/home.js',
        output='gen/home.js'),

    'home_css': Bundle(
        'css/lib/reset.css',
        'css/common.css',
        'css/home.css',
        output='gen/home.css'),

    'admin_js': Bundle(
        'js/lib/jquery-1.10.2.js',
        'js/lib/Chart.js',
        'js/admin.js',
        output='gen/admin.js'),

    'admin_css': Bundle(
        'css/lib/reset.css',
        'css/common.css',
        'css/admin.css',
        output='gen/admin.css')
}

assets = Environment(app)

assets.register(bundles)
~~~

Flask-Assetsは記述した順番通りにファイルを結合します。
*jquery-1.10.2.js*をバンドルする場合は先頭に記述する必要があるでしょう。

Flask-Assetsでバンドルを登録するには幾つかの方法がありますが、
ここではPythonの辞書形式で記述したバンドルを登録します。[^8-1]

`util.assets`モジュール内でバンドルを登録していますので、アプリケーションの初期化時に*\_\_init\_\_.py*でこのモジュールをインポートする必要があります。

~~~ {language="Python"}
# myapp/__init__.py

# [...] アプリケーションの初期化

from .util import assets
~~~

### バンドルの利用方法

adminバンドルを利用するために、*admin/layout.html*という親テンプレートを追加します。

~~~
templates/
    home/
        layout.html
        index.html
        about.html
    admin/
        layout.html
        dash.html
        stats.html
~~~

~~~ {language="HTML"}
{# myapp/templates/admin/layout.html #}

<!DOCTYPE html>
<html lang="en">
    <head>
        {% assets "admin_js" %}
            <script type="text/javascript" src="{{ ASSET_URL }}"></script>
        {% endassets %}
        {% assets "admin_css" %}
            <link rel="stylesheet" href="{{ ASSET_URL }}" />
        {% endassets %}
    </head>
    <body>
    {% block body %}
    {% endblock %}
    </body>
</html>
~~~

*templates/home/layout.html*でも同じようにしてhomeバンドルも利用できます。

### フィルタの利用

フィルターを利用して静的ファイルの前処理を行うこともできます。
この機能は主にJavaScriptやCSSを最小化するのに役立ちます。

~~~ {language="Python"}
# myapp/util/assets.py

# [...]

bundles = {

    'home_js': Bundle(
        'lib/jquery-1.10.2.js',
        'js/home.js',
        output='gen/home.js',
        filters='jsmin'),

    'home_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/home.css',
        output='gen/home.css',
        filters='cssmin'),

    'admin_js': Bundle(
        'lib/jquery-1.10.2.js',
        'lib/Chart.js',
        'js/admin.js',
        output='gen/admin.js',
        filters='jsmin'),

    'admin_css': Bundle(
        'lib/reset.css',
        'css/common.css',
        'css/admin.css',
        output='gen/admin.css',
        filters='cssmin')
}

# [...]
~~~

**注記**

`jsmin`と`cssmin`フィルターを利用するには、`jsmin`と`cssmin`パッケージをインストールする必要があります。(`pip install jsmin cssmin`)
*requirements.txt*に加えておきましょう。

Flask-Assetsはテンプレートを最初にレンダリングするタイミングでファイルの結合と圧縮を行います。
そしてソースファイルに変更があれば自動的に圧縮ファイルの更新を行います。

**注記**
設定ファイルにASSETS\_DEBUG = Trueと記述すると、Flask-Assetsは結合を行わずに個別のファイルを出力します。

**注記**
フィルターについての詳細は[こちら](http://elsdoerfer.name/docs/webassets/builtin_filters.html#js-css-compilers)を参照してください。

## まとめ
- 静的ファイルは*static/*ディレクトリに配置してください。
- 外部ライブラリとアプリケーションの静的ファイルは分離しましょう。
- テンプレートにfaviconの場所を指定しましょう。
- テンプレートに静的ファイルを差し込むにはFlask-Assetsを利用しましょう。
- Flask-Assetsは静的ファイルの結合や圧縮を行うことが出来ます。

[^8-1]: バンドルの登録がどの様に動作するかは[ソースコード](https://github.com/miracle2k/webassets/blob/0.8/src/webassets/env.py#L380)を読んでください。

