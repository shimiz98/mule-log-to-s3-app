# Anypoint Platform へいろいろデプロイするツール
このツールは、Anypoint Platform へ以下をデプロイするツールです

* 直近の予定
  * API Instance(Muleアプリ用)
  * API Policy(Muleアプリ用)
* 今後の予定【まだ実装しない】
  * Muleアプリケーション
  * API Instance (Omni Gateway用)
  * デプロイ前に、Muleアプリや、API仕様、Custom Policy をExchangeへpublish

## 問題・背景
* WEBコンソールで設定するのは、時間と手間がかかる。間違えも発生する。
* 単にデプロイするだけでなく、複数の環境の差分を管理と反映も、利用者が分かりやすくしたい。
* Terraform Providerはあるが、動作がいまいち不安定なので、自作したい。
* Anypoint CLI は、インストールする量が多いので、自作したい。

## 要件
* デプロイ対象
  * API Instance(Muleアプリ用)
  * API Policy(Muleアプリ用)
    * Included Policy ※groupIdが固定、かつ、設定項目もある程度固定
    * Custom Policy   ※groupIdが可変、かつ、設定項目も可変

* 環境差分
  * 本番環境を構成を基準にする。それに対する環境差分を定義して、デプロイ前に環境差分を反映してから、デプロイする。
  * 本番環境に対して、API Instanceを追加(優先度:低)
  * 本番環境に対して、API Instanceを削除
  * 本番環境に対して、API Policyを追加(優先度:低)
  * 本番環境に対して、API Policyを削除

* デプロイ単位
  * API Instanceを、1つまたは複数指定して、デプロイする。
  * API Policyを、1つまたは複数指定して、デプロイする。

* デプロイ前のチェック
  * 指定された環境に対して、環境差分を反映してエラー(項目が無いなど)が発生しないこと
  * 設定値ファイルの、ディレクトリ名とファイルの内容が一致していること(例: `${API名}_${APIバージョン}/` と `api-instance-config.json`の内容)
  * 環境差分の反映は、デプロイ単位で指定された以外も、指定された環境は全て反映チェックすることで、先に気づきやすくする。
  * デプロイ前の設定値と、これから設定する値を比較し、差分を表示する。どう表示すると利用者に分かりやすいか要検討(diff形式, jsonpatch形式など)。
  * デプロイ前の設定値が無い場合は、新規作成なので、その旨を利用者に分かりやすく表示する。

* デプロイ後のチェック
  * デプロイ前の設定値と、デプロイ後の設定値を比較し、差分を表示する。どう表示すると利用者に分かりやすいか要検討(diff形式, jsonpatch形式など)。
    * この差分では、例えば「最終更新日時」のように必ず差分が出るものは、差分として表示しないようにする。
    * ※どの項目で、必ず差分が出るかは試さないと不明なため、4から5項目くらいある想定で、まず仕組みだけ実装する。

* エラーハンドリング・リトライ
 * 基本的に、エラーが発生したら、そこで異常終了とする。そこからリトライできる構成とする。
   * 幸いなことに、Anypoint Platform の REST APIが、冪等なAPI仕様となっているので、新規作成or既存変更のみ気を付ければ、リトライできる想定。
   * 将来的には、エラーが発生しても続行して、エラー箇所のみリトライできる構成とするのも考えるが、まずはシンプルな実装・シンプルなリトライとする意図。
    
 * TODO:エラー時の挙動 や 部分的失敗時のリトライ/ロールバック など運用面の挙動

### ディレクトリ構成
* script/
  * prepare-kankyo-sabun.sh: ひな形に対して、環境差分を反映する。あらかじめすべてに反映することで、デプロイ前のチェックも兼ねる。
  * deploy-api-instance.sh
  * deploy-api-policy.sh
* deploy-config/
  * api-instance/
    * ${API名}_${APIバージョン}/
      * api-instance-config.json
      * api-policy-config_${API PolicyのassetId}.json  ※ほとんどは「API Policyのラベル」が無いため、この形式
      * api-policy-config_${API PolicyのassetId}_${API Policyのラベル}.json
      * api-contract-config.json ※まだ実装しない
  * automated-policy/   ※まだ実装しない
  * client-application/ ※まだ実装しない
  * mule-app/           ※まだ実装しない
  * kankyo-sabun/
    * ut1/
      * api-instance.json: 項目は「ファイル名のglobパターン」「jqの式」「その環境の設定値」「コメント」の4項目。
      * 「その環境の設定値」は、jsonのobjectの場合があるが、tsvだとインデントありの整形が困難なので、json形式にする。
    * ut2/

## 実装上の要件
* GitHub Actionsで動作予定なので、基本的にはbashとjqで実装する。

## 詳細設計
* Anypoint Platform API の認証方式
  * 予め 環境変数「ANYPOINT_ACCESS_TOKEN」にアクセストークンを設定し、それを使用する。
* 「organizationId」と「environmentId」は、コマンドライン引数で指定する。
* 使用するREST API
  * API Instanceの一覧取得[GET https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis]()
  * API Instanceの作成 [POST https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis](https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236285/)
  * API Instanceの変更 [PATCH https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis/{environmentApiId}](https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236350/)
  * API Policyの一覧取得 [GET https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis/{environmentApiId}/policies]()
  * API Policyの作成 [POST https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis/{environmentApiId}/policies](https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236450/)
  * API Policyの変更 [PATCH https://anypoint.mulesoft.com/apimanager/api/v1/organizations/{organizationId}/environments/{environmentId}/apis/{environmentApiId}/policies/{policyId}](https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/console/method/%236481/)
  * 作成または変更のAPIには、それぞれの構成のjsonをそのままPOSTまたはPATCHすればOK。
    * ただし、細かいところで変更が必要かもしれないが、それは動かさないとわからいので、まず実装する。
  * 作成または変更の判断は、事前に一覧取得するREST APIを実行して、存在しなければ作成、存在したら変更とする。

