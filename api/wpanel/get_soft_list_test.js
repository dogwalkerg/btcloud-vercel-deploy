const { proxyPluginList } = require('../../lib/btcloud');

module.exports = (req, res) => proxyPluginList(req, res, '/api/wpanel/get_soft_list_test', 'PLUGIN_LIST_WIN_URL');
