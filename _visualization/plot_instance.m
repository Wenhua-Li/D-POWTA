% D-POWTA 算例场景可视化
% 保留原visualize_instances.m的绘图风格
%
% 可视化内容:
%   - 防御区域边界
%   - 来袭区域边界
%   - 武器平台(三角形)及射程圈
%   - 雷达阵地(方形)及探测范围
%   - 来袭目标(圆形)及预测轨迹
%
% 使用方式:
%   plot_instance(instance)
%   plot_instance(instance, 'save_path', 'figure.png')
%
% 输入:
%   instance   - 算例数据
%   varargin   - 可选参数 (save_path, phase)
%
% Author: KG-DREA
% Date: 2026-03-18

function plot_instance(instance, varargin)
    %% 解析输入参数
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);
    addOptional(p, 'phase', 1, @isnumeric);

    parse(p, varargin{:});
    args = p.Results;

    phase = args.phase;

    % 获取阶段数据
    if phase > length(instance.phases)
        error('阶段 %d 超出范围', phase);
    end

    phase_data = instance.phases{phase};
    targets = phase_data.targets;
    n_t = phase_data.n_t;

    %% 创建图形窗口
    fig = figure('Position', [100, 100, 1200, 800], 'Color', [1 1 1]);
    hold on;
    grid on;
    axis equal;

    % 设置坐标轴范围
    xlim([-10, 220]);
    ylim([-10, 210]);

    % 绘制区域边界
    draw_regions();

    % 绘制武器平台
    draw_weapons(instance);

    % 绘制雷达阵地
    draw_radars(instance);

    % 绘制目标
    draw_targets(targets, n_t);

    % 添加图例
    add_legend();

    % 添加标题和标签
    title(sprintf('%s - 阶段 %d', instance.name, phase), ...
        'FontSize', 16, 'FontWeight', 'bold');
    xlabel('X (km)', 'FontSize', 12);
    ylabel('Y (km)', 'FontSize', 12);

    % 添加统计信息
    add_statistics(targets, instance);

    hold off;

    %% 保存图像
    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
        fprintf('图像已保存至: %s\n', args.save_path);
    end
end

%% ==================== 绘制区域 ====================

function draw_regions()
    % 防御区域
    rectangle('Position', [0, 50, 50, 100], ...
        'EdgeColor', [0.2, 0.6, 0.2], 'LineWidth', 2, 'LineStyle', '--');
    text(25, 45, '防御区域', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Color', [0.2, 0.6, 0.2]);

    % 来袭区域
    rectangle('Position', [100, 0, 100, 200], ...
        'EdgeColor', [0.8, 0.2, 0.2], 'LineWidth', 2, 'LineStyle', '--');
    text(150, 195, '来袭区域', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Color', [0.8, 0.2, 0.2]);
end

%% ==================== 绘制武器 ====================

function draw_weapons(instance)
    weapon_colors = lines(instance.m);

    for i = 1:instance.m
        wx = instance.weapon_x(i);
        wy = instance.weapon_y(i);

        % 武器位置
        plot(wx, wy, '^', 'MarkerSize', 15, 'MarkerFaceColor', weapon_colors(i,:), ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

        % 射程圈
        theta = linspace(0, 2*pi, 100);
        x_circle = wx + instance.R_max(i) * cos(theta);
        y_circle = wy + instance.R_max(i) * sin(theta);
        plot(x_circle, y_circle, '-', 'Color', weapon_colors(i,:), ...
            'LineWidth', 1, 'LineStyle', ':');

        % 标注
        text(wx+3, wy+3, sprintf('W%d', i), 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', weapon_colors(i,:));
    end
end

%% ==================== 绘制雷达 ====================

function draw_radars(instance)
    radar_colors = cool(instance.L);

    for k = 1:instance.L
        rx = instance.radar_x(k);
        ry = instance.radar_y(k);

        % 雷达位置
        plot(rx, ry, 's', 'MarkerSize', 12, 'MarkerFaceColor', radar_colors(k,:), ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

        % 探测范围圈
        theta = linspace(0, 2*pi, 100);
        x_circle = rx + instance.R_radar(k) * cos(theta);
        y_circle = ry + instance.R_radar(k) * sin(theta);
        plot(x_circle, y_circle, '-', 'Color', radar_colors(k,:), ...
            'LineWidth', 1, 'LineStyle', '-.');

        % 标注
        text(rx+3, ry-5, sprintf('R%d', k), 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', radar_colors(k,:));
    end
end

%% ==================== 绘制目标 ====================

function draw_targets(targets, n_t)
    for j = 1:n_t
        tx = targets(j).position_x;
        ty = targets(j).position_y;
        threat = targets(j).threat;
        speed = targets(j).speed;
        heading = targets(j).heading;

        % 颜色基于威胁等级
        color_intensity = threat;
        target_color = [1, 1-color_intensity*0.7, 1-color_intensity*0.7];

        % 目标标记
        plot(tx, ty, 'o', 'MarkerSize', 8+threat*6, 'MarkerFaceColor', target_color, ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1);

        % 目标编号
        text(tx+2, ty+2, sprintf('T%d', j), 'FontSize', 8, ...
            'FontWeight', 'bold', 'Color', 'k');

        % 预测轨迹
        heading_rad = heading * pi / 180;
        trajectory_length = 50;
        intercept_x = tx + trajectory_length * cos(heading_rad);
        intercept_y = ty + trajectory_length * sin(heading_rad);
        quiver(tx, ty, intercept_x-tx, intercept_y-ty, 0, ...
            'Color', target_color, 'LineWidth', 1.5, 'MaxHeadSize', 5);

        % 速度矢量
        vx = speed * cos(heading_rad) * 20;
        vy = speed * sin(heading_rad) * 20;
        plot([tx, tx+vx], [ty, ty+vy], 'b-', 'LineWidth', 1.5);
    end
end

%% ==================== 添加图例 ====================

function add_legend()
    legend_elements = [];
    legend_names = {};

    % 防御区域
    legend_elements(end+1) = plot(NaN, NaN, '--', 'Color', [0.2, 0.6, 0.2], 'LineWidth', 2);
    legend_names{end+1} = '防御区域';

    % 来袭区域
    legend_elements(end+1) = plot(NaN, NaN, '--', 'Color', [0.8, 0.2, 0.2], 'LineWidth', 2);
    legend_names{end+1} = '来袭区域';

    % 发射阵地
    legend_elements(end+1) = plot(NaN, NaN, '^', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0, 0.5, 1], 'MarkerEdgeColor', 'k');
    legend_names{end+1} = '发射阵地 (W)';

    % 雷达阵地
    legend_elements(end+1) = plot(NaN, NaN, 's', 'MarkerSize', 8, ...
        'MarkerFaceColor', [0, 0.7, 0.7], 'MarkerEdgeColor', 'k');
    legend_names{end+1} = '雷达阵地 (R)';

    % 来袭目标
    legend_elements(end+1) = plot(NaN, NaN, 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [1, 0.3, 0.3], 'MarkerEdgeColor', 'k');
    legend_names{end+1} = '来袭目标 (T)';

    % 预测轨迹
    legend_elements(end+1) = plot(NaN, NaN, 'k-', 'LineWidth', 1.5);
    legend_names{end+1} = '预测轨迹';

    legend(legend_elements, legend_names, 'Location', 'northwest', 'FontSize', 10);
end

%% ==================== 添加统计信息 ====================

function add_statistics(targets, instance)
    stats_text = sprintf(['统计信息:\n' ...
        '武器数量: %d\n' ...
        '雷达数量: %d\n' ...
        '目标数量: %d\n' ...
        '平均威胁: %.2f\n' ...
        '速度范围: %.2f-%.2f km/s'], ...
        instance.m, instance.L, length(targets), ...
        mean([targets.threat]), ...
        min([targets.speed]), max([targets.speed]));

    text(205, 150, stats_text, 'FontSize', 10, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.9, 0.9, 0.9], 'EdgeColor', 'k');
end
