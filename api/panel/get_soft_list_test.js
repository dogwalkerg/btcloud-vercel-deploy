const { proxyJson } = require('../_lib/btcloud');

module.exports = (req, res) => proxyJson(req, res, '/api/panel/get_soft_list_test');
