# デプロイ

![デプロイ](images/deployment.png)

私達のアプリを全世界に公開する準備が出来ました。
今こそデプロイを行う時です。
この手続きはには多くの要素が関わってきますのでややこしいです。
製品のスタックを決めるまでには多くの選択肢があります。
この章ではデプロイを行う上で重要な部分と幾つかの選択肢を紹介します。

## ホスト

まずどこかにサーバーを用意する必要があるでしょう。
サーバープロバイダーは数多くありますが、ここでは個人的に気に入っている3つを紹介します。
サービスの利用方法についてはこの本の対象外ですのではじめから説明しませんが、Flaskアプリケーションをデプロイする上での優位点についてお話しようと思います。

### Amazon Web Services EC2

Amazon Web Services(AWS)はAmazonが提供するサービスの総称です。
スタートアップ企業にとって最も一般的な選択肢という話はどこかで聞いたことがあると思います。
このAWSの中でも今回関係するのはElastic Compute Cloud(EC2)です。
EC2の最大の特徴はAWS用語でインスタンスと呼ばれる仮想サーバーを数秒で立ち上げられる所です。
もしも急にアプリケーションを拡張しなくてはならない場合でも追加のEC2インスタンスを立ち上げロードバランサ(AWS Elastic Load Balancer)の下にデプロイすることが出来ます。

Flaskに関して言っておくと、
AWSは標準的な仮想サーバーですのでお気に入りのLinuxディストリビューションを起動してFlaskアプリケーションを動かすことは簡単に出来ます。
しかしこれはある程度のシステム管理に関する知識が必要になるでしょう。

### Heroku

HerokuはAWS上に構築されたアプリケーションホスティングサービスです。
ECと比較するとサーバー管理に関する経験が必要無いというメリットがあります。

Herokuでは`git push`を実行してアプリケーションをサーバーにデプロイします。
これはサーバーにSSHしてあれこれソフトウェアをインストールしたりアプリケーションのデプロイ方法を考えるのに時間を掛けたく無い場合にはとても便利です。
この便利さには当然お金がかかりますが、AWSもHerokuも一定の規模であれば無料で利用することが出来ます。

**注記**
HerokuにFlaskアプリケーションをデプロイするためのチュートリアルはこちらに用意されています。

  - [tutorial on deploying Flask](https://devcenter.heroku.com/articles/getting-started-with-python)

**注記**

自分でデーターベースを管理しようとするとある程度の経験が必要で、手間も掛かります。
データーベースの管理について学ぶことは素晴らしいことですが、時にはアウトソーシングすることで手間と時間を節約しても良いでしょう。

HerokuとAWSは両方ともデーターベース管理機能を提供しています。
私はまだ使ったことはありませんが、非常に素晴らしいものだという評判を聞いています。
自分自身でデータの安全性を高めたりバックアップをしたくない場合はこれを検討してみても良いでしょう。

-   [Heroku Postgres](https://www.heroku.com/postgres)
-   [Amazon RDS](https://aws.amazon.com/rds/)

### Digital Ocean

Digital Oceanは最近始まったEC2の競合サービスです。
EC2の様に、Digital Oceanでも**droplets**と呼ばれる仮想サーバーを瞬時に起動できます。
全てのdropletsはSSDで動作しEC2に劣る所はありません。
個人的に最も大きな利点だと思うのは管理インターフェースがAWSのコントロールパネルよりも単純で使いやすい所です。
Digital Oceanは個人的に私の好みですので、一度試してみることをオススメします。

Digital OceanにFlaskアプリケーションをデプロイする方法はEC2と大体同じです。
まっさらなLinuxディストリビューションにソフトウェアスタックとFlaskアプリケーションをインストールするだけです。

**注記**

Digital Oceanはこの本のキックスターターキャンペーンを運用するのに十分適していました。
ですので私のユーザーとしての経験から自身を持ってオススメできます。
もし気に入ってなかったらこの本で取り上げていなかったでしょう。

## ソフトウェアスタック

ここではFlaskアプリケーションを動作させる為に必要なソフトウェアスタックについて説明します。
基本的なソフトウェアスタックはフロントWEBサーバーがバックエンドのFlaskアプリケーションランナーにリバースプロキシーを行うという構成です。
通常はデータベースも動いているでしょうからこれについて少し説明します。

### アプリケーションランナー

私達が開発時にローカルで実行しているFalskのサーバーはあまり多くのリクエストを処理することは出来ません。
実際にアプリケーションを公開する際はGunicornの様なアプリケーションランナーで動作させることになります。
Gunicornはスレッドなどを管理していますので多くのリクエストを処理することが出来ます。

Gunicornを利用するにはvirtualenv環境で`gunicorn`をpipでインストールします。
簡潔なコマンドでアプリケーションを実行することができます。

~~~ {language="Python"}
# app.py

from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
        return "Hello World!"
~~~

最小のFlaskアプリケーションを用意しました。
これをGunicornで動作させるには以下のように`gunicorn`コマンドを実行します。

~~~ {language="command"}
(ourapp)$ gunicorn rocket:app
2014-03-19 16:28:54 [62924] [INFO] Starting gunicorn 18.0
2014-03-19 16:28:54 [62924] [INFO] Listening at: http://127.0.0.1:8000 (62924)
2014-03-19 16:28:54 [62924] [INFO] Using worker: sync
2014-03-19 16:28:54 [62927] [INFO] Booting worker with pid: 62927
~~~

ここでブラウザで*<http://127.0.0.1:8000>*にアクセスすると「Hello World!」が表示されるでしょう。

サーバーをバックグラウンドで動作させるにはGunicornに`-D`オプションを渡してやります。
これでターミナルを終了してもGunicornが動作し続けるようになります

Gunicornをバックグラウンドで動作させると、サーバーを停止させるのが面倒になるかもしれません。
素早くプロセスを特定して停止するために、プロセスIDをファイルに書きだす様、Gunicornに指定できます。
`-p <file>`オプションを利用してください。

~~~ {language="command"}
(ourapp)$ gunicorn rocket:app -p rocket.pid -D
(ourapp)$ cat rocket.pid
63101
~~~

サーバーを再起動するには`kill -HUP`、停止するには`kill`コマンドを実行します。

~~~ {language="command"}
(ourapp)$ kill -HUP `cat rocket.pid`
(ourapp)$ kill `cat rocket.pid`
~~~

Gunicornはデフォルトで8000ポートを利用して動作します。
これを変更するには`-b`オプションを指定してください。

~~~ {language="command"}
(ourapp)$ gunicorn rocket:app -p rocket.pid -b 127.0.0.1:7999 -D
~~~

#### Gunicornを公開する

**警告**

Gunicornはリバースプロキシの背後に配置します。
もしもフロントエンドに晒してしまうと、DoS攻撃の格好の餌食となってしまいます。
デバッグ目的で直接接続する場合は十分注意してアクセス制御を行ってください。

先ほどのようにGunicornを実行した場合、ローカルシステムからしかアクセスすることができません。
Gunicornはデフォルトで127.0.0.1をbindするからです。
これはローカルシステムからのアクセスしか受け付けないことを意味しています。
これはリバースプロキシサーバーが同一サーバーで動作している場合には望ましい動作です。
もしGunicornで外部からの接続を受け付けたい場合は0.0.0.0をbindしてください。
これで全てのアクセスを受け付けられる様になります。

~~~ {language="command"}
(ourapp)$ gunicorn rocket:app -p rocket.pid -b 0.0.0.0:8000 -D
~~~

**注記**

- Gunicornの実行方法とデプロイについてはこちらを参照してください。
    - <http://docs.gunicorn.org/en/latest/>
- [Fabric](http://docs.fabfile.org/en/latest)はサーバーにSSHせずにアプリケーションをデプロイしたり管理することが出来るツールです。

### NGINXリバースプロキシ

リバースプロキシはフロントエンドへのHTTPリクエストをバックエンドのGunicornに渡し、Gunicornからのレスポンスをクライアントに返します。
NGINXはとても効率よくリバースプロキシを行えるため、GunicornはNGINXを利用することを強く推奨しています。

127.0.0.1:8000で動作しているGunicornに対してNGINXでリバースプロキシを行うには以下の設定ファイルを作成します:

*/etc/nginx/sites-available/expl-oreflask.com*

~~~ {language="nginx.conf"}
# /etc/nginx/sites-available/exploreflask.com

# www.exploreflask.com を exploreflask.com にリダイレクトする。
server {
    server_name www.exploreflask.com;
    rewrite ^ http://exploreflask.com/ permanent;
}

# Handle requests to exploreflask.com on port 80
server {
    listen 80;
    server_name exploreflask.com;

    # Handle all locations
    location / {
        # Pass the request to Gunicorn
        proxy_pass http://127.0.0.1:8000;

        # Set some HTTP headers so that our app knows where the 
        # request really came from
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
~~~

そして、このファイルを*/etc/nginx/sites-enabled*にシンボリックリンクを貼りNGINXを再起動します。

~~~ {language="command"}
$ sudo ln -s \
    /etc/nginx/sites-available/exploreflask.com \
    /etc/nginx/sites-enabled/exploreflask.com
~~~

これでNGINXへのリクエストが私達のアプリケーションに渡されるようになるはずです。

**注記**

- NGINXのセットアップ方法ついてはこちらにより詳しいドキュメントがあります。
    - [Nginx configuration section](http://docs.gunicorn.org/en/latest/deploy.html#nginx-configuration)

#### ProxyFix

Nginxでリバースプロキシを行うとリクエストの変数が期待通りにならない問題に遭遇するかもしれません。
たとえば`REMOTE_ADDR`や`HTTP_HOST`などの変数です。
これを修正するにはWerkzeug ProxyFixを利用してください。

~~~ {language="Python"}
# app.py

from flask import Flask

# Import the fixer
from werkzeug.contrib.fixers import ProxyFix

app = Flask(__name__)

# Use the fixer
app.wsgi_app = ProxyFix(app.wsgi_app)

@app.route('/')
def index():
    return "Hello World!"
~~~

**注記**

- ProxyFixについての詳細はこちらを参照してください。
    - [the Werkzeug docs](http://werkzeug.pocoo.org/docs/contrib/fixers/#werkzeug.contrib.fixers.ProxyFix)

## まとめ

- FlaskアプリケーションをAWS EC2やHeroku、Digital Oceanでホスティングするのは良い選択でしょう。
- Flaskアプリケーションの基本的なソフトウェアスタックは、アプリケーション、Gunicornなどのアプリケーションランナー、Nginxなどのリバースプロキシで構成されます。
- GunicornはNginxの背後に配置され、デフォルトで127.0.0.1をLISTENするので内部からのみのアクセスを受け付けます。
- Flaskアプリケーションでプロキシーヘッダーを適切に扱うにはWerkzeugのProxyFixを利用してください。

