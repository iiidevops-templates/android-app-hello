# Just matched `app/build.gradle`
export ANDROID_COMPILE_SDK="28"
# Just matched `app/build.gradle`
export ANDROID_BUILD_TOOLS="28.0.3"
# Version from https://developer.android.com/studio/releases/sdk-tools
export ANDROID_SDK_TOOLS="24.4.1"

export ANDROID_HOME="android-sdk-linux"
export PATH="$PATH:android-sdk-linux/platform-tools/"

echo $PATH

# install OS packages
apt-get --quiet update --yes
apt-get --quiet install --yes wget apt-utils tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev tree
# We use this for xxd hex->binary
apt-get --quiet install --yes vim-common
# install Android SDK
wget --quiet --output-document=android-sdk.tgz https://dl.google.com/android/android-sdk_r${ANDROID_SDK_TOOLS}-linux.tgz
tar --extract --gzip --file=android-sdk.tgz


echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter android-${ANDROID_COMPILE_SDK}
echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter platform-tools
echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter build-tools-${ANDROID_BUILD_TOOLS}
echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-android-m2repository
echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-google_play_services
echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-m2repository

# install FastLane
gem install bundler -v 1.16.6 && bundle install && ls

## 專案程式碼放入
## 檢測放入結果, IF使用者要除錯的話XD
#echo "Before Gradlew"
#ls -a && chmod +x ./gradlew

#echo "Test File Output" >> ./bash_shell_script.txt
## (這裡建議添加為前置步驟，可以註解掉) <- 因為這裡可以檢查專案裡面的結構語法Lint是否正確
#RUN ./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint

echo '========== Android Lint =========='
./gradlew :app:lint

## (這裡也建議添加為前置步驟，可以註解掉) <- 這裡可以跑專案內有寫的測試
./gradlew -Pci --console=plain :app:testDebug

## (這裡產生檔案APK檔案) <- 主要工作
./gradlew assembleDebug
#./gradlew
## 給使用者看產生出來的APK，IF使用者要除錯的話
echo $PWD
cd app && tree
ls -l