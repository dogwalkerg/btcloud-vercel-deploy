module.exports = (req, res) => {
  res.status(200).send(JSON.stringify({version: '2.3.3', description: '暂无更新日志', create_time: '2025-08-12'}));
};
