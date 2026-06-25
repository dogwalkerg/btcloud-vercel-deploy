module.exports = (req, res) => {
  res.status(200).json({status: true, msg: '登录成功！', data: bin2hex(JSON.stringify({uid:1,username:'Administrator',serverid:'',state:1}))});
};
function bin2hex(s){return Buffer.from(s).toString('hex')}
