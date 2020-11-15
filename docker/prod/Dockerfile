ARG RUST_BUILDER_IMAGE=ekidd/rust-musl-builder:stable

# Front end
FROM node:10-jessie as node
WORKDIR /app/ui

# Cache deps
COPY ui/package.json ui/yarn.lock ./
RUN yarn install --pure-lockfile

# Build the UI
COPY ./ui /app/ui
RUN yarn build

# Build the torrents.db file
FROM ubuntu:groovy as db_file_builder
WORKDIR /app
RUN apt-get -y update
RUN apt-get -y install sqlite3
COPY ./data ./data
COPY ./build_sqlite.sh .
RUN ./build_sqlite.sh

# Rust cargo chef build
FROM $RUST_BUILDER_IMAGE as planner
WORKDIR /app
# We only pay the installation cost once, 
# it will be cached from the second build onwards
RUN cargo install cargo-chef --version 0.1.6
COPY ./Cargo.toml ./Cargo.lock .
COPY ./src src
RUN ls
RUN cargo chef prepare --recipe-path recipe.json

FROM $RUST_BUILDER_IMAGE as cacher

ARG CARGO_BUILD_TARGET=x86_64-unknown-linux-musl

WORKDIR /app
RUN cargo install cargo-chef --version 0.1.6
COPY --from=planner /app/recipe.json ./recipe.json
RUN cargo chef cook --release --target ${CARGO_BUILD_TARGET} --recipe-path recipe.json

FROM $RUST_BUILDER_IMAGE as builder

ARG CARGO_BUILD_TARGET=x86_64-unknown-linux-musl
ARG RUSTRELEASEDIR="release"

WORKDIR /app
COPY ./Cargo.toml ./Cargo.lock .
COPY ./src src
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /home/rust/.cargo /home/rust/.cargo
RUN cargo build --release

# reduce binary size
RUN strip ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service

RUN cp ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service /app/torrents-csv-service

# The runner
FROM alpine:3.12
  
# Copy resources
COPY --from=builder /app/torrents-csv-service /app/
COPY --from=node /app/ui/dist /app/dist
COPY --from=db_file_builder /app/torrents.db /app/torrents.db
RUN addgroup -g 1000 torrents-csv-service
RUN adduser -D -s /bin/sh -u 1000 -G torrents-csv-service torrents-csv-service
RUN chown torrents-csv-service:torrents-csv-service /app/torrents-csv-service
USER torrents-csv-service
EXPOSE 8080
CMD ["/app/torrents-csv-service"]
