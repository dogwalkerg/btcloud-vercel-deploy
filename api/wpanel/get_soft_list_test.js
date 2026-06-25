module.exports = (req, res) => {
  res.status(200).json({
    list: [],
    type: [],
    ip: '127.0.0.1',
    serverid: '',
    uid: 1,
    pro: -1,
    ltd: 1849472000,
    beta: 0,
    skey: '',
    aln: 'AES加密字符串'
  });
};
