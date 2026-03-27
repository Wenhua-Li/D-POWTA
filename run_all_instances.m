% run_all_instances.m
% 批量运行 I1-I10 共10个算例，输出保存至 results/info.txt
% 使用方式: 在 MATLAB 中 cd 到本目录，运行 run_all_instances

close all; clc;
addpath('_core', '_operators', '_utils', '_visualization', 'config');

fprintf('============================================\n');
fprintf('  D-POWTA 批量求解 — I1 ~ I10\n');
fprintf('============================================\n\n');

% 打开 diary 捕获所有输出
if ~exist('results', 'dir'), mkdir('results'); end
diary_file = 'results/info.txt';
if exist(diary_file, 'file'), delete(diary_file); end
diary(diary_file);

diary on;

fprintf('开始批量求解 I1 ~ I10\n');
fprintf('时间: %s\n\n', datestr(now));

%% 算例配置
instances = {'I1','I2','I3','I4','I5','I6','I7','I8','I9','I10'};

%% 参数配置（与 main_I1 保持一致）
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
    'verbose',        true,     ...
    'save_history',   true ...
);

%% 逐个求解算例
for idx = 1:length(instances)
    name = instances{idx};
    fprintf('\n');
    fprintf('############################################\n');
    fprintf('#  算例 %d/10: %s\n', idx, name);
    fprintf('############################################\n\n');

    t0 = tic;

    % 加载算例
    instance = load_instance([name '.mat'], 'instances/');

    % 求解
    result = solve_kgdrea(instance, params);

    elapsed = toc(t0);

    % 结果摘要
    fprintf('\n========== %s 求解完成 ==========\n', name);
    fprintf('总耗时: %.2f 秒\n\n', elapsed);

    fprintf('各阶段结果:\n');
    fprintf('  %-6s %-14s %-10s %-10s %-12s\n', ...
        '阶段', '残余威胁', 'RMI', '分配数', 'ε-最优解数');
    fprintf('  %-6s %-14s %-10s %-10s %-12s\n', ...
        '----', '----------', '----', '----', '----------');
    for t = 1:length(result.phases)
        ph = result.phases{t};
        fprintf('  %-6d %-14.6f %-10.4f %-10d %-12d\n', ...
            t, ph.solution.fitness, ph.solution.rmi, ...
            sum(ph.solution.c ~= 0), length(ph.all_solutions));
    end
    fprintf('\n');

    % 打印各阶段详细分配方案
    for t = 1:length(result.phases)
        ph = result.phases{t};
        n_t = instance.phases{t}.n_t;
        A_jt = constraint_preprocess(instance.phases{t}, instance, params);

        fprintf('--- %s 阶段 %d ---\n', name, t);
        fprintf('  残余威胁 = %.6f,  RMI = %.6f\n', ph.solution.fitness, ph.solution.rmi);
        fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
            '目标', '威胁', '武器', '雷达', '弹药数');
        fprintf('  %-6s %-10s %-8s %-10s %-10s\n', ...
            '----', '----', '----', '----', '----');
        for j = 1:n_t
            if ph.solution.c(j) > 0
                combo = A_jt(j).combos{ph.solution.c(j)};
                fprintf('  T%-5d %-10.2f W%-4d R%-4d %-10d\n', ...
                    j, instance.phases{t}.targets(j).threat, combo(1), combo(2), combo(3));
            else
                fprintf('  T%-5d %-10.2f 未拦截\n', ...
                    j, instance.phases{t}.targets(j).threat);
            end
        end
        fprintf('\n');
    end

    % 保存单个算例结果
    save(['results/result_' name '.mat'], 'result', 'instance', 'params');

    % 可视化（关闭显示，只保存文件，避免弹窗阻塞）
    set(0, 'DefaultFigureVisible', 'off');

    % 收敛曲线
    plot_convergence(result, sprintf('results/%s_convergence.png', name));

    % 鲁棒性指标
    plot_robustness(result, sprintf('results/%s_robustness.png', name));

    % 各阶段场景和分配方案
    for t = 1:instance.T_total
        plot_instance(instance, sprintf('results/%s_phase%d_scene.png', name, t), t);
        close all;
    end
    for t = 1:length(result.phases)
        ph = result.phases{t};
        if instance.phases{t}.n_t > 0
            plot_allocation(instance, ph.solution, t, ...
                sprintf('results/%s_phase%d_allocation.png', name, t));
            close all;
        end
    end

    set(0, 'DefaultFigureVisible', 'on');

    fprintf('[%s] 已保存结果和图表到 results/\n\n', name);
end

%% 批量汇总表
fprintf('\n');
fprintf('============================================\n');
fprintf('  批量求解汇总\n');
fprintf('============================================\n\n');
fprintf('%-6s %-8s %-6s %-6s %-14s %-10s %-12s %-10s\n', ...
    '算例', '武器数', '雷达数', '阶段数', '总目标数', '残余威胁', '平均RMI', '总耗时(s)');
fprintf('%-6s %-8s %-6s %-6s %-14s %-10s %-12s %-10s\n', ...
    '------', '--------', '------', '------', '----------', '--------', '--------', '------');

for idx = 1:length(instances)
    name = instances{idx};
    data = load(['results/result_' name '.mat']);
    result = data.result;
    instance = data.instance;

    total_fitness = 0; total_rmi = 0;
    for t = 1:length(result.phases)
        total_fitness = total_fitness + result.phases{t}.solution.fitness;
        total_rmi = total_rmi + result.phases{t}.solution.rmi;
    end

    t_all = result.total_time;

    fprintf('%-6s %-8d %-6d %-6d %-14d %-10.4f %-12.4f %-10.2f\n', ...
        name, instance.m, instance.L, instance.T_total, instance.n, ...
        total_fitness, total_rmi / instance.T_total, t_all);
end

fprintf('\n');
diary off;

fprintf('============================================\n');
fprintf('  全部完成！\n');
fprintf('============================================\n');
fprintf('输出文件 (results/):\n');
fprintf('  info.txt                          — 完整运行日志\n');
for idx = 1:length(instances)
    name = instances{idx};
    fprintf('  result_%s.mat                   — 算例结果数据\n', name);
    fprintf('  %s_convergence.png              — 收敛曲线\n', name);
    fprintf('  %s_robustness.png               — 鲁棒性指标\n', name);
    fprintf('  %s_phase*_scene.png            — 各阶段场景\n', name);
    fprintf('  %s_phase*_allocation.png       — 各阶段分配方案\n', name);
end
fprintf('\n');
