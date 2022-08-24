const fs = require('fs'),
  readTorrent = require('read-torrent'),
  argv = require('minimist')(process.argv.slice(2)),
  readline = require('readline');

var scannedCsvHashes = new Set();

var torrentFilesCsv = '../torrent_files.csv';
console.log(`Scanning torrent files from ${argv.dir} into ${torrentFilesCsv} ...`);
main();

async function main() {
  await fillScannedHashes();
  scanFolder();
}

async function fillScannedHashes() {
  console.log(`Filling CSV hashes...`);
  const fileStream = fs.createReadStream(torrentFilesCsv);

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  for await (const line of rl) {
    var hash = line.split(';')[0];
    scannedCsvHashes.add(hash);
  }

  scannedCsvHashes.delete('infohash');
}

async function scanFolder() {
  console.log('Scanning dir: ' + argv.dir + '...');

  var files = fs.readdirSync(argv.dir).filter(f => {
    var sp = f.split('.');
    var ext = sp[1];
    var hash = sp[0];
    var fullPath = argv.dir + '/' + f;
    // It must be a torrent file,
    // must not be in the CSV file
    // must have a file size
    // must be in infohash format length
    return (ext == 'torrent' &&
      !scannedCsvHashes.has(hash) &&
      getFilesizeInBytes(fullPath) > 0) &&
      hash.length == 40;
  });

  for (file of files) {
    var fullPath = argv.dir + '/' + file;
    console.log(`Scanning File ${fullPath}`);
    var torrent = await read(fullPath).catch(e => console.log(e));
    await writeFile(torrent);
  }
  console.log('Done.');
}

function writeFile(torrent) {
  for (const infohash in torrent) {
    let files = torrent[infohash];
    for (const file of files) {
      let csvRow = `${infohash};${file.i};${file.p};${file.l}\n`;
      fs.appendFile(torrentFilesCsv, csvRow, function (err) {
        if (err) throw err;
      });

    }
  }
}

function getFilesizeInBytes(filename) {
  var stats = fs.statSync(filename);
  var fileSizeInBytes = stats["size"];
  return fileSizeInBytes;
}

function read(uri, options) {
  return new Promise((resolve, reject) => {
    readTorrent(uri, (err, info) => {
      if (!err) {
        // Removing some extra fields from files
        if (info.files) {
          info.files.forEach((f, i) => {
            f.i = i;
            f.p = f.path;
            f.l = f.length;
            delete f.name;
            delete f.offset;
            delete f.path;
            delete f.length;
          });
        }

        resolve({ [info.infoHash]: info.files });
      } else {
        console.error('Error in read-torrent: ' + err.message + ' for torrent uri: ' + uri);
        reject(err);
      }
    });
  });
}
