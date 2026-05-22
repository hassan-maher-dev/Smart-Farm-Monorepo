# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app

# Copy the app files
COPY . .

# Run flutter commands
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app with NGINX
FROM nginx:alpine

# Copy the compiled web files from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy the custom NGINX configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]