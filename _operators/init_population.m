% D-POWTA 知识引导种群初始化
%
% 初始化策略 (论文4.3节):
%   - 前 N/2 个体: 从无冲突补集 ~C_t 中采样
%   - 后 N/2 个体: 从完整集合 {0,1,...,H_jt} 中随机采样
%
% 这种混合策略既利用历史知识加速收敛,
% 又通过部分随机个体防止知识过时导致早熟
%
% 使用方式:
%   P = init_population(N, A_jt, KB)
%
% 输入:
%   N   - 种群规模
%   A_jt - 有效配对集
%   KB  - 知识库
%
% 输出:
%   P   - 初始种群 (结构体数组)
%
% Author: KG-DREA
% Date: 2026-03-18

function P = init_population(N, A_jt, KB)
    n_t = length(A_jt);

    % 计算分割点
    N_guided = floor(N / 2);

    P = struct('c', {}, 'allocation', {}, 'fitness', {}, 'feasible', {});

    %% 前 N/2 个体: 知识引导初始化
    for i = 1:N_guided
        c = zeros(1, n_t);

        for j = 1:n_t
            H_jt = length(A_jt(j).combos);

            if H_jt <= 1
                c(j) = 0;
                continue;
            end

            % 获取无冲突补集
            complement = get_complement_set(KB.conflict_set, j, H_jt);

            if isempty(complement)
                % 无冲突集为空,从完整集合采样
                c(j) = randi(H_jt);
            else
                % 从无冲突补集采样
                c(j) = complement(randi(length(complement)));
            end
        end

        % 构建解结构体
        allocation = encoding_decode(c, A_jt);

        P(i).c = c;
        P(i).allocation = allocation;
        P(i).fitness = [];
        P(i).feasible = true;
    end

    %% 后 N/2 个体: 随机初始化(保持多样性)
    for i = N_guided+1:N
        c = zeros(1, n_t);

        for j = 1:n_t
            H_jt = length(A_jt(j).combos);

            if H_jt <= 1
                c(j) = 0;
            else
                % 从完整集合采样,包括0(不拦截)
                c(j) = randi(H_jt);
            end
        end

        allocation = encoding_decode(c, A_jt);

        P(i).c = c;
        P(i).allocation = allocation;
        P(i).fitness = [];
        P(i).feasible = true;
    end
end
