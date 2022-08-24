export interface SearchParams {
  q: string;
  page: number;
  size?: number;
  type_: string;
}

export interface Results {
  torrents: Torrent[];
}

export interface Torrent {
  infohash: string;
  name: string;
  size_bytes: number;
  created_unix: number;
  seeders: number;
  leechers: number;
  completed: number;
  scraped_date: number;
  index_: number;
  path: string;
}
