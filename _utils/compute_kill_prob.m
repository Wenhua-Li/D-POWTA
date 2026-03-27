% D-POWTA 毁伤概率计算工具
%
% 武器-目标毁伤概率模型:
%   P_ij = 0.7 * range_factor * rcs_factor + 0.25
%
%   其中:
%   - range_factor = 1 - d_ij/R_max (射程因子)
%   - rcs_factor = min(1, RCS/1.0) (目标特性因子)
%
% 使用方式:
%   P_ij = compute_kill_prob(d_ij, R_max, RCS)
%
% Author: KG-DREA
% Date: 2026-03-18

function P_ij = compute_kill_prob(d_ij, R_max, RCS)
    % 计算武器-目标毁伤概率
    %
    % 输入:
    %   d_ij  - 武器-目标距离 (km)
    %   R_max - 武器最大射程 (km)
    %   RCS   - 目标雷达截面积 (m^2)
    %
    % 输出:
    %   P_ij  - 单发毁伤概率

    % 检查射程
    if d_ij > R_max
        P_ij = 0;
        return;
    end

    % 射程因子
    range_factor = 1 - (d_ij / R_max);

    % RCS因子
    rcs_factor = min(1, RCS / 1.0);

    % 毁伤概率计算
    P_ij = 0.7 * range_factor * rcs_factor + 0.25;

    % 上限约束
    P_ij = min(0.99, P_ij);
end

function P_ij_matrix = compute_kill_prob_matrix(weapon_x, weapon_y, targets, R_max)
    % 计算武器-目标毁伤概率矩阵
    %
    % 输入:
    %   weapon_x, weapon_y - 武器位置
    %   targets            - 目标结构体数组
    %   R_max              - 武器最大射程向量
    %
    % 输出:
    %   P_ij_matrix - m x n 毁伤概率矩阵

    m = length(weapon_x);
    n = length(targets);

    P_ij_matrix = zeros(m, n);

    for i = 1:m
        for j = 1:n
            % 计算距离
            d_ij = sqrt((weapon_x(i) - targets(j).position_x)^2 + ...
                (weapon_y(i) - targets(j).position_y)^2);

            % 计算毁伤概率
            P_ij_matrix(i,j) = compute_kill_prob(d_ij, R_max(i), targets(j).RCS);
        end
    end
end

function p_kj = compute_detection_prob(radar_x, radar_y, targets, lambda, R_radar)
    % 计算雷达探测概率
    %
    % 基于雷达方程:
    %   p = exp(-lambda * d^4 / sigma)
    %
    % 输入:
    %   radar_x, radar_y - 雷达位置
    %   targets          - 目标结构体数组
    %   lambda           - 雷达性能参数
    %   R_radar          - 雷达探测距离
    %
    % 输出:
    %   p_kj - L x n 探测概率矩阵

    L = length(radar_x);
    n = length(targets);

    p_kj = zeros(L, n);

    for k = 1:L
        for j = 1:n
            % 计算距离
            d_kj = sqrt((radar_x(k) - targets(j).position_x)^2 + ...
                (radar_y(k) - targets(j).position_y)^2);

            % 距离约束
            if d_kj > R_radar(k)
                p_kj(k,j) = 0;
                continue;
            end

            % 探测概率
            sigma = targets(j).RCS;
            p_kj(k,j) = exp(-lambda(k) * d_kj^4 / sigma);
            p_kj(k,j) = max(0.05, p_kj(k,j));
        end
    end
end
