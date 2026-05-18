# BAL Termux 内网穿透完整方案

## 文件说明

| 文件 | 用途 |
|------|------|
| `install-tunnel.sh` | 一键安装 cloudflared + cpolar |
| `quick-tunnel.sh` | 交互式快速穿透菜单 |
| `start-bal.sh` | BAL 项目一键启动 |
| `cloudflared-config.yml` | 完整配置文件模板 |

## 快速开始

### 方法一：全自动安装
```bash
# 下载所有脚本到 Termux
cd ~
# (使用文件管理器或 wget 下载上述文件)

# 运行安装
bash install-tunnel.sh
```

### 方法二：最快上手（无需配置）
```bash
# 1. 确保 BAL 在运行
~/start-bal.sh

# 2. 新窗口运行穿透
cloudflared tunnel --url http://localhost:3000
```

### 方法三：交互式菜单
```bash
~/quick-tunnel.sh
# 选择 1) 穿透前端
```

## Cloudflared 完整配置流程

```bash
# 1. 登录（只需一次）
cloudflared tunnel login

# 2. 创建隧道
cloudflared tunnel create bal2
# 记录输出的 UUID

# 3. 编辑配置
nano ~/.cloudflared/config.yml
# 复制 cloudflared-config.yml 内容，替换 YOUR_TUNNEL_ID

# 4. 添加 DNS
cloudflared tunnel route dns YOUR_TUNNEL_ID bal-yourname.pages.dev

# 5. 启动
cloudflared tunnel --config ~/.cloudflared/config.yml run bal2
```

## Cpolar 使用

```bash
# 设置 token（只需一次）
cpolar authtoken YOUR_TOKEN

# 启动穿透
cpolar http 3000 --subdomain=bal
```

## 常见问题

### Q: cpolar 报错 32-bit instead of 64-bit
A: 使用本安装脚本中的 arm64 版本，或改用 cloudflared

### Q: cloudflared 提示 cert.pem 已存在
A: 删除旧证书: `rm ~/.cloudflared/cert.pem` 然后重新 login

### Q: 隧道连接成功但无法访问
A: 检查本地服务是否运行: `curl http://localhost:3000`

### Q: Termux 后台被杀
A: 在 Android 设置中允许 Termux 后台运行，或使用 `termux-wake-lock`

## 安全提醒

⚠️ 公开 RPC 端点存在安全风险：
- 不要公开主网 RPC
- 仅用于本地测试节点
- 建议添加 IP 白名单或认证
