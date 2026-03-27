# D-POWTA 项目详细清单

## 项目概览

**项目名称**: D-POWTA (Dynamic Partially-Observable Weapon-Target Assignment)
**项目描述**: 动态部分可观察武器目标分配研究框架
**核心算法**: KG-DREA (知识引导的动态滚动多模态进化算法)
**编程语言**: MATLAB

---

## 任务清单

### Task #1: 创建项目目录结构 ✓
**状态**: 已创建计划
**优先级**: 高
**描述**: 创建D-POWTA项目的完整目录结构

#### 创建内容:
- [x] PROJECT_PLAN.md - 项目计划文档

#### 待创建目录:
- [ ] `instances/` - 算例数据存储目录
- [ ] `results/` - 结果输出目录
- [ ] `logs/` - 日志文件目录
- [ ] `@core/` - 核心功能模块
- [ ] `@operators/` - 进化算子模块
- [ ] `@visualization/` - 可视化模块
- [ ] `@utils/` - 工具函数
- [ ] `scripts/` - 主程序脚本
- [ ] `config/` - 配置文件

---

### Task #2: 实现核心功能模块 (@core)
**状态**: 待实现
**优先级**: 最高

#### 文件清单:

| 文件名 | 功能描述 | 输入 | 输出 |
|--------|----------|------|------|
| `generate_instances.m` | 动态算例生成器 | n, L, m, T_total参数 | instance结构体 |
| `solve_kgdrea.m` | KG-DREA主求解器 | instance, params | solution序列 |
| `constraint_preprocess.m` | 约束预处理 | instance | 有效配对集A_jt |
| `encoding_decode.m` | TC-FCE编码解码 | c向量, A_jt | 分配矩阵x_ijkt |
| `knowledge_manager.m` | 知识库管理 | 历史信息 | 冲突集合C_t |
| `rmi_evaluator.m` | RMI鲁棒性评估 | solution, A_jt | rmi值 |
| `fitness_evaluator.m` | 适应度评估 | x_ijkt, instance | fitness值 |

**关键技术点**:
- MRFDQI多雷达融合探测质量指数计算
- 11类硬约束体系
- TC-FCE目标中心可行组合编码

---

### Task #3: 实现进化算子模块 (@operators)
**状态**: 待实现
**优先级**: 高

#### 文件清单:

| 文件名 | 功能描述 | 输入 | 输出 |
|--------|----------|------|------|
| `init_population.m` | 知识引导种群初始化 | N, A_jt, KB | 种群P_0 |
| `crossover.m` | 均匀交叉算子 | 父本1, 父本2 | 子代 |
| `mutation.m` | 知识引导变异 | 个体, A_jt, KB, params | 变异后个体 |
| `niche_selection.m` | 汉明距离小生境选择 | P+Q, delta | 新种群P' |
| `repair_constraints.m` | 全局资源约束修复 | 解码方案, C1, C9 | 可行方案 |

**算法要点**:
- 知识引导初始化: 前N/2个体从无冲突补集采样
- 知识引导变异: 冲突区域p_guided=0.7, 非冲突区域p_mut=0.02
- 小生境半径: δ = ceil(0.2 * n_t)

---

### Task #4: 实现可视化模块 (@visualization)
**状态**: 待实现
**优先级**: 中

#### 文件清单:

| 文件名 | 功能描述 | 风格参考 |
|--------|----------|----------|
| `plot_instance.m` | 算例场景可视化 | 保留原visualize_instances.m风格 |
| `plot_allocation.m` | 各阶段分配方案 | 武器-目标配对连线 |
| `plot_convergence.m` | 收敛曲线 | 多算法对比曲线 |
| `plot_robustness.m` | RMI等鲁棒性指标 | 柱状图/热力图 |
| `plot_comparison.m` | 多算法性能对比 | 统计对比图 |

**可视化风格**:
- 参考现有visualize_instances.m的配色方案
- 防御区域: 绿色虚线边框
- 来袭区域: 红色虚线边框
- 武器平台: 三角形(△)
- 雷达阵地: 方形(□)
- 目标: 圆形(○), 颜色深浅表示威胁等级

---

### Task #5: 实现工具函数模块 (@utils)
**状态**: 待实现
**优先级**: 高

#### 文件清单:

| 文件名 | 功能描述 |
|--------|----------|
| `compute_distance.m` | 计算武器-目标/雷达-目标欧氏距离 |
| `compute_mrfdqi.m` | 计算MRFDQI多雷达融合探测质量指数 |
| `compute_kill_prob.m` | 计算武器-目标毁伤概率 |
| `load_instance.m` | 从MAT文件加载算例数据 |

---

### Task #6: 实现主程序脚本 (scripts)
**状态**: 待实现
**优先级**: 高

#### 文件清单:

| 文件名 | 功能描述 | 使用方式 |
|--------|----------|----------|
| `generate_test_suite.m` | 生成标准化测试集I1-I10 | `generate_test_suite` |
| `run_kgdrea.m` | 运行KG-DREA求解 | `run_kgdrea('instance_24.mat')` |
| `compare_algorithms.m` | 对比KG-DREA/GA/HA/LKEA | `compare_algorithms('I1')` |
| `demo.m` | 快速演示 | `demo` |

---

### Task #7: 创建配置文件
**状态**: 待实现
**优先级**: 中

#### 文件清单:

| 文件名 | 内容 |
|--------|------|
| `default_params.m` | 所有算法参数的默认值定义 |

**参数列表**:
```matlab
% 种群参数
params.N = [];           % 种群规模, 默认5*n_t
params.G_max = 100;     % 最大迭代代数
params.epsilon = 0.01;   % 近似最优解阈值

% 小生境参数
params.delta = [];       % 小生境半径, 默认ceil(0.2*n_t)
params.beta = 0.2;       % 半径系数

% 变异参数
params.p_mut = 0.02;     % 标准变异率
params.p_guided = 0.7;   % 知识引导变异率

% RMI参数
params.r = 2;            % 汉明邻域半径
params.S = 50;           % 蒙特卡洛采样数

% 知识库参数
params.theta_c = 5;     % 冲突判定阈值

% 对比算法参数
params.HA.gamma = 0.5;   % HA资源保护参数
```

---

## 功能需求对照表

### 功能1: 动态算例生成

| 需求 | 实现位置 | 状态 |
|------|----------|------|
| 支持4参数调整(n,L,m,T_total) | generate_instances.m | 待实现 |
| 目标隐身特性分布(6:3:1) | generate_instances.m | 待实现 |
| 多雷达异质性 | generate_instances.m | 待实现 |
| 跨阶段目标动态演变 | generate_instances.m | 待实现 |
| 参数化定制 | generate_instances.m | 待实现 |
| 保留绘图风格 | plot_instance.m | 待实现 |

### 功能2: 多阶段KG-DREA求解

| 需求 | 实现位置 | 状态 |
|------|----------|------|
| 完整KG-DREA流程 | solve_kgdrea.m | 待实现 |
| 加载指定MAT实例 | run_kgdrea.m | 待实现 |
| 算法参数可设置 | default_params.m + solve_kgdrea.m | 待实现 |
| 输出多阶段结果 | solve_kgdrea.m | 待实现 |

### 功能3: 结果展示与对比

| 需求 | 实现位置 | 状态 |
|------|----------|------|
| 保留可视化风格 | plot_*.m | 待实现 |
| 分配方案展示 | plot_allocation.m | 待实现 |
| 鲁棒性指标展示 | plot_robustness.m | 待实现 |
| 残余威胁演变 | plot_convergence.m | 待实现 |
| 基线算法对比 | compare_algorithms.m | 待实现 |

---

## 约束与指标说明

### 11类硬约束

| 编号 | 约束名称 | 描述 |
|------|----------|------|
| C1 | 武器平台弹药总量 | 发射弹药≤剩余弹药 |
| C2 | 武器平台可用状态 | 故障/耗尽平台不可用 |
| C3 | 目标最大拦截弹药 | 分配弹药≤U_jt |
| C4 | 射程有效性 | 目标在射程内 |
| C5 | 打击时效性 | 拦截时间≤打击窗口 |
| C6 | 雷达探测距离 | 目标在探测距离内 |
| C7 | 雷达探测概率阈值 | p≥p_th |
| C8 | 武器-雷达协同 | 具备制导能力 |
| C9 | 雷达火控通道容量 | 跟踪数≤C_k^track |
| C10 | 目标可探测性 | η_jt>0 |
| C11 | 最低毁伤概率 | 综合毁伤≥P_min |
| C12 | 武器优先级匹配 | 武器等级匹配目标威胁 |
| C13 | 决策变量非负整数 | x_ijkt∈Z_≥0 |

### 关键指标

| 指标 | 英文 | 定义 |
|------|------|------|
| MRFDQI | Multi-Radar Fusion Detection Quality Index | η_jt = 1-∏(1-p_kj) |
| RMI | Robustness Metric Index | ρ(c) = 平均邻域优势 |
| TC-FCE | Target-Centric Feasible Combination Encoding | 目标中心可行组合编码 |

---

## 测试集配置 (I1-I10)

| 算例 | 武器数m | 雷达数L | 总目标N | 阶段数T | 各阶段目标数 |
|------|---------|---------|---------|---------|--------------|
| I1 | 6 | 6 | 24 | 2 | 13, 11 |
| I2 | 6 | 6 | 30 | 3 | 11, 10, 9 |
| I3 | 6 | 6 | 50 | 4 | 14, 13, 12, 11 |
| I4 | 6 | 6 | 100 | 5 | 22, 21, 20, 19, 18 |
| I5 | 8 | 6 | 100 | 8 | 14,13,13,13,12,12,12,11 |
| I6 | 8 | 6 | 200 | 5 | 43, 41, 40, 39, 37 |
| I7 | 10 | 6 | 200 | 10 | 22,21,21,20,20,20,19,19,19,19 |
| I8 | 10 | 8 | 300 | 6 | 53, 52, 51, 49, 48, 47 |
| I9 | 10 | 8 | 500 | 8 | 67,65,64,63,63,62,61,55 |
| I10 | 10 | 8 | 500 | 10 | 53,52,51,51,50,50,49,48,48,48 |

---

## 版本记录

| 版本 | 日期 | 作者 | 描述 |
|------|------|------|------|
| 1.0 | 2026-03-18 | KG-DREA | 项目初始化 |
