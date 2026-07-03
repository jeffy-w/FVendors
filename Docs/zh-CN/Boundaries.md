# 模块边界

FVendors 是轻量 app 基础设施底座，不是完整 app framework。每个 target 都应保持职责聚焦，让 app 可以按需导入最小 surface。

## Target 职责

- `FVendorsModels`：共享值类型、领域错误和跨模块枚举。
- `FVendorsClients`：client 抽象、请求构建、wrapper 和测试替身。
- `FVendorsClientsLive`：生产实现和第三方库适配。
- `FVendorsExt`：可选 SwiftUI/UIKit helper。
- `FVendors`：仅作为核心 umbrella，re-export Models + Clients + ClientsLive，不得 re-export `FVendorsExt`。

## 已强制执行的规则

`Scripts/check-boundaries.sh` 是 CI 中的边界 canary。以下情况会失败：

1. UI helper 回到 `Sources/FVendors`。
2. `Sources/FVendors/FVendors.swift` re-export `FVendorsExt`。
3. `Sources/FVendors` 下出现 SwiftUI/UIKit 代码。
4. `FVendorsExt` SwiftPM product 消失，或不再指向 `FVendorsExt` target。
5. `FVendors` target 依赖超过 `FVendorsModels`、`FVendorsClients`、`FVendorsClientsLive`。
6. 未经批准的 hard-gated future client 名称进入 package sources。

修改 product 边界前，先在本地运行：

```bash
Scripts/check-boundaries.sh
```

## 增加新能力

优先扩展现有 client 或给现有 client 增加 wrapper，不要急于新增 package-owned client。`EnvironmentClient`、`FeatureFlagClient`、`ReachabilityClient`、`AuthTokenClient` 等新 API 需要 Demo 或真实 app 反复证明、测试友好变体、聚焦测试、中英文文档和模块边界理由。
