# stall_pos

摆摊进销存利润计算软件 - 轻量级摊位经营管理解决方案

## 功能特点

- **商品管理** - 商品录入、库存管理、价格设置
- **销售开单** - 快速开单、收银记录
- **统计报表** - 利润统计、销售分析、数据可视化
- **数据导出** - 支持数据分享导出

## 技术栈

- **Flutter** - 跨平台移动应用框架
- **SQLite** - 本地数据存储
- **fl_chart** - 数据可视化图表
- **share_plus** - 数据分享功能

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── database/
│   └── database_helper.dart  # 数据库操作
├── models/
│   └── models.dart         # 数据模型
└── screens/
    ├── home_screen.dart       # 主页/导航
    ├── products_screen.dart   # 商品管理
    ├── sales_screen.dart      # 销售开单
    ├── statistics_screen.dart # 统计报表
    └── settings_screen.dart   # 系统设置
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK

### 运行项目

```bash
# 克隆项目
git clone https://github.com/wjzsj/stall_pos.git

# 进入目录
cd stall_pos

# 获取依赖
flutter pub get

# 运行应用
flutter run
```

### 构建 APK

```bash
flutter build apk --release
```

## 界面预览

| 商品管理 | 销售开单 | 统计报表 |
|---------|---------|---------|
| 商品列表 | 快速开单 | 利润图表 |
| 库存管理 | 收银记录 | 销售分析 |

## 数据说明

- 所有数据存储在本地 SQLite 数据库
- 支持数据导出分享
- 无需网络连接即可使用

## 许可证

MIT License
