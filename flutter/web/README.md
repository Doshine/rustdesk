# flutter/web — 蓝鲸银河 Web Client 资源

本目录自上游 git 历史恢复（上游在 `5faf0ad3c` 删除了整个 `flutter/web/`；恢复点 `5faf0ad3c^`）。原 `v1/` 子目录内容已整体上提至顶层（`flutter build web` 要求 `index.html` 在顶层），原 `v2/` 仅有一行 "Under dev."，已删除。

注意：上游拆分 v1/v2 时留下的原话是 "v1 is not compatible with current Flutter source code."——这套 JS bridge（`js/`）与当前 Flutter 源码未做过联调验证，重新构建时需按构建文档逐环节验证。

目录说明：

- `index.html` / `manifest.json` / `favicon.png` / `icons/`：已品牌化为蓝鲸银河
- `js/`：v1 JS bridge（TypeScript + vite@2.8 构建，产物输出到 `js/dist/`）
- `yuv.js` / `yuv.wasm`：YUV 渲染 WASM
- `ogvjs-1.8.6/`、`yuv-canvas-1.2.6.js`、`libopus.js/.wasm`、`assets/`：不在 git 中，由 `web_deps.tar.gz` 提供（见 .gitignore）
- `index.html` 中 `<script src="/webclient-config/index.js">` 为 rustdesk-api 服务端动态注入的 API 配置，部署替换资源时必须保留

构建与部署流程见 workspace 根：`docs/sop/webclient-build.md`
