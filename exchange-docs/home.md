# README.md

このMuleアプリは、ログをFileコネクタとS3コネクタを用いてS3へログ転送するサンプル実装です。

## 実装の補足説明

### ファイル「pom.xml」の補足説明

* Fileコネクタ(MuleSoft提供)を追加した。
* S3コネクタ(MuleSoft提供)を追加した。

### ファイル「log4j2.xml」の補足説明

* RollingFile の設定項目は、以下を参照。
  * https://logging.apache.org/log4j/2.x/manual/appenders/rolling-file.html
* RollingFile の 日時「%d」の代わりに、世代番号「%i」を使うのは、この方法には不適当。
  * 後続のFileコネクタで、ファイル一覧取得後に、ログローテンションが行われると、ファイル名が世代番号「%i」がrenameされて、ずれてしまうため。
* RollingFile の {GMT+0} の理由。
  * ローカル実行時に、CloudHub2と同様に揃える目的で指定している。
* プロパティのデフォルト値の指定方法は、以下を参照。
  * https://logging.apache.org/log4j/2.x/manual/configuration.html#property-substitution
* Muleアプリのアプリケーション名がべた書きな問題は、改良予定。
    
### Muleフロー「log-to-s3Flow」の補足説明
 
* S3のKey名
  * 2レプリカ以上の構成でKeyが重複を避けるため、mule.nodeId を使用している。
  * 1階層に大量にファイルが作成される問題は、日付「yyyy-mm-dd」で1階層を作る予定。
* フローの最後のログファイル削除
  * Fileコネクタの「On New or Updated File」の設定でも削除可能だが、動作をログ出力する都合で、とりあえず個別実装しているだけ。
    
### HOWTO enable FileAppender in CloudHub 2.0
https://help.salesforce.com/s/articleView?id=001119412&type=1
CloudHub 2.0 | Anypoint monitoring custom file appender disabled
Publish Date: 2024年3月2日

`customFileAppender.enable=true`

検索条件： 「log appender cloudhub 2.0」

CloudHub 2.0 Logging FAQ
https://help.salesforce.com/s/articleView?id=001119527&type=1
Publish Date: 2024年3月2日

### AWS IAM Policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::ysk-mule-log-to-s3/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
```

## （未使用) How to Send Logs via Log4j2.xml to AWS S3 in Mule 4
https://help.salesforce.com/s/articleView?id=001115774&type=1

