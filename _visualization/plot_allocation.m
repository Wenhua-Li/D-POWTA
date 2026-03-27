% D-POWTA 分配方案可视化
% 显示各阶段的武器-目标分配方案
%
% 使用方式:
%   plot_allocation(instance, solution, phase)
%   plot_allocation(instance, solution, phase, 'save_path', 'fig.png')
%
% 输入:
%   instance   - 算例数据
%   solution   - 解结构体
%   phase      - 阶段编号
%
% Author: KG-DREA
% Date: 2026-03-18

function plot_allocation(instance, solution, phase, varargin)
    %% 解析输入
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);

    parse(p, varargin{:});
    args = p.Results;

    %% 获取数据
    phase_data = instance.phases{phase};
    targets = phase_data.targets;
    allocation = solution.allocation;

    %% 创建图形
    fig = figure('Position', [100, 100, 1200, 800], 'Color', [1 1 1]);
    hold on;
    grid on;
    axis equal;

    xlim([-10, 220]);
    ylim([-10, 210]);

    % 绘制基础场景
    draw_scene(instance, phase);

    % 绘制分配连线
    draw_allocation_lines(instance, targets, allocation);

    % 标题
    title(sprintf('阶段 %d 分配方案 (Fitness: %.4f, RMI: %.4f)', ...
        phase, solution.fitness, solution.rmi), ...
        'FontSize', 14, 'FontWeight', 'bold');

    hold off;

    % 保存
    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
    end
end

%% ==================== 绘制场景基础元素 ====================

function draw_scene(instance, phase)
    % 防御区域
    rectangle('Position', [0, 50, 50, 100], ...
        'EdgeColor', [0.2, 0.6, 0.2], 'LineWidth', 2, 'LineStyle', '--');

    % 来袭区域
    rectangle('Position', [100, 0, 100, 200], ...
        'EdgeColor', [0.8, 0.2, 0.2], 'LineWidth', 2, 'LineStyle', '--');

    % 武器
    weapon_colors = lines(instance.m);
    for i = 1:instance.m
        plot(instance.weapon_x(i), instance.weapon_y(i), '^', ...
            'MarkerSize', 12, 'MarkerFaceColor', weapon_colors(i,:), ...
            'MarkerEdgeColor', 'k');
        text(instance.weapon_x(i)+2, instance.weapon_y(i)+2, sprintf('W%d', i), ...
            'FontSize', 9, 'FontWeight', 'bold');
    end

    % 雷达
    radar_colors = cool(instance.L);
    for k = 1:instance.L
        plot(instance.radar_x(k), instance.radar_y(k), 's', ...
            'MarkerSize', 10, 'MarkerFaceColor', radar_colors(k,:), ...
            'MarkerEdgeColor', 'k');
    end
end

%% ==================== 绘制分配连线 ====================

function draw_allocation_lines(instance, targets, allocation)
    [m, n_t, L] = size(allocation.x_ijkt);

    % 武器颜色映射
    weapon_colors = lines(m);

    for j = 1:n_t
        tx = targets(j).position_x;
        ty = targets(j).position_y;
        threat = targets(j).threat;

        % 绘制目标
        target_color = [1, 1-threat*0.7, 1-threat*0.7];
        plot(tx, ty, 'o', 'MarkerSize', 8+threat*4, ...
            'MarkerFaceColor', target_color, 'MarkerEdgeColor', 'k');
        text(tx+2, ty+2, sprintf('T%d', j), 'FontSize', 8);

        % 绘制分配连线
        for i = 1:m
            for k = 1:L
                s = allocation.x_ijkt(i, j, k);

                if s > 0
                    wx = instance.weapon_x(i);
                    wy = instance.weapon_y(i);

                    % 线条颜色基于武器
                    line_color = weapon_colors(i,:);

                    % 绘制连线
                    line_width = 1 + s;
                    plot([wx, tx], [wy, ty], '-', ...
                        'Color', line_color, 'LineWidth', line_width, ...
                        'Marker', 'o', 'MarkerSize', 3);

                    % 标注弹药数
                    mid_x = (wx + tx) / 2;
                    mid_y = (wy + ty) / 2;
                    text(mid_x, mid_y, sprintf('×%d', s), ...
                        'FontSize', 8, 'Color', line_color, ...
                        'BackgroundColor', 'w');
                end
            end
        end
    end
end
