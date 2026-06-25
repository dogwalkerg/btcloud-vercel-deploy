const { proxyPluginList } = require('../../lib/btcloud');

module.exports = (req, res) => proxyPluginList(req, res, '/api/panel/getSoftList', 'PLUGIN_LIST_EN_URL');
