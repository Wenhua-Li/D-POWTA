% D-POWTA 收敛曲线可视化
%
% 使用方式:
%   plot_convergence(result)
%   plot_convergence(result, 'save_path', 'convergence.png')
%
% 输入:
%   result - KG-DREA求解结果
%
% Author: KG-DREA
% Date: 2026-03-18

function plot_convergence(result, varargin)
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);
    parse(p, varargin{:});
    args = p.Results;

    T_total = length(result.phases);

    fig = figure('Position', [100, 100, 1000, 600], 'Color', [1 1 1]);

    % 绘制各阶段收敛曲线
    for t = 1:T_total
        subplot(ceil(T_total/2), 2, t);
        hold on;

        history = result.phases{t}.fitness_history;
        mean_history = result.phases{t}.mean_fitness_history;

        if ~isempty(history)
            plot(1:length(history), history, 'b-', 'LineWidth', 2, 'DisplayName', '最优适应度');
            if ~isempty(mean_history)
                plot(1:length(mean_history), mean_history, 'r--', 'LineWidth', 1.5, 'DisplayName', '平均适应度');
                legend('Location', 'best');
            end
            xlabel('代数');
            ylabel('适应度');
            title(sprintf('阶段 %d 收敛曲线', t));
            grid on;
        end
    end

    sgtitle([result.algorithm ' 收敛曲线 - ' result.instance_name], ...
        'FontSize', 14, 'FontWeight', 'bold');

    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
    end
end

%% ==================== 多算法对比收敛曲线 ====================

function plot_comparison(results, varargin)
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);
    addOptional(p, 'algorithms', {'KG-DREA', 'GA', 'LKEA', 'HA'});
    parse(p, varargin{:});
    args = p.Results;

    fig = figure('Position', [100, 100, 1000, 600], 'Color', [1 1 1]);
    hold on;

    colors = {'b-', 'r--', 'g-.', 'm:'};
    markers = {'o', 's', '^', 'd'};

    for i = 1:length(results)
        result = results{i};
        if isempty(result) || isempty(result.phases)
            continue;
        end

        history = result.phases{1}.fitness_history;
        if ~isempty(history)
            plot(1:length(history), history, colors{i}, ...
                'LineWidth', 2, 'Marker', markers{i}, 'MarkerIndices', 1:10:length(history));
        end
    end

    xlabel('代数');
    ylabel('适应度 (残余威胁)');
    title('算法收敛曲线对比');
    legend(args.algorithms, 'Location', 'best');
    grid on;

    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
    end
end
