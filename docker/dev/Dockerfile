FROM node:10-jessie as node
WORKDIR /app/ui

# Cache deps
COPY server/ui/package.json server/ui/yarn.lock ./
RUN yarn install --pure-lockfile

# Build 
COPY server/ui /app/ui
RUN yarn build

FROM rust:1.42 as rust

# Install musl
RUN apt-get update
RUN apt-get install musl-tools -y
RUN rustup target add x86_64-unknown-linux-musl

# Cache deps
WORKDIR /app
RUN USER=root cargo new server
WORKDIR /app/server/service
COPY server/service/Cargo.toml server/service/Cargo.lock ./
RUN  mkdir -p ./src/bin \
  && echo 'fn main() { println!("Dummy") }' > ./src/bin/main.rs 
RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl
RUN rm -f ./target/x86_64-unknown-linux-musl/release/deps/torrents-csv-*
COPY server/service/src ./src/

# build for release
RUN RUSTFLAGS=-Clinker=musl-gcc cargo build --frozen --release --target=x86_64-unknown-linux-musl

FROM alpine:3.10
  
# Copy resources
COPY --from=rust /app/server/service/target/x86_64-unknown-linux-musl/release/torrents-csv-service /app/
COPY --from=node /app/ui/dist /app/dist
RUN addgroup -g 1000 torrents-csv-service
RUN adduser -D -s /bin/sh -u 1000 -G torrents-csv-service torrents-csv-service
RUN chown torrents-csv-service:torrents-csv-service /app/torrents-csv-service
USER torrents-csv-service
EXPOSE 8080
CMD ["/app/torrents-csv-service"]
