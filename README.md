Android Example From GitLab Template
===

## 索引

[TOC]

## 注意事項

* 此範例主要是針對大部分過去`Android`常見方式來做範本與說明，近年來Android已主要採用Commandline的形式來方便開發者做相關套件的維護與下載。
* 實證環境的網頁服務`EXPOSE PORT`為`80`，若有需要做更動調整請參考`iiidevops`教學網站內的`.rancher-pipeline`修改說明文件。
* 由於本專案並無`Postman`與`Sideex`的需求，因此專案內iiidevops資料夾內看到的`Postman`與`Sideex`資料夾與相關文件可以無視。
* 由於`Android`專案的特殊性，因此若持續開發上可能會面臨一些需求需要調整的部分，因此詳細修改說明將在下方章節做描述。

### 專案資訊
此為針對此範本的專案資訊，若已有建立專案請無視此部分並將專案程式碼放入到專案內。
* Application Name: "My First App"
* Company Domain: "example.com"

## 修改專案編譯目標
此部分主要是針對Android開發專案在開發上的實際開發目標做調整，首先需要先了解專案開發上所需面臨的專案Android版本最低與目標版本需求(此會影響專案內可用的函式與功能外，對一些硬體與權限存取方式也會有些許的不同)。
### 了解自身專案需求
Android內有多種不同的版本與架構，主要描述文件在專案內的`build.gradle`文件，在此範例中由於專案為app內，因此需參考`app/build.gradle`，在此範例中主要希望主要針對的目標為`Android 4.0.3`至`Android 9`的手機，因此對應的`SDK`版本最低為`15`至`28`。
```
android {
    compileSdkVersion 28 <- 這裡決定編譯時的目標版本
    defaultConfig {
        ...........
        minSdkVersion 15 <- 這裡決定支援的最低目標版本
        targetSdkVersion 28 <- 這裡決定支援的主要目標版本
        ...........
}
```
### 修改iiidevops相關檔案至符合自身專案需求
在這裡會修改兩個檔案，一個是`Dockerfile`另外一個是`.rancher-pipeline.yaml`，需要更改的原因描述如下:
* `Dockerfile`: 主要目的是因為在`iiidevops`內透過`Dockerfile`來編譯產生`Debug`用的`APK`檔案以及透過網頁檔案管理來做實證環境部屬。
    ```
    FROM openjdk:8-jdk AS Builder

    # Just matched `app/build.gradle`
    ENV ANDROID_COMPILE_SDK "28" <- 這裡是編譯版本28
    # Just matched `app/build.gradle`
    ENV ANDROID_BUILD_TOOLS "28.0.3" <- 這裡是Build版本
    # Version from https://developer.android.com/studio/releases/sdk-tools
    ENV ANDROID_SDK_TOOLS "24.4.1" <- 這裡是SDK版本(如果不是很新的SDK 30的話通常是不必去動這個部分)

    ...........
    ```
* `.rancher-pipeline.yaml`: 此則主要是因為在`rancher-pipeleine.yaml`內需要進行Sonarqube掃描，`Sonarqube`針對`JAVA`的掃描機制需要透過`Gradle` Build來進行掃描動作，因此需要針對這裡做調整與修改來完成`Gardle`的編譯，同時在Sonarqube步驟內也會包含`AndroidLint`的測試報告內容。
    ```
    - name: Test--SonarQube for Java(Gradle)
      iiidevops: sonarqube
      steps:
      - runScriptConfig:
          image: library/gradle:jdk11
          shellScript: |
            # 這裡要和你要編譯的Android版本相同在 `app/build.gradle`
            export ANDROID_COMPILE_SDK="28" <- 這裡是編譯版本28
            # 這裡也是要和要編譯的版本相同 `app/build.gradle`
            export ANDROID_BUILD_TOOLS="28.0.3" <- 這裡是Build版本
            # Version from https://developer.android.com/studio/releases/sdk-tools
            export ANDROID_SDK_TOOLS="24.4.1" <- 這裡是SDK版本(如果不是很新的SDK 30的話通常是不必去動這個部分)
            ...........
    ```
  * AndroidLint使用說明: 在此範例中由於是app資料夾內的專案要進行`AndroidLint`分析，因此在`.rancher-pipeline`內會看到與`AndroidLint`相關的步驟會先進行專案的`AndroidLint`測試產生報告並儲存為`xml`，這裡的專案主要儲存在`app`資料夾內因此測試透過`./gradlew :app:lint`而輸出的資料夾目錄為`app/build/reports/lint-results.xml`，通過AndroidLint測試後再將其產生的`xml`報告一併上傳到Sonarqube伺服器內。
      ```
      - name: Test--SonarQube for Java(Gradle)
      iiidevops: sonarqube
      steps:
      - runScriptConfig:
          image: library/gradle:jdk11
          shellScript: |
            ...........
            echo '========== AndroidLint =========='
            ./gradlew :app:lint <- 代表在app資料夾內專案進行AndroidLint Test
            ./gradlew ........... -Dsonar.androidLint.reportPaths=${PWD}/app/build/reports/lint-results.xml ...........
      ```

## 修改專案支援`Sonarqube`掃描
在此範例中將在根目錄內的`build.gradle`做修改，需注意的是`Plugin`需在`buildscript`之後，但是又在其他項目之前，因此順序依序為`buildscript`->`plugins`->其它項目。
```
buildscript {
    ...........
}
// 這裡Plugin添加Sonarqube
plugins {
  id "org.sonarqube" version "3.3"
}
// Plugin在其他的之前
allprojects {
    ...........
}
...........
```

## Dockerfile內選擇性測試
在這裡的部分步驟是非強制性需要去進行的，但是在跑以前若有添加這些步驟可以做簡單驗證，此非必要動作且可能會導致編譯時間過長，在這裡可移除的步驟分為兩個
* 檢查Lint語法 <- 這個步驟會協助產師與寫的測試，如果這個步驟取消的話請一併註解後面的`COPY --from=Builder /app/build/reports/lint-results.html /srv/androidlint網頁結果報告.html`這段。
* 跑專案的Test測試 <- 這個步驟選擇性，由開發者實際的需求做決定。
```
...........
## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#RUN ./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint
RUN ./gradlew :app:lint

## (這裡也建議添加為前置步驟，可以註解掉) <- 這裡可以跑專案內有寫的測試
RUN ./gradlew -Pci --console=plain :app:testDebug
...........
```

### 觀看瀏覽器`html`版本的`AndroidLint`報告
此步驟仰賴`Dockerfile`內添加下列`AndroidLint`這個步驟，因為此步驟會產生兩種檔案，分別是是`xml`與`html`格式的檔案，然後在最後添加上`COPY --from=Builder /app/build/reports/lint-results.html /srv/androidlint網頁結果報告.html`即可在最後的`實證環境`上的檔案瀏覽器上面找到AndroidLint網頁結果報告檔案(`androidlint網頁結果報告.html`)，下載下來後即可透過瀏覽器開啟報告結果。
```
...........
## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#RUN ./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint
RUN ./gradlew :app:lint
...........
COPY --from=Builder /app/build/reports/lint-results.html /srv/androidlint網頁結果報告.html
...........
```
![](https://i.imgur.com/gPJTxgG.png)

## APK測試安裝檔案下載
此APK安裝檔案主要用於一般測試用途，若真的需要Debug請透過IDE透過adb連線到實體手機或是遠端手機(可透過有線或是網路方式來進行adb連線)，在本範例中安裝用的apk檔案在檔案管理內的`apk/debug`資料夾內的`app-debug.apk`檔案
![](https://i.imgur.com/wptYXdu.png)

---------------------------------------------------------------------


## 專案資料夾與檔案格式說明
檔案可按照需求做修改，此主要針對大部分專案規定來進行描述，針對不同專案可能會有些許變化，詳細使用方式請參考iiidevops教學說明文件。

| 型態 | 名稱 | 說明 | 路徑 |
| --- | --- | --- | --- |
| 資料夾 | app | 專案主要程式碼 | 根目錄 |
| 資料夾 | iiidevops | :warning: (不可更動)devops系統測試所需檔案 | 在根目錄 |
| 檔案 | .rancher-pipeline.yml | :warning: (不可更動)devops系統測試所需檔案 | 在根目錄 |
| 檔案 | pipeline_settings.json | :warning: (不可更動)devops系統測試所需檔案 | 在iiidevops資料夾內 |
| 檔案 | app.env | (可調整)實證環境 `web`環境變數添加 | 在iiidevops資料夾內 | 
| 檔案 | postman_collection.json | (可調整)devops newman部屬測試案例檔案 | iiidevops/postman資料夾內 |
| 檔案 | postman_environment.json | (可調整)devops newman部屬測試環境變數檔案 | iiidevops/postman資料夾內 |
| 檔案 | sideex.json | (可調整)devops Sideex部屬測試檔案 | iiidevops/sideex資料夾內 |
| 檔案 | Dockerfile | (可調整)devops k8s環境部屬檔案 | 根目錄 |

## iiidevops
* 專案內`.rancher-pipeline.yml`請勿更動，產品系統設計上不支援pipeline修改，但若預設`README.md`文件內有寫引導說明部分則例外。
* `iiidevops`資料夾內`pipeline_settings.json`請勿更動。
* `postman`資料夾內則是您在devops管理網頁上的Postman-collection(newman)自動測試檔案，devops系統會以`postman`資料夾內檔案做自動測試。
* `Dockerfile`內可能會看到很多來源都加上前墜`dockerhub`，此為必須需求，為使image能從iiidevops產品所架設的`harbor`上作為來源擷取出Docker Hub的image來源。
* 若使用上有任何問題請至`https://www.iiidevops.org/`內的`聯絡方式`頁面做問題回報。



## Reference and FAQ

* [setting-up-gitlab-ci-for-android-projects](https://about.gitlab.com/blog/2018/10/24/setting-up-gitlab-ci-for-android-projects/)

###### tags: `iiidevops Templates README` `Documentation`
