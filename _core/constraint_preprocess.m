% D-POWTA 约束预处理
% 为每个目标构造可行交战组合集A_jt
%
% 约束预处理流程:
%   1. 有效探测雷达子集 B_jt (C6, C7)
%   2. 可行平台-雷达对 W_jkt (C2, C4, C5, C8, C12)
%   3. 弹药数量枚举 (C3)
%   4. C9启发式剪枝
%   5. C11可行性预检
%
% 使用方式:
%   A = constraint_preprocess(phase_data, instance, params)
%
% 输入:
%   phase_data - 阶段数据结构体
%   instance   - 算例结构体
%   params     - 参数结构体
%
% 输出:
%   A - 有效配对集, 结构体数组 A(j).combos = {[i,k,s], ...}
%
% Author: KG-DREA
% Date: 2026-03-18

function A = constraint_preprocess(phase_data, instance, params)
    n_t = phase_data.n_t;
    targets = phase_data.targets;
    m = instance.m;
    L = instance.L;

    % 提取参数
    weapon_x = instance.weapon_x;
    weapon_y = instance.weapon_y;
    R_max = instance.R_max;
    tau_react = instance.tau_react;
    v_weapon = instance.v_weapon;
    priority = instance.priority;
    ammo = phase_data.available;

    radar_x = instance.radar_x;
    radar_y = instance.radar_y;
    lambda = instance.lambda;
    R_radar = instance.R_radar;
    p_th = instance.p_th;
    alpha = instance.alpha;
    C_track = instance.C_track;

    % 初始化有效配对集
    A = struct('target_id', {}, 'combos', {}, 'H_jt', {});

    for j = 1:n_t
        target = targets(j);
        A(j).target_id = target.id;
        A(j).combos = {};

        % 步骤1: 构造有效探测雷达子集 B_jt (C6, C7)
        B_jt = [];  % 有效雷达索引
        p_kj = zeros(1, L);

        for k = 1:L
            % 计算雷达-目标距离
            d_kj = sqrt((radar_x(k) - target.position_x)^2 + ...
                (radar_y(k) - target.position_y)^2);

            % C6: 探测距离约束
            if d_kj <= R_radar(k)
                % 计算探测概率
                sigma = target.RCS;
                p_detect = exp(-lambda(k) * d_kj^4 / sigma);
                p_detect = max(0.05, p_detect);
                p_kj(k) = p_detect;

                % C7: 探测概率阈值约束
                if p_detect >= p_th
                    B_jt = [B_jt, k];
                end
            end
        end

        % 若无有效探测雷达，该目标不可拦截
        if isempty(B_jt)
            A(j).combos = {[0, 0, 0]};  % 空动作
            A(j).H_jt = 0;
            continue;
        end

        % 步骤2: 构造可行平台-雷达对
        combos = {};

        for k = B_jt
            for i = 1:m
                % 检查武器-雷达协同能力 (C8)
                if alpha(i, k) == 0
                    continue;
                end

                % 检查武器可用状态 (C2)
                if ammo(i) <= 0
                    continue;
                end

                % 计算武器-目标距离
                d_ij = sqrt((weapon_x(i) - target.position_x)^2 + ...
                    (weapon_y(i) - target.position_y)^2);

                % C4: 射程有效性约束
                if d_ij > R_max(i)
                    continue;
                end

                % C5: 打击时效性约束 (打击窗口)
                intercept_time = tau_react(i) + d_ij / v_weapon(i);
                if intercept_time > target.W
                    continue;
                end

                % C12: 武器优先级匹配约束
                % 简化: 高优先级武器应对高威胁目标
                if priority(i) < 2 && target.threat > 0.7
                    continue;
                end

                % 步骤3: 枚举弹药数量 (C3)
                max_s = min(ammo(i), target.U);
                for s = 1:max_s
                    combos{end+1} = [i, k, s];  %#ok<AGROW>
                end
            end
        end

        % 步骤4: C9启发式剪枝 (雷达火控通道容量)
        % 简化为不限制，由约束修复处理

        % 步骤5: C11可行性预检 (最低毁伤概率)
        % 简化: 保留所有组合

        % 添加"不拦截"选项
        if ~isempty(combos)
            combos{end+1} = [0, 0, 0];  % 不拦截
        else
            combos = {[0, 0, 0]};  % 只能不拦截
        end

        A(j).combos = combos;
        A(j).H_jt = length(combos) - 1;  % 可行组合数量(不含不拦截)
    end
end
