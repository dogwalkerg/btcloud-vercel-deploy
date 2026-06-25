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
  aln: 'AES加密字符串',
};

function trimSlash(value) {
  return String(value || '').replace(/\/+$/, '');
}

function getUpstream() {
  return trimSlash(process.env.BTCLOUD_UPSTREAM || process.env.BT_CLOUD_UPSTREAM);
}

function appendQuery(target, req) {
  const base = new URL(target);
  const incoming = new URL(req.url || '/', 'http://localhost');
  incoming.searchParams.forEach((value, key) => base.searchParams.append(key, value));
  return base.toString();
}

function getRequestBody(req) {
  if (!req.body) return undefined;
  if (typeof req.body === 'string' || Buffer.isBuffer(req.body)) return req.body;
  return new URLSearchParams(req.body).toString();
}

async function proxyJson(req, res, upstreamPath, fallback = EMPTY_PLUGIN_LIST) {
  const upstream = getUpstream();
  if (!upstream) {
    res.status(200).json(fallback);
    return;
  }

  try {
    const method = req.method || 'GET';
    const url = appendQuery(upstream + upstreamPath, req);
    const body = method === 'GET' || method === 'HEAD' ? undefined : getRequestBody(req);
    const response = await fetch(url, {
      method,
      headers: body ? { 'content-type': 'application/x-www-form-urlencoded' } : undefined,
      body,
    });

    const text = await response.text();
    res.status(response.status);
    res.setHeader('content-type', response.headers.get('content-type') || 'application/json; charset=utf-8');
    res.send(text);
  } catch (error) {
    res.status(502).json({ status: false, msg: error.message || 'upstream request failed' });
  }
}

async function proxyPluginList(req, res, upstreamPath, listUrlEnvName) {
  const listUrl = process.env[listUrlEnvName];
  if (listUrl) {
    try {
      const response = await fetch(listUrl);
      const text = await response.text();
      res.status(response.status);
      res.setHeader('content-type', response.headers.get('content-type') || 'application/json; charset=utf-8');
      res.send(text);
      return;
    } catch (error) {
      res.status(502).json({ status: false, msg: error.message || 'plugin list request failed' });
      return;
    }
  }

  await proxyJson(req, res, upstreamPath);
}

function redirectPackage(req, res, options) {
  const query = req.method === 'GET' ? req.query || {} : { ...(req.query || {}), ...(req.body || {}) };
  const name = query.name;
  const version = query.version;
  if (!name || !version) {
    res.status(400).json({ status: false, msg: '参数不能为空' });
    return true;
  }
  if (!/^[a-zA-Z0-9_]+$/.test(name) || !/^[0-9.]+$/.test(version)) {
    res.status(400).json({ status: false, msg: '参数不正确' });
    return true;
  }

  const base = trimSlash(options.baseUrl);
  if (!base) return false;

  const filename = `${name}-${version}.zip`;
  res.writeHead(302, { Location: `${base}/${encodeURIComponent(filename)}` });
  res.end();
  return true;
}

function redirectOtherFile(req, res, baseUrl) {
  const fname = (req.query && (req.query.fname || req.query.filename)) || '';
  if (!fname || fname.includes('..')) {
    res.status(400).json({ status: false, msg: '参数不正确' });
    return true;
  }

  const base = trimSlash(baseUrl);
  if (!base) return false;

  const safePath = fname.split('/').map(encodeURIComponent).join('/');
  res.writeHead(302, { Location: `${base}/${safePath}` });
  res.end();
  return true;
}

async function proxyDownload(req, res, upstreamPath) {
  const upstream = getUpstream();
  if (!upstream) {
    res.status(404).json({ status: false, msg: '未配置下载源' });
    return;
  }

  try {
    const method = req.method || 'GET';
    const url = appendQuery(upstream + upstreamPath, req);
    const body = method === 'GET' || method === 'HEAD' ? undefined : getRequestBody(req);
    const response = await fetch(url, {
      method,
      headers: body ? { 'content-type': 'application/x-www-form-urlencoded' } : undefined,
      body,
    });
    const buffer = Buffer.from(await response.arrayBuffer());
    res.status(response.status);
    ['content-type', 'content-disposition', 'content-md5', 'file-size'].forEach((key) => {
      const value = response.headers.get(key);
      if (value) res.setHeader(key, value);
    });
    res.send(buffer);
  } catch (error) {
    res.status(502).json({ status: false, msg: error.message || 'download failed' });
  }
}

module.exports = {
  proxyJson,
  proxyPluginList,
  proxyDownload,
  redirectPackage,
  redirectOtherFile,
};
