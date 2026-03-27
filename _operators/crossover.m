% D-POWTA 均匀交叉算子
%
% 对两个父本执行均匀交叉:
%   对每个基因位j,以概率0.5分别遗传自父本的组合选择
%
% 使用方式:
%   Q = crossover(P, p_crossover)
%
% 输入:
%   P           - 父本种群
%   p_crossover - 交叉概率
%
% 输出:
%   Q - 子代种群
%
% Author: KG-DREA
% Date: 2026-03-18

function Q = crossover(P, p_crossover)
    if mod(length(P), 2) ~= 0
        % 奇数个个体,去除最后一个
        P(end) = [];
    end

    N = length(P);
    Q = struct('c', {}, 'allocation', {}, 'fitness', {}, 'feasible', {});

    % 随机配对
    indices = randperm(N);

    for i = 1:2:N
        parent1 = P(indices(i));
        parent2 = P(indices(i+1));

        % 执行交叉
        if rand() < p_crossover
            child = uniform_crossover(parent1.c, parent2.c);
        else
            % 不交叉,直接复制
            if rand() < 0.5
                child = parent1.c;
            else
                child = parent2.c;
            end
        end

        % 创建子代结构体
        Q(end+1).c = child;  %#ok<AGROW>
        Q(end).allocation = [];
        Q(end).fitness = [];
        Q(end).feasible = true;
    end
end

%% ==================== 均匀交叉 ====================

function child = uniform_crossover(c1, c2)
    n_t = length(c1);
    child = zeros(1, n_t);

    for j = 1:n_t
        if rand() < 0.5
            child(j) = c1(j);
        else
            child(j) = c2(j);
        end
    end
end
