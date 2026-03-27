% D-POWTA 知识库管理器
%
% 功能:
%   1. 管理分配冲突知识 (Assignment Conflict Knowledge, ACK)
%   2. 从进化过程提取冲突模式
%   3. 知识引导的初始化和变异
%
% 知识结构:
%   C_t = {(j, h) | 组合(j,h)在历史周期中高频淘汰}
%
% 使用方式:
%   KB = knowledge_manager(KB, solution, A_jt, phase_data, params)
%
% 输入:
%   KB         - 知识库结构体
%   solution   - 最优解结构体
%   A_jt       - 有效配对集
%   phase_data - 阶段数据
%   params     - 参数结构体
%
% 输出:
%   KB - 更新后的知识库
%
% Author: KG-DREA
% Date: 2026-03-18

function KB = knowledge_manager(KB, solution, A_jt, phase_data, params)
    n_t = phase_data.n_t;
    theta_c = params.theta_c;  % 冲突判定阈值

    c = solution.c;

    % 初始化 elim_count cell 数组（每行 j 长度动态匹配 H_jt）
    H_jt_list = zeros(1, n_t);
    for j = 1:n_t
        H_jt_list(j) = length(A_jt(j).combos);
    end

    if ~isfield(KB, 'elim_count') || ~iscell(KB.elim_count)
        % 首次初始化
        KB.elim_count = cell(1, n_t);
        for j = 1:n_t
            KB.elim_count{j} = zeros(1, H_jt_list(j));
        end
    else
        % 扩展已有行，匹配新的 H_jt
        if length(KB.elim_count) < n_t
            for j = length(KB.elim_count)+1:n_t
                KB.elim_count{j} = zeros(1, H_jt_list(j));
            end
        end
        % 对已有行，若新 H_jt 更大则扩展
        for j = 1:n_t
            if H_jt_list(j) > length(KB.elim_count{j})
                KB.elim_count{j}(end+1:H_jt_list(j)) = 0;
            end
        end
    end

    % 从当前解提取冲突模式
    for j = 1:n_t
        combo_idx = c(j);

        if combo_idx > 0 && combo_idx <= length(A_jt(j).combos)
            % 动态扩展 elim_count{j} 长度（兜底）
            if combo_idx > length(KB.elim_count{j})
                KB.elim_count{j}(end+1:combo_idx) = 0;
            end
            KB.elim_count{j}(combo_idx) = KB.elim_count{j}(combo_idx) + 0.5;
        end
    end

    % 更新冲突集合
    KB.conflict_set = zeros(0, 2);
    for j = 1:n_t
        H_j = length(A_jt(j).combos);
        for h = 1:H_j
            if h <= length(KB.elim_count{j}) && KB.elim_count{j}(h) >= theta_c
                KB.conflict_set = [KB.conflict_set; j, h];
            end
        end
    end

    % 更新历史记录
    history_entry = struct();
    history_entry.phase = phase_data.phase;
    history_entry.c = c;
    history_entry.fitness = solution.fitness;
    history_entry.conflict_count = size(KB.conflict_set, 1);

    if isempty(KB.history)
        KB.history = history_entry;
    else
        KB.history(end+1) = history_entry;
    end

    % 限制历史长度
    if length(KB.history) > params.max_history
        KB.history = KB.history(end-params.max_history+1:end);
    end
end
