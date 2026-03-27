# D-POWTA 项目结构

## 项目根目录
E:\学生指导\姚兴懿\code

## 目录结构
D-POWTA/
├── instances/              # 算例数据存储目录
├── results/               # 结果输出目录
├── logs/                   # 日志文件目录
│
├── @core/                  # 核心功能模块（包结构）
│   ├── generate_instances.m    % 动态算例生成器
│   ├── solve_kgdrea.m         % KG-DREA求解器
│   ├── constraint_preprocess.m % 约束预处理
│   ├── encoding_decode.m      % TC-FCE编码解码
│   ├── knowledge_manager.m    % 知识库管理
│   ├── rmi_evaluator.m       % RMI鲁棒性评估
│   └── fitness_evaluator.m   % 适应度评估
│
├── @operators/             % 进化算子模块
│   ├── init_population.m      % 种群初始化
│   ├── crossover.m           % 交叉算子
│   ├── mutation.m             % 知识引导变异
│   ├── niche_selection.m     % 小生境选择
│   └── repair_constraints.m   % 约束修复
│
├── @visualization/          % 可视化模块
│   ├── plot_instance.m       % 算例可视化
│   ├── plot_allocation.m     % 分配方案可视化
│   ├── plot_convergence.m    % 收敛曲线
│   ├── plot_robustness.m     % 鲁棒性指标
│   └── plot_comparison.m     % 算法对比
│
├── @utils/                  % 工具函数
│   ├── compute_distance.m     % 距离计算
│   ├── compute_mrfdqi.m      % MRFDQI计算
│   ├── compute_kill_prob.m   % 毁伤概率计算
│   └── load_instance.m      % 算例加载
│
├── scripts/                 % 主程序脚本
│   ├── generate_test_suite.m % 生成测试集
│   ├── run_kgdrea.m          % 运行KG-DREA
│   ├── compare_algorithms.m  % 算法对比
│   └── demo.m                % 演示脚本
│
├── config/                  % 配置文件
│   └── default_params.m      % 默认参数
│
├── lwh.md                   % 论文文档（已有）
├── generate_instances.m      % 旧版生成脚本（已有）
├── visualize_instances.m     % 旧版可视化脚本（已有）
└── README.md                % 项目说明

## 核心文件说明

### @core/ - 核心模块
| 文件 | 功能描述 |
|------|----------|
| generate_instances.m | 动态算例生成，支持参数化配置(n,L,m,T_total) |
| solve_kgdrea.m | KG-DREA主求解器 |
| constraint_preprocess.m | 约束预处理，构建有效配对集A_jt |
| encoding_decode.m | TC-FCE编码解码 |
| knowledge_manager.m | 知识库管理（ACK冲突模式） |
| rmi_evaluator.m | RMI鲁棒性度量指标计算 |
| fitness_evaluator.m | 目标函数值评估 |

### @operators/ - 进化算子
| 文件 | 功能描述 |
|------|----------|
| init_population.m | 知识引导种群初始化 |
| crossover.m | 均匀交叉算子 |
| mutation.m | 知识引导变异算子 |
| niche_selection.m | 汉明距离小生境选择 |
| repair_constraints.m | 全局资源约束修复 |

### @visualization/ - 可视化
| 文件 | 功能描述 |
|------|----------|
| plot_instance.m | 算例场景可视化（武器/雷达/目标） |
| plot_allocation.m | 各阶段分配方案可视化 |
| plot_convergence.m | 收敛曲线绘制 |
| plot_robustness.m | RMI等鲁棒性指标可视化 |
| plot_comparison.m | 多算法性能对比 |

### scripts/ - 主程序
| 文件 | 功能描述 |
|------|----------|
| generate_test_suite.m | 生成标准化测试集(I1-I10) |
| run_kgdrea.m | 运行KG-DREA求解指定算例 |
| compare_algorithms.m | 对比KG-DREA/GA/HA/LKEA |
| demo.m | 快速演示脚本 |

## 关键数据结构

### 算例结构 (instance)
```
instance = struct(
    'name',           % 算例名称
    'phase',          % 当前阶段
    'n',              % 目标数量
    'm',              % 武器平台数量
    'L',              % 雷达数量
    'T_total',        % 总阶段数

    % 武器参数
    'weapon_x',       % 武器X坐标
    'weapon_y',       % 武器Y坐标
    'R_max',          % 最大射程
    'tau_react',      % 反应时间
    'v_weapon',       % 飞行速度
    'priority',       % 优先级
    'ammo',           % 载弹量

    % 雷达参数
    'radar_x',        % 雷达X坐标
    'radar_y',        % 雷达Y坐标
    'lambda',         % 雷达性能参数
    'R_radar',        % 探测距离

    % 目标参数
    'targets',        % 目标结构体数组

    % 预计算矩阵
    'P_ij',           % 武器-目标毁伤概率
    'eta_j',         % MRFDQI探测质量指数
    'd_ij',          % 武器-目标距离

    % 约束参数
    'p_th',          % 探测概率门限
    'lambda0',       % 目标函数权重
    'dt'             % 决策间隔
)
```

### 目标结构 (target)
```
target = struct(
    'id',            % 目标ID
    'position_x',    % X坐标
    'position_y',    % Y坐标
    'speed',         % 飞行速度
    'heading',       % 航向角(度)
    'threat',        % 威胁等级[0,1]
    'RCS',           % 雷达截面积
    'W',             % 打击窗口时长
    'U',             % 最大允许弹药数
    'P_min'          % 最低毁伤概率要求
)
```

### 知识库结构 (knowledge_base)
```
KB = struct(
    'conflict_set',  % 冲突集合 C_t
    'history',       % 历史记录
    'theta_c',       % 冲突阈值(默认5)
    'elim_count'     % 淘汰计数矩阵
)
```

### 解码方案结构 (solution)
```
sol = struct(
    'c',             % TC-FCE编码向量
    'fitness',       % 目标函数值
    'rmi',           % RMI鲁棒性指标
    'feasible',      % 可行性标志
    'allocation'     % 解码后的分配矩阵
)
```

## KG-DREA算法流程

1. **初始化**: 加载/生成算例，初始化知识库K_0
2. **For t = 1 to T_total**:
   - 约束预处理: 构造有效配对集A_jt
   - 知识引导初始化: 生成初始种群P_0
   - **For g = 1 to G_max**:
     - 知识引导交叉变异生成子代Q_g
     - 小生境环境选择得P_g
   - 构造近似最优解集S_t^ε
   - RMI评估与方案优选: c_t* = argmax RMI(c)
   - 知识更新: K_t = K_{t-1} ∪ G(c_t*, E_t)
   - 执行方案，更新战场状态
3. **Return**: 最优方案序列{c_1*, ..., c_T*}

## 关键参数配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| N (种群规模) | 5*n_t | 随目标数自适应 |
| G_max | 100 | 最大迭代代数 |
| delta (小生境半径) | ceil(0.2*n_t) | 自适应 |
| S (RMI采样数) | 50 | 蒙特卡洛近似 |
| p_mut | 0.02 | 标准变异率 |
| p_guided | 0.7 | 知识引导变异率 |
| epsilon | 0.01 | 近似最优解阈值 |
| theta_c | 5 | 冲突判定阈值 |

## 命名规范

- MATLAB函数: camelCase (如 generateInstances.m)
- 变量: lowercase_with_underscores
- 结构体字段: lowercase
- 常量: UPPERCASE
- 注释: 中文为主，英文专业术语保留
