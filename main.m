% main_I1.m
% 主程序：使用 KG-DREA 算法求解 I1 算例
% 使用方式: 在 MATLAB 中 cd 到本目录，运行 main_I1

close all; clear; clc;
addpath('_core', '_operators', '_utils', '_visualization', 'config');

%% 测试案例
TestInstanceNum = 1;

%% ========== 1. 加载算例 ==========
fprintf('[Step 1/5] 加载 I%d 算例...\n',TestInstanceNum);
instance = load_instance(sprintf('I%d.mat',TestInstanceNum), 'instances/');
fprintf('  各阶段目标数: %s\n\n', mat2str(instance.phase_targets));

% %% ========== 2. 可视化算例场景 ==========
% fprintf('[Step 2/5] 生成算例场景可视化...\n');
% for t = 1:instance.T_total
%     plot_instance(instance, sprintf('results/%s_phase%d_scene.png', instance.name, t), t);
% end

%% ========== 3. 配置算法参数 ==========
fprintf('[Step 3/5] 配置 KG-DREA 参数...\n');
params = default_params( ...
    'N',              100,      ...
    'G_max',          100,     ...
    'epsilon',        0.01,    ...
    'p_crossover',    0.8,     ...
    'p_mut',          0.1,    ...
    'p_guided',       0.7,     ...
    'r',              2,        ...
    'S',              50,       ...
    'use_monte_carlo', true,   ...
    'theta_c',        5,        ...
    'delta',          3,        ...
    'verbose',        true,     ...
    'save_history',   true ...
);
fprintf('  N=%d, G_max=%d, delta=%d, r=%d, S=%d\n\n', ...
    params.N, params.G_max, params.delta, params.r, params.S);

%% ========== 4. 调用 KG-DREA 求解 ==========
fprintf('[Step 4/5] 开始求解...\n');
result = solve_kgdrea(instance, params);

fprintf('\n  各阶段结果:\n');
fprintf('  %-6s %-14s %-10s %-10s\n', '阶段', '残余威胁', 'RMI', '分配数');
fprintf('  %-6s %-14s %-10s %-10s\n', '----', '----------', '----', '----');
for t = 1:length(result.phases)
    ph = result.phases{t};
    fprintf('  %-6d %-14.6f %-10.4f %-10d\n', ...
        t, ph.solution.fitness, ph.solution.rmi, sum(ph.solution.c ~= 0));
end
fprintf('\n');

%% ========== 5. 可视化求解结果 ==========
fprintf('[Step 5/5] 生成结果可视化...\n');

% 收敛曲线
plot_convergence(result, sprintf('results/%s_convergence.png', instance.name));
fprintf('  收敛曲线已保存.\n');

% 鲁棒性指标
plot_robustness(result, sprintf('results/%s_robustness.png', instance.name));
fprintf('  鲁棒性指标图已保存.\n');

% 各阶段分配方案
for t = 1:length(result.phases)
    ph = result.phases{t};
    n_t = instance.phases{t}.n_t;
    if n_t > 0
        % 重新计算 A_jt 用于解码
        A_jt = constraint_preprocess(instance.phases{t}, instance, params);

        % % 使用已有的分配方案可视化函数
        plot_allocation(instance, ph.solution, t, ...
            sprintf('results/%s_phase%d_allocation.png', instance.name, t));

        % 打印详细表格
        fprintf('\n--- 阶段 %d ---\n', t);
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
                fprintf('  T%-5d %-10.2f 未拦截\n', j, instance.phases{t}.targets(j).threat);
            end
        end
    end
end
fprintf('\n');

%% ========== 6. 保存结果 ==========
fprintf('正在保存结果...\n');
save(sprintf('results/result_I%d.mat',TestInstanceNum), 'result', 'instance', 'params');
fprintf('结果已保存: results/result_I%d.mat\n', TestInstanceNum);

fprintf('\n============================================\n');
fprintf('算例求解完成！\n');
fprintf('============================================\n');
fprintf('输出文件 (results/):\n');
fprintf('  %s_phase1_scene.png, %s_phase2_scene.png  — 算例场景\n', instance.name, instance.name);
fprintf('  %s_convergence.png  — 收敛曲线\n', instance.name);
fprintf('  %s_robustness.png   — 鲁棒性指标\n', instance.name);
fprintf('  %s_phase1_allocation.png, %s_phase2_allocation.png — 分配方案\n', instance.name, instance.name);
fprintf('  result_I%d.mat       — 完整结果数据\n',TestInstanceNum);
fprintf('\n');
