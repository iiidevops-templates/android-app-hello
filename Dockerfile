# This Dockerfile creates a static build image for CI

FROM openjdk:8-jdk AS Builder

# Just matched `app/build.gradle`
ENV ANDROID_COMPILE_SDK "28"
# Just matched `app/build.gradle`
ENV ANDROID_BUILD_TOOLS "28.0.3"
# Version from https://developer.android.com/studio/releases/sdk-tools
ENV ANDROID_SDK_TOOLS "24.4.1"

ENV ANDROID_HOME /android-sdk-linux
ENV PATH="${PATH}:/android-sdk-linux/platform-tools/"

# install OS packages
RUN apt-get --quiet update --yes
RUN apt-get --quiet install --yes wget apt-utils tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev
# We use this for xxd hex->binary
RUN apt-get --quiet install --yes vim-common
# install Android SDK
RUN wget --quiet --output-document=android-sdk.tgz https://dl.google.com/android/android-sdk_r${ANDROID_SDK_TOOLS}-linux.tgz
RUN tar --extract --gzip --file=android-sdk.tgz
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter android-${ANDROID_COMPILE_SDK}
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter platform-tools
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter build-tools-${ANDROID_BUILD_TOOLS}
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-android-m2repository
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-google_play_services
RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-m2repository
# install FastLane
COPY Gemfile.lock .
COPY Gemfile .
RUN gem install bundler -v 1.16.6
RUN bundle install

## 輔助看打包檔案指令XDDD
RUN apt-get --quiet install --yes tree

## 專案程式碼放入
COPY . ./
## 檢測放入結果, IF使用者要除錯的話XD
RUN ls -a && chmod +x ./gradlew

## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#RUN ./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint
RUN ./gradlew :app:lint

## (這裡也建議添加為前置步驟，可以註解掉) <- 這裡可以跑專案內有寫的測試
RUN ./gradlew -Pci --console=plain :app:testDebug

## (這裡產生檔案APK檔案) <- 主要工作
RUN ./gradlew assembleDebug
## 給使用者看產生出來的APK，IF使用者要除錯的話
RUN echo $PWD
RUN cd /app/build/outputs/ && tree

# https://filebrowser.org/installation
# https://filebrowser.org/configuration/authentication-method
FROM filebrowser/filebrowser
COPY --from=Builder /app/build/outputs /srv
COPY --from=Builder /app/build/reports/lint-results.html /srv/androidlint網頁結果報告.html
RUN cd /srv && ls -a
