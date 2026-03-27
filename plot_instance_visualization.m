% D-POWTA 算例可视化脚本
% 显示防御区域、武器阵地+射程圈、雷达阵地+探测范围、来袭目标+预测轨迹

%% 单个算例可视化函数
function plot_instance_visualization(instance, phase)
    % 创建图形窗口
    fig = figure('Position', [100, 100, 1200, 800], 'Color', [1 1 1]);
    hold on;
    grid on;
    axis equal;

    % 设置坐标轴范围
    xlim([-10, 220]);
    ylim([-10, 210]);

    % 防御区域边界
    rectangle('Position', [0, 50, 50, 100], ...
        'EdgeColor', [0.2, 0.6, 0.2], 'LineWidth', 2, 'LineStyle', '--');
    text(25, 45, '防御区域', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Color', [0.2, 0.6, 0.2]);

    % 来袭区域边界
    rectangle('Position', [100, 0, 100, 200], ...
        'EdgeColor', [0.8, 0.2, 0.2], 'LineWidth', 2, 'LineStyle', '--');
    text(150, 195, '来袭区域', 'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'Color', [0.8, 0.2, 0.2]);

    % 绘制武器（发射阵地）+ 射程圈
    weapon_colors = lines(max(instance.m, 6));
    for i = 1:instance.m
        wx = instance.weapon_x(i);
        wy = instance.weapon_y(i);

        plot(wx, wy, '^', 'MarkerSize', 15, 'MarkerFaceColor', weapon_colors(i,:), ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

        % 射程圈
        theta = linspace(0, 2*pi, 100);
        x_circle = wx + instance.R_max(i) * cos(theta);
        y_circle = wy + instance.R_max(i) * sin(theta);
        plot(x_circle, y_circle, '-', 'Color', weapon_colors(i,:), 'LineWidth', 1, 'LineStyle', ':');

        text(wx+3, wy+3, sprintf('W%d', i), 'FontSize', 10, 'FontWeight', 'bold', ...
            'Color', weapon_colors(i,:));
    end

    % 绘制雷达阵地 + 探测范围圈
    radar_colors = cool(max(instance.L, 6));
    for k = 1:instance.L
        rx = instance.radar_x(k);
        ry = instance.radar_y(k);

        plot(rx, ry, 's', 'MarkerSize', 12, 'MarkerFaceColor', radar_colors(k,:), ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

        % 探测范围圈
        theta = linspace(0, 2*pi, 100);
        x_circle = rx + instance.R_radar(k) * cos(theta);
        y_circle = ry + instance.R_radar(k) * sin(theta);
        plot(x_circle, y_circle, '-', 'Color', radar_colors(k,:), 'LineWidth', 1, 'LineStyle', '-.');

        text(rx+3, ry-5, sprintf('R%d', k), 'FontSize', 10, 'FontWeight', 'bold', ...
            'Color', radar_colors(k,:));
    end

    % 绘制目标和预测轨迹
    phase_data = instance.phases{phase};
    target_data = phase_data.targets;
    n_t = phase_data.n_t;

    % 显示前30个目标以避免图形过于拥挤
    display_limit = min(n_t, 30);

    for j = 1:display_limit
        tx = target_data(j).position_x;
        ty = target_data(j).position_y;
        threat = target_data(j).threat;
        speed = target_data(j).speed;
        heading = target_data(j).heading;

        % 根据威胁等级设置颜色
        color_intensity = threat;
        target_color = [1, 1-color_intensity*0.7, 1-color_intensity*0.7];

        % 绘制目标
        plot(tx, ty, 'o', 'MarkerSize', 8+threat*6, 'MarkerFaceColor', target_color, ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1);

        % 标注目标编号
        text(tx+2, ty+2, sprintf('T%d', j), 'FontSize', 8, 'FontWeight', 'bold', ...
            'Color', 'k');

        % 预测轨迹（指向防御区域）
        heading_rad = heading * pi / 180;
        trajectory_length = 40;
        intercept_x = tx + trajectory_length * cos(heading_rad);
        intercept_y = ty + trajectory_length * sin(heading_rad);
        quiver(tx, ty, intercept_x-tx, intercept_y-ty, 0, ...
            'Color', target_color, 'LineWidth', 1.5, 'MaxHeadSize', 5);
    end

    % 如果目标过多，显示提示
    if n_t > display_limit
        text(200, 180, sprintf('(显示前%d个目标)', display_limit), ...
            'FontSize', 10, 'HorizontalAlignment', 'right', 'Color', [0.5 0.5 0.5]);
    end

    % 图例
    legend_elements = [];
    legend_names = {};

    legend_elements(end+1) = plot(NaN, NaN, '--', 'Color', [0.2, 0.6, 0.2], 'LineWidth', 2);
    legend_names{end+1} = '防御区域';
    legend_elements(end+1) = plot(NaN, NaN, '--', 'Color', [0.8, 0.2, 0.2], 'LineWidth', 2);
    legend_names{end+1} = '来袭区域';
    legend_elements(end+1) = plot(NaN, NaN, '^', 'MarkerSize', 10, 'MarkerFaceColor', weapon_colors(1,:), 'MarkerEdgeColor', 'k');
    legend_names{end+1} = sprintf('发射阵地 (W) x%d', instance.m);
    legend_elements(end+1) = plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', radar_colors(1,:), 'MarkerEdgeColor', 'k');
    legend_names{end+1} = sprintf('雷达阵地 (R) x%d', instance.L);
    legend_elements(end+1) = plot(NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [1, 0.3, 0.3], 'MarkerEdgeColor', 'k');
    legend_names{end+1} = sprintf('来袭目标 (T) x%d', n_t);
    legend_elements(end+1) = plot(NaN, NaN, 'k-', 'LineWidth', 1.5);
    legend_names{end+1} = '预测轨迹';

    legend(legend_elements, legend_names, 'Location', 'northwest', 'FontSize', 10);

    % 标题
    title_str = sprintf('%s - 阶段%d (n=%d, m=%d, L=%d)', ...
        instance.name, phase, n_t, instance.m, instance.L);
    title(title_str, 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('X (km)', 'FontSize', 12);
    ylabel('Y (km)', 'FontSize', 12);

    % 统计信息
    avg_threat = mean([target_data.threat]);
    avg_speed = mean([target_data.speed]);
    stats_text = sprintf(['统计信息:\n' ...
        '武器数量: %d\n' ...
        '雷达数量: %d\n' ...
        '目标数量: %d\n' ...
        '平均威胁: %.2f\n' ...
        '平均速度: %.2f km/s'], ...
        instance.m, instance.L, n_t, avg_threat, avg_speed);

    text(205, 150, stats_text, 'FontSize', 10, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.9, 0.9, 0.9], 'EdgeColor', 'k');

    hold off;

    % 保存图像
    % saveas(fig, save_path);
    % close(fig);
end
