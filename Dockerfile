# Start from Ubuntu
FROM ubuntu:22.04 AS build

# Install required dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Set Flutter version (latest stable)
ENV FLUTTER_VERSION=3.22.1
ENV FLUTTER_HOME=/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 ${FLUTTER_HOME}
RUN flutter --version

WORKDIR /app

# Copy pubspec files and install dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the app and build for web
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Use nginx to serve the app
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"] 