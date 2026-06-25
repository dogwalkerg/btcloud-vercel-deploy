const { proxyPluginList } = require('../_lib/btcloud');

module.exports = (req, res) => proxyPluginList(req, res, '/api/wpanel/get_soft_list', 'PLUGIN_LIST_WIN_URL');
