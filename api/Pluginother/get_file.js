const { proxyDownload, redirectOtherFile } = require('../../lib/btcloud');

module.exports = async (req, res) => {
  if (redirectOtherFile(req, res, process.env.PLUGIN_OTHER_BASE_URL)) return;
  await proxyDownload(req, res, '/api/Pluginother/get_file');
};
