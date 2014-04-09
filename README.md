# スマブラポータル

[スマブラ専門 個人ポータルサイト](http://ssbp.info)

スマブラ専門の個人ポータルサイト (かつての iGoogle のように、自分のための情報を集めた Web ページを持てるサイト) です。スマコムと呼ばれるコミュニティサイトが閉鎖することとになったので作りました。

特徴はコミュニティサイトといいつつもほとんど機能は持たず、最低限のアカウント、リレーション、ニュース機能のみ持ち、コンテンツは全て外部に依存するところです。
これはコミュニティが閉鎖的であることは衰退に繋がるという危機感と今までにスマコムが閉鎖したことによるリポジトリとしての不信感に対するアンチテーゼです。

機能としてはフォロー機能、フィードや Web API から新着情報取得、表示です。


## 技術

[Node.js](https://nodejs.org) 上で [Sails.js](https://sailsjs.org) をメインとして作成しています。


## 使用サービス

- [はてなブログ](http://hatenablog.com) (日記)
- [Zusaar](http://www.zusaar.com) (オフ会)
- [Twitch](http://ja.twitch.tv) (生放送)
- [Twitter](https://twitter.com) (一行宣伝)


## 使い方

```shell
npm install
sails lift
```

また、環境変数に以下が必要です。

- MONGOLAB_URI
- NODE_ENV
- SENDGRID_PASSWORD
- SENDGRID_USERNAME
- SESSION_SECRET
- TWITTER_ACCESS_TOKEN
- TWITTER_ACCESS_TOKEN_SECRET
- TWITTER_CONSUMER_KEY
- TWITTER_CONSUMER_SECRET
