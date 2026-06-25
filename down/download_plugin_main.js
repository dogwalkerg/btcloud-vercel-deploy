const { proxyDownload } = require('../api/_lib/btcloud');

module.exports = (req, res) => proxyDownload(req, res, '/down/download_plugin_main');
