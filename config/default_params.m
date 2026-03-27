% D-POWTA 默认参数配置文件
% 定义KG-DREA算法及所有相关模块的默认参数
%
% 使用方式:
%   params = default_params();
%   params = default_params('n', 50, 'm', 6);  % 覆盖默认值
%
% Author: KG-DREA
% Date: 2026-03-18

function params = default_params(varargin)
    % 默认参数结构体

    %% ==================== 基础参数 ====================
    params.algorithm = 'KG-DREA';        % 算法名称
    params.version = '1.0';              % 版本号

    %% ==================== 种群参数 ====================
    params.N = [];                       % 种群规模，默认5*n_t
    params.G_max = 100;                  % 最大迭代代数
    params.epsilon = 0.01;               % 近似最优解阈值

    %% ==================== 小生境参数 ====================
    params.delta = [];                   % 小生境半径，默认ceil(0.2*n_t)
    params.beta = 0.2;                  % 半径系数 (0, 0.3)
    params.elite_size = 20;             % 精英集合规模

    %% ==================== 变异参数 ====================
    params.p_mut = 0.05;                 % 标准变异率 [0.01, 0.05]
    params.p_guided = 0.7;              % 知识引导变异率 [0.6, 0.9]
    params.p_crossover = 0.8;           % 交叉概率

    %% ==================== RMI鲁棒性参数 ====================
    params.r = 2;                       % 汉明邻域半径
    params.S = 50;                      % 蒙特卡洛采样数
    params.use_monte_carlo = true;      % 是否使用蒙特卡洛近似

    %% ==================== 知识库参数 ====================
    params.theta_c = 5;                 % 冲突判定阈值
    params.max_history = 100;           % 最大历史记录数

    %% ==================== 算例生成参数 ====================
    % 区域参数
    params.area_x_min = 0;
    params.area_x_max = 200;
    params.area_y_min = 0;
    params.area_y_max = 200;
    params.defense_x_min = 0;
    params.defense_x_max = 50;
    params.defense_y_min = 50;
    params.defense_y_max = 150;

    % 目标隐身特性分布 (6:3:1)
    params.rcs_conventional = [1, 5];       % 常规目标 RCS [m^2]
    params.rcs_low_observable = [0.1, 1];    % 低可观测目标 RCS
    params.rcs_stealth = [0.01, 0.1];       % 高隐身目标 RCS
    params.ratio_conventional = 0.6;        % 常规目标比例
    params.ratio_low_observable = 0.3;     % 低可观测目标比例
    params.ratio_stealth = 0.1;            % 高隐身目标比例

    % 目标动态参数
    params.speed_min = 0.3;                 % 最小速度 (km/s)
    params.speed_max = 0.7;                 % 最大速度 (km/s)
    params.threat_min = 0.3;                % 最小威胁等级
    params.threat_max = 1.0;                % 最大威胁等级

    % 武器参数
    params.weapon_range_min = 150;          % 最小射程 (km)
    params.weapon_range_max = 180;          % 最大射程 (km)
    params.weapon_react_min = 8;            % 最小反应时间 (s)
    params.weapon_react_max = 12;          % 最大反应时间 (s)
    params.weapon_speed_min = 2.5;          % 最小飞行速度 (km/s)
    params.weapon_speed_max = 3.0;          % 最大飞行速度 (km/s)
    params.ammo_per_weapon = 6;             % 每武器载弹量

    % 雷达参数
    params.radar_range_min = 220;            % 最小探测距离 (km)
    params.radar_range_max = 250;          % 最大探测距离 (km)
    params.radar_lambda_min = 5e-9;         % 最小雷达性能参数
    params.radar_lambda_max = 7e-9;        % 最大雷达性能参数
    params.p_th = 0.1;                      % 探测概率门限
    params.C_track = 10;                    % 雷达火控通道容量

    % 作战参数
    params.dt = 30;                         % 决策间隔 (s)
    params.lambda0 = 1.0;                   % 目标函数权重

    %% ==================== 对比算法参数 ====================
    % HA (Heuristic Algorithm)
    params.HA.gamma = 0.5;                  % 资源保护参数

    % GA (Genetic Algorithm)
    params.GA.N = [];                       % 默认同KG-DREA
    params.GA.G_max = 100;
    params.GA.p_mut = 0.02;
    params.GA.p_crossover = 0.8;

    % LKEA
    params.LKEA.N = [];                     % 默认同KG-DREA
    params.LKEA.G_max = 100;

    %% ==================== 输出控制参数 ====================
    params.verbose = true;                   % 是否显示详细信息
    params.save_history = true;             % 是否保存进化历史
    params.plot_convergence = true;        % 是否绘制收敛曲线
    params.save_results = true;             % 是否保存结果

    % 路径配置
    params.instance_dir = 'instances/';     % 算例目录
    params.result_dir = 'results/';         % 结果目录
    params.log_dir = 'logs/';               % 日志目录

    %% ==================== 随机种子 ====================
    params.seed = [];                      % 随机种子，默认随机

    %% ==================== 处理输入参数覆盖 ====================
    if mod(length(varargin), 2) ~= 0
        error('参数必须成对出现: 参数名, 参数值');
    end

    for i = 1:2:length(varargin)
        param_name = varargin{i};
        param_value = varargin{i+1};

        if isfield(params, param_name)
            if isstruct(param_value)
                % 处理嵌套结构体
                fieldnames = fieldnames(param_value);
                for j = 1:length(fieldnames)
                    subfield = fieldnames{j};
                    full_field = [param_name '.' subfield];
                    if isfield(params, full_field)
                        params.(full_field) = param_value.(subfield);
                    end
                end
            else
                params.(param_name) = param_value;
            end
        else
            warning('未知参数: %s', param_name);
        end
    end
end

% ==================== 辅助函数 ====================

function params = set_niche_radius(params, n_t)
    % 根据目标数自适应设置小生境半径
    % δ(t) = ceil(β * n_t), β ∈ (0, 0.3)
    if isempty(params.delta)
        params.delta = ceil(params.beta * n_t);
    end
end

function params = set_population_size(params, n_t)
    % 根据目标数自适应设置种群规模
    % N = 5 * n_t
    if isempty(params.N)
        params.N = 5 * n_t;
    end
end
