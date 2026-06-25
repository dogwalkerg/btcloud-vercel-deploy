module.exports = (req, res) => {
  res.status(200).json({status: false, msg: '不支持当前操作'});
};
