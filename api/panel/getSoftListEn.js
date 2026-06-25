const { proxyJson } = require('../_lib/btcloud');

module.exports = (req, res) => proxyJson(req, res, '/api/panel/getSoftListEn');
