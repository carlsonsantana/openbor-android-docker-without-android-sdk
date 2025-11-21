FROM archlinux:base-devel-20251019.0.436919 as android-sdk-builder

# Build arguments
ARG SDK_VERSION="9477386_latest"
ARG APKTOOL_VERSION="2.12.1"

# Install dependencies
RUN pacman -Syu --noconfirm && \
  pacman -S jdk11-openjdk jdk17-openjdk unzip --noconfirm && \
  rm -R /var/cache/pacman/pkg/*
RUN mkdir /apktool && \
  curl -L "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_""$APKTOOL_VERSION"".jar" --output /apktool/apktool.jar

# Copy OpenBOR repository
COPY openbor /openbor

# Create version header file
WORKDIR /openbor/engine
RUN ./version.sh && \
  sed -i "s|org\.openbor\.engine|aaaa.bbbbb.ccccc|g" /openbor/engine/android/app/build.gradle && \
  sed -i "s|\"Openbor\"|\"ZZZZZ\"|g" /openbor/engine/android/app/build.gradle

# Create source builder
WORKDIR /
RUN export ANDROID_SDK_ROOT=/android-sdk && \
  mkdir /android-sdk && \
  curl -L https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}.zip --output /android-sdk/cmdline-tools.zip && \
  unzip /android-sdk/cmdline-tools.zip && \
  mkdir -p /android-sdk/cmdline-tools && \
  mv cmdline-tools /android-sdk/cmdline-tools/latest && \
  cd /android-sdk/cmdline-tools/latest/bin && \
  archlinux-java set java-17-openjdk && \
  echo "y" | ./sdkmanager --install "build-tools;29.0.3" "platform-tools" "platforms;android-29" "tools" "ndk-bundle" && \
  cd /openbor/engine/android && \
  archlinux-java set java-11-openjdk && \
  keytool -genkey -noprompt -v \
    -keystore game_certificate.jks \
    -storepass 123456 \
    -keypass 123456 \
    -alias a \
    -keyalg RSA \
    -dname "CN=gamename.mycompany.com, OU=O, O=O, L=O, S=O, C=US" && \
  printf "storePassword=123456\nkeyPassword=123456\nkeyAlias=a\nstoreFile=/openbor/engine/android/game_certificate.jks\n" > keystore.properties && \
  touch /openbor/engine/android/app/src/main/assets/bor.pak && \
  ./gradlew assembleRelease --no-daemon --no-build-cache && \
  archlinux-java set java-17-openjdk && \
  java -jar /apktool/apktool.jar d /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk -o /openbor-android && \
  rm keystore.properties game_certificate.jks /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk && \
  rm /openbor/engine/android/app/src/main/res/drawable-hdpi/icon.png && \
  rm /openbor/engine/android/app/src/main/res/drawable-ldpi/icon.png && \
  rm /openbor/engine/android/app/src/main/res/drawable-mdpi/icon.png && \
  rm /openbor/engine/android/app/src/main/assets/bor.pak && \
  rm -R /android-sdk ~/.gradle ~/.android && \
  unset ANDROID_SDK_ROOT


# Another image with only used resources
FROM eclipse-temurin:17.0.17_10-jre-alpine-3.22

# Environment variables
ENV GAME_APK_NAME "com.mycompany.gamename"
ENV GAME_NAME "Game Name"

# Install dependencies
RUN apk --update --no-cache add imagemagick

# Copy files from previous build
RUN mkdir /apktool
COPY --from=android-sdk-builder /apktool/apktool.jar /apktool/apktool.jar
COPY --from=android-sdk-builder /openbor-android /openbor-android

# Volumes
RUN mkdir /output
VOLUME /bor.pak
VOLUME /icon.png
VOLUME /output

# Run build
WORKDIR /
COPY run.sh /
CMD ["sh", "/run.sh"]
