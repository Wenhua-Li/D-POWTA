% D-POWTA 距离计算工具
%
% 功能:
%   - 计算武器-目标欧氏距离
%   - 计算雷达-目标欧氏距离
%   - 计算武器-雷达通信距离
%
% 使用方式:
%   d = compute_distance(x1, y1, x2, y2)
%   d_ij = compute_weapon_target_distance(instance)
%
% Author: KG-DREA
% Date: 2026-03-18

function d = compute_distance(x1, y1, x2, y2)
    % 计算两点间欧氏距离
    d = sqrt((x1 - x2).^2 + (y1 - y2).^2);
end

function d_ij = compute_weapon_target_distance(weapon_x, weapon_y, target_x, target_y)
    % 计算武器-目标距离矩阵
    m = length(weapon_x);
    n = length(target_x);

    d_ij = zeros(m, n);

    for i = 1:m
        for j = 1:n
            d_ij(i,j) = sqrt((weapon_x(i) - target_x(j))^2 + ...
                (weapon_y(i) - target_y(j))^2);
        end
    end
end

function d_kj = compute_radar_target_distance(radar_x, radar_y, target_x, target_y)
    % 计算雷达-目标距离矩阵
    L = length(radar_x);
    n = length(target_x);

    d_kj = zeros(L, n);

    for k = 1:L
        for j = 1:n
            d_kj(k,j) = sqrt((radar_x(k) - target_x(j))^2 + ...
                (radar_y(k) - target_y(j))^2);
        end
    end
end

function d_ik = compute_weapon_radar_distance(weapon_x, weapon_y, radar_x, radar_y)
    % 计算武器-雷达通信距离矩阵
    m = length(weapon_x);
    L = length(radar_x);

    d_ik = zeros(m, L);

    for i = 1:m
        for k = 1:L
            d_ik(i,k) = sqrt((weapon_x(i) - radar_x(k))^2 + ...
                (weapon_y(i) - radar_y(k))^2);
        end
    end
end
