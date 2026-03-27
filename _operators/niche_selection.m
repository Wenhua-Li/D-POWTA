% D-POWTA 汉明距离小生境环境选择
%
% 选择策略 (论文4.5节):
%   1. 将候选池按适应度升序排列
%   2. 依次取出候选个体:
%      - 若与已选个体的汉明距离均>delta,直接加入
%      - 否则,与距离最近的已选个体比较,更优则替换
%   3. 重复直至达到种群规模N
%
% 汉明距离定义:
%   d_TC(c, c') = Σ 1[c_j ≠ c'_j]
%
% 使用方式:
%   P_next = niche_selection(R, N, delta)
%
% 输入:
%   R     - 候选池(父代+子代)
%   N     - 目标种群规模
%   delta - 小生境半径
%
% 输出:
%   P_next - 下一代种群
%
% Author: KG-DREA
% Date: 2026-03-18

function P_next = niche_selection(R, N, delta)
    if isempty(R)
        P_next = struct('c', {}, 'allocation', {}, 'fitness', {}, 'feasible', {});
        return;
    end

    % 按适应度升序排列
    fitness_vals = [R.fitness];
    [~, sort_idx] = sort(fitness_vals, 'ascend');
    R_sorted = R(sort_idx);

    % 用 cell 数组收集，避免 struct 数组字段不一致问题
    selected = cell(1, N);
    sel_count = 0;

    % 峰值保护选择
    for i = 1:length(R_sorted)
        candidate = R_sorted(i);

        if sel_count >= N
            break;
        end

        % 检查与已选个体的汉明距离
        is_diverse = true;
        replace_idx = -1;

        for j = 1:sel_count
            d = hamming_distance(candidate.c, selected{j}.c);

            if d <= delta
                % 距离太近,检查是否更优
                is_diverse = false;

                if candidate.fitness < selected{j}.fitness
                    replace_idx = j;
                end
                break;
            end
        end

        if is_diverse
            sel_count = sel_count + 1;
            selected{sel_count} = candidate;
        elseif replace_idx > 0
            selected{replace_idx} = candidate;
        end
    end

    % 如果种群不足,补充随机个体
    while sel_count < N
        idx = randi(length(R_sorted));
        sel_count = sel_count + 1;
        selected{sel_count} = R_sorted(idx);
    end

    % 转换为结构体数组
    if sel_count > 0
        P_next = [selected{1:sel_count}];
    else
        P_next = struct('c', {}, 'allocation', {}, 'fitness', {}, 'feasible', {});
    end
end

%% ==================== 辅助函数 ====================

function d = hamming_distance(c1, c2)
    % 计算两个编码的汉明距离
    d = sum(c1 ~= c2);
end
