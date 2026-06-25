const { proxyJson } = require('../_lib/btcloud');

module.exports = (req, res) => proxyJson(req, res, '/api/wpanel/get_soft_list');
