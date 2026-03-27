% D-POWTA TC-FCE编码解码器
%
% TC-FCE (Target-Centric Feasible Combination Encoding) 编码:
%   - 每个目标对应一个基因位
%   - 基因值表示选用的可行交战组合索引
%   - 0 表示不拦截
%   - 解码时将编码转换为决策变量 x_ijkt
%
% 使用方式:
%   allocation = encoding_decode(c, A_jt)
%
% 输入:
%   c   - TC-FCE编码向量 (1 x n_t)
%   A_jt - 有效配对集结构体
%
% 输出:
%   allocation - 分配矩阵结构体
%
% Author: KG-DREA
% Date: 2026-03-18

function allocation = encoding_decode(c, A_jt)
    n_t = length(c);

    % 初始化分配矩阵 (武器 x 目标 x 雷达)
    % 使用稀疏矩阵优化
    m_max = 0;
    L_max = 0;
    for j = 1:n_t
        for idx = 1:length(A_jt(j).combos)
            combo = A_jt(j).combos{idx};
            m_max = max(m_max, combo(1));
            L_max = max(L_max, combo(2));
        end
    end

    allocation.x_ijkt = zeros(m_max, n_t, L_max);
    allocation.weapon_used = zeros(1, m_max);
    allocation.radar_used = zeros(1, L_max);

    % 解码每个基因位
    for j = 1:n_t
        combo_idx = c(j);

        if combo_idx == 0 || combo_idx > length(A_jt(j).combos)
            % 不拦截
            continue;
        end

        combo = A_jt(j).combos{combo_idx};
        i = combo(1);  % 武器索引
        k = combo(2);  % 雷达索引
        s = combo(3);  % 弹药数量

        if i == 0 || k == 0
            % 不拦截
            continue;
        end

        % 填充分配矩阵
        allocation.x_ijkt(i, j, k) = s;
        allocation.weapon_used(i) = allocation.weapon_used(i) + s;
        allocation.radar_used(k) = allocation.radar_used(k) + s;
    end
end
