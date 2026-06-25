const { proxyPluginList } = require('../../lib/btcloud');

module.exports = (req, res) => proxyPluginList(req, res, '/api/panel/get_soft_list', 'PLUGIN_LIST_URL');
