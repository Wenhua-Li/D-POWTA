% D-POWTA KG-DREA 主求解器
% 实现知识引导的动态滚动多模态进化算法
%
% 算法流程:
%   1. 约束预处理: 构造有效配对集A_jt
%   2. 知识引导初始化: 生成初始种群P_0
%   3. 进化主循环: 知识引导交叉变异 + 小生境选择
%   4. RMI鲁棒性评估与方案优选
%   5. 知识更新
%
% 使用方式:
%   result = solve_kgdrea(instance);
%   result = solve_kgdrea(instance, 'N', 100, 'G_max', 200);
%
% 输入参数:
%   instance - 算例结构体
%   params   - 参数结构体 (可选)
%
% 输出:
%   result - 求解结果结构体
%
% Author: KG-DREA
% Date: 2026-03-18

function result = solve_kgdrea(instance, varargin)
    %% ==================== 解析输入参数 ====================
    if isstruct(varargin{1})
        params = varargin{1};
    else
        params = default_params(varargin{:});
    end

    % 设置随机种子
    if isempty(params.seed)
        rng('shuffle');
    else
        rng(params.seed);
    end

    fprintf('\n========== KG-DREA 求解开始 ==========\n');
    fprintf('算例: %s\n', instance.name);
    fprintf('武器数: %d, 雷达数: %d, 目标数: %d, 阶段数: %d\n', ...
        instance.m, instance.L, instance.n, instance.T_total);

    %% ==================== 初始化结果结构 ====================
    result = struct();
    result.instance_name = instance.name;
    result.algorithm = 'KG-DREA';
    result.params = params;
    result.phases = cell(1, instance.T_total);
    result.total_time = 0;
    result.history = [];

    %% ==================== 初始化知识库 ====================
    KB = struct();
    KB.conflict_set = zeros(0, 2);  % 冲突集合 C_t
    KB.history = [];                % 历史记录
    KB.elim_count = cell(1, 0);    % 淘汰计数 cell 数组

    %% ==================== 阶段循环 ====================
    tic;

    for t = 1:instance.T_total
        fprintf('\n--- 阶段 %d/%d ---\n', t, instance.T_total);

        % 获取当前阶段数据
        phase_data = instance.phases{t};
        n_t = phase_data.n_t;
        targets = phase_data.targets;

        % 自适应设置参数
        if isempty(params.N)
            params.N = 5 * n_t;
        end
        if isempty(params.delta)
            params.delta = ceil(params.beta * n_t);
        end

        fprintf('目标数: %d, 种群规模: %d, 小生境半径: %d\n', n_t, params.N, params.delta);

        %% 步骤1: 约束预处理
        if params.verbose
            fprintf('  [1/5] 约束预处理...\n');
        end
        A_jt = constraint_preprocess(phase_data, instance, params);

        %% 步骤2: 知识引导初始化
        if params.verbose
            fprintf('  [2/5] 知识引导初始化...\n');
        end
        P = init_population(params.N, A_jt, KB);

        % 评估初始种群的适应度
        for i = 1:length(P)
            P(i).fitness = fitness_evaluator(P(i).allocation, phase_data, instance);
        end

        %% 步骤3: 进化主循环
        if params.verbose
            fprintf('  [3/5] 进化主循环 (最大代数: %d)...\n', params.G_max);
        end

        fitness_history = zeros(1, params.G_max);
        mean_fitness_history = zeros(1, params.G_max);

        for g = 1:params.G_max
            % 知识引导交叉
            Q = crossover(P, params.p_crossover);

            % 知识引导变异
            Q = mutation(Q, A_jt, KB, params);

            % 约束修复
            Q = repair_constraints(Q, phase_data, instance, A_jt);

            % 评估适应度
            for i = 1:length(Q)
                Q(i).fitness = fitness_evaluator(Q(i).allocation, phase_data, instance);
            end

            % 合并父代和子代
            R = [P, Q];

            % 小生境环境选择
            P = niche_selection(R, params.N, params.delta);

            % 记录最优和平均适应度
            fitness_history(g) = min([P.fitness]);
            mean_fitness_history(g) = mean([P.fitness]);

            if params.verbose && mod(g, 20) == 0
                fprintf('    代数 %d: 最优适应度 = %.4f\n', g, fitness_history(g));
            end
        end

        %% 步骤4: RMI鲁棒性评估与方案优选
        if params.verbose
            fprintf('  [4/5] RMI鲁棒性评估...\n');
        end

        % 构造近似最优解集 S_t^epsilon
        epsilon_threshold = min([P.fitness]) * (1 + params.epsilon);
        S_epsilon = P([P.fitness] <= epsilon_threshold);

        fprintf('  近似最优解数量: %d\n', length(S_epsilon));

        % 计算各方案的RMI值
        for i = 1:length(S_epsilon)
            S_epsilon(i).rmi = rmi_evaluator(S_epsilon(i), A_jt, phase_data, instance, params);
        end

        %% ===== 多模态分析：展示 ε-最优解集的局部多样性 =====
        if params.verbose
            fprintf('\n  ===== 多模态分析 =====\n');
            fprintf('  %-4s %-14s %-10s %-12s %-10s\n', ...
                '#', 'Fitness', 'RMI', '汉明距离', '分配数');
            fprintf('  %-4s %-14s %-10s %-12s %-10s\n', ...
                '----', '----------', '----', '--------', '----');

        % 取前5个最优解（按fitness升序）
        [~, sort_idx] = sort([S_epsilon.fitness], 'ascend');
        topK = min(5, length(S_epsilon));
        top_solutions = S_epsilon(sort_idx(1:topK));

        for k = 1:length(top_solutions)
            sol = top_solutions(k);
            alloc_count = sum(sol.c ~= 0);
            fprintf('  %-4d %-14.6f %-10.4f', k, sol.fitness, sol.rmi);

            % 计算与第1个解的汉明距离
            if k == 1
                fprintf(' %-12s', '-');
            else
                d = sum(top_solutions(1).c ~= sol.c);
                fprintf(' %-12d', d);
            end
            fprintf(' %-10d\n', alloc_count);
        end

        % 计算前5个解之间的两两汉明距离矩阵
        if topK >= 2
            fprintf('\n  前%d个解两两汉明距离矩阵:\n', topK);
            fprintf('         ');
            for k = 1:topK, fprintf('  %-7d', k); end
            fprintf('\n');
            for i = 1:topK
                fprintf('  %-4d ', i);
                for j = 1:topK
                    if i == j
                        fprintf('  %-7s', '-');
                    else
                        d = sum(top_solutions(i).c ~= top_solutions(j).c);
                        fprintf('  %-7d', d);
                    end
                end
                fprintf('\n');
            end

            % 统计信息
            all_dists = [];
            for i = 1:topK-1
                for j = i+1:topK
                    all_dists(end+1) = sum(top_solutions(i).c ~= top_solutions(j).c);
                end
            end
            fprintf('\n  汉明距离统计: min=%d, max=%d, mean=%.2f, std=%.2f\n', ...
                min(all_dists), max(all_dists), mean(all_dists), std(all_dists));
            fprintf('  Fitness 差异: %.6f → %.6f (跨度 %.4f)\n', ...
                top_solutions(end).fitness, top_solutions(1).fitness, ...
                top_solutions(end).fitness - top_solutions(1).fitness);
            fprintf('  RMI 差异: %.4f → %.4f (跨度 %.4f)\n', ...
                min([top_solutions.rmi]), max([top_solutions.rmi]), ...
                max([top_solutions.rmi]) - min([top_solutions.rmi]));
        end
        fprintf('  ===========================\n');

        % 优选方案: RMI最大的方案
        [~, best_idx] = max([S_epsilon.rmi]);
        best_solution = S_epsilon(best_idx);

        fprintf('  最优方案: fitness=%.4f, RMI=%.4f\n', best_solution.fitness, best_solution.rmi);
        end

        %% 步骤5: 知识更新
        if params.verbose
            fprintf('  [5/5] 知识更新...\n');
        end
        KB = knowledge_manager(KB, best_solution, A_jt, phase_data, params);

        %% 保存阶段结果
        phase_result = struct();
        phase_result.phase = t;
        phase_result.solution = best_solution;
        phase_result.all_solutions = S_epsilon;
        phase_result.top_solutions = top_solutions;     % 前5最优（多模态分析用）
        phase_result.fitness_history = fitness_history;
        phase_result.mean_fitness_history = mean_fitness_history;
        phase_result.final_population = P;
        phase_result.knowledge = KB;

        result.phases{t} = phase_result;
    end

    result.total_time = toc;

    fprintf('\n========== KG-DREA 求解完成 ==========\n');
    fprintf('总耗时: %.2f 秒\n', result.total_time);

    %% ==================== 后处理 ====================
    % 计算各阶段残余威胁
    result.residual_threat = zeros(1, instance.T_total);
    for t = 1:instance.T_total
        result.residual_threat(t) = result.phases{t}.solution.fitness;
    end

    % 保存历史
    if params.save_history
        result.params = params;
    end
end
