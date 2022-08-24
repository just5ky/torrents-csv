let host = `${window.location.hostname}`;
let port = `${window.location.port == '4444' ? '8902' : window.location.port}`;
export let endpoint = `${window.location.protocol}//${host}:${port}`;
