# btcloud Vercel 部署版

在 Vercel 上部署 btcloud 的静态文件 + API 服务，无需 PHP 服务器。

## 部署步骤

### 1. 复制文件

从 btcloud 项目复制文件到 `public/` 目录：

```
public/
  install/
    public.sh
    install_panel.sh
    update6.sh
    update_panel.sh
    install_7.0_en.sh
    update_7.x_en.sh
    install_btmonitor.sh
    update_btmonitor.sh
    src/
      panel6.zip
      bt-monitor-2.3.3.zip
      panel_7_en.zip
    update/
      LinuxPanel-11.8.0.zip
      LinuxPanel_EN-7.0.25.zip
```

大 zip 文件默认被 .gitignore 排除。如需包含，删掉 .gitignore 中的 #。

### 2. 修改 Btapi_Url

将所有脚本中的 Btapi_Url 改为你的 Vercel 域名：

```bash
Btapi_Url='https://my-btcloud.vercel.app'
```

### 3. 推送到 GitHub + 部署到 Vercel

```bash
git init && git add . && git commit -m "init"
git remote add origin https://github.com/你的用户名/btcloud-vercel.git
git push -u origin main
```

在 Vercel 中导入该仓库即可。

## 安装命令

```bash
yum install -y wget && wget -O install.sh https://域名/install/install_panel.sh && sh install.sh
```

## API 接口

| 路径 | 返回 |
|---|---|
| /api/SetupCount | ok |
| /api/panel/get_version | 11.8.0 |
| /api/panel/getLatestOfficialVersion | 7.0.25 |
| /api/bt_monitor/latest_version | JSON 版本信息 |
