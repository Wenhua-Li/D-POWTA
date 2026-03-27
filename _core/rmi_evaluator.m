% D-POWTA RMI鲁棒性度量指标评估器
%
% RMI (Robustness Metric Index) 定义:
%   ρ(c) = (1/|N_r(c)|) * Σ[F(c') - F(c)]
%
% 其中:
%   - N_r(c) 为r阶汉明邻域
%   - F(c) 为目标函数值
%   - ρ越大表示解越鲁棒(处于更深的"谷底")
%
% 使用方式:
%   rmi = rmi_evaluator(solution, A_jt, phase_data, instance, params)
%
% 输入:
%   solution   - 待评估的解
%   A_jt       - 有效配对集
%   phase_data - 阶段数据
%   instance   - 算例数据
%   params     - 参数结构体
%
% 输出:
%   rmi - RMI鲁棒性指标值
%
% Author: KG-DREA
% Date: 2026-03-18

function rmi = rmi_evaluator(solution, A_jt, phase_data, instance, params)
    c = solution.c;
    n_t = length(c);
    r = params.r;      % 邻域半径
    S = params.S;      % 蒙特卡洛采样数
    use_mc = params.use_monte_carlo;

    % 计算当前解的目标函数值
    f_current = solution.fitness;

    if use_mc && n_t > 20
        % 大规模问题: 使用蒙特卡洛近似
        rmi = compute_monte_carlo_rmi(c, f_current, A_jt, phase_data, instance, r, S);
    else
        % 小规模问题: 精确枚举
        rmi = compute_exact_rmi(c, f_current, A_jt, phase_data, instance, r);
    end
end

%% ==================== 精确计算 ====================

function rmi = compute_exact_rmi(c, f_current, A_jt, phase_data, instance, r)
    n_t = length(c);

    % 枚举r阶汉明邻域
    neighbors = generate_hamming_neighbors(c, r, A_jt);

    if isempty(neighbors)
        rmi = 0;
        return;
    end

    % 计算邻居的适应度
    neighbor_fitness = zeros(1, length(neighbors));
    for i = 1:length(neighbors)
        neighbor = neighbors{i};
        allocation = encoding_decode(neighbor, A_jt);
        neighbor_fitness(i) = fitness_evaluator(allocation, phase_data, instance);
    end

    % 计算RMI
    rmi = mean(neighbor_fitness - f_current);
end

%% ==================== 蒙特卡洛近似 ====================

function rmi = compute_monte_carlo_rmi(c, f_current, A_jt, phase_data, instance, r, S)
    n_t = length(c);

    neighbor_fitness = zeros(1, S);

    for s = 1:S
        % 随机生成一个邻居
        neighbor_c = generate_random_neighbor(c, r, A_jt);

        % 计算邻居适应度
        allocation = encoding_decode(neighbor_c, A_jt);
        neighbor_fitness(s) = fitness_evaluator(allocation, phase_data, instance);
    end

    % 计算RMI (蒙特卡洛估计)
    rmi = mean(neighbor_fitness - f_current);
end

%% ==================== 辅助函数 ====================

function neighbors = generate_hamming_neighbors(c, r, A_jt)
    % 生成所有r阶汉明邻居
    n_t = length(c);

    neighbors = {};

    % 生成所有可能的变异组合
   var_positions = nchoosek(1:n_t, r);
    n_combinations = size(var_positions, 1);

    for i = 1:min(n_combinations, 1000)  % 限制数量
        neighbor_c = c;
        positions = var_positions(i, :);

        for pos = positions
            % 随机选择一个新的组合
            H_jt = length(A_jt(pos).combos);
            if H_jt > 1
                new_idx = randi(H_jt);
                neighbor_c(pos) = new_idx;
            end
        end

        neighbors{end+1} = neighbor_c;  %#ok<AGROW>
    end
end

function neighbor_c = generate_random_neighbor(c, r, A_jt)
    % 随机生成一个r阶汉明邻居
    n_t = length(c);
    neighbor_c = c;

    % 随机选择r个位置
    positions = randperm(n_t, min(r, n_t));

    for pos = positions
        H_jt = length(A_jt(pos).combos);
        if H_jt > 1
            % 随机选择一个新的组合索引
            new_idx = randi(H_jt);
            neighbor_c(pos) = new_idx;
        end
    end
end
