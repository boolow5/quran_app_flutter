FROM ubuntu AS build

RUN apt-get update
RUN apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git 
ENV PATH="/flutter/bin:${PATH}"
COPY . /app
WORKDIR /app
RUN flutter doctor -v
RUN flutter clean
RUN flutter build web || echo "expected fail (build triggered to preload web sdk)"
FROM nginx
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80