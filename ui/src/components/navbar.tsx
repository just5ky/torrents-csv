import { Component, linkEvent } from 'inferno';
import { SearchParams } from '../interfaces';
import { repoUrl } from '../utils';

interface State {
  searchParams: SearchParams;
}

export class Navbar extends Component<any, State> {
  state: State = {
    searchParams: {
      page: 1,
      q: '',
      type_: 'torrent',
    },
  };

  constructor(props: any, context: any) {
    super(props, context);
    this.fillSearchField();
  }

  render() {
    return <div class="sticky-top">{this.navbar()}</div>;
  }

  navbar() {
    return (
      <nav class="navbar navbar-dark bg-dark p-1 shadow">
        <a class="navbar-brand mx-1" href="#">
          <svg class="icon icon-database mr-2">
            <use xlinkHref="#icon-database"></use>
          </svg>
          Torrents.csv
        </a>
        <div class="navbar-nav ml-auto mr-2">
          <a class="nav-item nav-link" href={repoUrl}>
            <svg class="icon icon-github">
              <use xlinkHref="#icon-github"></use>
            </svg>
          </a>
        </div>
        {this.searchForm()}
      </nav>
    );
  }

  searchForm() {
    return (
      <form
        class="col-12 col-sm-6 m-0 px-1"
        onSubmit={linkEvent(this, this.search)}
      >
        <div class="input-group w-100">
          <input
            class="form-control border-left-0 border-top-0 border-bottom-0 no-outline"
            type="search"
            placeholder="Search..."
            aria-label="Search..."
            required
            minLength={3}
            value={this.state.searchParams.q}
            onInput={linkEvent(this, this.searchChange)}
          ></input>
          <div class="input-group-append">
            <select
              value={this.state.searchParams.type_}
              onInput={linkEvent(this, this.searchTypeChange)}
              class="custom-select border-top-0 border-bottom-0 rounded-0"
            >
              <option disabled>Type</option>
              <option value="torrent">Torrent</option>
              <option value="file">File</option>
            </select>
            <button
              class="btn btn-secondary border-0 rounded-right no-outline"
              type="submit"
            >
              <svg class="icon icon-search">
                <use xlinkHref="#icon-search"></use>
              </svg>
            </button>
          </div>
        </div>
      </form>
    );
  }

  search(i: Navbar, event: any) {
    event.preventDefault();
    i.context.router.history.push(
      `/search/${i.state.searchParams.type_}/${i.state.searchParams.q}/${i.state.searchParams.page}`
    );
  }

  searchChange(i: Navbar, event: any) {
    let searchParams: SearchParams = {
      q: event.target.value,
      page: 1,
      type_: i.state.searchParams.type_,
    };
    i.setState({ searchParams: searchParams });
  }

  searchTypeChange(i: Navbar, event: any) {
    let searchParams: SearchParams = {
      q: i.state.searchParams.q,
      page: 1,
      type_: event.target.value,
    };
    i.setState({ searchParams: searchParams });
  }
  fillSearchField() {
    let splitPath: string[] = this.context.router.route.location.pathname.split(
      '/'
    );
    if (splitPath.length == 5 && splitPath[1] == 'search')
      this.state.searchParams = {
        page: Number(splitPath[4]),
        q: splitPath[3],
        type_: splitPath[2],
      };
  }
}
