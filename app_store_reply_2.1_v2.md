# App Store 审核回复草稿（第二次驳回 / Guideline 2.1）

> 用途：复制到 App Store Connect → Resolution Center 回复
> 语言：英文（审核团队使用英文沟通）
> 策略：强调已同步修改 App Store 元数据 + App 本质是个人学习工具 + 无任何预置书刊内容

---

Hello App Review Team,

Thank you for your continued review. We have carefully addressed the outstanding issues and made comprehensive changes to both the app and its App Store presentation.

**1. App Store Metadata Updated**

We have revised all App Store metadata to accurately reflect the app's nature as a **personal study productivity tool**, not a content distributor:

- **Subtitle** changed from "考研刷题助手" to "考研学习助手" (Postgraduate Study Assistant)
- **Description** completely rewritten: removed all wording such as "海量题库" (massive question bank), "真题" (real exam questions), and "在线刷题平台" (online practice platform). The new description focuses on personal features: wrong-question notebook, self-managed favorites, study progress tracking, and practice modes.
- **Keywords** updated: removed "题库" (question bank), "真题" (real questions), "教材" (textbook), and other terms that may trigger a book/magazine classification.
- **Category** remains Education, but the secondary category is now Utilities to emphasize the tool nature.
- **Screenshots** will be updated to showcase personal data management features (wrong-question notebook, study records, progress tracking) rather than any browsable content library.

**2. How the App Actually Works**

"猴哥星球" (Monkey Planet) is fundamentally a **personal learning management utility** for individual exam candidates. Its core value lies in the user's own data and self-management capabilities:

- **Personal Wrong-Question Notebook**: Automatically collects questions the user answers incorrectly. This is user-generated, user-owned data.
- **Self-Managed Favorites**: Users build and manage their own collection of important questions.
- **Study Progress Tracking**: Per-user practice history and performance analytics.
- **Self-Assessment Practice**: Interactive practice modes (sequential, random, targeted) using the user's own content.
- **In-App Error Reporting**: Users can flag and correct mistakes in their personal notes.

**3. No Pre-Installed Book or Magazine Content**

We want to be absolutely clear:

- The app does **not** come with any pre-installed, browsable library of books, magazines, or exam papers.
- The app does **not** sell, publish, or distribute reading material of any kind.
- There is **no** in-app book or magazine reading experience.
- The only content a user sees is content they have personally interacted with and generated through their own study activity.

The app is a blank tool until a user begins their own learning journey. The data belongs to the user, not the app developer.

**4. Previous Third-Party Content Fully Removed**

As stated in our previous reply, all third-party copyrighted and commercially published question banks have been completely removed from our server. This remains in effect.

**Conclusion**

We believe the app, in its current form and with its updated metadata, is a personal study utility tool and does not fall under the "books or magazines" category requiring a publishing license. We respectfully request that you continue the review based on these clarifications and changes.

If there is any remaining concern, please specify the exact content or feature that triggers the publishing license requirement, and we will remove it immediately.

Thank you for your time and guidance.

Best regards,
[Your Name]

---

## 操作检查清单（在提交回复前完成）

### App Store Connect 元数据修改

- [ ] 修改 Subtitle 为：考研学习助手 / 个人学习助手 / 高效备考工具（三选一）
- [ ] 修改 Description 为上方版本（去掉题库/真题/海量等词）
- [ ] 修改 Keywords 为：考研,学习,错题本,备考,练习,考试,研究生,复习,上岸,笔记
- [ ] Secondary Category 改为：Utilities（工具）
- [ ] 上传新的截图（展示错题本/学习记录/进度追踪，避免展示题库列表封面）

### App 端建议（如果审核员实际测试）

- [ ] 确保测试账号登录后，首页不展示任何带有"出版物"外观的内容（如书籍封面、杂志目录、题库列表等）
- [ ] 确保"错题本"和"收藏"功能明显是用户个人数据管理
- [ ] 确保没有任何付费解锁题库/书籍的入口或内购项目
- [ ] 确保 App 内没有"下载教材/书籍/资料"的功能

---

## 备选策略（如果第三次仍被拒）

如果苹果仍然坚持需要出版许可，说明审核员实际打开 App 后看到的内容仍然被判定为"书刊"。此时建议：

**Plan B: 彻底转型为纯工具**
- 后端完全移除预置题库数据
- App 变为"用户自行导入/手动添加题目"的空白工具
- 仅保留错题本、收藏、进度追踪等个人管理功能
- 类似 Anki、Notion 等纯工具形态

这是最稳妥的上架路线，但会牺牲一部分用户体验。需要评估是否值得。