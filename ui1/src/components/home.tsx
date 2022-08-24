import { Component } from 'inferno';
import { repoUrl } from '../utils';

export class Home extends Component<any, any> {
  render() {
    return <div class="container">{this.onboard()}</div>;
  }

  onboard() {
    return (
      <p class="text-justify">
        <a href={repoUrl}>Torrents.csv</a> is a <i>collaborative</i> git
        repository of torrents, consisting of a single, searchable{' '}
        <code>torrents.csv</code> file. Its initially populated with a January
        2017 backup of the pirate bay, and new torrents are periodically added
        from various torrents sites. It comes with a self-hostable webserver, a
        command line search, and a folder scanner to add torrents.
        <br />
        <br />
        <a href={repoUrl}>Torrents.csv</a> will only store torrents with at
        least one seeder to keep the file small, will be periodically purged of
        non-seeded torrents, and sorted by seeders descending.
        <br />
        <br />
        API:{' '}
        <code>
          http://torrents-csv.ml/service/search?q=[QUERY]&size=[NUMBER_OF_RESULTS]&page=[PAGE]
        </code>
        <br />
        <br />
        To request more torrents, or add your own, go <a href={repoUrl}>here</a>
        .<br />
        <br />
        Made with <a href="https://www.rust-lang.org">Rust</a>,{' '}
        <a href="https://github.com/BurntSushi/ripgrep">ripgrep</a>,{' '}
        <a href="https://actix.rs/">Actix</a>,{' '}
        <a href="https://www.infernojs.org">Inferno</a>, and{' '}
        <a href="https://www.typescriptlang.org/">Typescript</a>.
      </p>
    );
  }
}
