# TODOS

## P2 — Credential Management Layer
Agent 注册服务后的账号密码安全存储 + 复用。需要: D1 加密存储、密钥管理、租户隔离、审计链。
**Why:** 把 mails-skills 从 "OTP 工具" 升级到 "agent 身份管理"。
**Blocked by:** OTP 工具先验证产品市场匹配。先做好 OTP，再扩展到身份。
**Effort:** L (human: ~1 week / CC: ~30 min)

## P3 — Agent-to-Agent Email
多个 agent 之间用邮件协调工作。走标准 SMTP (Resend)，不需要新协议。
**Why:** 差异化场景，没有竞争者做过。
**Blocked by:** 市场需求未验证。等有用户反馈再考虑。
**Effort:** M (human: ~3 days / CC: ~30 min)
