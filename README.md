Android Example From GitLab Template
===

## 索引

[TOC]

## 注意事項

* 此範例主要是針對大部分過去`Android`常見方式來做範本與說明，近年來Android已主要採用Commandline的形式來方便開發者做相關套件的維護與下載。
* 實證環境的網頁服務`EXPOSE PORT`為`80`，若有需要做更動調整請參考`iiidevops`教學網站內的`.rancher-pipeline`修改說明文件。
* 由於`Android`專案的特殊性，因此若持續開發上可能會面臨一些需求需要調整的部分，因此詳細修改說明將在下方章節做描述。

### 專案資訊
此為範本的專案資訊，若已有建立專案請可忽略這部分並直接將專案程式碼放入到專案內。
* Application Name: "My First App"
* Company Domain: "example.com"

## 修改專案編譯目標
此部分是針對Android專案實際開發的目標進行調整，首先要先確認專案預計支援的Android最低與目標版本需求(此會影響專案內可用的函式與功能外，對一些硬體與權限存取方式也會有些許的不同)。
### 了解自身專案需求
Android內有多種不同的版本與架構，主要描述文件在專案內的`build.gradle`文件，在此範例中由於專案目錄為app，因此需參考`app/build.gradle`，在此範例中主要希望主要針對的目標為`Android 4.0.3`至`Android 9`的手機，因此對應的`SDK`版本最低為`15`至`28`。
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
在這裡會修改兩個檔案，一個是`Dockerfile.sh`另外一個是`SonarScan.sh`，需要更改的原因描述如下:
* `Dockerfile.sh`: 主要目的是因為在`iiidevops`內透過`Dockerfile.sh`來編譯產生`Debug`用的`APK`檔案以及透過網頁檔案管理來做實證環境部屬與後續 CMAS 的 APK 黑箱弱點掃描。
```
# Just matched `app/build.gradle`
export ANDROID_COMPILE_SDK="28" <- 這裡是編譯版本28
# Just matched `app/build.gradle`
export ANDROID_BUILD_TOOLS="28.0.3" <- 這裡是Build版本
# Version from https://developer.android.com/studio/releases/sdk-tools
export ANDROID_SDK_TOOLS="24.4.1" <- 這裡是SDK版本(如果不是很新的SDK 30的話通常是不必去動這個部分)    
    ...........
```
* `SonarScan.sh`: 此檔主要是要進行Sonarqube掃描，`Sonarqube`針對`JAVA`的掃描機制需要透過`Gradle` Build來進行掃描動作，因此需要針對這裡做調整與修改來完成`Gardle`的編譯，同時在Sonarqube步驟內也會包含`AndroidLint`的測試報告內容。
```
# Just matched `app/build.gradle`
export ANDROID_COMPILE_SDK="28" <- 這裡是編譯版本28
# Just matched `app/build.gradle`
export ANDROID_BUILD_TOOLS="28.0.3" <- 這裡是Build版本
# Version from https://developer.android.com/studio/releases/sdk-tools
export ANDROID_SDK_TOOLS="24.4.1" <- 這裡是SDK版本(如果不是很新的SDK 30的話通常是不必去動這個部分)    
    ...........
```
  * AndroidLint使用說明: 在此範例中由於是app資料夾內的專案要進行`AndroidLint`分析，因此在`Dockerfile.sh` 與 `SonarScan.sh` 內會看到與`AndroidLint`的相關步驟對專案程式碼測試產生報告並儲存為`xml`檔，這裡的專案主要儲存在`app`資料夾內因此測試透過`./gradlew :app:lint` , 所輸出的資料夾目錄為`app/build/reports/lint-results.xml`，通過AndroidLint測試後再將其產生的`xml`報告一併上傳到Sonarqube伺服器內。
  * Dockerfile.sh
  ```
    ...........
## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint
./gradlew :app:lint
    ...........
  ```
  * SonarScan.sh
  ```
    ...........
echo '========== Android Lint =========='
chmod -R 777 . 
./gradlew :app:lint
    ...........
echo '========== Android SonarQube =========='
./gradlew -Dsonar.host.url=http://sonarqube-server-service.default:9000\
	-Dsonar.projectKey=${CICD_GIT_REPO_NAME} -Dsonar.projectName=${CICD_GIT_REPO_NAME}\
	-Dsonar.projectVersion=${CICD_GIT_BRANCH}:${CICD_GIT_COMMIT} -Dsonar.androidLint.reportPaths=${PWD}/app/build/reports/lint-results.xml\
	-Dsonar.log.level=DEBUG -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=600\
	-Dsonar.login=$SONAR_TOKEN sonarqube
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

## Dockerfile.sh 內選擇性測試
在這裡的部分步驟可依實際需要去進行，這些步驟能做簡單的驗證，但可能會讓編譯時間變更長，因此簡要說明如下:
```
...........
## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint
./gradlew :app:lint

## (這裡也建議添加為前置步驟，可以註解掉) <- 這裡可以跑專案內有寫的測試
./gradlew -Pci --console=plain :app:testDebug
...........
```

### 觀看瀏覽器`html`版本的`AndroidLint`報告
此步驟是在`Dockerfile.sh`內添加下列`AndroidLint`來產生網頁檔案瀏覽與下載功能

預設登入帳號為 **admin** , 密碼為 **iiidevops**
可自行修改 iiidevops/app.env 內的 **FB_USERNAME** 與 **FB_PASSWORD** 的設定值來更改登入帳號與密碼

密碼採用 bcrypt 編碼加密, 可以使用 [Bcrypt-Generator.com](https://bcrypt-generator.com/) 網頁工具來產生

由 `Dockerfile.sh` 步驟執行後產生兩種檔案，分別是`xml`與`html`格式的檔案，然後在 `Dockerfile` 建立專案實證環境網站的映像檔中, 將相關檔案複製進去, 即可在最後的`實證環境`上的檔案瀏覽器上面找到AndroidLint網頁結果報告檔案(`androidlint_report.html`)，下載後可透過瀏覽器開啟報告內容。
  * Dockerfile
  ```
...........
FROM dockerhub/filebrowser/filebrowser:latest
COPY ./app/build/outputs ./srv
COPY ./app/build/reports/lint-results.html ./srv/androidlint_report.html
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
| 檔案 | Dockerfile | (可調整)devops k8s環境部屬檔案 | 根目錄 |
| 檔案 | Dockerfile.sh | (可調整) Android 編譯使用 | 根目錄 |
| 檔案 | SonarScan.sh | (可調整) 整合 SonarQube 使用 | 根目錄 |
| 檔案 | build.gradle | (可調整) Android 編譯使用 | 根目錄 |

## iiidevops
* 專案內`.rancher-pipeline.yml`請勿更動，產品系統設計上不支援pipeline修改，但若預設`README.md`文件內有寫引導說明部分則例外。
* `iiidevops`資料夾內`pipeline_settings.json`請勿更動。
* `Dockerfile`內可能會看到很多來源都加上前墜`dockerhub`，此為使image能從iiidevops產品所架設的`harbor`擔任Docker Hub的 Proxy , 提高至 Internet 抓取 image 的效率。
* 若使用上有任何問題請至 https://www.iiidevops.org/ 內的`聯絡方式`頁面做問題回報。



## Reference and FAQ

* [setting-up-gitlab-ci-for-android-projects](https://about.gitlab.com/blog/2018/10/24/setting-up-gitlab-ci-for-android-projects/)
.

###### tags: `iiidevops Templates README` `Documentation`
