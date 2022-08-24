export let repoUrl = 'https://gitea.com/heretic/torrents-csv-server';

export function magnetLink(
  infohash: string,
  name: string,
  index?: number
): string {
  let link = `magnet:?xt=urn:btih:${infohash}&dn=${name}${trackerListToUrl(
    trackerList
  )}`;
  if (index != undefined) {
    link += `&so=${index}`;
  }
  return link;
}

let trackerList: string[] = [
  'udp://tracker.coppersurfer.tk:6969/announce',
  'udp://tracker.open-internet.nl:6969/announce',
  'udp://tracker.leechers-paradise.org:6969/announce',
  'udp://tracker.internetwarriors.net:1337/announce',
  'udp://tracker.opentrackr.org:1337/announce',
  'udp://9.rarbg.to:2710/announce',
  'udp://9.rarbg.me:2710/announce',
  'http://tracker3.itzmx.com:6961/announce',
  'http://tracker1.itzmx.com:8080/announce',
  'udp://exodus.desync.com:6969/announce',
  'udp://explodie.org:6969/announce',
  'udp://ipv4.tracker.harry.lu:80/announce',
  'udp://denis.stalker.upeer.me:6969/announce',
  'udp://tracker.torrent.eu.org:451/announce',
  'udp://tracker.tiny-vps.com:6969/announce',
  'udp://thetracker.org:80/announce',
  'udp://open.demonii.si:1337/announce',
  'udp://tracker4.itzmx.com:2710/announce',
  'udp://tracker.cyberia.is:6969/announce',
  'udp://retracker.netbynet.ru:2710/announce',
];

export function getFileName(path: string): string {
  let lines = path.split('/');
  let out: string = lines[0];

  for (let i = 1; i < lines.length; i++) {
    let tabs = new Array(i + 1).join('  ');
    out += '\n' + tabs + '└─ ' + lines[i];
  }

  return out;
}

function trackerListToUrl(trackerList: string[]): string {
  return trackerList.map(t => '&tr=' + t).join('');
}

export function humanFileSize(bytes: number, si: boolean): string {
  let thresh = si ? 1000 : 1024;
  if (Math.abs(bytes) < thresh) {
    return `${bytes} B`;
  }
  let units = si
    ? ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    : ['KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
  let u = -1;
  do {
    bytes /= thresh;
    ++u;
  } while (Math.abs(bytes) >= thresh && u < units.length - 1);
  return `${bytes.toFixed(1)} ${units[u]}`;
}
