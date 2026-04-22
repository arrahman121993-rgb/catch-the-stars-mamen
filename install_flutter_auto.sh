#!/bin/bash
# 1. Update sistem Ubuntu
apt update && apt upgrade -y
apt install -y curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk wget

# 2. Ambil Flutter SDK
mkdir -p /opt
cd /opt
if [ ! -d "/opt/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 3. Ambil Alat Android SDK (Command Line Tools)
mkdir -p /opt/android-sdk/cmdline-tools
cd /opt/android-sdk/cmdline-tools
if [ ! -d "/opt/android-sdk/cmdline-tools/latest" ]; then
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q *latest.zip
  mv cmdline-tools latest
  rm *latest.zip
fi

# 4. Seting PATH biar Flutter & Android SDK kedeteksi
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/android-sdk/cmdline-tools/latest/bin"' >> ~/.bashrc
export PATH="$PATH:/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin"
export ANDROID_HOME=/opt/android-sdk

# 5. Terima Lisensi Android (Otomatis)
yes | sdkmanager --licenses --sdk_root=/opt/android-sdk

# 6. Cek Status Akhir
flutter doctor
