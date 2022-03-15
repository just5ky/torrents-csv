extern crate actix_files;
extern crate actix_web;
extern crate serde;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;
extern crate rusqlite;
#[macro_use]
extern crate failure;
extern crate r2d2;
extern crate r2d2_sqlite;

use actix_files as fs;
use actix_files::NamedFile;
use actix_web::{middleware, web, App, HttpResponse, HttpServer};
use failure::Error;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::params;
use serde_json::Value;
use std::{cmp, env, io, ops::Deref};

const DEFAULT_SIZE: usize = 25;

#[actix_web::main]
async fn main() -> io::Result<()> {
  println!("Access me at {}", endpoint());
  std::env::set_var("RUST_LOG", "actix_web=debug");
  env_logger::init();

  let manager = SqliteConnectionManager::file(torrents_db_file());
  let pool = r2d2::Pool::builder().max_size(15).build(manager).unwrap();

  HttpServer::new(move || {
    App::new()
      .data(pool.clone())
      .wrap(middleware::Logger::default())
      .service(fs::Files::new("/static", front_end_dir()))
      .route("/", web::get().to(index))
      .route("/service/search", web::get().to(search))
  })
  .keep_alive(None)
  .bind(endpoint())?
  .run()
  .await
}

async fn index() -> Result<NamedFile, actix_web::error::Error> {
  Ok(NamedFile::open(front_end_dir() + "/index.html")?)
}

fn front_end_dir() -> String {
  env::var("TORRENTS_CSV_FRONT_END_DIR").unwrap_or_else(|_| "./ui/dist".to_string())
}

fn torrents_db_file() -> String {
  env::var("TORRENTS_CSV_DB_FILE").unwrap_or_else(|_| "./torrents.db".to_string())
}

fn endpoint() -> String {
  env::var("TORRENTS_CSV_ENDPOINT").unwrap_or_else(|_| "0.0.0.0:8902".to_string())
}

#[derive(Deserialize)]
struct SearchQuery {
  q: String,
  page: Option<usize>,
  size: Option<usize>,
  type_: Option<String>,
}

async fn search(
  db: web::Data<r2d2::Pool<SqliteConnectionManager>>,
  query: web::Query<SearchQuery>,
) -> Result<HttpResponse, actix_web::Error> {
  let res = web::block(move || {
    let conn = db.get().unwrap();
    search_query(query, conn)
  })
  .await
  .map(|body| {
    HttpResponse::Ok()
      .header("Access-Control-Allow-Origin", "*")
      .json(body)
  })
  .map_err(actix_web::error::ErrorBadRequest)?;
  Ok(res)
}

fn search_query(
  query: web::Query<SearchQuery>,
  conn: r2d2::PooledConnection<SqliteConnectionManager>,
) -> Result<Value, Error> {
  let q = query.q.trim();
  if q.is_empty() || q.len() < 3 || q == "2020" {
    return Err(format_err!(
      "{{\"error\": \"{}\"}}",
      "Empty query".to_string()
    ));
  }

  let page = query.page.unwrap_or(1);
  let size = cmp::min(100, query.size.unwrap_or(DEFAULT_SIZE));
  let type_ = query.type_.as_ref().map_or("torrent", String::deref);
  let offset = size * (page - 1);

  println!(
    "query = {}, type = {}, page = {}, size = {}",
    q, type_, page, size
  );

  let res = if type_ == "file" {
    let results = torrent_file_search(conn, q, size, offset)?;
    serde_json::to_value(&results).unwrap()
  } else {
    let results = torrent_search(conn, q, size, offset)?;
    serde_json::to_value(&results).unwrap()
  };

  Ok(res)
}

#[derive(Debug, Serialize, Deserialize)]
struct Torrent {
  infohash: String,
  name: String,
  size_bytes: isize,
  created_unix: u32,
  seeders: u32,
  leechers: u32,
  completed: Option<u32>,
  scraped_date: u32,
}

fn torrent_search(
  conn: r2d2::PooledConnection<SqliteConnectionManager>,
  query: &str,
  size: usize,
  offset: usize,
) -> Result<Vec<Torrent>, Error> {
  let stmt_str = "select * from torrents where name like '%' || ?1 || '%' limit ?2, ?3";
  let mut stmt = conn.prepare(stmt_str)?;
  let torrent_iter = stmt.query_map(
    params![
      query.replace(' ', "%"),
      offset.to_string(),
      size.to_string(),
    ],
    |row| {
      Ok(Torrent {
        infohash: row.get(0)?,
        name: row.get(1)?,
        size_bytes: row.get(2)?,
        created_unix: row.get(3)?,
        seeders: row.get(4)?,
        leechers: row.get(5)?,
        completed: row.get(6)?,
        scraped_date: row.get(7)?,
      })
    },
  )?;

  let mut torrents = Vec::new();
  for torrent in torrent_iter {
    torrents.push(torrent.unwrap());
  }
  Ok(torrents)
}

#[derive(Debug, Serialize, Deserialize)]
struct File {
  infohash: String,
  index_: u32,
  path: String,
  size_bytes: isize,
  created_unix: u32,
  seeders: u32,
  leechers: u32,
  completed: Option<u32>,
  scraped_date: u32,
}

fn torrent_file_search(
  conn: r2d2::PooledConnection<SqliteConnectionManager>,
  query: &str,
  size: usize,
  offset: usize,
) -> Result<Vec<File>, Error> {
  let stmt_str = "select * from files where path like '%' || ?1 || '%' limit ?2, ?3";
  let mut stmt = conn.prepare(stmt_str).unwrap();
  let file_iter = stmt.query_map(
    params![
      query.replace(' ', "%"),
      offset.to_string(),
      size.to_string(),
    ],
    |row| {
      Ok(File {
        infohash: row.get(0)?,
        index_: row.get(1)?,
        path: row.get(2)?,
        size_bytes: row.get(3)?,
        created_unix: row.get(4)?,
        seeders: row.get(5)?,
        leechers: row.get(6)?,
        completed: row.get(7)?,
        scraped_date: row.get(8)?,
      })
    },
  )?;

  let mut files = Vec::new();
  for file in file_iter {
    files.push(file.unwrap());
  }
  Ok(files)
}

#[cfg(test)]
mod tests {
  use r2d2_sqlite::SqliteConnectionManager;

  #[test]
  fn test() {
    let manager = SqliteConnectionManager::file(super::torrents_db_file());
    let pool = r2d2::Pool::builder().max_size(15).build(manager).unwrap();
    let conn = pool.get().unwrap();
    let results = super::torrent_search(conn, "sherlock", 10, 0);
    assert!(results.unwrap().len() > 2);
    // println!("Query took {:?} seconds.", end - start);
  }
}
