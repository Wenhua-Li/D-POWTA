% D-POWTA MRFDQI计算工具
%
% MRFDQI (Multi-Radar Fusion Detection Quality Index):
%   η_jt = 1 - ∏_{k∈B_jt} (1 - p_kj)
%
% 其中:
%   - p_kj: 雷达k对目标j的探测概率
%   - B_jt: 有效探测雷达子集 (满足距离和概率阈值约束)
%
% 使用方式:
%   eta_j = compute_mrfdqi(p_kj, p_th)
%   eta_j = compute_mrfdqi_from_instance(instance, phase_data)
%
% Author: KG-DREA
% Date: 2026-03-18

function eta_j = compute_mrfdqi(p_kj, p_th, R_radar, d_kj)
    % 直接计算MRFDQI
    %
    % 输入:
    %   p_kj     - L x n 探测概率矩阵
    %   p_th     - 探测概率阈值
    %   R_radar  - 雷达探测距离 (可选)
    %   d_kj     - 雷达-目标距离 (可选)

    [L, n] = size(p_kj);
    eta_j = zeros(1, n);

    for j = 1:n
        % 确定有效探测雷达集合
        if nargin >= 3 && ~isempty(R_radar)
            % 使用距离约束
            valid_idx = find(p_kj(:, j) >= p_th & d_kj(:, j) <= R_radar(:));
        else
            % 仅使用概率阈值
            valid_idx = find(p_kj(:, j) >= p_th);
        end

        if isempty(valid_idx)
            % 无有效探测雷达
            eta_j(j) = 0;
        else
            % 计算融合探测质量
            prod_term = 1;
            for k = valid_idx'
                prod_term = prod_term * (1 - p_kj(k, j));
            end
            eta_j(j) = 1 - prod_term;
            eta_j(j) = max(0.1, eta_j(j));  % 最小值约束
        end
    end
end

function eta_j = compute_mrfdqi_from_instance(instance, phase_data)
    % 从完整算例数据计算MRFDQI
    %
    % 输入:
    %   instance   - 算例数据
    %   phase_data - 阶段数据

    targets = phase_data.targets;
    n_t = phase_data.n_t;
    L = instance.L;

    % 雷达参数
    radar_x = instance.radar_x;
    radar_y = instance.radar_y;
    lambda = instance.lambda;
    R_radar = instance.R_radar;
    p_th = instance.p_th;

    % 计算各雷达对各目标的探测概率
    p_kj = zeros(L, n_t);
    d_kj = zeros(L, n_t);

    for k = 1:L
        for j = 1:n_t
            % 距离计算
            d_kj(k,j) = sqrt((radar_x(k) - targets(j).position_x)^2 + ...
                (radar_y(k) - targets(j).position_y)^2);

            % 探测概率计算 (雷达方程)
            if d_kj(k,j) <= R_radar(k)
                sigma = targets(j).RCS;
                p_kj(k,j) = exp(-lambda(k) * d_kj(k,j)^4 / sigma);
                p_kj(k,j) = max(0.05, p_kj(k,j));
            else
                p_kj(k,j) = 0;
            end
        end
    end

    % 计算MRFDQI
    eta_j = compute_mrfdqi(p_kj, p_th, R_radar, d_kj);
end
