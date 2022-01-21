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

echo '========== Android Lint =========='
chmod -R 777 . 
./gradlew :app:lint
export SONAR_TOKEN=$(cat sonar-token.txt) && ./gradlew -Dsonar.host.url=http://sonarqube-server-service.default:9000\
	-Dsonar.projectKey=${CICD_GIT_REPO_NAME} -Dsonar.projectName=${CICD_GIT_REPO_NAME}\
	-Dsonar.projectVersion=${CICD_GIT_BRANCH}:${CICD_GIT_COMMIT} -Dsonar.androidLint.reportPaths=${PWD}/app/build/reports/lint-results.xml\
	-Dsonar.log.level=DEBUG -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=600\
	-Dsonar.login=$SONAR_TOKEN sonarqube
