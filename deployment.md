# 配備

![配備](images/deployment.png)

私達のアプリを全世界に公開する準備が出来ました。
配備の時間です。
この手続きはには多くの要素が関わってきますのでややこしいです。
製品スタックを決めるためには多くの選択肢があります。
この章では重要な要素と幾つかの選択肢を紹介します。

## ホスト

まずどこかにサーバーを用意する必要があるでしょう。
サーバープロバイダーは数多くありますが、ここでは個人的に気に入っている3つを紹介します。
この本の対象外ですのでサービスの利用方法について最初から説明しませんが、
Flaskアプリケーションを配備する上での優位点についてお話しようと思います。

### Amazon Web Services EC2

Amazon Web Services(AWS)はAmazonが提供するサービスの総称です。
スタートアップ企業にとって最も一般的な選択肢という話はどこかで聞いたことがあると思います。
このAWSの中でも今回関係するのはElastic Compute Cloud(EC2)です。
EC2の最大の特徴はAWS用語でインスタンスと呼ばれる仮想サーバーを数秒で立ち上げられる所です。
もしも急にアプリケーションを拡張しなくてはならない場合でも追加のEC2インスタンスを立ち上げロードバランサ(AWS Elastic Load Balancer)の下に配備することが出来ます。

Flaskに関して言っておくと、
AWSは標準的な仮想サーバーですのでお気に入りのLinuxディストリビューションを起動してFlaskアプリケーションを動かすことは簡単に出来ます。
しかしこれはある程度のシステム管理に関する知識が必要になるでしょう。

### Heroku

HerokuはAWS上に構築されたアプリケーションホスティングサービスです。
ECと比較するとサーバー管理に関する経験が必要無いというメリットがあります。

Herokuでは`git push`を実行してアプリケーションをサーバーに配備します。
これはサーバーにSSHしてあれこれソフトウェアをインストールしたりアプリケーションの配備方法を考えるのに時間を掛けたく無い場合にはとても便利です。
この便利さには当然お金がかかりますが、AWSもHerokuも一定の規模であれば無料で利用することが出来ます。

**注記**
HerokuにFlaskアプリケーションを配備するためのチュートリアルはこちらに用意されています。

  - [tutorial on deploying Flask](https://devcenter.heroku.com/articles/getting-started-with-python)

**注記**

自分でデーターベースを管理しようとするとある程度の経験が必要で、手間も掛かります。
データーベースの管理について学ぶことは素晴らしい事ですが、時にはアウトソーシングする事で手間と時間を節約しても良いでしょう。

HerokuとAWSは両方データーベース管理機能を提供しています。
私はまだ使った事はありませんが、非常に素晴らしいものだという評判を聞いています。
自分自身でデータの安全性を高めたりバックアップをしたくない場合はこれを検討してみても良いでしょう。

-   [Heroku Postgres](https://www.heroku.com/postgres)
-   [Amazon RDS](https://aws.amazon.com/rds/)

### Digital Ocean

Digital Oceanは最近始まったEC2の競合サービスです。
EC2の様に、Digital Oceanでも**droplets**と呼ばれる仮想サーバーを瞬時に起動できます。
全てのdropletsはSSDで動作しEC2に劣る所はありません。
個人的に最も大きな利点だと思うのは管理インターフェースがAWSのコントロールパネルよりも単純で使いやすい所です。
Digital Oceanは個人的に私の好みですので、一度見てみることをオススメします。

Digital OceanにFlaskアプリケーションを配備する方法はEC2と大体同じです。
まっさらなLinuxディストリビューションにソフトウェアスタックとFlaskアプリケーションをインストールするだけです。

**注記**

Digital Oceanはこの本のキックスターターキャンペーンを運用するのに十分適していました。
ですので私のユーザーとしての経験から自身を持ってオススメできます。
もし気に入ってなかったらこの本で取り上げていなかったでしょう。

## スタック

This section will cover some of the software that we'll need to install
on our server to serve our Flask application to the world. The basic
stack is a front server that reverse proxies requests to an application
runner that is running our Flask app. We'll usually have a database too,
so we'll talk a little about those options as well.

### Application runner

The server that we use to run Flask locally when we're developing our
application isn't good at handling real requests. When we're actually
serving our application to the public, we want to run it with an
application runner like Gunicorn. Gunicorn handles requests and takes
care of complicated things like threading.

To use Gunicorn, we install the `gunicorn` package in our virtual
environment with Pip. Running our app is a simple command away.

    # app.py

    from flask import Flask

    app = Flask(__name__)

    @app.route('/')
    def index():
            return "Hello World!"

A fine app indeed. Now, to serve it up with Gunicorn, we simply run the
`gunicorn` command.

    (ourapp)$ gunicorn rocket:app
    2014-03-19 16:28:54 [62924] [INFO] Starting gunicorn 18.0
    2014-03-19 16:28:54 [62924] [INFO] Listening at: http://127.0.0.1:8000 (62924)
    2014-03-19 16:28:54 [62924] [INFO] Using worker: sync
    2014-03-19 16:28:54 [62927] [INFO] Booting worker with pid: 62927

At this point, we should see "Hello World!" when we navigate our browser
to *<http://127.0.0.1:8000>*.

To run this server in the background (i.e. daemonize it), we can pass
the `-D` option to Gunicorn. That way it'll run even after we close our
current terminal session.

If we daemonize Gunicorn, we might have a hard time finding the process
to close later when we want to stop the server. We can tell Gunicorn to
stick the process ID in a file so that we can stop or restart it later
without searching through lists of running processess. We use the
`-p <file>` option to do that.

    (ourapp)$ gunicorn rocket:app -p rocket.pid -D
    (ourapp)$ cat rocket.pid
    63101

To restart and kill the server, we can run `kill -HUP` and `kill`
respectively.

    (ourapp)$ kill -HUP `cat rocket.pid`
    (ourapp)$ kill `cat rocket.pid`

By default Gunicorn runs on port 8000. We can change the port by adding
the `-b` bind option.

    (ourapp)$ gunicorn rocket:app -p rocket.pid -b 127.0.0.1:7999 -D

#### Making Gunicorn public

> **warning**
>
> Gunicorn is meant to sit behind a reverse proxy. If you tell it to
> listen to requests coming in from the public, it makes an easy target
> for denial of service attacks. It's just not meant to handle those
> kinds of requests. Only allow outside connections for debugging
> purposes and make sure to switch it back to only allowing internal
> connections when you're done.

If we run Gunicorn like we have in the listings, we won't be able to
access it from our local system. That's because Gunicorn binds to
127.0.0.1 by default. This means that it will only listen to connections
coming from the server itself. This is the behavior that we want when we
have a reverse proxy server that is sitting between the public and our
Gunicorn server. If, however, we need to make requests from outside of
the server for debugging purposes, we can tell Gunicorn to bind to
0.0.0.0. This tells it to listen for all requests.

    (ourapp)$ gunicorn rocket:app -p rocket.pid -b 0.0.0.0:8000 -D

> **note**
>
> -   Read more about running and deploying Gunicorn [in the
>     documentation](http://docs.gunicorn.org/en/latest/).
> -   [Fabric](http://docs.fabfile.org/en/latest) is a tool that lets
>     you run all of these deployment and management commands from the
>     comfort of your local machine without SSHing into every server.

### Nginx Reverse Proxy

A reverse proxy handles public HTTP requests, sends them back to
Gunicorn and gives the response back to the requesting client. Nginx can
be used very effectively as a reverse proxy and Gunicorn "strongly
advises" that we use it.

To configure Nginx as a reverse proxy to a Gunicorn server running on
127.0.0.1:8000, we can create a file for our app:
*/etc/nginx/sites-available/expl-oreflask.com*.

    # /etc/nginx/sites-available/exploreflask.com

    # Redirect www.exploreflask.com to exploreflask.com
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

Now we'll create a symlink to this file at */etc/nginx/sites-enabled*
and restart Nginx.

    $ sudo ln -s \
    /etc/nginx/sites-available/exploreflask.com \
    /etc/nginx/sites-enabled/exploreflask.com

We should now be able to make our requests to Nginx and receive the
response from our app.

> **note**
>
> The [Nginx configuration
> section](http://docs.gunicorn.org/en/latest/deploy.html#nginx-configuration)
> in the Gunicorn docs will give you more information about setting
> Nginx up for this purpose.

#### ProxyFix

We may run into some issues with Flask not properly handling the proxied
requests. It has to do with those headers we set in the Nginx
configuration. We can use the Werkzeug ProxyFix to ... fix the proxy.

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

> **note**
>
> -   Read more about ProxyFix in [the Werkzeug
>     docs](http://werkzeug.pocoo.org/docs/contrib/fixers/#werkzeug.contrib.fixers.ProxyFix).

Summary
-------

-   Three good choices for hosting Flask apps are AWS EC2, Heroku and
    Digital Ocean.
-   The basic deployment stack for a Flask application consists of the
    app, an application runner like Gunicorn and a reverse proxy like
    Nginx.
-   Gunicorn should sit behind Nginx and listen on 127.0.0.1 (internal
    requests) not 0.0.0.0 (external requests).
-   Use Werkzeug's ProxyFix to handle the appropriate proxy headers in
    your Flask application.

