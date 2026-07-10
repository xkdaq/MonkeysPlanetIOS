# App Store 审核回复草稿（1.0.1 / Guideline 2.1）

> 用途：复制到 App Store Connect → 该版本 → App Review → 回复（Resolution Center）
> 语言：英文（审核团队使用英文沟通）
> 策略：已下架第三方版权题库；将 App 重新定位为「个人学习工具」而非「内容出版方」；剩余内容仅官方历年真题，以交互式刷题形式呈现，无书刊阅读体验。

---

Hello App Review Team,

Thank you for the clarification regarding Guideline 2.1. We have taken action based on your feedback.

**What we changed**

We have completely removed all third-party copyrighted and commercially published question banks from our server. The app no longer distributes any books, magazines, or paid/proprietary educational publications of any kind.

**How the app actually works**

"猴帝星球" is a personal study productivity tool for exam candidates, not a content publisher. Its core value is the user's own learning data and self-management, including:

- A personal **wrong-question notebook** that automatically collects the questions a user answers incorrectly
- **Favorites** the user builds and manages themselves
- **Study progress / practice history** tracked per user account
- **Self-assessment practice** in sequential / random / targeted modes
- An in-app **question error-reporting** feature so users can flag and correct mistakes

All of the above are user-generated, user-owned data managed per account. The app does not sell, publish, or distribute reading material.

**Remaining content**

The only practice content now available consists of **official, publicly released past exam papers (真题)**, presented strictly as interactive practice questions — one question at a time, with the user's own answer and result — not as browsable books or magazines. There is no in-app book/magazine reading experience.

We believe the app no longer falls under the "books or magazines" category referenced in your message, and we respectfully request that you continue the review.

If any specific item still appears to require a publishing license, please let us know the exact content and we will remove it immediately.

Thank you for your time and guidance.

Best regards,
[你的名字 / Your Name]

---

## 配套建议（非回复内容，给开发者看）

1. **App Store 元数据同步调整**（在 App Store Connect 里改）：
   - 副标题/描述弱化「海量题库、名师解析、刷题神器」这类话术
   - 强化「学习工具、错题管理、进度追踪、个人备考助手」
   - 关键词避免 book / 教材 / 题库 等易触发书刊判定的词

2. **App 端加「题库可见性过滤」**（双保险，防止后端遗漏）：
   - 在 `exam_provider.loadBanks()` 处按 bank ID 过滤
   - 确保审核员实测时只看到你希望出现的内容

3. **风险提示**：苹果本次判定的核心是「内容类型（书刊）」而非版权归属。
   仅下架版权题、保留真题，**仍有概率再次被要求出版许可**。
   若二次被拒，最稳路线是：不预置任何题库，改为「用户自行导入/自带内容」的工具形态。
