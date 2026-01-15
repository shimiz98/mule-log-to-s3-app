# 

## 手順のメモ

以下の公式docを読んだ。
https://docs.mulesoft.com/mule-gateway/policies-custom-getting-started

### generate 
公式docに記載されているコマンドラインは以下のとおり。
```sh
mvn -Parchetype-repository archetype:generate \
-DarchetypeGroupId=org.mule.tools \
-DarchetypeArtifactId=api-gateway-custom-policy-archetype \
-DarchetypeVersion=1.2.0 \
-DgroupId=${orgId} \
-DartifactId=${policyName} \
-Dversion=1.0.0 \
-Dpackage=mule-policy
```

生成したコマンドラインは以下のとおり。
```sh
mvn \
-s ./maven-settings-for-generate.xml \
-Parchetype-repository archetype:generate \
-DarchetypeGroupId=org.mule.tools \
-DarchetypeArtifactId=api-gateway-custom-policy-archetype \
-DarchetypeVersion=1.2.0 \
-DgroupId=a81c52fe-cb9e-4acb-8e3a-284b26c4f12e \
-DartifactId=my-custom-policy-00 \
-Dversion=1.0.0 \
-Dpackage=mule-policy \
-DpolicyDescription=my-policy-description \
-DpolicyName=my-policy-name \
--batch-mode \
--show-version \
| tee ./output-mvn-$(date +%Y%m%d-%H%M%S)-generate.log
```

※1: 公式docに記載されている settings.xml は、xmlのルート要素が無いため、以下を参照して追加した。
https://maven.apache.org/settings.html


※2: 以下のエラーが出たが、Mavenの引数 -s,--settings を末尾から、先頭に移動したら解消した。
```log
[WARNING] Could not transfer metadata /archetype-catalog.xml from/to archetype (https://repository.mulesoft.org/nexus/content/repositories/public): Checksum validation failed, no checksums available
[WARNING] failed to download from remoteorg.eclipse.aether.transfer.MetadataTransferException: Could not transfer metadata /archetype-catalog.xml from/to archetype (https://repository.mulesoft.org/nexus/content/repositories/public): Checksum validation failed, no checksums available
[WARNING] No archetype found in remote catalog. Defaulting to internal catalog
[WARNING] Archetype not found in any catalog. Falling back to central repository.
[WARNING] Add a repository with id 'archetype' in your settings.xml if archetype's repository is elsewhere.
```

※3: 以下のWARNINGが出たため、Mavenの引数を追加した。
```log
[WARNING] Property policyDescription is missing. Add -DpolicyDescription=someValue
[WARNING] Property policyName is missing. Add -DpolicyName=someValue
```


### pom.xml を書き換えた
1. <properties> mule.maven.plugin.version
  * 3.3.6 で生成されたが、何かエラー発生したので、実施時の最新の4.6.1に変更した。
2. <dependency> com.mulesoft.anypoint:mule-http-policy-transform-extension
  * 一般公開のrepositoryに見当たらなかったので、コメントアウトした。Enterprise用かもしれないので、
3. <plugin> org.apache.maven.plugins:maven-deploy-plugin
  * これはExchange-v1用の設定な模様。以下のExchange-v3を使う場合は、不要なので、pom.xmlから削除した。
  * https://docs.mulesoft.com/exchange/to-publish-assets-maven#prerequisites
  * > Do not include the plugin org.apache.maven.plugins.maven-deploy-plugin in your POM file or settings file, because it is not compatible with the required plugin.
3. <plugin> org.mule.tools.maven:mule-maven-plugin
  * 以下を参考にExchange-v3の設定した。mule-maven-pluginは自動生成されていたので、<classifier>mule-policy</classifier> を追加しただけ。
  * https://docs.mulesoft.com/exchange/to-publish-assets-maven#publish-an-asset-to-exchange-using-maven
4. <properties> exchange.url
  * なぜかv1用のURLのままで動作した。v3用に変更して、試した方がいい気がする。
  * https://maven.anypoint.mulesoft.com/api/v1/organizations/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/maven
  * https://maven.anypoint.mulesoft.com/api/v3/organizations/ORGANIZATION_ID/maven


### src/main/template.xml を書き換えた
* mule-http-policy-transform-extensionが一般公開のrepositoryに見当たらなかったので、「<http-transform:set-response>」を削除して、簡単なLoggerに置き換えた。

### mule-artifact.json を書き換えた
* java17を追加したが、これで正しいか、まだ確証がない。

## エラーメッセージ
### generate 時に、org.mule.tools:api-gateway-custom-policy-archetype:1.2.0 が無い。

対処: Mavenのsetting.xmlに設定する。

```log
[INFO] Generating project in Interactive mode
Downloading from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml
Downloaded from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml (18 MB at 30 MB/s)
[WARNING] Archetype not found in any catalog. Falling back to central repository.
[WARNING] Add a repository with id 'archetype' in your settings.xml if archetype's repository is elsewhere.
Downloading from central: https://repo.maven.apache.org/maven2/org/mule/tools/api-gateway-custom-policy-archetype/1.2.0/api-gateway-custom-policy-archetype-1.2.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.844 s
[INFO] Finished at: 2026-01-15T23:18:54+09:00
[INFO] ------------------------------------------------------------------------
[WARNING] The requested profile "archetype-repository" could not be activated because it does not exist.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-archetype-plugin:3.4.1:generate (default-cli) on project standalone-pom: The desired archetype does not exist (org.mule.tools:api-gateway-custom-policy-archetype:1.2.0) -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```

### Muleアプリ起動時に、Custom Policyのxml構造エラー
対処: Custom Policyを修正する。
```
ERROR 2026-01-16 00:56:55,372 [agw-policy-set-deployment.01] com.mulesoft.mule.runtime.gw.policies.deployment.DefaultPolicyDeployer: Error deploying policy my-custom-polily-01-7634037 to application study-mule-minmum-04-app
org.mule.runtime.deployment.model.api.policy.PolicyRegistrationException: Error occured registering policy 'my-custom-polily-01-7634037-mainFlow'
	at org.mule.runtime.deployment.model.impl@4.9.0/org.mule.runtime.module.deployment.impl.internal.application.MuleApplicationPolicyProvider.addPolicy(MuleApplicationPolicyProvider.java:112) ~[mule-module-deployment-model-impl-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.core@4.9.0/com.mulesoft.mule.runtime.gw.model.ApiImplementation.addPolicy(ApiImplementation.java:86) ~[api-gateway-core-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.deployment.DefaultPolicyDeployer.internalDeploy(DefaultPolicyDeployer.java:78) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.deployment.DefaultPolicyDeployer.deploy(DefaultPolicyDeployer.java:45) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultTransactionalPolicyDeploymentService.deploy(DefaultTransactionalPolicyDeploymentService.java:56) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultMultiplexingPolicyDeploymentService.lambda$newPolicy$0(DefaultMultiplexingPolicyDeploymentService.java:28) ~[mule-module-policies-4.9.0.jar:?]
	at java.base/java.util.Optional.ifPresent(Optional.java:178) ~[?:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultMultiplexingPolicyDeploymentService.lambda$forAllApis$5(DefaultMultiplexingPolicyDeploymentService.java:59) ~[mule-module-policies-4.9.0.jar:?]
	at java.base/java.util.Collections$SingletonList.forEach(Collections.java:4966) ~[?:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultMultiplexingPolicyDeploymentService.forAllApis(DefaultMultiplexingPolicyDeploymentService.java:58) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultMultiplexingPolicyDeploymentService.newPolicy(DefaultMultiplexingPolicyDeploymentService.java:28) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.detection.PolicyChangeProcessor.visit(PolicyChangeProcessor.java:47) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.detection.change.PolicyAdded.accept(PolicyAdded.java:19) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.detection.PolicyChangeProcessor.lambda$process$0(PolicyChangeProcessor.java:42) ~[mule-module-policies-4.9.0.jar:?]
	at java.base/java.lang.Iterable.forEach(Iterable.java:75) ~[?:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.detection.PolicyChangeProcessor.process(PolicyChangeProcessor.java:42) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.module.policies@4.9.0/com.mulesoft.mule.runtime.gw.policies.service.DefaultPolicySetDeploymentService.lambda$policiesForApi$0(DefaultPolicySetDeploymentService.java:76) ~[mule-module-policies-4.9.0.jar:?]
	at com.mulesoft.anypoint.gw.backoff@1.5.0/com.mulesoft.anypoint.retry.runnable.RetrierRunnable.execute(RetrierRunnable.java:40) [api-gateway-backoff-1.5.0.jar:?]
	at com.mulesoft.anypoint.gw.backoff@1.5.0/com.mulesoft.anypoint.backoff.scheduler.runnable.BackoffRunnable.run(BackoffRunnable.java:36) [api-gateway-backoff-1.5.0.jar:?]
	at com.mulesoft.anypoint.gw.backoff@1.5.0/com.mulesoft.anypoint.backoff.scheduler.runnable.FastRecovery.run(FastRecovery.java:32) [api-gateway-backoff-1.5.0.jar:?]
	at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539) [?:?]
	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264) [?:?]
	at java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304) [?:?]
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136) [?:?]
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635) [?:?]
	at java.base/java.lang.Thread.run(Thread.java:840) [?:?]
Caused by: org.mule.runtime.api.lifecycle.InitialisationException: Cannot create artifact context for the policy instance
Caused by: org.mule.runtime.core.api.config.ConfigurationException: There was '1' error while parsing the given file 'C:\mulesoft\AnypointStudio-7.21\plugins\org.mule.tooling.server.4.9.ee_7.21.0.202502030106\mule\policies\my-custom-polily-01-7634037\policy.xml'.
Full list:
org.xml.sax.SAXParseException; lineNumber: 16; columnNumber: 59; cvc-complex-type.2.4.a: Invalid content was found starting with element '{"http://www.mulesoft.org/schema/mule/http-policy-transform":set-response}'. One of '{"http://www.mulesoft.org/schema/mule/core":abstract-message-processor, "http://www.mulesoft.org/schema/mule/core":abstract-mixed-content-message-processor}' is expected.

Caused by: org.mule.runtime.api.exception.MuleRuntimeException: There was '1' error while parsing the given file 'C:\mulesoft\AnypointStudio-7.21\plugins\org.mule.tooling.server.4.9.ee_7.21.0.202502030106\mule\policies\my-custom-polily-01-7634037\policy.xml'.
Full list:
org.xml.sax.SAXParseException; lineNumber: 16; columnNumber: 59; cvc-complex-type.2.4.a: Invalid content was found starting with element '{"http://www.mulesoft.org/schema/mule/http-policy-transform":set-response}'. One of '{"http://www.mulesoft.org/schema/mule/core":abstract-message-processor, "http://www.mulesoft.org/schema/mule/core":abstract-mixed-content-message-processor}' is expected.
```