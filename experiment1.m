% experiment1.m
% 总体性能对比实验
% 运行全部算法(HA, GA, LKEA, KG-DREA)在全部测试算例(I1-I10)上
% 每个实验独立运行5次计算均值，最终输出LaTeX格式表格
%
% 使用方式: 在 MATLAB 中 cd 到本目录，运行 experiment1

close all; clear; clc;
addpath('_core', '_operators', '_utils', '_visualization', 'config', 'competitor algorithms');

%% ==================== 实验配置 ====================
instances = {'I1','I2','I3','I4','I5','I6','I7','I8','I9','I10'};
n_instances = length(instances);
n_runs = 5;  % 独立运行次数

fprintf('============================================\n');
fprintf('  D-POWTA 总体性能对比实验\n');
fprintf('============================================\n');
fprintf('算例: I1 ~ I10 (共%d个)\n', n_instances);
fprintf('算法: HA, GA, LKEA, KG-DREA\n');
fprintf('每次实验独立运行: %d次\n', n_runs);
fprintf('============================================\n\n');

%% ==================== 存储结果 ====================
% results(algo_idx, instance_idx, run_idx) = total_fitness
% algo_idx: 1=HA, 2=GA, 3=LKEA, 4=KG-DREA
algo_names = {'HA', 'GA', 'LKEA', 'KG-DREA'};
results = zeros(4, n_instances, n_runs);

%% ==================== KG-DREA 参数 ====================
params = default_params( ...
    'N',              50,      ...
    'G_max',          100,     ...
    'epsilon',        0.01,    ...
    'p_crossover',    0.8,     ...
    'p_mut',          0.02,    ...
    'p_guided',       0.7,     ...
    'r',              2,        ...
    'S',              50,       ...
    'use_monte_carlo', true,   ...
    'theta_c',        5,        ...
    'delta',          3,        ...
    'verbose',        false,    ...
    'save_history',   false ...
);

%% ==================== 逐个算例求解 ====================
for inst_idx = 1:n_instances
    inst_name = instances{inst_idx};
    fprintf('\n[%2d/%2d] 算例 %s\n', inst_idx, n_instances, inst_name);
    fprintf('--------------------------------------------\n');

    % 加载算例
    instance = load_instance([inst_name '.mat'], 'instances/');

    % 加载一次获取约束预处理函数所需的A_jt结构
    A_cell = cell(1, instance.T_total);
    for t = 1:instance.T_total
        A_cell{t} = constraint_preprocess(instance.phases{t}, instance, params);
    end

    %% ---- HA (确定性算法，只需运行1次) ----
    fprintf('  HA: ');
    ha_total = run_HA(instance);
    results(1, inst_idx, 1) = ha_total;
    for r = 2:n_runs
        results(1, inst_idx, r) = ha_total;  % 复制相同结果
    end
    fprintf('%.4f\n', ha_total);

    %% ---- GA (随机算法，运行5次) ----
    fprintf('  GA: ');
    ga_runs = zeros(1, n_runs);
    for r = 1:n_runs
        ga_runs(r) = run_GA(instance);
        fprintf('%.4f ', ga_runs(r));
    end
    results(2, inst_idx, :) = ga_runs;
    fprintf(' (Mean=%.4f, Std=%.4f)\n', mean(ga_runs), std(ga_runs));

    %% ---- LKEA (随机算法，运行5次) ----
    fprintf('  LKEA: ');
    lkea_runs = zeros(1, n_runs);
    for r = 1:n_runs
        lkea_runs(r) = run_LKEA(instance);
        fprintf('%.4f ', lkea_runs(r));
    end
    results(3, inst_idx, :) = lkea_runs;
    fprintf(' (Mean=%.4f, Std=%.4f)\n', mean(lkea_runs), std(lkea_runs));

    %% ---- KG-DREA (随机算法，运行5次) ----
    fprintf('  KG-DREA: ');
    kg_runs = zeros(1, n_runs);
    for r = 1:n_runs
        kg_runs(r) = run_KG_DREA(instance, params);
        fprintf('%.4f ', kg_runs(r));
    end
    results(4, inst_idx, :) = kg_runs;
    fprintf(' (Mean=%.4f, Std=%.4f)\n', mean(kg_runs), std(kg_runs));
end

%% ==================== 统计分析与显著性检验 ====================
fprintf('\n============================================\n');
fprintf('  统计分析\n');
fprintf('============================================\n');

% 计算均值和标准差
mean_results = squeeze(mean(results, 3));
std_results = squeeze(std(results, 0, 3));

% Wilcoxon rank-sum test (α = 0.05)
alpha = 0.05;
significance = cell(n_instances, 4);  % significance{inst_idx, algo_idx}

for inst_idx = 1:n_instances
    for algo_idx = 1:4
        sig_marks = '';

        % KG-DREA (algo 4) 与其他对比
        if algo_idx == 4
            % vs HA
            [~, p] = wilcoxon_rank_sum(results(4, inst_idx, :), results(1, inst_idx, :));
            sig_marks = [sig_marks, ifelse(p < alpha && mean_results(4, inst_idx) < mean_results(1, inst_idx), '+', '-')];

            % vs GA
            [~, p] = wilcoxon_rank_sum(results(4, inst_idx, :), results(2, inst_idx, :));
            sig_marks = [sig_marks, '/', ifelse(p < alpha && mean_results(4, inst_idx) < mean_results(2, inst_idx), '+', '-')];

            % vs LKEA
            [~, p] = wilcoxon_rank_sum(results(4, inst_idx, :), results(3, inst_idx, :));
            sig_marks = [sig_marks, '/', ifelse(p < alpha && mean_results(4, inst_idx) < mean_results(3, inst_idx), '+', '-')];
        end

        significance{inst_idx, algo_idx} = sig_marks;
    end
end

%% ==================== 输出LaTeX表格 ====================
fprintf('\n============================================\n');
fprintf('  LaTeX表格\n');
fprintf('============================================\n');

latex_table = sprintf('\\begin{tabular}{@{}cccccc@{}}\n');
latex_table = [latex_table, '    \\toprule\n'];
latex_table = [latex_table, '    \\textbf{算例} & \\textbf{HA} & \\textbf{GA} & \\textbf{LKEA} & \\textbf{KG-DREA} & \\textbf{显著性检验}$^{\\text{a}}$ \\\\\n'];
latex_table = [latex_table, '    \\midrule\n'];

for inst_idx = 1:n_instances
    inst_name = instances{inst_idx};

    % HA (确定性，只显示均值)
    ha_str = sprintf('$%.4f$', mean_results(1, inst_idx));

    % GA
    ga_str = sprintf('$%.4f \\pm %.2f$', mean_results(2, inst_idx), std_results(2, inst_idx));

    % LKEA
    lkea_str = sprintf('$%.4f \\pm %.2f$', mean_results(3, inst_idx), std_results(3, inst_idx));

    % KG-DREA
    kg_str = sprintf('$%.4f \\pm %.2f$', mean_results(4, inst_idx), std_results(4, inst_idx));

    % 显著性检验 (KG-DREA vs others)
    sig = significance{inst_idx, 4};

    latex_table = [latex_table, sprintf('    %s  & %s & %s & %s & %s & %s \\\\\n', ...
        inst_name, ha_str, ga_str, lkea_str, kg_str, sig)];
end

latex_table = [latex_table, '    \\bottomrule\n'];
latex_table = [latex_table, '\\end{tabular}\n'];

fprintf('\n%s\n', latex_table);

% 保存LaTeX表格到文件
fid = fopen('results/experiment1_table.tex', 'w');
fprintf(fid, '%s', latex_table);
fclose(fid);
fprintf('\nLaTeX表格已保存至: results/experiment1_table.tex\n');

% 保存完整结果
save('results/experiment1_results.mat', 'results', 'mean_results', 'std_results', ...
    'significance', 'instances', 'algo_names', 'n_runs');

fprintf('\n============================================\n');
fprintf('  实验完成\n');
fprintf('============================================\n');
fprintf('结果文件:\n');
fprintf('  results/experiment1_table.tex    - LaTeX表格\n');
fprintf('  results/experiment1_results.mat   - 完整结果数据\n');
fprintf('\n');


%% ==================== 辅助函数 ====================

function total_fitness = run_HA(instance)
% 运行HA算法，返回总残余威胁
gamma = 0.5;
weapon_ammo = instance.ammo;
radar_channels = ones(1, instance.L) * 100;
total_fitness = 0;

for t = 1:instance.T_total
    phase_data = instance.phases{t};
    targets = phase_data.targets;
    n_t = phase_data.n_t;

    A = constraint_preprocess_local(phase_data, instance);

    % 计算优先级得分并排序
    priority_scores = zeros(n_t, 2);
    for j = 1:n_t
        priority_scores(j, 1) = j;
        priority_scores(j, 2) = targets(j).threat * phase_data.eta_j(j);
    end
    [~, sort_idx] = sortrows(priority_scores, -2);

    c = zeros(1, n_t);

    for idx = 1:length(sort_idx)
        j = sort_idx(idx);
        target = targets(j);

        best_combo_idx = 0;
        best_score = -inf;
        best_combo = [];

        for combo_idx = 1:length(A(j).combos)
            combo = A(j).combos{combo_idx};
            if isempty(combo) || combo(1) == 0
                continue;
            end

            i = combo(1);
            k = combo(2);
            s = combo(3);

            if radar_channels(k) < s
                continue;
            end

            actual_s = s;
            if weapon_ammo(i) < s
                if weapon_ammo(i) <= 0
                    continue;
                end
                actual_s = weapon_ammo(i);
            end

            P_kill = phase_data.P_ij(i, j);
            resource_factor = 1 - gamma * (weapon_ammo(i) / instance.ammo(i));
            score = P_kill * resource_factor;

            if score > best_score
                best_score = score;
                best_combo_idx = combo_idx;
                best_combo = combo;
            end
        end

        if best_combo_idx > 0 && ~isempty(best_combo)
            c(j) = best_combo_idx;
            i = best_combo(1);
            k = best_combo(2);
            s = best_combo(3);
            weapon_ammo(i) = weapon_ammo(i) - s;
            radar_channels(k) = radar_channels(k) - s;
        end
    end

    fitness = fitness_evaluator_ha_local(c, targets, phase_data, A);
    total_fitness = total_fitness + fitness;
end
end


function total_fitness = run_GA(instance)
% 运行GA算法，返回总残余威胁
N = 50;
G_max = 100;
p_crossover = 0.8;
p_mut = 0.02;

total_fitness = 0;

for t = 1:instance.T_total
    phase_data = instance.phases{t};
    n_t = phase_data.n_t;
    targets = phase_data.targets;

    A = constraint_preprocess_local(phase_data, instance);

    % 初始化种群
    P = init_population_ga(N, n_t, A);

    % 评估
    for i = 1:length(P)
        P(i).allocation = encoding_decode_local(P(i).c, A);
        [P(i).allocation, P(i).c] = repair_constraints_local(P(i).allocation, P(i).c, A, targets, instance.ammo);
        P(i).fitness = fitness_evaluator_local(P(i).allocation, targets, phase_data);
    end

    % 进化
    for g = 1:G_max
        Q = crossover_ga(P, p_crossover);
        Q = mutation_ga(Q, A, p_mut);

        for i = 1:length(Q)
            Q(i).allocation = encoding_decode_local(Q(i).c, A);
            [Q(i).allocation, Q(i).c] = repair_constraints_local(Q(i).allocation, Q(i).c, A, targets, instance.ammo);
            Q(i).fitness = fitness_evaluator_local(Q(i).allocation, targets, phase_data);
        end

        R = [P, Q];
        P = selection_ga(R, N);

        for i = 1:length(P)
            [P(i).allocation, P(i).c] = repair_constraints_local(P(i).allocation, P(i).c, A, targets, instance.ammo);
        end
    end

    [~, best_idx] = min([P.fitness]);
    best = P(best_idx);
    [best.allocation, best.c] = repair_constraints_local(best.allocation, best.c, A, targets, instance.ammo);
    best.fitness = fitness_evaluator_local(best.allocation, targets, phase_data);

    total_fitness = total_fitness + best.fitness;
end
end


function total_fitness = run_LKEA(instance)
% 运行LKEA算法，返回总残余威胁
N = 50;
G_max = 100;
p_crossover = 0.8;
p_mut = 0.02;
p_guided = 0.7;

total_fitness = 0;

for t = 1:instance.T_total
    phase_data = instance.phases{t};
    n_t = phase_data.n_t;
    targets = phase_data.targets;

    A = constraint_preprocess_local(phase_data, instance);
    KB.elim_count = zeros(n_t, 50);

    P = init_population_lkea(N, A);

    for i = 1:length(P)
        P(i).allocation = encoding_decode_local(P(i).c, A);
        [P(i).allocation, P(i).c] = repair_constraints_local(P(i).allocation, P(i).c, A, targets, instance.ammo);
        P(i).fitness = fitness_evaluator_local(P(i).allocation, targets, phase_data);
    end

    for g = 1:G_max
        Q = crossover_lkea(P, p_crossover);
        Q = mutation_lkea(Q, A, KB, p_mut, p_guided);

        for i = 1:length(Q)
            Q(i).allocation = encoding_decode_local(Q(i).c, A);
            [Q(i).allocation, Q(i).c] = repair_constraints_local(Q(i).allocation, Q(i).c, A, targets, instance.ammo);
            Q(i).fitness = fitness_evaluator_local(Q(i).allocation, targets, phase_data);
        end

        R = [P, Q];
        P = selection_lkea(R, N);

        for i = 1:length(P)
            [P(i).allocation, P(i).c] = repair_constraints_local(P(i).allocation, P(i).c, A, targets, instance.ammo);
        end
    end

    [~, best_idx] = min([P.fitness]);
    best = P(best_idx);
    [best.allocation, best.c] = repair_constraints_local(best.allocation, best.c, A, targets, instance.ammo);
    best.fitness = fitness_evaluator_local(best.allocation, targets, phase_data);

    total_fitness = total_fitness + best.fitness;
end
end


function total_fitness = run_KG_DREA(instance, params)
% 运行KG-DREA算法，返回总残余威胁
result = solve_kgdrea(instance, params);
total_fitness = 0;
for t = 1:length(result.phases)
    total_fitness = total_fitness + result.phases{t}.solution.fitness;
end
end


%% ==================== HA辅助函数 ====================

function A = constraint_preprocess_local(phase_data, instance)
n_t = phase_data.n_t;
targets = phase_data.targets;
m = instance.m;
L = instance.L;

A = struct('target_id', {}, 'combos', {}, 'H_jt', {});

for j = 1:n_t
    target = targets(j);
    A(j).target_id = target.id;
    combos = {};

    for k = 1:L
        d_kj = sqrt((instance.radar_x(k) - target.position_x)^2 + ...
                     (instance.radar_y(k) - target.position_y)^2);

        if d_kj > instance.R_radar(k)
            continue;
        end

        p_det = max(0.05, exp(-instance.lambda(k) * d_kj^4 / target.RCS));

        if p_det < instance.p_th
            continue;
        end

        for i = 1:m
            d_ij = sqrt((instance.weapon_x(i) - target.position_x)^2 + ...
                         (instance.weapon_y(i) - target.position_y)^2);

            if d_ij > instance.R_max(i)
                continue;
            end

            intercept_time = instance.tau_react(i) + d_ij / instance.v_weapon(i);
            if intercept_time > target.W
                continue;
            end

            available_ammo = min(instance.ammo(i), target.U);

            for s = 1:min(3, available_ammo)
                combos{end + 1} = [i, k, s];
            end
        end
    end

    combos{end + 1} = [0, 0, 0];
    A(j).combos = combos;
    A(j).H_jt = length(combos) - 1;
end
end


function fitness = fitness_evaluator_ha_local(c, targets, phase_data, A)
n_t = length(targets);
P_ij = phase_data.P_ij;
eta_j = phase_data.eta_j;

[m, ~, L] = deal(size(P_ij, 1), n_t, size(phase_data.P_ij, 3));
allocation = zeros(m, n_t, L);

for j = 1:n_t
    combo_idx = c(j);
    if combo_idx > 0 && combo_idx <= length(A(j).combos)
        combo = A(j).combos{combo_idx};
        if ~isempty(combo) && combo(1) > 0
            allocation(combo(1), j, combo(2)) = combo(3);
        end
    end
end

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
    fitness = fitness + target.threat * eta_j(j) * survival;
end
end


%% ==================== GA/LKEA通用辅助函数 ====================

function P = init_population_ga(N, n_t, A)
P = struct('c', {}, 'allocation', {}, 'fitness', {});
for i = 1:N
    c = zeros(1, n_t);
    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1
            c(j) = randi(H_jt - 1);
        end
    end
    P(i).c = c;
end
end


function P = init_population_lkea(N, A)
n_t = length(A);
P = struct('c', {}, 'allocation', {}, 'fitness', {});
N1 = floor(N / 2);
N2 = N - N1;

for i = 1:N1
    c = zeros(1, n_t);
    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1
            c(j) = randi(H_jt - 1);
        end
    end
    P(i).c = c;
end

for i = N1 + 1:N2
    c = zeros(1, n_t);
    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1
            c(j) = randi(H_jt - 1);
        end
    end
    P(i).c = c;
end
end


function Q = crossover_ga(P, p_crossover)
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


function Q = crossover_lkea(P, p_crossover)
% 与crossover_ga相同
Q = crossover_ga(P, p_crossover);
end


function Q = mutation_ga(Q, A, p_mut)
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


function Q = mutation_lkea(Q, A, KB, p_mut, p_guided)
for i = 1:length(Q)
    c = Q(i).c;
    n_t = length(c);

    for j = 1:n_t
        H_jt = length(A(j).combos);
        if H_jt > 1 && rand() < p_mut
            if c(j) == 0 && rand() < p_guided
                c(j) = randi(H_jt - 1);
            else
                c(j) = randi(H_jt - 1);
            end
        end
    end

    Q(i).c = c;
end
end


function P_next = selection_ga(R, N)
[~, sort_idx] = sort([R.fitness], 'ascend');
R_sorted = R(sort_idx);

P_next = struct('c', {}, 'allocation', {}, 'fitness', {});

for i = 1:length(R_sorted)
    if length(P_next) >= N
        break;
    end
    P_next(end + 1) = R_sorted(i);
end

while length(P_next) < N
    idx = randi(length(R_sorted));
    P_next(end + 1) = R_sorted(idx);
end
end


function P_next = selection_lkea(R, N)
% 与selection_ga相同
P_next = selection_ga(R, N);
end


function allocation = encoding_decode_local(c, A)
n_t = length(c);

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


function [allocation, c] = repair_constraints_local(allocation, c, A, targets, weapon_ammo)
[m, n_t, L] = size(allocation.x_ijkt);
n_weapons = length(weapon_ammo);

usage = zeros(n_weapons, 1);
for i = 1:min(m, n_weapons)
    usage(i) = sum(allocation.x_ijkt(i, :, :), 'all');
end

[~, priority_idx] = sort([targets.threat], 'descend');

new_alloc = zeros(m, n_t, L);
new_c = zeros(1, n_t);

for j_idx = 1:n_t
    j = priority_idx(j_idx);

    for i = 1:min(m, n_weapons)
        for k = 1:L
            s = allocation.x_ijkt(i, j, k);
            if s > 0
                if usage(i) + s <= weapon_ammo(i)
                    new_alloc(i, j, k) = s;
                    usage(i) = usage(i) + s;
                    for idx = 1:length(A(j).combos)
                        combo = A(j).combos{idx};
                        if ~isempty(combo) && combo(1) == i && combo(2) == k && combo(3) == s
                            new_c(j) = idx;
                            break;
                        end
                    end
                    break;
                end

                best_found = false;
                for combo_idx = 1:length(A(j).combos)
                    combo = A(j).combos{combo_idx};
                    if isempty(combo) || combo(1) == 0
                        continue;
                    end
                    alt_i = combo(1);
                    alt_k = combo(2);
                    alt_s = combo(3);
                    if usage(alt_i) + alt_s <= weapon_ammo(alt_i)
                        new_alloc(alt_i, j, alt_k) = alt_s;
                        usage(alt_i) = usage(alt_i) + alt_s;
                        new_c(j) = combo_idx;
                        best_found = true;
                        break;
                    end
                end
                if best_found
                    break;
                end
                break;
            end
        end
    end
end

allocation.x_ijkt = new_alloc;
c = new_c;
end


function fitness = fitness_evaluator_local(allocation, targets, phase_data)
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

    fitness = fitness + target.threat * eta_j(j) * survival;
end
end


%% ==================== 统计检验函数 ====================

function [p, h] = wilcoxon_rank_sum(x, y)
% Wilcoxon rank-sum test (Mann-Whitney U test)
% x, y: 1D vectors
% Returns p-value and h (1 if significant at 0.05, 0 otherwise)

x = x(:);
y = y(:);
n1 = length(x);
n2 = length(y);

% Combine and rank
all_data = [x; y];
[~, sorted_idx] = sort(all_data);
ranks = zeros(length(all_data), 1);
ranks(sorted_idx) = 1:length(all_data);

R1 = sum(ranks(1:n1));
R2 = sum(ranks(n1+1:end));

% U statistics
U1 = R1 - n1 * (n1 + 1) / 2;
U2 = R2 - n2 * (n2 + 1) / 2;
U = min(U1, U2);

% Normal approximation for large samples
n = n1 + n2;
mu_U = n1 * n2 / 2;
sigma_U = sqrt(n1 * n2 * (n + 1) / 12);

if sigma_U > 0
    z = (U - mu_U) / sigma_U;
    % Two-tailed p-value
    p = 2 * normcdf(z);
else
    p = 1;
end

h = double(p < 0.05);
end


function result = ifelse(condition, true_val, false_val)
if condition
    result = true_val;
else
    result = false_val;
end
end