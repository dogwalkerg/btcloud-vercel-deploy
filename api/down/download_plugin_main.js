const { proxyDownload } = require('../../lib/btcloud');

module.exports = (req, res) => proxyDownload(req, res, '/down/download_plugin_main');
