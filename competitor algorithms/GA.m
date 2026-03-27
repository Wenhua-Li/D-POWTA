% GA.m - Standard Genetic Algorithm for D-POWTA
% 标准遗传算法（对比基准算法）
%
% 特点：
% - 与KG-DREA相同的TC-FCE编码方式
% - 标准交叉、变异、选择算子
% - 无跨阶段知识迁移机制
% - 无小生境多模态保持机制
% - 无RMI鲁棒性选择
%
% Author: Competitor Algorithms
% Date: 2026-03-26

TestInstanceNum = 1;  % 算例编号选择 (1-10)

% 添加路径以找到其他模块的函数
addpath('../_visualization');
addpath('../_core');
addpath('../_utils');

%% ==================== 参数设置 ====================
N = 50;           % 种群规模
G_max = 100;      % 最大迭代代数
p_crossover = 0.8;  % 交叉概率
p_mut = 0.02;     % 变异概率

%% ==================== 加载算例 ====================
fprintf('\n');
fprintf('========================================\n');
fprintf('   GA 标准遗传算法求解\n');
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
fprintf('GA参数: N=%d, G_max=%d, p_crossover=%.2f, p_mut=%.2f\n', ...
    N, G_max, p_crossover, p_mut);
fprintf('\n');

%% ==================== GA主算法 ====================
tic;
total_fitness = 0;
ga_results = cell(1, instance.T_total);

for t = 1:instance.T_total
    fprintf('\n--- 阶段 %d/%d ---\n', t, instance.T_total);

    phase_data = instance.phases{t};
    n_t = phase_data.n_t;
    targets = phase_data.targets;

    % 约束预处理：构造有效配对集
    A = constraint_preprocess(phase_data, instance);

    % ========== GA进化 ==========

    % 初始化种群
    P = init_population(N, A);

    % 评估初始种群
    for i = 1:length(P)
        P(i).allocation = encoding_decode(P(i).c, A);
        % 约束修复
        [P(i).allocation, P(i).c] = repair_constraints(P(i).allocation, P(i).c, A, targets, instance.ammo);
        P(i).fitness = fitness_evaluator_ga(P(i).allocation, targets, phase_data);
    end

    % 进化主循环
    fitness_history = zeros(1, G_max);

    for g = 1:G_max
        % 交叉
        Q = crossover(P, p_crossover);

        % 变异（标准变异，无知识引导）
        Q = mutation(Q, A, p_mut);

        % 评估子代
        for i = 1:length(Q)
            Q(i).allocation = encoding_decode(Q(i).c, A);
            % 约束修复
            [Q(i).allocation, Q(i).c] = repair_constraints(Q(i).allocation, Q(i).c, A, targets, instance.ammo);
            Q(i).fitness = fitness_evaluator_ga(Q(i).allocation, targets, phase_data);
        end

        % 合并父代和子代
        R = [P, Q];

        % 标准选择（基于适应度的锦标赛选择，无小生境）
        P = selection(R, N);

        % 修复选择后的种群约束
        for i = 1:length(P)
            [P(i).allocation, P(i).c] = repair_constraints(P(i).allocation, P(i).c, A, targets, instance.ammo);
        end

        % 记录最优适应度
        fitness_history(g) = min([P.fitness]);

        if mod(g, 20) == 0
            fprintf('  Generation %d: Best fitness = %.4f\n', g, fitness_history(g));
        end
    end

    % 选择最优解
    [~, best_idx] = min([P.fitness]);
    best = P(best_idx);

    % 最终修复确保c和allocation同步
    [best.allocation, best.c] = repair_constraints(best.allocation, best.c, A, targets, instance.ammo);
    best.fitness = fitness_evaluator_ga(best.allocation, targets, phase_data);

    fprintf('  最优适应度: %.4f\n', best.fitness);

    % 打印详细表格
    fprintf('\n--- 阶段 %d ---\n', t);
    fprintf('  残余威胁 = %.6f,  RMI = N/A\n', best.fitness);
    fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
        '目标', '威胁', '武器', '雷达', '弹药数');
    fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
        '----', '----', '----', '----', '----');
    for j = 1:n_t
        if best.c(j) > 0 && best.c(j) <= length(A(j).combos)
            combo = A(j).combos{best.c(j)};
            if ~isempty(combo) && combo(1) > 0
                fprintf('  T%-5d %-10.2f W%-4d R%-4d %-10d\n', ...
                    j, targets(j).threat, combo(1), combo(2), combo(3));
            else
                fprintf('  T%-5d %-10.2f 未拦截\n', j, targets(j).threat);
            end
        else
            fprintf('  T%-5d %-10.2f 未拦截\n', j, targets(j).threat);
        end
    end

    ga_results{t}.c = best.c;
    ga_results{t}.fitness = best.fitness;
    ga_results{t}.allocation = best.allocation;
    ga_results{t}.fitness_history = fitness_history;

    total_fitness = total_fitness + best.fitness;
end

elapsed_time = toc;

%% ==================== 结果输出 ====================
fprintf('\n========================================\n');
fprintf('   GA求解完成\n');
fprintf('========================================\n');
fprintf('算法: GA (标准遗传算法)\n');
fprintf('算例: %s\n', instance_name);
fprintf('总耗时: %.4f 秒\n', elapsed_time);
fprintf('总残余威胁: %.4f\n', total_fitness);
fprintf('\n各阶段结果:\n');
for t = 1:instance.T_total
    fprintf('  阶段%d: %.4f\n', t, ga_results{t}.fitness);
end

% 保存结果
if ~exist('results', 'dir')
    mkdir('results');
end
save(['results/GA_result_', instance_name, '.mat'], 'ga_results', 'instance', 'elapsed_time');

fprintf('\n结果已保存至 results/GA_result_%s.mat\n', instance_name);

%% ==================== 结果分析 ====================
fprintf('\n========================================\n');
fprintf('   结果分析\n');
fprintf('========================================\n');

% 计算统计数据
fitness_values = zeros(1, instance.T_total);
convergence_data = cell(1, instance.T_total);
for t = 1:instance.T_total
    fitness_values(t) = ga_results{t}.fitness;
    convergence_data{t} = ga_results{t}.fitness_history;
end

fprintf('\n【残余威胁统计】\n');
fprintf('  均值: %.4f\n', mean(fitness_values));
fprintf('  标准差: %.4f\n', std(fitness_values));
fprintf('  最大值: %.4f\n', max(fitness_values));
fprintf('  最小值: %.4f\n', min(fitness_values));

fprintf('\n【收敛分析】\n');
for t = 1:instance.T_total
    hist = convergence_data{t};
    if ~isempty(hist)
        improvement = (hist(1) - hist(end)) / hist(1) * 100;
        fprintf('  阶段%d: 初始=%.4f, 最终=%.4f, 提升=%.2f%%\n', ...
            t, hist(1), hist(end), improvement);
    end
end

% 调用可视化函数
plot_GA_results(instance, ga_results, instance_name);

fprintf('\n可视化已生成!\n');


%% ==================== 可视化函数 ====================

function plot_GA_results(instance, ga_results, instance_name)
fprintf('\n生成可视化...\n');

% 图1: 收敛曲线
n_phases = instance.T_total;
if n_phases <= 4
    fig1 = figure('Position', [100, 100, 1000, 400], 'Color', [1 1 1]);
    for t = 1:n_phases
        subplot(1, n_phases, t);
        hist = ga_results{t}.fitness_history;
        if ~isempty(hist)
            plot(1:length(hist), hist, 'b-', 'LineWidth', 2);
            xlabel('Generation');
            ylabel('Fitness');
            title(sprintf('阶段%d 收敛曲线', t));
            grid on;
        end
    end
    sgtitle([instance_name, ' GA算法 - 收敛曲线'], 'FontSize', 14, 'FontWeight', 'bold');
else
    fig1 = figure('Position', [100, 100, 1200, 800], 'Color', [1 1 1]);
    for t = 1:n_phases
        subplot(ceil(n_phases/2), 2, t);
        hist = ga_results{t}.fitness_history;
        if ~isempty(hist)
            plot(1:length(hist), hist, 'b-', 'LineWidth', 2);
            xlabel('Generation');
            ylabel('Fitness');
            title(sprintf('阶段%d', t));
            grid on;
        end
    end
    sgtitle([instance_name, ' GA算法 - 收敛曲线'], 'FontSize', 14, 'FontWeight', 'bold');
end
saveas(fig1, ['results/GA_', instance_name, '_convergence.png']);
close(fig1);

% 图2: 各阶段残余威胁
fitness_vals = zeros(1, instance.T_total);
for t = 1:instance.T_total
    fitness_vals(t) = ga_results{t}.fitness;
end
fig2 = figure('Position', [100, 100, 800, 300], 'Color', [1 1 1]);
subplot(1, 2, 1);
bar(1:instance.T_total, fitness_vals, 'FaceColor', [0.2, 0.6, 0.8]);
xlabel('阶段');
ylabel('残余威胁');
title([instance_name, ' GA算法 - 各阶段残余威胁']);
grid on;

% 各阶段改进率
subplot(1, 2, 2);
improvement = zeros(1, instance.T_total);
for t = 1:instance.T_total
    hist = ga_results{t}.fitness_history;
    if ~isempty(hist) && hist(1) > 0
        improvement(t) = (hist(1) - hist(end)) / hist(1) * 100;
    end
end
bar(1:instance.T_total, improvement, 'FaceColor', [0.4, 0.7, 0.4]);
xlabel('阶段');
ylabel('改进率 (%)');
title([instance_name, ' GA算法 - 各阶段收敛改进率']);
grid on;

saveas(fig2, ['results/GA_', instance_name, '_performance.png']);
close(fig2);

% 图3: 各阶段分配方案可视化
for t = 1:instance.T_total
    solution.fitness = ga_results{t}.fitness;
    solution.rmi = 0;
    solution.allocation = ga_results{t}.allocation;
    save_path = sprintf('results/GA_%s_phase%d_allocation.png', instance_name, t);
    plot_allocation(instance, solution, t, save_path);
end

fprintf('  - GA_%s_convergence.png: 收敛曲线\n', instance_name);
fprintf('  - GA_%s_performance.png: 性能指标\n', instance_name);
fprintf('  - GA_%s_phaseX_allocation.png: 各阶段分配方案\n', instance_name);
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

            % 枚举弹药数量
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


function P = init_population(N, A)
% 种群初始化
n_t = length(A);
P = struct('c', {}, 'allocation', {}, 'fitness', {});

for i = 1:N
    c = zeros(1, n_t);
    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1
            c(j) = randi(H_jt - 1);  % 随机选择（不选最后一个空选项）
        end
    end
    P(i).c = c;
end
end


function Q = crossover(P, p_crossover)
% 均匀交叉算子
N = length(P);
indices = randperm(N);
Q = struct('c', {}, 'allocation', {}, 'fitness', {});

for i = 1:2:length(indices) - 1
    if i + 1 > length(indices)
        break;
    end

    p1 = P(indices(i)).c;
    p2 = P(indices(i + 1)).c;

    if rand() < p_crossover
        child = zeros(size(p1));
        for j = 1:length(p1)
            if rand() < 0.5
                child(j) = p1(j);
            else
                child(j) = p2(j);
            end
        end
    else
        child = p1;
    end

    Q(end + 1).c = child;
end
end


function Q = mutation(Q, A, p_mut)
% 标准变异算子（无知识引导）
for i = 1:length(Q)
    c = Q(i).c;
    n_t = length(c);

    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1 && rand() < p_mut
            c(j) = randi(H_jt - 1);
        end
    end

    Q(i).c = c;
end
end


function P_next = selection(R, N)
% 标准锦标赛选择（无小生境机制）
% 每次从R中随机选择2个个体，保留较优者

[~, sort_idx] = sort([R.fitness], 'ascend');
R_sorted = R(sort_idx);

P_next = struct('c', {}, 'allocation', {}, 'fitness', {});

for i = 1:length(R_sorted)
    if length(P_next) >= N
        break;
    end
    P_next(end + 1) = R_sorted(i);
end

% 如果种群规模不足，随机补充
while length(P_next) < N
    idx = randi(length(R_sorted));
    P_next(end + 1) = R_sorted(idx);
end
end


function allocation = encoding_decode(c, A)
% TC-FCE解码
n_t = length(c);

% 获取矩阵维度
m_max = 0;
L_max = 0;
for j = 1:n_t
    for idx = 1:length(A(j).combos)
        combo = A(j).combos{idx};
        m_max = max(m_max, combo(1));
        L_max = max(L_max, combo(2));
    end
end

allocation.x_ijkt = zeros(m_max, n_t, L_max);

% 解码
for j = 1:n_t
    combo_idx = c(j);

    if combo_idx == 0 || combo_idx > length(A(j).combos)
        continue;
    end

    combo = A(j).combos{combo_idx};
    i = combo(1);
    k = combo(2);
    s = combo(3);

    if i > 0 && k > 0
        allocation.x_ijkt(i, j, k) = s;
    end
end
end


function [allocation, c] = repair_constraints(allocation, c, A, targets, weapon_ammo)
% 全局资源约束修复
% 按威胁优先级重新分配，确保每个武器总弹药不超过限制
[m, n_t, L] = size(allocation.x_ijkt);
n_weapons = length(weapon_ammo);

% 计算每个武器当前使用弹药数
usage = zeros(n_weapons, 1);
for i = 1:min(m, n_weapons)
    usage(i) = sum(allocation.x_ijkt(i, :, :), 'all');
end

% 获取按威胁优先级排序的目标索引
[~, priority_idx] = sort([targets.threat], 'descend');

% 创建新的分配矩阵
new_alloc = zeros(m, n_t, L);

% 按威胁优先级重新分配，同时更新 c
new_c = zeros(1, n_t);

for j_idx = 1:n_t
    j = priority_idx(j_idx);

    % 遍历该目标的分配 - 按P_ij降序排列的武器
    for i = 1:min(m, n_weapons)
        for k = 1:L
            s = allocation.x_ijkt(i, j, k);
            if s > 0
                % 检查弹药是否足够
                if usage(i) + s <= weapon_ammo(i)
                    new_alloc(i, j, k) = s;
                    usage(i) = usage(i) + s;
                    % 找到对应的组合索引
                    for idx = 1:length(A(j).combos)
                        combo = A(j).combos{idx};
                        if ~isempty(combo) && combo(1) == i && combo(2) == k && combo(3) == s
                            new_c(j) = idx;
                            break;
                        end
                    end
                    break;
                end
                % 如果弹药不足，尝试为该目标找替代方案
                % 遍历该目标的所有可行组合，找一个弹药足够的
                best_found = false;
                for combo_idx = 1:length(A(j).combos)
                    combo = A(j).combos{combo_idx};
                    if isempty(combo) || combo(1) == 0
                        continue;
                    end
                    alt_i = combo(1);
                    alt_k = combo(2);
                    alt_s = combo(3);
                    % 检查替代方案弹药是否足够
                    if usage(alt_i) + alt_s <= weapon_ammo(alt_i)
                        new_alloc(alt_i, j, alt_k) = alt_s;
                        usage(alt_i) = usage(alt_i) + alt_s;
                        new_c(j) = combo_idx;
                        best_found = true;
                        break;
                    end
                end
                if best_found
                    break;  % 找到替代方案，处理下一个(j,k)对
                end
                % 如果没找到替代方案，该目标被放弃
                break;
            end
        end
    end
end

allocation.x_ijkt = new_alloc;
c = new_c;
end


function fitness = fitness_evaluator_ga(allocation, targets, phase_data)
% GA适应度评估函数
n_t = length(targets);
[m, ~, L] = size(allocation.x_ijkt);
P_ij = phase_data.P_ij;
eta_j = phase_data.eta_j;

fitness = 0;

for j = 1:n_t
    target = targets(j);
    survival = 1;

    for i = 1:min(m, size(P_ij, 1))
        for k = 1:L
            x = allocation.x_ijkt(i, j, k);
            if x > 0 && i <= size(P_ij, 1)
                survival = survival * (1 - P_ij(i, j))^x;
            end
        end
    end

    % 目标函数：加权残余威胁
    fitness = fitness + target.threat * eta_j(j) * survival;
end
end