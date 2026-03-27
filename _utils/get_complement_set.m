% D-POWTA 无冲突补集计算
%
% 获取目标j的无冲突组合索引集合
%
% 使用方式:
%   complement = get_complement_set(conflict_set, j, H_jt)
%
% Author: KG-DREA
% Date: 2026-03-27

function complement = get_complement_set(conflict_set, j, H_jt)
    complement = zeros(1, H_jt);
    count = 0;

    for h = 1:H_jt
        if ~is_in_conflict(conflict_set, j, h)
            count = count + 1;
            complement(count) = h;
        end
    end

    complement = complement(1:count);
end

function is_conflict = is_in_conflict(conflict_set, j, h)
    % 检查(j,h)是否在冲突集中
    is_conflict = false;

    if isempty(conflict_set) || size(conflict_set, 1) == 0 || h == 0
        return;
    end

    % 使用向量化查找
    matches = find(conflict_set(:, 1) == j & conflict_set(:, 2) == h);
    if ~isempty(matches)
        is_conflict = true;
    end
end