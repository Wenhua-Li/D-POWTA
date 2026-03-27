% D-POWTA 全局资源约束修复
%
% 约束说明:
%   - C1: 武器平台弹药总量约束
%   - C9: 雷达火控通道容量约束
%
% 修复策略:
%   1. 按威胁优先级降序排列目标
%   2. 依次检查资源约束
%   3. 若触发超限,在可行组合中搜索替代方案
%   4. 无可行替代则令c_jt = 0(不拦截)
%
% 使用方式:
%   Q = repair_constraints(Q, phase_data, instance, A_jt)
%
% 输入:
%   Q          - 待修复种群
%   phase_data - 阶段数据
%   instance   - 算例数据
%   A_jt       - 有效配对集
%
% 输出:
%   Q - 修复后的种群
%
% Author: KG-DREA
% Date: 2026-03-18

function Q = repair_constraints(Q, phase_data, instance, A_jt)
    targets = phase_data.targets;
    n_t = phase_data.n_t;
    ammo = phase_data.available;
    C_track = instance.C_track;
    m = instance.m;
    L = instance.L;

    for i = 1:length(Q)
        c = Q(i).c;

        % 按威胁优先级排序目标索引
        [~, threat_order] = sort([targets.threat], 'descend');

        % 修复C1(武器弹药约束)和C9(雷达通道约束)
        c = repair_c1_c9(c, threat_order, A_jt, targets, ammo, C_track, m, L);

        Q(i).c = c;
        Q(i).allocation = encoding_decode(c, A_jt);
    end
end

%% ==================== 约束修复 ====================

function c = repair_c1_c9(c, threat_order, A_jt, targets, ammo, C_track, m, L)
    n_t = length(c);

    % 分配跟踪
    weapon_used = zeros(1, m);
    radar_used = zeros(1, L);

    % 第一次扫描: 记录当前使用量
    for j = 1:n_t
        combo_idx = c(j);
        if combo_idx > 0 && combo_idx <= length(A_jt(j).combos)
            combo = A_jt(j).combos{combo_idx};
            i = combo(1);
            k = combo(2);
            s = combo(3);

            if i > 0 && k > 0
                weapon_used(i) = weapon_used(i) + s;
                radar_used(k) = radar_used(k) + s;
            end
        end
    end

    % 第二次扫描: 按威胁优先级修复
    for j = threat_order
        combo_idx = c(j);

        if combo_idx == 0
            continue;
        end

        if combo_idx > length(A_jt(j).combos)
            c(j) = 0;
            continue;
        end

        combo = A_jt(j).combos{combo_idx};
        i = combo(1);
        k = combo(2);
        s = combo(3);

        if i == 0 || k == 0
            continue;
        end

        % 检查C1: 武器弹药约束
        weapon_exceed = weapon_used(i) > ammo(i);
        % 检查C9: 雷达通道约束
        radar_exceed = radar_used(k) > C_track(k);

        if weapon_exceed || radar_exceed
            % 尝试寻找替代组合
            new_idx = find_alternative_combination(...
                A_jt(j), ammo, C_track, weapon_used, radar_used, targets(j));

            if new_idx > 0
                % 找到替代,更新分配
                old_combo = A_jt(j).combos{combo_idx};
                old_i = old_combo(1);
                old_k = old_combo(2);
                old_s = old_combo(3);

                weapon_used(old_i) = weapon_used(old_i) - old_s;
                radar_used(old_k) = radar_used(old_k) - old_s;

                new_combo = A_jt(j).combos{new_idx};
                new_i = new_combo(1);
                new_k = new_combo(2);
                new_s = new_combo(3);

                weapon_used(new_i) = weapon_used(new_i) + new_s;
                radar_used(new_k) = radar_used(new_k) + new_s;

                c(j) = new_idx;
            else
                % 无可行替代,移除该分配
                weapon_used(i) = weapon_used(i) - s;
                radar_used(k) = radar_used(k) - s;
                c(j) = 0;
            end
        end
    end
end

function new_idx = find_alternative_combination(A_j, ammo, C_track, weapon_used, radar_used, target)
    % 为目标j寻找替代组合
    combos = A_j.combos;

    % 按毁伤概率排序尝试(简化)
    best_idx = 0;

    for idx = 1:length(combos)
        combo = combos{idx};

        if combo(1) == 0 || combo(2) == 0
            continue;
        end

        i = combo(1);
        k = combo(2);
        s = combo(3);

        % 检查资源约束
        if weapon_used(i) + s <= ammo(i) && radar_used(k) + s <= C_track(k)
            best_idx = idx;
            break;  % 找到第一个可行的
        end
    end

    new_idx = best_idx;
end
