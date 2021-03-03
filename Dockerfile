FROM alpine as files

WORKDIR /files

RUN apk add -U unzip

ARG GODOT_VERSION="3.5.2"
ARG RELEASE_NAME="stable"

# This is only needed for non-stable builds (alpha, beta, RC)
# e.g. SUBDIR "/beta3"
# Use an empty string "" when the RELEASE_NAME is "stable"
ARG SUBDIR ""

RUN wget -O /tmp/godot.zip https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64.zip
RUN unzip /tmp/godot.zip -d /tmp/godot
RUN mkdir -p godot
RUN mv /tmp/godot/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless.64 /tmp/godot/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64/godot
RUN mv /tmp/godot/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_linux_headless_64/* /files/godot

RUN wget -O /tmp/godot_templates.tpz https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz
RUN unzip /tmp/godot_templates.tpz -d /tmp/godot_templates
RUN mkdir -p templates/${GODOT_VERSION}.${RELEASE_NAME}.mono
RUN mv /tmp/godot_templates/templates/* /files/templates/${GODOT_VERSION}.${RELEASE_NAME}.mono

RUN wget -O /tmp/android_sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
RUN unzip /tmp/android_sdk.zip -d /tmp/android_sdk
RUN mv /tmp/android_sdk/* /files

FROM mono:6.12.0.182

USER root

ENV DEBIAN_FRONTEND=noninteractive
ARG ANDROID_COMPILE_SDK=32
ARG ANDROID_BUILD_TOOLS=32.0.0

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-11-jdk-headless && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=files /files/godot /usr/local/bin
COPY --from=files /files/templates /root/.local/share/godot/templates
COPY --from=files /files/cmdline-tools /opt/android-sdk/cmdline-tools/latest

RUN  yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses
RUN  /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-$ANDROID_COMPILE_SDK" "build-tools;${ANDROID_BUILD_TOOLS}"

RUN godot -e -v -q \
        && echo 'export/android/android_sdk_path = "/opt/android-sdk"' >> ~/.config/godot/editor_settings-3.tres
