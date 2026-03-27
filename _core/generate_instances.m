% D-POWTA 动态算例生成器
% 支持通过4个参数调整生成算例：目标数量(n)、雷达数量(L)、武器数量(m)、阶段数量(T_total)
%
% 功能特性:
% - 目标隐身特性分布 (常规6:低观测3:高隐身1)
% - 多雷达异质性建模
% - 跨阶段目标动态演变
% - 参数化定制
%
% 使用方式:
%   instance = generate_instances('n', 24, 'L', 6, 'm', 6, 'T_total', 2);
%   instance = generate_instances();  % 使用默认参数
%
% 输入参数 (可选，键值对形式):
%   n           - 总目标数量 (默认24)
%   L           - 雷达数量 (默认6)
%   m           - 武器数量 (默认6)
%   T_total     - 阶段数量 (默认2)
%   save_file   - 保存文件名 (可选)
%   params      - 参数结构体 (可选)
%
% 输出:
%   instance - 算例结构体
%
% Author: KG-DREA
% Date: 2026-03-18

function instance = generate_instances(varargin)
    %% ==================== 解析输入参数 ====================
    p = inputParser;
    addOptional(p, 'n', 24, @isnumeric);
    addOptional(p, 'L', 6, @isnumeric);
    addOptional(p, 'm', 6, @isnumeric);
    addOptional(p, 'T_total', 2, @isnumeric);
    addOptional(p, 'save_file', '', @ischar);
    addOptional(p, 'params', [], @isstruct);

    parse(p, varargin{:});
    args = p.Results;

    n = args.n;
    L = args.L;
    m = args.m;
    T_total = args.T_total;

    % 使用内联默认参数
    params = get_default_params();

    fprintf('=== D-POWTA 动态算例生成 ===\n');
    fprintf('参数: n=%d, L=%d, m=%d, T_total=%d\n', n, L, m, T_total);

    %% ==================== 初始化基础参数 ====================
    % 作战区域
    AREA_X_MIN = params.area_x_min;
    AREA_X_MAX = params.area_x_max;
    AREA_Y_MIN = params.area_y_min;
    AREA_Y_MAX = params.area_y_max;

    % 防御区域
    DEFENSE_X_MIN = params.defense_x_min;
    DEFENSE_X_MAX = params.defense_x_max;
    DEFENSE_Y_MIN = params.defense_y_min;
    DEFENSE_Y_MAX = params.defense_y_max;

    % 雷达参数
    p_th = params.p_th;

    %% ==================== 生成武器平台 ====================
    fprintf('生成武器平台...\n');

    % 武器位置分布在防御区域内
    weapon_x = linspace(DEFENSE_X_MIN + 5, DEFENSE_X_MAX - 5, m);
    weapon_y = linspace(DEFENSE_Y_MIN + 10, DEFENSE_Y_MAX - 10, m);

    % 添加小随机扰动
    weapon_x = weapon_x + rand(1, m) * 5 - 2.5;
    weapon_y = weapon_y + rand(1, m) * 5 - 2.5;

    % 武器参数
    R_max = params.weapon_range_min + rand(1, m) * (params.weapon_range_max - params.weapon_range_min);
    tau_react = params.weapon_react_min + rand(1, m) * (params.weapon_react_max - params.weapon_react_min);
    v_weapon = params.weapon_speed_min + rand(1, m) * (params.weapon_speed_max - params.weapon_speed_min);
    priority = randi([2, 3], 1, m);  % 优先级等级 2-3
    ammo = params.ammo_per_weapon * ones(1, m);  % 载弹量

    %% ==================== 生成雷达阵地 ====================
    fprintf('生成雷达阵地...\n');

    % 雷达位置分布在防御区域前后
    radar_x = linspace(DEFENSE_X_MIN + 2, DEFENSE_X_MAX - 5, L);
    radar_y = linspace(DEFENSE_Y_MIN + 5, DEFENSE_Y_MAX - 5, L);
    radar_x = radar_x + rand(1, L) * 3 - 1.5;
    radar_y = radar_y + rand(1, L) * 5 - 2.5;

    % 雷达参数 - 异质性建模
    lambda = params.radar_lambda_min + rand(1, L) * (params.radar_lambda_max - params.radar_lambda_min);
    R_radar = params.radar_range_min + rand(1, L) * (params.radar_range_max - params.radar_lambda_min);

    % 协同制导能力矩阵 (简化为所有武器-雷达对可用)
    alpha = ones(m, L);

    %% ==================== 生成所有目标 ====================
    fprintf('生成目标数据...\n');

    % 根据隐身特性分布生成目标
    targets_all = generate_all_targets(n, params, DEFENSE_X_MIN, DEFENSE_X_MAX, DEFENSE_Y_MIN, DEFENSE_Y_MAX);

    %% ==================== 分配各阶段目标数量 ====================
    % 按论文规则分配: 新增目标约占前一阶段的20%-40%
    phase_targets = distribute_targets_across_phases(n, T_total);

    fprintf('各阶段目标数: [%s]\n', num2str(phase_targets));

    %% ==================== 生成多阶段算例数据 ====================
    instance = struct();
    instance.name = sprintf('instance_%d_%d_%d_%d', n, L, m, T_total);
    instance.n = n;
    instance.L = L;
    instance.m = m;
    instance.T_total = T_total;
    instance.phase_targets = phase_targets;

    % 武器参数
    instance.weapon_x = weapon_x;
    instance.weapon_y = weapon_y;
    instance.R_max = R_max;
    instance.tau_react = tau_react;
    instance.v_weapon = v_weapon;
    instance.priority = priority;
    instance.ammo = ammo;
    instance.available = ammo;  % 初始可用弹药等于载弹量
    instance.alpha = alpha;

    % 雷达参数
    instance.radar_x = radar_x;
    instance.radar_y = radar_y;
    instance.lambda = lambda;
    instance.R_radar = R_radar;
    instance.p_th = p_th;
    instance.C_track = params.C_track * ones(1, L);

    % 其他参数
    instance.lambda0 = params.lambda0;
    instance.dt = params.dt;

    % 生成各阶段数据
    instance.phases = cell(1, T_total);
    cumulative_targets = 0;

    % 存活目标列表
    survived_targets = [];

    for t = 1:T_total
        fprintf('生成第 %d 阶段数据 (%d个目标)...\n', t, phase_targets(t));

        % 确定当前阶段目标
        if t == 1
            % 第一阶段: 全部为新目标
            current_target_indices = 1:phase_targets(t);
        else
            % 后续阶段: 部分存活目标 + 新目标
            n_new = round(phase_targets(t-1) * (0.2 + 0.2*rand()));  % 20%-40%新增
            n_new = min(n_new, phase_targets(t));  % 不超过总目标数
            n_survived = phase_targets(t) - n_new;

            % 从存活目标中随机选择
            if length(survived_targets) >= n_survived
                selected_survived = survived_targets(randperm(length(survived_targets), n_survived));
            else
                selected_survived = survived_targets;
            end

            % 新目标索引
            n_used = cumulative_targets;
            new_indices = (n_used+1):min(n_used+n_new, n);

            current_target_indices = [selected_survived, new_indices];
        end

        % 提取当前阶段目标
        current_targets = targets_all(current_target_indices);

        % 更新目标位置 (考虑时间推进)
        for j = 1:length(current_targets)
            time_elapsed = (t-1) * params.dt;
            heading_rad = current_targets(j).heading * pi / 180;
            current_targets(j).position_x = current_targets(j).position_x - current_targets(j).speed * time_elapsed * cos(heading_rad);
            current_targets(j).position_y = current_targets(j).position_y - current_targets(j).speed * time_elapsed * sin(heading_rad);

            % 威胁等级随时间增加
            current_targets(j).threat = min(1.0, current_targets(j).threat + 0.05 * (t-1));
        end

        % 计算预计算矩阵
        [P_ij, eta_j, d_ij, W_jt, U_jt, P_min_jt] = compute_phase_matrices(...
            current_targets, weapon_x, weapon_y, R_max, tau_react, v_weapon, priority, ...
            radar_x, radar_y, lambda, R_radar, p_th, ammo);

        % 保存阶段数据
        phase_data = struct();
        phase_data.phase = t;
        phase_data.n_t = phase_targets(t);
        phase_data.targets = current_targets;
        phase_data.P_ij = P_ij;
        phase_data.eta_j = eta_j;
        phase_data.d_ij = d_ij;
        phase_data.W_jt = W_jt;
        phase_data.U_jt = U_jt;
        phase_data.P_min_jt = P_min_jt;
        phase_data.available = ammo;  % 更新可用弹药

        instance.phases{t} = phase_data;

        % 更新累计目标数和存活目标
        cumulative_targets = cumulative_targets + phase_targets(t);

        % 模拟存活目标 (简单假设70%存活)
        n_destroyed = round(phase_targets(t) * 0.7);
        survived_targets = current_target_indices;
        if length(survived_targets) > n_destroyed
            survived_targets = survived_targets(randperm(length(survived_targets), n_destroyed));
        end
    end

    %% ==================== 保存算例 ====================
    if ~isempty(args.save_file)
        save_path = fullfile(params.instance_dir, args.save_file);
        instance.save_path = save_path;
        save(save_path, 'instance');
        fprintf('算例已保存至: %s\n', save_path);
    end

    fprintf('=== 算例生成完成 ===\n');
end

%% ==================== 辅助函数 ====================

function targets = generate_all_targets(n, params, def_x_min, def_x_max, def_y_min, def_y_max)
    % 生成所有目标，包含隐身特性分布

    targets = struct('id', {}, 'position_x', {}, 'position_y', {}, ...
        'speed', {}, 'heading', {}, 'threat', {}, 'RCS', {}, ...
        'W', {}, 'U', {}, 'P_min', {}, 'category', {});

    % 确定各类型目标数量
    n_conventional = round(n * params.ratio_conventional);
    n_low_observable = round(n * params.ratio_low_observable);
    n_stealth = n - n_conventional - n_low_observable;

    % 随机分配目标类型
    category_pool = [repmat({'conventional'}, 1, n_conventional), ...
        repmat({'low_observable'}, 1, n_low_observable), ...
        repmat({'stealth'}, 1, n_stealth)];
    categories = category_pool(randperm(n));

    for j = 1:n
        targets(j).id = j;

        % 目标位置: 来袭区域
        targets(j).position_x = def_x_max + rand() * (params.area_x_max - def_x_max);
        targets(j).position_y = params.area_y_min + rand() * (params.area_y_max - params.area_y_min);

        % 运动参数
        targets(j).speed = params.speed_min + rand() * (params.speed_max - params.speed_min);

        % 航向: 指向防御区域中心
        center_x = (def_x_min + def_x_max) / 2;
        center_y = (def_y_min + def_y_max) / 2;
        heading_to_defense = atan2(center_y - targets(j).position_y, center_x - targets(j).position_x) * 180 / pi;
        targets(j).heading = heading_to_defense + (rand() - 0.5) * 40;  % ±20度扰动

        % 威胁等级: 基于位置和类型
        x_normalized = (targets(j).position_x - def_x_max) / (params.area_x_max - def_x_max);
        threat_base = 1 - x_normalized;
        targets(j).threat = max(params.threat_min, min(params.threat_max, threat_base + rand() * 0.3));

        % RCS: 基于隐身类型
        cat = categories{j};
        switch cat
            case 'conventional'
                targets(j).RCS = 10^(rand() * log10(params.rcs_conventional(2)/params.rcs_conventional(1)) + log10(params.rcs_conventional(1)));
            case 'low_observable'
                targets(j).RCS = 10^(rand() * log10(params.rcs_low_observable(2)/params.rcs_low_observable(1)) + log10(params.rcs_low_observable(1)));
            case 'stealth'
                targets(j).RCS = 10^(rand() * log10(params.rcs_stealth(2)/params.rcs_stealth(1)) + log10(params.rcs_stealth(1)));
        end
        targets(j).category = cat;

        % 打击窗口和弹药限制
        targets(j).W = 60 + rand() * 30;  % 打击窗口 (s)
        targets(j).U = randi([1, 3]);      % 最大允许弹药
        targets(j).P_min = 0.3 + rand() * 0.2;  % 最低毁伤概率
    end
end

function phase_targets = distribute_targets_across_phases(n, T_total)
    % 将总目标数分配到各阶段

    if T_total == 1
        phase_targets = n;
        return;
    end

    phase_targets = zeros(1, T_total);
    remaining = n;

    for t = 1:T_total-1
        % 按比例递减，每阶段减少约20%-40%
        ratio = 0.6 + rand() * 0.2;  % 60%-80%保留
        n_t = round(remaining * ratio);
        n_t = max(1, n_t);  % 至少1个目标
        phase_targets(t) = n_t;
        remaining = remaining - n_t;
    end

    % 最后阶段分配剩余目标
    phase_targets(T_total) = remaining;
end

function [P_ij, eta_j, d_ij, W_jt, U_jt, P_min_jt] = compute_phase_matrices(...
    targets, weapon_x, weapon_y, R_max, tau_react, v_weapon, priority, ...
    radar_x, radar_y, lambda, R_radar, p_th, ammo)

    n = length(targets);
    m = length(weapon_x);
    L = length(radar_x);

    % 初始化矩阵
    P_ij = zeros(m, n);
    d_ij = zeros(m, n);
    W_jt = zeros(1, n);
    U_jt = zeros(1, n);
    P_min_jt = zeros(1, n);

    % 计算武器-目标距离和毁伤概率
    for i = 1:m
        for j = 1:n
            d_ij(i,j) = sqrt((weapon_x(i) - targets(j).position_x)^2 + ...
                (weapon_y(i) - targets(j).position_y)^2);

            % 射程内计算毁伤概率
            if d_ij(i,j) <= R_max(i)
                range_factor = 1 - (d_ij(i,j) / R_max(i));
                rcs_factor = min(1, targets(j).RCS / 1.0);
                P_ij(i,j) = 0.7 * range_factor * rcs_factor + 0.25;
                P_ij(i,j) = min(0.99, P_ij(i,j));
            else
                P_ij(i,j) = 0;
            end
        end
    end

    % 雷达探测
    p_kj = zeros(L, n);
    for k = 1:L
        for j = 1:n
            d_kj = sqrt((radar_x(k) - targets(j).position_x)^2 + ...
                (radar_y(k) - targets(j).position_y)^2);

            if d_kj <= R_radar(k)
                sigma = targets(j).RCS;
                p_kj(k,j) = exp(-lambda(k) * d_kj^4 / sigma);
                p_kj(k,j) = max(0.05, p_kj(k,j));
            else
                p_kj(k,j) = 0;
            end
        end
    end

    % 计算MRFDQI (多雷达融合探测质量指数)
    eta_j = zeros(1, n);
    for j = 1:n
        valid_idx = find(p_kj(:, j) >= p_th);
        if isempty(valid_idx)
            valid_idx = find(p_kj(:, j) > 0);
        end
        if isempty(valid_idx)
            eta_j(j) = 0;
        else
            prod_term = 1;
            for k = valid_idx'
                prod_term = prod_term * (1 - p_kj(k, j));
            end
            eta_j(j) = 1 - prod_term;
            eta_j(j) = max(0.1, eta_j(j));
        end

        % 复制目标参数
        W_jt(j) = targets(j).W;
        U_jt(j) = targets(j).U;
        P_min_jt(j) = targets(j).P_min;
    end
end

%% ==================== 内联默认参数 ====================

function params = get_default_params()
    % 内联默认参数，避免路径依赖
    params = struct();

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
    params.rcs_conventional = [1, 5];
    params.rcs_low_observable = [0.1, 1];
    params.rcs_stealth = [0.01, 0.1];
    params.ratio_conventional = 0.6;
    params.ratio_low_observable = 0.3;
    params.ratio_stealth = 0.1;

    % 目标动态参数
    params.speed_min = 0.3;
    params.speed_max = 0.7;
    params.threat_min = 0.3;
    params.threat_max = 1.0;

    % 武器参数
    params.weapon_range_min = 150;
    params.weapon_range_max = 180;
    params.weapon_react_min = 8;
    params.weapon_react_max = 12;
    params.weapon_speed_min = 2.5;
    params.weapon_speed_max = 3.0;
    params.ammo_per_weapon = 6;

    % 雷达参数
    params.radar_range_min = 220;
    params.radar_range_max = 250;
    params.radar_lambda_min = 5e-9;
    params.radar_lambda_max = 7e-9;
    params.p_th = 0.1;
    params.C_track = 10;

    % 作战参数
    params.dt = 30;
    params.lambda0 = 1.0;
end
