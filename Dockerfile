#ARG RUST_BUILDER_IMAGE=rust:alpine

FROM dessalines/torrents-csv-server:latest as repack

# Front end
#FROM node:alpine as node
#WORKDIR /app/ui

# Cache deps
#COPY ui/package.json ui/yarn.lock ./
#RUN yarn install --pure-lockfile

# Build the UI
#COPY /ui /app/ui
#RUN yarn build

# Build the torrents.db file
#FROM alpine:3 as db_file_builder
#RUN apk add sed sqlite bash coreutils tree
#WORKDIR /app
#COPY data data
#WORKDIR /app/data/scripts
#RUN pwd && \
#    tree /app/data && \
#    ./import_to_sqlite_fast.sh && \
#    tree /app/data

#FROM $RUST_BUILDER_IMAGE as chef
#USER root
#RUN cargo install cargo-chef
#WORKDIR /app

# Chef plan
#FROM chef as planner
#COPY /Cargo.toml /Cargo.lock ./
#COPY /src src
#RUN cargo chef prepare --recipe-path recipe.json

# Chef build
#FROM chef as builder
#ARG CARGO_BUILD_TARGET=aarch64-unknown-linux-musl
#ARG RUSTRELEASEDIR="release"

#COPY --from=planner /app/recipe.json ./recipe.json
#RUN cargo chef cook --release --target ${CARGO_BUILD_TARGET} --recipe-path recipe.json
FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx

FROM --platform=$BUILDPLATFORM rust:alpine as base
RUN apk add clang lld git file tree musl-dev
COPY --from=xx / /

FROM base as builder
ARG TARGETPLATFORM
RUN xx-info env
ARG CARGO_BUILD_TARGET=aarch64-unknown-linux-musl
ARG RUSTRELEASEDIR="release"
WORKDIR /app
RUN xx-apk add --no-cache musl-dev
RUN rustup target add aarch64-unknown-linux-musl
COPY Cargo.toml Cargo.lock ./
COPY src src
RUN xx-cargo build --release --config net.git-fetch-with-cli=true --target $CARGO_BUILD_TARGET --target-dir /app/bin
RUN xx-verify --static /app/bin/$CARGO_BUILD_TARGET/release/torrents-csv-service && \
    cp /app/bin/$CARGO_BUILD_TARGET/release/torrents-csv-service /app/torrents-csv-service

# reduce binary size
FROM alpine as stripper
RUN apk add binutils
WORKDIR /app
COPY --from=builder /app/torrents-csv-service /app/torrents-csv-service
RUN strip /app/torrents-csv-service
#RUN strip ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service
#RUN cp ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service /app/torrents-csv-service

# The runner
FROM alpine
RUN addgroup -S myuser && adduser -S myuser -G myuser
ENV TORRENTS_CSV_DB_FILE=/app/torrents.db 
ENV TORRENTS_CSV_FRONT_END_DIR=/app/dist
# Copy resources
COPY --from=stripper /app/torrents-csv-service /app/torrents-csv-service
COPY --from=repack /app/dist /app/dist
COPY --from=repack /app/torrents.db /app/torrents.db
EXPOSE 8080
USER myuser
CMD ["/app/torrents-csv-service"]
