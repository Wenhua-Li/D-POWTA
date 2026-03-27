% D-POWTA 知识引导变异算子
%
% 变异策略 (论文4.4节):
%   - 若当前基因位在冲突集中: 以p_guided从补集采样
%   - 若不在冲突集中: 以p_mut标准变异率随机变异
%   - 若补集为空: 退化为标准变异
%
% 使用方式:
%   Q = mutation(Q, A_jt, KB, params)
%
% 输入:
%   Q      - 子代种群
%   A_jt   - 有效配对集
%   KB     - 知识库
%   params  - 参数结构体
%
% 输出:
%   Q - 变异后的子代种群
%
% Author: KG-DREA
% Date: 2026-03-18

function Q = mutation(Q, A_jt, KB, params)
    p_mut = params.p_mut;
    p_guided = params.p_guided;

    for i = 1:length(Q)
        c = Q(i).c;
        n_t = length(c);

        for j = 1:n_t
            % 检查当前组合是否在冲突集中
            combo_idx = c(j);
            is_conflict = is_in_conflict(KB.conflict_set, j, combo_idx);

            if is_conflict
                % 知识引导变异: 从补集采样
                H_jt = length(A_jt(j).combos);
                complement = get_complement_set(KB.conflict_set, j, H_jt);

                if ~isempty(complement) && rand() < p_guided
                    c(j) = complement(randi(length(complement)));
                end
            else
                % 标准变异
                H_jt = length(A_jt(j).combos);

                if H_jt > 1 && rand() < p_mut
                    % 随机选择新组合
                    new_idx = randi(H_jt);
                    c(j) = new_idx;
                end
            end
        end

        Q(i).c = c;
        Q(i).allocation = [];
    end
end
