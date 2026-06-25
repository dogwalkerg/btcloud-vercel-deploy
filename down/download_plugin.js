const { proxyDownload, redirectPackage } = require('../api/_lib/btcloud');

module.exports = async (req, res) => {
  const os = ((req.body && req.body.os) || (req.query && req.query.os) || 'Linux').toLowerCase();
  const baseUrl =
    os === 'en'
      ? process.env.PLUGIN_PACKAGE_EN_BASE_URL
      : os === 'windows'
        ? process.env.PLUGIN_PACKAGE_WIN_BASE_URL
        : process.env.PLUGIN_PACKAGE_BASE_URL;

  if (redirectPackage(req, res, { baseUrl })) return;
  await proxyDownload(req, res, '/down/download_plugin');
};
