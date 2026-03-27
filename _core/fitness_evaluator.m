% D-POWTA 适应度评估器
%
% 目标函数定义 (论文公式):
%   min F_t(X_t) = Σ Th_jt * ∏_{i=1}^m ∏_{k=1}^L (1 - P_ijkt)^{x_ijkt}
%
% 即: 最小化经探测质量加权后的全场残余威胁总量
%
% 使用方式:
%   fitness = fitness_evaluator(allocation, phase_data, instance)
%
% 输入:
%   allocation - 分配矩阵结构体 (x_ijkt)
%   phase_data - 阶段数据
%   instance   - 算例数据
%
% 输出:
%   fitness - 适应度值 (越小越优)
%
% Author: KG-DREA
% Date: 2026-03-18

function fitness = fitness_evaluator(allocation, phase_data, instance)
    targets = phase_data.targets;
    n_t = phase_data.n_t;
    eta_j = phase_data.eta_j;  % MRFDQI

    % 计算约束违反惩罚（惩罚权重应足够大，使不可行解被淘汰）
    penalty_weight = 1000;
    penalty = 0;

    % C1: 武器弹药约束违反惩罚
    ammo = phase_data.available;
    n_weapons = length(allocation.weapon_used);
    for i = 1:n_weapons
        if allocation.weapon_used(i) > ammo(i)
            penalty = penalty + (allocation.weapon_used(i) - ammo(i)) * penalty_weight;
        end
    end

    % C9: 雷达通道约束违反惩罚
    n_radars = length(allocation.radar_used);
    for k = 1:n_radars
        if allocation.radar_used(k) > instance.C_track(k)
            penalty = penalty + (allocation.radar_used(k) - instance.C_track(k)) * penalty_weight;
        end
    end

    % 获取目标威胁等级
    Th = zeros(1, n_t);
    for j = 1:n_t
        Th(j) = targets(j).threat;
    end

    % 计算每个目标的残存概率
    survival_prob = zeros(1, n_t);

    for j = 1:n_t
        % 获取目标j的分配
        x_ij = squeeze(allocation.x_ijkt(:, j, :));  % m x L

        % 计算联合未毁伤概率
        prod_prob = 1;

        for i = 1:size(x_ij, 1)
            for k = 1:size(x_ij, 2)
                x_ijkt = x_ij(i, k);
                if x_ijkt > 0
                    % 获取毁伤概率
                    P_ijkt = phase_data.P_ij(i, j);
                    if P_ijkt > 0
                        % 多发弹药独立毁伤
                        prod_prob = prod_prob * (1 - P_ijkt)^x_ijkt;
                    end
                end
            end
        end

        survival_prob(j) = prod_prob;
    end

    % MRFDQI加权残余威胁
    weighted_threat = Th .* eta_j .* survival_prob;

    % 目标函数值
    fitness = sum(weighted_threat) + penalty;

    % 确保数值稳定性
    if isnan(fitness) || isinf(fitness)
        fitness = 1e10;
    end
end
