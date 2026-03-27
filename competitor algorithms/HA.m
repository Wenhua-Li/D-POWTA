% HA.m - Heuristic Allocation Algorithm for D-POWTA
% 基于专家规则驱动的工程基线方法
%
% 算法步骤：
% 1. 按威胁等级Th_jt和MRFDQI η_jt降序排列目标
% 2. 对每个目标贪心选择毁伤概率最高的武器
% 3. 使用资源保护参数γ=0.5防止资源过度集中
%
% Author: Competitor Algorithms
% Date: 2026-03-26
close all;clc;clear

TestInstanceNum = 2;  % 算例编号选择 (1-10)

% 添加路径以找到其他模块的函数
addpath('../_visualization');
addpath('../_core');
addpath('../_utils');

%% ==================== 参数设置 ====================
gamma = 0.5;  % 资源保护参数，防止过度集中

%% ==================== 加载算例 ====================
fprintf('\n');
fprintf('========================================\n');
fprintf('   HA 启发式分配算法求解\n');
fprintf('========================================\n');
fprintf('\n');

% 根据选择加载对应算例
instance_files = {'I1.mat', 'I2.mat', 'I3.mat', 'I4.mat', 'I5.mat', ...
                  'I6.mat', 'I7.mat', 'I8.mat', 'I9.mat', 'I10.mat'};
instance_names = {'I1', 'I2', 'I3', 'I4', 'I5', 'I6', 'I7', 'I8', 'I9', 'I10'};

if TestInstanceNum < 1 || TestInstanceNum > 10
    error('算例编号必须在1-10之间');
end

filename = instance_files{TestInstanceNum};
instance_name = instance_names{TestInstanceNum};
fprintf('【加载算例】%s\n', filename);

% 加载算例
instance_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'instances', filename);
data = load(instance_path);
if isfield(data, 'instance')
    instance = data.instance;
else
    instance = data;
end

fprintf('算例: %s\n', instance.name);
fprintf('武器数: %d, 雷达数: %d, 总目标数: %d, 阶段数: %d\n', ...
    instance.m, instance.L, instance.n, instance.T_total);
fprintf('\n');

%% ==================== HA主算法 ====================
tic;
total_fitness = 0;
ha_results = cell(1, instance.T_total);

% 初始化资源状态（在所有阶段之前）
weapon_ammo = instance.ammo;  % 武器剩余弹药（跨阶段共享）
radar_channels = ones(1, instance.L) * 100;  % 雷达通道容量

for t = 1:instance.T_total
    fprintf('--- 阶段 %d/%d ---\n', t, instance.T_total);

    phase_data = instance.phases{t};
    targets = phase_data.targets;
    n_t = phase_data.n_t;

    % 约束预处理：构造有效配对集
    A = constraint_preprocess(phase_data, instance);

    % ========== HA核心步骤 ==========

    % 步骤1：计算每个目标的优先级得分并排序
    priority_scores = zeros(n_t, 2);  % [目标ID, 得分]
    for j = 1:n_t
        target = targets(j);
        priority_scores(j, 1) = j;
        % 得分 = 威胁等级 * MRFDQI
        priority_scores(j, 2) = target.threat * phase_data.eta_j(j);
    end

    % 按得分降序排列
    [~, sort_idx] = sortrows(priority_scores, -2);
    sorted_targets = sort_idx;

    % 初始化分配方案
    c = zeros(1, n_t);  % TC-FCE编码
    allocation = zeros(instance.m, n_t, instance.L);

    % 步骤2 & 3：贪心分配
    for idx = 1:length(sorted_targets)
        j = sorted_targets(idx);
        target = targets(j);

        % 寻找该目标的最优可用组合
        best_combo_idx = 0;
        best_score = -inf;
        best_combo = [];
        best_actual_s = 0;  % 实际分配的弹药数（可能因约束而调整）

        for combo_idx = 1:length(A(j).combos)
            combo = A(j).combos{combo_idx};
            if isempty(combo) || combo(1) == 0
                continue;
            end

            i = combo(1);  % 武器
            k = combo(2);  % 雷达
            s = combo(3);  % 弹药数

            % 检查雷达通道约束
            if radar_channels(k) < s
                continue;
            end

            % 检查弹药约束：如果弹药不足，尝试使用剩余弹药
            actual_s = s;
            if weapon_ammo(i) < s
                if weapon_ammo(i) <= 0
                    continue;  % 完全没有弹药，跳过
                end
                actual_s = weapon_ammo(i);  % 使用剩余弹药
            end

            % 计算毁伤概率得分（考虑资源保护γ）
            P_kill = phase_data.P_ij(i, j);
            % 考虑剩余资源的优先级调整
            resource_factor = 1 - gamma * (weapon_ammo(i) / instance.ammo(i));

            score = P_kill * resource_factor;

            if score > best_score
                best_score = score;
                best_combo_idx = combo_idx;
                best_combo = combo;
                best_actual_s = actual_s;
            end
        end

        % 执行分配
        if best_combo_idx > 0 && ~isempty(best_combo)
            c(j) = best_combo_idx;
            i = best_combo(1);
            k = best_combo(2);
            s = best_actual_s;
            allocation(i, j, k) = s;
            weapon_ammo(i) = weapon_ammo(i) - s;
            radar_channels(k) = radar_channels(k) - s;
        end
    end

    % 计算适应度
    fitness = fitness_evaluator_ha(allocation, targets, phase_data);

    % 构建解结构体（兼容plot_allocation）
    solution.fitness = fitness;
    solution.rmi = 0;  % HA不计算RMI
    solution.c = c;
    solution.allocation = struct('x_ijkt', allocation);

    % 打印详细表格
    fprintf('\n--- 阶段 %d ---\n', t);
    fprintf('  残余威胁 = %.6f,  RMI = N/A\n', fitness);
    fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
        '目标', '威胁', '武器', '雷达', '弹药数');
    fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
        '----', '----', '----', '----', '----');
    for j = 1:n_t
        if c(j) > 0 && c(j) <= length(A(j).combos)
            combo = A(j).combos{c(j)};
            if ~isempty(combo) && combo(1) > 0
                % 显示实际分配的弹药数（可能因约束而调整）
                actual_ammo = allocation(combo(1), j, combo(2));
                if actual_ammo ~= combo(3)
                    fprintf('  T%-5d %-10.2f W%-4d R%-4d %-10d (请求%d，调整为%d)\n', ...
                        j, targets(j).threat, combo(1), combo(2), actual_ammo, combo(3), actual_ammo);
                else
                    fprintf('  T%-5d %-10.2f W%-4d R%-4d %-10d\n', ...
                        j, targets(j).threat, combo(1), combo(2), combo(3));
                end
            else
                fprintf('  T%-5d %-10.2f 未拦截\n', j, targets(j).threat);
            end
        else
            fprintf('  T%-5d %-10.2f 未拦截\n', j, targets(j).threat);
        end
    end

    ha_results{t}.c = c;
    ha_results{t}.fitness = fitness;
    ha_results{t}.allocation = solution.allocation;

    total_fitness = total_fitness + fitness;
end

elapsed_time = toc;

%% ==================== 结果输出 ====================
fprintf('\n========================================\n');
fprintf('   HA求解完成\n');
fprintf('========================================\n');
fprintf('算法: HA (启发式分配算法)\n');
fprintf('算例: %s\n', instance_name);
fprintf('总耗时: %.4f 秒\n', elapsed_time);
fprintf('总残余威胁: %.4f\n', total_fitness);
fprintf('\n各阶段结果:\n');
for t = 1:instance.T_total
    fprintf('  阶段%d: %.4f\n', t, ha_results{t}.fitness);
end

% 保存结果
if ~exist('results', 'dir')
    mkdir('results');
end
save(['results/HA_result_', instance_name, '.mat'], 'ha_results', 'instance', 'elapsed_time');

fprintf('\n结果已保存至 results/HA_result_%s.mat\n', instance_name);

%% ==================== 结果分析 ====================
fprintf('\n========================================\n');
fprintf('   结果分析\n');
fprintf('========================================\n');

% 计算统计数据
fitness_values = zeros(1, instance.T_total);
for t = 1:instance.T_total
    fitness_values(t) = ha_results{t}.fitness;
end

fprintf('\n【残余威胁统计】\n');
fprintf('  均值: %.4f\n', mean(fitness_values));
fprintf('  标准差: %.4f\n', std(fitness_values));
fprintf('  最大值: %.4f\n', max(fitness_values));
fprintf('  最小值: %.4f\n', min(fitness_values));

% 调用可视化函数
plot_HA_results(instance, ha_results, instance_name);

fprintf('\n可视化已生成!\n');


%% ==================== 可视化函数 ====================

function plot_HA_results(instance, ha_results, instance_name)
fprintf('\n生成可视化...\n');

% 图1: 各阶段残余威胁
fitness_vals = zeros(1, instance.T_total);
for t = 1:instance.T_total
    fitness_vals(t) = ha_results{t}.fitness;
end
fig1 = figure('Position', [100, 100, 800, 300], 'Color', [1 1 1]);
bar(1:instance.T_total, fitness_vals, 'FaceColor', [0.2, 0.6, 0.8]);
xlabel('阶段');
ylabel('残余威胁');
title([instance_name, ' HA算法 - 各阶段残余威胁']);
grid on;
saveas(fig1, ['results/HA_', instance_name, '_threat.png']);
close(fig1);

% 图2: 各阶段分配方案可视化
for t = 1:instance.T_total
    solution.fitness = ha_results{t}.fitness;
    solution.rmi = 0;
    solution.allocation = ha_results{t}.allocation;
    save_path = sprintf('results/HA_%s_phase%d_allocation.png', instance_name, t);
    plot_allocation(instance, solution, t, save_path);
end

fprintf('  - HA_%s_threat.png: 各阶段残余威胁\n', instance_name);
fprintf('  - HA_%s_phaseX_allocation.png: 各阶段分配方案\n', instance_name);
end


%% ==================== 子函数 ====================

function A = constraint_preprocess(phase_data, instance)
% 约束预处理：构造有效配对集
n_t = phase_data.n_t;
targets = phase_data.targets;
m = instance.m;
L = instance.L;

A = struct('target_id', {}, 'combos', {}, 'H_jt', {});

for j = 1:n_t
    target = targets(j);
    A(j).target_id = target.id;
    combos = {};

    % 遍历所有雷达
    for k = 1:L
        % 计算雷达与目标距离
        d_kj = sqrt((instance.radar_x(k) - target.position_x)^2 + ...
                     (instance.radar_y(k) - target.position_y)^2);

        % 雷达探测距离约束 (C6)
        if d_kj > instance.R_radar(k)
            continue;
        end

        % 计算探测概率
        p_det = max(0.05, exp(-instance.lambda(k) * d_kj^4 / target.RCS));

        % 探测概率阈值约束 (C7)
        if p_det < instance.p_th
            continue;
        end

        % 遍历所有武器
        for i = 1:m
            % 武器与目标距离
            d_ij = sqrt((instance.weapon_x(i) - target.position_x)^2 + ...
                         (instance.weapon_y(i) - target.position_y)^2);

            % 射程约束 (C4)
            if d_ij > instance.R_max(i)
                continue;
            end

            % 打击时效约束 (C5)
            intercept_time = instance.tau_react(i) + d_ij / instance.v_weapon(i);
            if intercept_time > target.W
                continue;
            end

            % 可用弹药数
            available_ammo = min(instance.ammo(i), target.U);

            % 枚举弹药数量 (1到available_ammo)
            for s = 1:min(3, available_ammo)
                combos{end + 1} = [i, k, s];
            end
        end
    end

    % 添加不拦截选项
    combos{end + 1} = [0, 0, 0];

    A(j).combos = combos;
    A(j).H_jt = length(combos) - 1;
end
end


function fitness = fitness_evaluator_ha(allocation, targets, phase_data)
% HA适应度评估函数
n_t = length(targets);
[m, ~, L] = size(allocation);
P_ij = phase_data.P_ij;
eta_j = phase_data.eta_j;

fitness = 0;

for j = 1:n_t
    target = targets(j);
    survival = 1;

    for i = 1:min(m, size(P_ij, 1))
        for k = 1:L
            x = allocation(i, j, k);
            if x > 0 && i <= size(P_ij, 1)
                survival = survival * (1 - P_ij(i, j))^x;
            end
        end
    end

    % 目标函数：加权残余威胁
    fitness = fitness + target.threat * eta_j(j) * survival;
end
end