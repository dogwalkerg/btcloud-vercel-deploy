const EMPTY_PLUGIN_LIST = {
  list: [],
  type: [],
  ip: '127.0.0.1',
  serverid: '',
  uid: 1,
  pro: -1,
  ltd: 1849472000,
  beta: 0,
  skey: '',
  aln: 'AES encrypted string',
};

function trimSlash(value) {
  return String(value || '').replace(/\/+$/, '');
}

function getPath(req) {
  const value = req.query && req.query.path;
  if (Array.isArray(value)) return value.join('/');
  return String(value || '');
}

function getBody(req) {
  if (!req.body) return undefined;
  if (typeof req.body === 'string' || Buffer.isBuffer(req.body)) return req.body;
  return new URLSearchParams(req.body).toString();
}

function buildUpstreamPath(path) {
  if (path.startsWith('down/')) return `/${path}`;
  return `/api/${path}`;
}

function appendQuery(url, req) {
  const target = new URL(url);
  const incoming = new URL(req.url || '/', 'http://localhost');
  incoming.searchParams.forEach((value, key) => {
    if (key !== 'path') target.searchParams.append(key, value);
  });
  return target.toString();
}

function fallback(path, res) {
  if (path === 'SetupCount') return res.status(200).send('ok');
  if (path === 'panel/get_version') return res.status(200).send('11.8.0');
  if (path === 'wpanel/get_version') return res.status(200).send('8.5.2');
  if (path === 'bt_monitor/latest_version') {
    return res.status(200).json({ version: '2.3.3', description: 'No update log', create_time: '2025-08-12' });
  }
  if (
    path === 'panel/get_soft_list' ||
    path === 'panel/get_soft_list_test' ||
    path === 'panel/get_plugin_list' ||
    path === 'wpanel/get_soft_list' ||
    path === 'wpanel/get_soft_list_test'
  ) {
    return res.status(200).json(EMPTY_PLUGIN_LIST);
  }
  return res.status(404).json({ status: false, msg: 'not found' });
}

module.exports = async (req, res) => {
  const path = getPath(req);
  const upstream = trimSlash(process.env.BTCLOUD_UPSTREAM || process.env.BT_CLOUD_UPSTREAM);
  if (!upstream) return fallback(path, res);

  try {
    const method = req.method || 'GET';
    const body = method === 'GET' || method === 'HEAD' ? undefined : getBody(req);
    const upstreamUrl = appendQuery(upstream + buildUpstreamPath(path), req);
    const response = await fetch(upstreamUrl, {
      method,
      headers: body ? { 'content-type': 'application/x-www-form-urlencoded' } : undefined,
      body,
    });
    const buffer = Buffer.from(await response.arrayBuffer());
    res.status(response.status);
    response.headers.forEach((value, key) => {
      const lower = key.toLowerCase();
      if (lower !== 'content-encoding' && lower !== 'transfer-encoding') {
        res.setHeader(key, value);
      }
    });
    res.send(buffer);
  } catch (error) {
    res.status(502).json({ status: false, msg: error.message || 'upstream request failed' });
  }
};
