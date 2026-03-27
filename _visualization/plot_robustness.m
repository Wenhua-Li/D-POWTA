% D-POWTA 鲁棒性指标可视化
%
% 使用方式:
%   plot_robustness(result)
%   plot_robustness(result, 'save_path', 'robustness.png')
%
% 输入:
%   result - KG-DREA求解结果
%
% Author: KG-DREA
% Date: 2026-03-18

function plot_robustness(result, varargin)
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);
    parse(p, varargin{:});
    args = p.Results;

    T_total = length(result.phases);

    fig = figure('Position', [100, 100, 1200, 400], 'Color', [1 1 1]);

    % 子图1: 各阶段RMI值
    subplot(1, 2, 1);
    phases = 1:T_total;
    rmi_values = zeros(1, T_total);
    for t = 1:T_total
        rmi_values(t) = result.phases{t}.solution.rmi;
    end

    bar(phases, rmi_values, 'FaceColor', [0.2, 0.6, 0.8]);
    xlabel('阶段');
    ylabel('RMI (鲁棒性指标)');
    title('各阶段方案RMI值');
    grid on;

    % 子图2: 残余威胁演变
    subplot(1, 2, 2);
    residual_threat = zeros(1, T_total);
    for t = 1:T_total
        residual_threat(t) = result.phases{t}.solution.fitness;
    end

    plot(phases, residual_threat, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('阶段');
    ylabel('残余威胁');
    title('残余威胁演变趋势');
    grid on;

    sgtitle(['鲁棒性指标分析 - ' result.instance_name], ...
        'FontSize', 14, 'FontWeight', 'bold');

    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
    end
end
