ARG RUST_BUILDER_IMAGE=rust:alpine

# Front end
FROM node:10-jessie as node
WORKDIR /app/ui

# Cache deps
COPY ui/package.json ui/yarn.lock ./
RUN yarn install --pure-lockfile

# Build the UI
COPY /ui /app/ui
RUN yarn build

# Build the torrents.db file
FROM alpine:3.17.0 as db_file_builder
WORKDIR /app
RUN apk add sed sqlite bash coreutils
COPY /data ./data
COPY /build_sqlite.sh .
RUN ./build_sqlite.sh

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

FROM $RUST_BUILDER_IMAGE as builder
ARG CARGO_BUILD_TARGET=aarch64-unknown-linux-musl
ARG RUSTRELEASEDIR="release"
WORKDIR /app
RUN apk add --no-cache musl-dev
RUN rustup target add aarch64-unknown-linux-musl
COPY /Cargo.toml /Cargo.lock ./
COPY /src src
RUN cargo build --release --target ${CARGO_BUILD_TARGET}

# reduce binary size
RUN strip ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service
RUN cp ./target/$CARGO_BUILD_TARGET/$RUSTRELEASEDIR/torrents-csv-service /app/torrents-csv-service

# The runner
FROM alpine
RUN addgroup -S myuser && adduser -S myuser -G myuser
ENV TORRENTS_CSV_DB_FILE=/app/torrents.db 
ENV TORRENTS_CSV_FRONT_END_DIR=/app/dist
# Copy resources
COPY --from=builder /app/torrents-csv-service /app/
COPY --from=node /app/ui/dist /app/dist
COPY --from=db_file_builder /app/torrents.db /app/torrents.db
EXPOSE 8080
USER myuser
CMD ["/app/torrents-csv-service"]
